const crypto = require('crypto'); const bcrypt = require('bcrypt');
const { getModels } = require('../models');

const ACTIVE_STATUSES = Object.freeze(['IDENTITY_VERIFICATION_REQUIRED', 'VERIFIED', 'PROCESSING']);
const TRANSITIONS = Object.freeze({
  IDENTITY_VERIFICATION_REQUIRED: ['VERIFIED', 'FAILED'],
  VERIFIED: ['PROCESSING', 'FAILED'],
  PROCESSING: ['COMPLETED', 'FAILED'],
  COMPLETED: [],
  FAILED: [],
});

const nullable = (row, field) => row.get(field) ?? null;
const safeRequest = (row) => ({
  id: String(row.id), requestType: row.requestType, status: row.status,
  requestedAt: row.requestedAt, identityVerifiedAt: nullable(row, 'identityVerifiedAt'),
  processingStartedAt: nullable(row, 'processingStartedAt'), completedAt: nullable(row, 'completedAt'),
  failedAt: nullable(row, 'failedAt'), failureCode: nullable(row, 'failureCode'), correlationId: row.correlationId,
  createdAt: row.createdAt, updatedAt: row.updatedAt,
});

class PrivacyRequestService {
  static confirmationToken() { const selector=crypto.randomBytes(16).toString('hex'); const secret=crypto.randomBytes(32).toString('hex'); const token=`${selector}.${secret}`; return {token,selector,hash:crypto.createHash('sha256').update(token).digest('hex')}; }
  async create({ userId, requestType, withdrawalPurposes = null }) {
    const { User, PrivacyRequest } = getModels();
    return User.sequelize.transaction(async (transaction) => {
      // Locking the owner serializes retries for the same person across request types.
      const user = await User.findByPk(userId, { transaction, lock: transaction.LOCK.UPDATE });
      if (!user) {
        const error = new Error('User not found.'); error.status = 404; error.code = 'NOT_FOUND'; throw error;
      }
      const existing = await PrivacyRequest.findOne({
        where: { userId, requestType, status: ACTIVE_STATUSES },
        order: [['requestedAt', 'DESC'], ['id', 'DESC']], transaction, lock: transaction.LOCK.UPDATE,
      });
      if (existing) return { request: existing, duplicate: true };
      const request = await PrivacyRequest.create({
        userId, requestType, status: 'IDENTITY_VERIFICATION_REQUIRED', requestedAt: new Date(),
        correlationId: crypto.randomUUID(), metadata: requestType === 'WITHDRAWAL' ? { withdrawalPurposes } : null,
      }, { transaction });
      return { request, duplicate: false };
    });
  }

  // Reserved for a future authenticated staff workflow; no client route may call this.
  async transition({ requestId, nextStatus, failureCode = null, assignedAdminId = null }) {
    const { PrivacyRequest } = getModels();
    return PrivacyRequest.sequelize.transaction(async (transaction) => {
      const request = await PrivacyRequest.findByPk(requestId, { transaction, lock: transaction.LOCK.UPDATE });
      if (!request) { const error = new Error('Privacy request not found.'); error.status = 404; error.code = 'NOT_FOUND'; throw error; }
      if (!TRANSITIONS[request.status].includes(nextStatus)) { const error = new Error('Privacy request transition is invalid.'); error.status = 409; error.code = 'PRIVACY_REQUEST_TRANSITION_INVALID'; throw error; }
      const now = new Date();
      const values = { status: nextStatus };
      if (nextStatus === 'VERIFIED') values.identityVerifiedAt = now;
      if (nextStatus === 'PROCESSING') values.processingStartedAt = now;
      if (nextStatus === 'COMPLETED') values.completedAt = now;
      if (nextStatus === 'FAILED') { values.failedAt = now; values.failureCode = failureCode || 'PRIVACY_REQUEST_FAILED'; }
      if (assignedAdminId !== null) values.assignedAdminId = assignedAdminId;
      await request.update(values, { transaction });
      return request;
    });
  }

  async issueConfirmation({ userId, requestId, password }) {
    const { User, PrivacyRequest, PrivacyRequestConfirmation } = getModels();
    return User.sequelize.transaction(async (transaction) => {
      const request=await PrivacyRequest.findOne({where:{id:requestId,userId},transaction,lock:transaction.LOCK.UPDATE});
      if(!request) { const e=new Error('Privacy request not found.');e.status=404;e.code='NOT_FOUND';throw e; }
      if(!['ACCESS','CORRECTION','EXPORT','WITHDRAWAL'].includes(request.requestType)||request.status!=='IDENTITY_VERIFICATION_REQUIRED'){const e=new Error('Privacy request cannot be verified.');e.status=409;e.code='PRIVACY_REQUEST_NOT_VERIFIABLE';throw e;}
      const user=await User.findByPk(userId,{transaction}); if(user.authProvider!=='local'||!password||!(await bcrypt.compare(password,user.passwordHash||''))){const e=new Error('Re-authentication failed.');e.status=401;e.code='REAUTHENTICATION_FAILED';throw e;}
      const g=PrivacyRequestService.confirmationToken(); await PrivacyRequestConfirmation.create({privacyRequestId:request.id,userId,tokenSelector:g.selector,tokenHash:g.hash,purpose:request.requestType==='WITHDRAWAL'?'privacy_withdrawal_step_up':'privacy_request_step_up',expiresAt:new Date(Date.now()+300000)},{transaction}); return g.token;
    });
  }

  async consumeConfirmation({ userId, requestId, confirmation }) {
    const { PrivacyRequest, PrivacyRequestConfirmation }=getModels(); const [selector]=String(confirmation||'').split('.',1); const hash=crypto.createHash('sha256').update(String(confirmation||'')).digest('hex');
    return PrivacyRequest.sequelize.transaction(async(transaction)=>{const request=await PrivacyRequest.findOne({where:{id:requestId,userId},transaction,lock:transaction.LOCK.UPDATE}); if(!request){const e=new Error('Privacy request not found.');e.status=404;e.code='NOT_FOUND';throw e;} const purpose=request.requestType==='WITHDRAWAL'?'privacy_withdrawal_step_up':'privacy_request_step_up'; const row=await PrivacyRequestConfirmation.findOne({where:{privacyRequestId:requestId,userId,tokenSelector:selector,purpose,consumedAt:null},transaction,lock:transaction.LOCK.UPDATE}); if(!row||row.expiresAt<=new Date()||!crypto.timingSafeEqual(Buffer.from(row.tokenHash,'hex'),Buffer.from(hash,'hex'))){const e=new Error('Privacy confirmation is invalid.');e.status=401;e.code='PRIVACY_CONFIRMATION_INVALID';throw e;} if(request.status!=='IDENTITY_VERIFICATION_REQUIRED'){const e=new Error('Privacy request cannot be verified.');e.status=409;e.code='PRIVACY_REQUEST_NOT_VERIFIABLE';throw e;} row.consumedAt=new Date(); await row.save({transaction}); request.status='VERIFIED';request.identityVerifiedAt=new Date();await request.save({transaction});return request;});
  }

  async processAccess({userId,requestId}) { const m=getModels(); return m.PrivacyRequest.sequelize.transaction(async(transaction)=>{const r=await m.PrivacyRequest.findOne({where:{id:requestId,userId,requestType:'ACCESS'},transaction,lock:transaction.LOCK.UPDATE});if(!r){const e=new Error('Privacy request not found.');e.status=404;e.code='NOT_FOUND';throw e;}if(r.status!=='VERIFIED'){const e=new Error('Privacy request is not ready.');e.status=409;e.code='PRIVACY_REQUEST_NOT_READY';throw e;}r.status='PROCESSING';r.processingStartedAt=new Date();await r.save({transaction});try {const [u,p,d,n,c,history]=await Promise.all([m.User.findByPk(userId,{attributes:['id','name','email','phoneNumber','authProvider','isVerified','accountStatus','createdAt'],transaction}),m.OnboardingProfile.findOne({where:{userId},attributes:['birthDate','gender','city','profession','education','hometown','interests','languages','createdAt','updatedAt'],transaction}),m.DiscoverFilterPreference.findOne({where:{userId},attributes:['minAge','maxAge','maxDistanceKm','minScore','city','verifiedOnly','onlineNow'],transaction}),m.NotificationPreference.findOne({where:{userId},attributes:['newMatches','messages','eventReminders','offers','pushEnabled','emailEnabled','smsEnabled'],transaction}),m.ConsentEvent.findAll({where:{userId},attributes:['documentVersionId','purpose','action','source','platform','occurredAt'],order:[['occurredAt','ASC']],transaction}),m.PrivacyRequest.findAll({where:{userId},attributes:['id','requestType','status','requestedAt','identityVerifiedAt','processingStartedAt','completedAt','failedAt','failureCode','correlationId'],order:[['requestedAt','ASC']],transaction})]);const data={account:u?.toJSON()||null,onboardingProfile:p?.toJSON()||null,discoveryPreferences:d?.toJSON()||null,notificationPreferences:n?.toJSON()||null,consentHistory:c.map(x=>x.toJSON()),privacyRequestHistory:history.map(safeRequest)};await m.PrivacyAccessResult.create({privacyRequestId:r.id,userId,data,generatedAt:new Date()},{transaction});r.status='COMPLETED';r.completedAt=new Date();await r.save({transaction});return {request:r,data};}catch(error){r.status='FAILED';r.failedAt=new Date();r.failureCode='ACCESS_PROCESSING_FAILED';await r.save({transaction});throw error;}}); }
}

module.exports = { PrivacyRequestService, ACTIVE_STATUSES, TRANSITIONS, safeRequest };

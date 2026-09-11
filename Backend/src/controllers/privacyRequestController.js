const { getModels } = require('../models');
const { PrivacyRequestService, safeRequest } = require('../services/privacyRequestService');

const forbiddenFields = new Set(['userId', 'status', 'requestedAt', 'identityVerifiedAt', 'processingStartedAt', 'completedAt', 'failedAt', 'failureCode', 'assignedAdminId', 'correlationId', 'metadata']);
const hasForbiddenFields = (body) => Object.keys(body || {}).some((key) => forbiddenFields.has(key));

exports.create = async (req, res, next) => {
  try {
    if (hasForbiddenFields(req.body)) return res.status(400).json({ success: false, message: 'Privacy request contains server-controlled fields.', code: 'PRIVACY_REQUEST_FIELDS_FORBIDDEN', errors: [] });
    if (Object.keys(req.body || {}).some((key) => !['requestType', 'purposes'].includes(key))) return res.status(400).json({ success: false, message: 'Privacy request contains unsupported fields.', code: 'PRIVACY_REQUEST_FIELDS_FORBIDDEN', errors: [] });
    let withdrawalPurposes = null;
    if (req.body.requestType === 'WITHDRAWAL') withdrawalPurposes = require('../services/withdrawableConsentService').normalizePurposes(req.body.purposes);
    else if (Object.hasOwn(req.body || {}, 'purposes')) return res.status(400).json({ success: false, message: 'Withdrawal scope is invalid.', code: 'INVALID_WITHDRAWAL_SCOPE', errors: [] });
    const result = await new PrivacyRequestService().create({ userId: Number(req.user.sub), requestType: req.body.requestType, withdrawalPurposes });
    if (result.duplicate) return res.status(409).json({ success: false, message: 'An active privacy request of this type already exists.', code: 'PRIVACY_REQUEST_ALREADY_ACTIVE', errors: [], data: { request: safeRequest(result.request) } });
    return res.status(201).json({ success: true, message: 'Privacy request recorded. Identity verification is required before processing.', data: { request: safeRequest(result.request) } });
  } catch (error) { return next(error); }
};

exports.listMine = async (req, res, next) => {
  try {
    const rows = await getModels().PrivacyRequest.findAll({ where: { userId: Number(req.user.sub) }, order: [['requestedAt', 'DESC'], ['id', 'DESC']] });
    return res.json({ success: true, message: 'Privacy requests retrieved.', data: { requests: rows.map(safeRequest) } });
  } catch (error) { return next(error); }
};

exports.getMine = async (req, res, next) => {
  try {
    const row = await getModels().PrivacyRequest.findOne({ where: { id: req.params.id, userId: Number(req.user.sub) } });
    if (!row) return res.status(404).json({ success: false, message: 'Privacy request not found.', code: 'NOT_FOUND', errors: [] });
    return res.json({ success: true, message: 'Privacy request retrieved.', data: { request: safeRequest(row) } });
  } catch (error) { return next(error); }
};

exports.issueStepUp = async (req,res,next)=>{try{const confirmation=await new PrivacyRequestService().issueConfirmation({userId:Number(req.user.sub),requestId:Number(req.params.id),password:req.body.password});return res.json({success:true,message:'Privacy confirmation issued.',data:{confirmation,expiresIn:300}});}catch(e){return next(e);}};
exports.verifyStepUp = async (req,res,next)=>{try{const request=await new PrivacyRequestService().consumeConfirmation({userId:Number(req.user.sub),requestId:Number(req.params.id),confirmation:req.body.confirmation});return res.json({success:true,message:'Privacy request identity verified.',data:{request:safeRequest(request)}});}catch(e){return next(e);}};
exports.processAccess = async(req,res,next)=>{try{const result=await new PrivacyRequestService().processAccess({userId:Number(req.user.sub),requestId:Number(req.params.id)});return res.json({success:true,message:'Access request completed.',data:{request:safeRequest(result.request),result:result.data}});}catch(e){return next(e);}};
exports.processWithdrawal = async(req,res,next)=>{try{const result=await require('../services/withdrawableConsentService').processWithdrawal({userId:Number(req.user.sub),requestId:Number(req.params.id)});return res.json({success:true,message:'Consent withdrawal completed.',data:{request:safeRequest(result.request),consents:result.states}});}catch(e){return next(e);}};
exports.getWithdrawableConsents = async(req,res,next)=>{try{const consents=await require('../services/withdrawableConsentService').currentStates(Number(req.user.sub));return res.json({success:true,message:'Withdrawable consent states retrieved.',data:{consents}});}catch(e){return next(e);}};
exports.getAccessResult = async(req,res,next)=>{try{const {PrivacyRequest,PrivacyAccessResult}=getModels();const request=await PrivacyRequest.findOne({where:{id:req.params.id,userId:Number(req.user.sub),requestType:'ACCESS'}});if(!request)return res.status(404).json({success:false,message:'Privacy request not found.',code:'NOT_FOUND',errors:[]});const result=await PrivacyAccessResult.findOne({where:{privacyRequestId:request.id,userId:Number(req.user.sub)} });if(!result)return res.status(404).json({success:false,message:'Access result not found.',code:'NOT_FOUND',errors:[]});return res.json({success:true,message:'Access result retrieved.',data:{request:safeRequest(request),result:result.data,generatedAt:result.generatedAt}});}catch(e){return next(e);}};
exports.submitCorrection = async(req,res,next)=>{try{if(Object.keys(req.body||{}).some((key)=>!['category','requestedBirthDate'].includes(key)))return res.status(400).json({success:false,message:'Correction contains unsupported fields.',code:'CORRECTION_FIELDS_FORBIDDEN',errors:[]});const {PrivacyRequest,PrivacyCorrectionDetail}=getModels();const userId=Number(req.user.sub);const request=await PrivacyRequest.findOne({where:{id:req.params.id,userId,requestType:'CORRECTION'}});if(!request)return res.status(404).json({success:false,message:'Privacy request not found.',code:'NOT_FOUND',errors:[]});if(request.status!=='VERIFIED')return res.status(409).json({success:false,message:'Privacy request is not ready.',code:'PRIVACY_REQUEST_NOT_READY',errors:[]});const detail=await PrivacyCorrectionDetail.create({privacyRequestId:request.id,category:'DATE_OF_BIRTH',requestedBirthDate:req.body.requestedBirthDate,submittedAt:new Date()});return res.status(201).json({success:true,message:'Correction submitted for manual privacy review.',data:{request:safeRequest(request),correction:{category:detail.category,requestedBirthDate:detail.requestedBirthDate,submittedAt:detail.submittedAt}}});}catch(e){return next(e);}};
exports.getCorrection = async(req,res,next)=>{try{const {PrivacyRequest,PrivacyCorrectionDetail}=getModels();const request=await PrivacyRequest.findOne({where:{id:req.params.id,userId:Number(req.user.sub),requestType:'CORRECTION'}});if(!request)return res.status(404).json({success:false,message:'Privacy request not found.',code:'NOT_FOUND',errors:[]});const detail=await PrivacyCorrectionDetail.findOne({where:{privacyRequestId:request.id}});return res.json({success:true,message:'Correction details retrieved.',data:{request:safeRequest(request),correction:detail?{category:detail.category,requestedBirthDate:detail.requestedBirthDate,submittedAt:detail.submittedAt}:null}});}catch(e){return next(e);}};
exports.generateExport = async(req,res,next)=>{try{const {PrivacyExportArtifactService}=require('../services/privacyExportArtifactService');const artifact=await new PrivacyExportArtifactService().generate({userId:Number(req.user.sub),privacyRequestId:Number(req.params.id)});return res.json({success:true,message:'Export generated.',data:{artifact:{id:String(artifact.id),status:artifact.status,filename:artifact.filename,mimeType:artifact.mimeType,byteSize:artifact.byteSize,checksum:artifact.checksum,generatedAt:artifact.generatedAt}}});}catch(e){return next(e);}};
exports.downloadExport = async(req,res,next)=>{try{const {PrivacyExportArtifactService}=require('../services/privacyExportArtifactService');const result=await new PrivacyExportArtifactService().download({userId:Number(req.user.sub),privacyRequestId:Number(req.params.id)});let content;try{content=await require('fs').promises.readFile(result.filePath);}catch(_){const e=new Error('Export artifact is unavailable.');e.status=409;e.code='EXPORT_ARTIFACT_UNAVAILABLE';return next(e);}res.set('Content-Type','application/json');res.set('Content-Disposition',`attachment; filename="${result.artifact.filename}"`);res.set('Cache-Control','private, no-store');return res.send(content);}catch(e){return next(e);}};

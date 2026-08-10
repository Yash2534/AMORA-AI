const crypto = require('crypto');

class ProviderConfigurationError extends Error {
  constructor(message = 'Razorpay sandbox credentials are not configured.') {
    super(message); this.code = 'PAYMENT_PROVIDER_NOT_CONFIGURED'; this.status = 503;
  }
}

class ProviderRequestError extends Error {
  constructor(message, status = 502, details = {}) {
    super(message); this.code = 'PAYMENT_PROVIDER_ERROR'; this.status = status; this.details = details;
  }
}

const configured = () => Boolean(process.env.RAZORPAY_KEY_ID && process.env.RAZORPAY_KEY_SECRET);
const apiBase = () => process.env.RAZORPAY_API_BASE_URL || 'https://api.razorpay.com/v1';
const secureEqual = (first, second) => {
  const a = Buffer.from(String(first || ''), 'utf8'); const b = Buffer.from(String(second || ''), 'utf8');
  return a.length === b.length && crypto.timingSafeEqual(a, b);
};

async function providerRequest(method, path, body) {
  if (!configured()) throw new ProviderConfigurationError();
  const authorization = Buffer.from(`${process.env.RAZORPAY_KEY_ID}:${process.env.RAZORPAY_KEY_SECRET}`).toString('base64');
  const response = await fetch(`${apiBase()}${path}`, {
    method, headers: { authorization: `Basic ${authorization}`, accept: 'application/json', ...(body ? { 'content-type': 'application/json' } : {}) }, body: body ? JSON.stringify(body) : undefined,
  });
  const value = await response.json().catch(() => ({}));
  if (!response.ok) {
    const description = value?.error?.description || 'The payment provider request failed.';
    throw new ProviderRequestError(description, response.status >= 500 ? 502 : 400, { providerStatus: response.status, providerCode: value?.error?.code });
  }
  return value;
}

const razorpay = {
  name: 'razorpay',
  isConfigured: configured,
  publicKey: () => process.env.RAZORPAY_KEY_ID || null,
  createOrder: ({ amount, currency, receipt, notes }) => providerRequest('POST', '/orders', { amount, currency, receipt, notes }),
  fetchPayment: (paymentId) => providerRequest('GET', `/payments/${encodeURIComponent(paymentId)}`),
  verifyCheckoutSignature({ orderId, paymentId, signature }) {
    if (!configured()) throw new ProviderConfigurationError();
    const expected = crypto.createHmac('sha256', process.env.RAZORPAY_KEY_SECRET).update(`${orderId}|${paymentId}`).digest('hex');
    return secureEqual(expected, signature);
  },
  verifyWebhookSignature(rawBody, signature) {
    const secret = process.env.RAZORPAY_WEBHOOK_SECRET;
    if (!secret) throw new ProviderConfigurationError('Razorpay webhook secret is not configured.');
    const expected = crypto.createHmac('sha256', secret).update(rawBody).digest('hex');
    return secureEqual(expected, signature);
  },
};

let override;
module.exports = {
  getPaymentProvider: () => override || razorpay,
  setPaymentProviderForTests: (value) => { if (process.env.NODE_ENV !== 'test') throw new Error('Provider overrides are test-only.'); override = value; },
  clearPaymentProviderForTests: () => { override = undefined; },
  ProviderConfigurationError,
  ProviderRequestError,
};

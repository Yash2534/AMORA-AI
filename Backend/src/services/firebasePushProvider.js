const { GoogleAuth } = require('google-auth-library');

function configuration() {
  const projectId = process.env.FIREBASE_PROJECT_ID;
  const clientEmail = process.env.FIREBASE_CLIENT_EMAIL;
  const privateKey = process.env.FIREBASE_PRIVATE_KEY?.replace(/\\n/g, '\n');
  return projectId && clientEmail && privateKey ? { projectId, clientEmail, privateKey } : null;
}

const isConfigured = () => Boolean(configuration());

async function send({ token, title, body, data = {} }) {
  const config = configuration();
  if (!config) {
    const error = new Error('Firebase push credentials are not configured.');
    error.code = 'PUSH_CREDENTIALS_REQUIRED';
    throw error;
  }
  const auth = new GoogleAuth({
    credentials: { client_email: config.clientEmail, private_key: config.privateKey },
    scopes: ['https://www.googleapis.com/auth/firebase.messaging'],
  });
  const accessToken = await auth.getAccessToken();
  const response = await fetch(`https://fcm.googleapis.com/v1/projects/${encodeURIComponent(config.projectId)}/messages:send`, {
    method: 'POST',
    headers: { authorization: `Bearer ${accessToken}`, 'content-type': 'application/json' },
    body: JSON.stringify({ message: {
      token,
      notification: { title, body },
      data: Object.fromEntries(Object.entries(data).map(([key, value]) => [key, String(value)])),
    } }),
  });
  const payload = await response.json().catch(() => ({}));
  if (!response.ok) {
    const error = new Error('Firebase rejected the push notification.');
    error.code = payload?.error?.status || 'PUSH_DELIVERY_FAILED';
    error.invalidToken = ['NOT_FOUND', 'INVALID_ARGUMENT'].includes(error.code);
    throw error;
  }
  return { messageId: payload.name || null };
}

module.exports = { isConfigured, send };

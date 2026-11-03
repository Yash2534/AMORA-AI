function resolveTrustProxy(env = process.env) {
  const raw = String(env.TRUST_PROXY_HOPS || '').trim();
  if (!raw) return false;
  if (!/^\d+$/.test(raw)) throw new Error('TRUST_PROXY_HOPS must be an integer from 0 through 3.');
  const hops = Number(raw);
  if (!Number.isInteger(hops) || hops < 0 || hops > 3) throw new Error('TRUST_PROXY_HOPS must be an integer from 0 through 3.');
  return hops === 0 ? false : hops;
}

module.exports = { resolveTrustProxy };

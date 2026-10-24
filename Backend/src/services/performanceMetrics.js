const counters = new Map();
const durations = new Map();

function boundedLabel(value) {
  return String(value || 'unknown').replace(/[^a-z0-9_.-]/gi, '_').slice(0, 40);
}

function increment(name, labels = {}) {
  const key = `${boundedLabel(name)}:${Object.entries(labels).sort().map(([k, v]) => `${boundedLabel(k)}=${boundedLabel(v)}`).join(',')}`;
  counters.set(key, (counters.get(key) || 0) + 1);
}

function observe(name, milliseconds) {
  const key = boundedLabel(name);
  const current = durations.get(key) || { count: 0, sumMs: 0, maxMs: 0 };
  current.count += 1;
  current.sumMs += Math.max(0, Number(milliseconds) || 0);
  current.maxMs = Math.max(current.maxMs, Number(milliseconds) || 0);
  durations.set(key, current);
}

function snapshot() {
  return { counters: Object.fromEntries(counters), durations: Object.fromEntries(durations) };
}

function reset() { counters.clear(); durations.clear(); }

module.exports = { increment, observe, snapshot, reset };

let initialized = false;
let shuttingDown = false;

function markInitialized(value = true) { initialized = Boolean(value); }
function markShuttingDown(value = true) { shuttingDown = Boolean(value); }
function snapshot() { return { initialized, shuttingDown }; }
function reset() { initialized = false; shuttingDown = false; }

module.exports = { markInitialized, markShuttingDown, snapshot, reset };

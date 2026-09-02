require("./config/bootstrapEnv");
require("./config/env");
const express = require("express");
const http = require("http");
const helmet = require("helmet");
const cors = require("cors");
const path = require("path");
const { initializeDatabase } = require("./config/db");
const authRoutes = require("./routes/authRoutes");
const onboardingRoutes = require("./routes/onboardingRoutes");
const discoverRoutes = require("./routes/discoverRoutes");
const profileRoutes = require("./routes/profileRoutes");
const meProfileRoutes = require("./routes/meProfileRoutes");
const blockRoutes = require("./routes/blockRoutes");
const reportRoutes = require("./routes/reportRoutes");
const accountRoutes = require("./routes/accountRoutes");
const matchRoutes = require("./routes/matchRoutes");
const conversationRoutes = require("./routes/conversationRoutes");
const messageRoutes = require("./routes/messageRoutes");
const eventRoutes = require("./routes/eventRoutes");
const subscriptionRoutes = require("./routes/subscriptionRoutes");
const paymentRoutes = require("./routes/paymentRoutes");
const roseRoutes = require("./routes/roseRoutes");
const { saved: savedProfileRoutes, reactions: reactionRoutes, me: meRelationshipRoutes } = require('./routes/relationshipRoutes');
const notificationPreferenceRoutes = require('./routes/notificationPreferenceRoutes');
const notificationRoutes = require('./routes/notificationRoutes');
const identityVerificationRoutes = require('./routes/identityVerificationRoutes');
const deviceRoutes = require('./routes/deviceRoutes');
const mePreferenceRoutes = require('./routes/mePreferenceRoutes');
const adminRoutes = require('./routes/adminRoutes');
const publicMaintenance = require('./middleware/publicMaintenanceMiddleware');
const { publicConfiguration } = require('./controllers/platformSettingsController');
const { attachRealtimeServer } = require("./realtime/realtimeHub");
const errorHandler = require("./middleware/errorHandler");
const { port } = require("./config/env");
const { logGoogleStatus } = require("./controllers/authController");
const app = express();
app.set("trust proxy", 1);
const origin = process.env.CORS_ORIGIN || "*";
if (process.env.NODE_ENV === "development" && origin === "*")
  console.warn(
    "[CORS] Development mode allows all origins. Configure CORS_ORIGIN before production.",
  );
app.use(helmet({
  hsts: process.env.NODE_ENV === 'production'
    ? { maxAge: 31536000, includeSubDomains: true, preload: true }
    : false,
  crossOriginResourcePolicy: { policy: 'same-site' },
}));
app.use(
  cors({
    origin: origin === "*" ? "*" : origin.split(",").map((item) => item.trim()),
    credentials: origin !== "*",
  }),
);
app.use(express.json({ limit: "100kb", verify: (req, _res, buffer) => {
  if (req.originalUrl === "/api/payments/webhook") req.rawBody = Buffer.from(buffer);
} }));
app.use("/uploads", express.static(path.join(__dirname, "../uploads")));
app.get("/health", (_req, res) =>
  res.json({
    success: true,
    message: "Amora AI backend is healthy.",
    data: {},
  }),
);
app.use("/api/auth", authRoutes);
app.get('/api/app-config', publicConfiguration);
app.use("/api/onboarding", publicMaintenance, onboardingRoutes);
app.use("/api/discover", publicMaintenance, discoverRoutes);
app.use("/api/profiles", publicMaintenance, profileRoutes);
app.use("/api/me/profile", publicMaintenance, meProfileRoutes);
app.use("/api/me/preferences", publicMaintenance, mePreferenceRoutes);
app.use("/api/blocks", publicMaintenance, blockRoutes);
app.use("/api/reports", publicMaintenance, reportRoutes);
app.use("/api/account", publicMaintenance, accountRoutes);
app.use("/api/matches", publicMaintenance, matchRoutes);
app.use("/api/conversations", publicMaintenance, conversationRoutes);
app.use("/api/messages", publicMaintenance, messageRoutes);
app.use("/api/events", publicMaintenance, eventRoutes);
app.use("/api/subscriptions", publicMaintenance, subscriptionRoutes);
app.use("/api/payments", publicMaintenance, paymentRoutes);
app.use("/api/roses", publicMaintenance, roseRoutes);
app.use('/api/saved-profiles', publicMaintenance, savedProfileRoutes);
app.use('/api/reactions', publicMaintenance, reactionRoutes);
app.use('/api/me', publicMaintenance, meRelationshipRoutes);
app.use('/api/notification-preferences', publicMaintenance, notificationPreferenceRoutes);
app.use('/api/notifications', publicMaintenance, notificationRoutes);
app.use('/api/identity-verification', publicMaintenance, identityVerificationRoutes);
app.use('/api/devices', publicMaintenance, deviceRoutes);
app.use('/api/admin/v1', adminRoutes);
app.use((_req, res) =>
  res
    .status(404)
    .json({
      success: false,
      message: "Route not found.",
      code: "NOT_FOUND",
      errors: [],
    }),
);
app.use(errorHandler);
async function startServer() {
  await initializeDatabase();
  return new Promise((resolve) => {
    logGoogleStatus();
    const server = createHttpServer();
    server.listen(port, () => {
      console.log(`[Server] Amora AI backend listening on port ${port}`);
      resolve(server);
    });
  });
}

function createHttpServer() {
  const server = http.createServer(app);
  attachRealtimeServer(server);
  return server;
}

if (require.main === module) {
  startServer().catch(() => process.exit(1));
}

module.exports = { app, startServer, createHttpServer };

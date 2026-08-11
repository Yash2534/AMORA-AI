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
const realtimeRoutes = require("./routes/realtimeRoutes");
const eventRoutes = require("./routes/eventRoutes");
const hostEventRoutes = require("./routes/hostEventRoutes");
const subscriptionRoutes = require("./routes/subscriptionRoutes");
const paymentRoutes = require("./routes/paymentRoutes");
const walletRoutes = require("./routes/walletRoutes");
const boostRoutes = require("./routes/boostRoutes");
const giftRoutes = require("./routes/giftRoutes");
const { saved: savedProfileRoutes, reactions: reactionRoutes, me: meRelationshipRoutes } = require('./routes/relationshipRoutes');
const notificationPreferenceRoutes = require('./routes/notificationPreferenceRoutes');
const notificationRoutes = require('./routes/notificationRoutes');
const mePreferenceRoutes = require('./routes/mePreferenceRoutes');
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
app.use(helmet());
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
app.use("/api/onboarding", onboardingRoutes);
app.use("/api/discover", discoverRoutes);
app.use("/api/profiles", profileRoutes);
app.use("/api/me/profile", meProfileRoutes);
app.use("/api/me/preferences", mePreferenceRoutes);
app.use("/api/blocks", blockRoutes);
app.use("/api/reports", reportRoutes);
app.use("/api/account", accountRoutes);
app.use("/api/matches", matchRoutes);
app.use("/api/conversations", conversationRoutes);
app.use("/api/messages", messageRoutes);
app.use("/api/realtime", realtimeRoutes);
app.use("/api/events", eventRoutes);
app.use("/api/host", hostEventRoutes);
app.use("/api/subscriptions", subscriptionRoutes);
app.use("/api/payments", paymentRoutes);
app.use("/api/wallet", walletRoutes);
app.use("/api/boosts", boostRoutes);
app.use("/api/gifts", giftRoutes);
app.use('/api/saved-profiles', savedProfileRoutes);
app.use('/api/reactions', reactionRoutes);
app.use('/api/me', meRelationshipRoutes);
app.use('/api/notification-preferences', notificationPreferenceRoutes);
app.use('/api/notifications', notificationRoutes);
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

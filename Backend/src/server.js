require("./config/bootstrapEnv");
require("./config/env");
const express = require("express");
const helmet = require("helmet");
const cors = require("cors");
const path = require("path");
const { initializeDatabase } = require("./config/db");
const authRoutes = require("./routes/authRoutes");
const onboardingRoutes = require("./routes/onboardingRoutes");
const discoverRoutes = require("./routes/discoverRoutes");
const profileRoutes = require("./routes/profileRoutes");
const blockRoutes = require("./routes/blockRoutes");
const reportRoutes = require("./routes/reportRoutes");
const accountRoutes = require("./routes/accountRoutes");
const matchRoutes = require("./routes/matchRoutes");
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
app.use(express.json({ limit: "20kb" }));
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
app.use("/api/blocks", blockRoutes);
app.use("/api/reports", reportRoutes);
app.use("/api/account", accountRoutes);
app.use("/api/matches", matchRoutes);
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
    const server = app.listen(port, () => {
      console.log(`[Server] Amora AI backend listening on port ${port}`);
      resolve(server);
    });
  });
}

if (require.main === module) {
  startServer().catch(() => process.exit(1));
}

module.exports = { app, startServer };

// PM2 definition for the isolated client-QA staging backend.
// Start with: pm2 start deploy/client-staging/ecosystem.client-staging.config.js
// Never reuses the production process name, directory, or port.
module.exports = {
  apps: [
    {
      name: 'amora-client-staging',
      cwd: '/root/AMORA-AI-CLIENT-STAGING/Backend',
      script: 'src/server.js',
      instances: 1,
      exec_mode: 'fork',
      max_memory_restart: '512M',
      max_restarts: 10,
      min_uptime: '30s',
      restart_delay: 5000,
      kill_timeout: 20000,
      // Secrets are read from Backend/.env by bootstrapEnv; only non-secret
      // identity values are pinned here.
      env: {
        NODE_ENV: 'staging',
        PORT: '5002',
      },
    },
  ],
};

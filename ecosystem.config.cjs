module.exports = {
  apps: [
    {
      name: "cf-tunnel",
      // Use just 'npx' here
      script: "npx", 
      args: [
        "cloudflared", 
        "tunnel", 
        "--url", "http://127.0.0.1:10000"
      ],
      // THIS IS THE FIX: 
      // 'none' tells PM2: "Don't use Node. Just run this in the shell."
      interpreter: "none", 
      shell: true, 
      autorestart: true,
      restart_delay: 5000
    },
    {
      name: "nodejs-test",
      script: "./src/index.js"
    }
  ]
};
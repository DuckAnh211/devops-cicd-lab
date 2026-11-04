const express = require('express');

const app = express();
app.disable('x-powered-by');
app.use(express.json());

app.get('/', (req, res) => {
  res.json({ message: process.env.APP_MESSAGE || 'Hello from DevOps CI/CD Lab!', version: process.env.APP_VERSION || '1.0.0' });
});

app.get('/health', (req, res) => {
  res.status(200).json({ status: 'ok' });
});

module.exports = app;

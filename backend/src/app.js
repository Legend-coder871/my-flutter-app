const express = require('express');
const cors = require('cors');

// Create the Express app
const app = express();

app.use(cors());
app.use(express.json());

// Mount the API router at /api
const apiRouter = express.Router();

// GET /api/health returns the health status
apiRouter.get('/health', (req, res) => {
  res.status(200).json({ status: 'ok' });
});

app.use('/api', apiRouter);

// Mount the auth routes at /api/auth
app.use('/api/auth', require('./routes/auth'));

// Mount the services routes at /api/services
app.use('/api/services', require('./routes/services'));

// JSON 404 handler for unknown routes
app.use((req, res) => {
  res.status(404).json({ error: 'Route not found' });
});

// Final error-handling middleware
app.use((err, req, res, next) => {
  console.error(err);
  res.status(500).json({ error: 'Server error' });
});

module.exports = app;

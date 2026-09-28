require('dotenv').config();

// Refuse to start without a signing secret
if (!process.env.JWT_SECRET) {
  console.error('Error: JWT_SECRET is missing. Add JWT_SECRET to backend/.env');
  process.exit(1);
}

const app = require('./app');
require('./db');

// Read the port from .env, falling back to 3000
const PORT = process.env.PORT || 3000;

// Start the HTTP server
app.listen(PORT, () => {
  console.log(`Server running on port ${PORT}`);
});

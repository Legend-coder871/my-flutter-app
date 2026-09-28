require('dotenv').config();

const app = require('./app');
require('./db');

// Read the port from .env, falling back to 3000
const PORT = process.env.PORT || 3000;

// Start the HTTP server
app.listen(PORT, () => {
  console.log(`Server running on port ${PORT}`);
});

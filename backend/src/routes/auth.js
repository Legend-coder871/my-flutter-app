const express = require('express');
const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');
const db = require('../db');
const { requireAuth } = require('../middleware/auth');

const router = express.Router();

// Create a 7 day JWT containing the user id
function signToken(user) {
  return jwt.sign({ id: user.id }, process.env.JWT_SECRET, { expiresIn: '7d' });
}

// Return the public shape of a user (never password_hash)
function publicUser(user) {
  return { id: user.id, name: user.name, email: user.email, phone: user.phone };
}

// POST /api/auth/register - create a new user
router.post('/register', (req, res) => {
  const { name, email, password, phone } = req.body || {};
  if (!name || !email || !password || !phone) {
    return res.status(400).json({ error: 'name, email, password and phone are required' });
  }
  const cleanEmail = String(email).trim().toLowerCase();
  if (!/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(cleanEmail)) {
    return res.status(400).json({ error: 'Email does not look like a valid email' });
  }
  if (String(password).length < 6) {
    return res.status(400).json({ error: 'Password must be at least 6 characters' });
  }
  const existing = db.prepare('SELECT id FROM users WHERE email = ?').get(cleanEmail);
  if (existing) {
    return res.status(409).json({ error: 'Email already registered' });
  }
  const passwordHash = bcrypt.hashSync(String(password), 10);
  const info = db
    .prepare('INSERT INTO users (name, email, password_hash, phone) VALUES (?, ?, ?, ?)')
    .run(String(name).trim(), cleanEmail, passwordHash, String(phone).trim());
  const user = db
    .prepare('SELECT id, name, email, phone FROM users WHERE id = ?')
    .get(info.lastInsertRowid);
  return res.status(201).json({ token: signToken(user), user: publicUser(user) });
});

// POST /api/auth/login - exchange credentials for a token
router.post('/login', (req, res) => {
  const { email, password } = req.body || {};
  if (!email || !password) {
    return res.status(400).json({ error: 'email and password are required' });
  }
  const cleanEmail = String(email).trim().toLowerCase();
  const user = db.prepare('SELECT * FROM users WHERE email = ?').get(cleanEmail);
  if (!user || !bcrypt.compareSync(String(password), user.password_hash)) {
    return res.status(401).json({ error: 'Invalid email or password' });
  }
  return res.status(200).json({ token: signToken(user), user: publicUser(user) });
});

// GET /api/auth/me - return the authenticated user
router.get('/me', requireAuth, (req, res) => {
  return res.status(200).json({ user: req.user });
});

module.exports = router;

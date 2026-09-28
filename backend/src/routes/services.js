const express = require('express');
const db = require('../db');
const { requireAuth } = require('../middleware/auth');

const router = express.Router();

// Convert is_active to a boolean for JSON responses
function shape(service) {
  return { ...service, is_active: !!service.is_active };
}

// Validate the writable service fields; returns an error message or null
function validateBody(body) {
  const { title, description, category, price } = body || {};
  if (!title || !description || !category || price === undefined) {
    return 'title, description, category and price are required';
  }
  const n = Number(price);
  if (Number.isNaN(n) || n < 0) {
    return 'price must be a number >= 0';
  }
  return null;
}

// GET /api/services/mine - the logged-in user's services, newest first
router.get('/mine', requireAuth, (req, res) => {
  const rows = db
    .prepare('SELECT * FROM services WHERE user_id = ? ORDER BY id DESC')
    .all(req.user.id);
  return res.status(200).json(rows.map(shape));
});

// GET /api/services - active services with provider info, newest first
router.get('/', (req, res) => {
  const { q, category } = req.query;
  const clauses = ['s.is_active = 1'];
  const params = [];
  if (q) {
    clauses.push("(s.title LIKE ? OR s.description LIKE ? OR s.category LIKE ?)");
    const like = `%${q}%`;
    params.push(like, like, like);
  }
  if (category) {
    clauses.push('LOWER(s.category) = LOWER(?)');
    params.push(category);
  }
  const rows = db
    .prepare(
      `SELECT s.*, u.name AS provider_name, u.phone AS provider_phone
       FROM services s JOIN users u ON u.id = s.user_id
       WHERE ${clauses.join(' AND ')}
       ORDER BY s.id DESC`
    )
    .all(...params);
  return res.status(200).json(rows.map(shape));
});

// GET /api/services/:id - one service with provider info
router.get('/:id', (req, res) => {
  const row = db
    .prepare(
      `SELECT s.*, u.name AS provider_name, u.phone AS provider_phone
       FROM services s JOIN users u ON u.id = s.user_id
       WHERE s.id = ?`
    )
    .get(req.params.id);
  if (!row) {
    return res.status(404).json({ error: 'Service not found' });
  }
  return res.status(200).json(shape(row));
});

// POST /api/services - create a service for the logged-in user
router.post('/', requireAuth, (req, res) => {
  const error = validateBody(req.body);
  if (error) {
    return res.status(400).json({ error });
  }
  const { title, description, category, price } = req.body;
  const info = db
    .prepare(
      'INSERT INTO services (user_id, title, description, category, price) VALUES (?, ?, ?, ?, ?)'
    )
    .run(req.user.id, title, description, category, Number(price));
  const row = db.prepare('SELECT * FROM services WHERE id = ?').get(info.lastInsertRowid);
  return res.status(201).json(shape(row));
});

// PUT /api/services/:id - update your own service
router.put('/:id', requireAuth, (req, res) => {
  const existing = db.prepare('SELECT * FROM services WHERE id = ?').get(req.params.id);
  if (!existing) {
    return res.status(404).json({ error: 'Service not found' });
  }
  if (existing.user_id !== req.user.id) {
    return res.status(403).json({ error: 'Not allowed' });
  }
  const { title, description, category, price, is_active } = req.body || {};
  if (price !== undefined && (Number.isNaN(Number(price)) || Number(price) < 0)) {
    return res.status(400).json({ error: 'price must be a number >= 0' });
  }
  const next = {
    title: title === undefined ? existing.title : title,
    description: description === undefined ? existing.description : description,
    category: category === undefined ? existing.category : category,
    price: price === undefined ? existing.price : Number(price),
    is_active: is_active === undefined ? existing.is_active : (is_active ? 1 : 0),
  };
  db.prepare(
    'UPDATE services SET title = ?, description = ?, category = ?, price = ?, is_active = ? WHERE id = ?'
  ).run(next.title, next.description, next.category, next.price, next.is_active, req.params.id);
  const row = db.prepare('SELECT * FROM services WHERE id = ?').get(req.params.id);
  return res.status(200).json(shape(row));
});

// DELETE /api/services/:id - delete your own service
router.delete('/:id', requireAuth, (req, res) => {
  const existing = db.prepare('SELECT * FROM services WHERE id = ?').get(req.params.id);
  if (!existing) {
    return res.status(404).json({ error: 'Service not found' });
  }
  if (existing.user_id !== req.user.id) {
    return res.status(403).json({ error: 'Not allowed' });
  }
  db.prepare('DELETE FROM services WHERE id = ?').run(req.params.id);
  return res.status(200).json({ message: 'Deleted' });
});

module.exports = router;

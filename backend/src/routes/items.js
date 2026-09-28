const express = require('express');
const db = require('../db');
const { requireAuth } = require('../middleware/auth');

const router = express.Router();

// Convert is_available to a boolean for JSON responses
function shape(item) {
  return { ...item, is_available: !!item.is_available };
}

// Validate the writable item fields; returns an error message or null
function validateBody(body) {
  const { name, description, category, price } = body || {};
  if (!name || !description || !category || price === undefined) {
    return 'name, description, category and price are required';
  }
  const n = Number(price);
  if (Number.isNaN(n) || n < 0) {
    return 'price must be a number >= 0';
  }
  if (body.quantity !== undefined) {
    const q = Number(body.quantity);
    if (!Number.isInteger(q) || q < 1) {
      return 'quantity must be an integer >= 1';
    }
  }
  return null;
}

// GET /api/items/mine - the logged-in user's items, newest first
router.get('/mine', requireAuth, (req, res) => {
  const rows = db
    .prepare('SELECT * FROM items WHERE user_id = ? ORDER BY id DESC')
    .all(req.user.id);
  return res.status(200).json(rows.map(shape));
});

// GET /api/items/search?q= - search available items
router.get('/search', (req, res) => {
  const q = String(req.query.q || '').trim();
  if (!q) {
    return res.status(400).json({ error: 'Search term is required' });
  }
  const like = `%${q}%`;
  const rows = db
    .prepare(
      `SELECT i.*, u.name AS seller_name, u.phone AS seller_phone
       FROM items i JOIN users u ON u.id = i.user_id
       WHERE i.is_available = 1
         AND (i.name LIKE ? OR i.description LIKE ? OR i.category LIKE ?)
       ORDER BY i.id DESC`
    )
    .all(like, like, like);
  if (rows.length === 0) {
    return res
      .status(200)
      .json({ found: false, message: 'Item not in market', results: [] });
  }
  return res.status(200).json({ found: true, results: rows.map(shape) });
});

// GET /api/items - all available items with seller info, newest first
router.get('/', (req, res) => {
  const rows = db
    .prepare(
      `SELECT i.*, u.name AS seller_name, u.phone AS seller_phone
       FROM items i JOIN users u ON u.id = i.user_id
       WHERE i.is_available = 1
       ORDER BY i.id DESC`
    )
    .all();
  return res.status(200).json(rows.map(shape));
});

// GET /api/items/:id - one item with seller info
router.get('/:id', (req, res) => {
  const row = db
    .prepare(
      `SELECT i.*, u.name AS seller_name, u.phone AS seller_phone
       FROM items i JOIN users u ON u.id = i.user_id
       WHERE i.id = ?`
    )
    .get(req.params.id);
  if (!row) {
    return res.status(404).json({ error: 'Item not found' });
  }
  return res.status(200).json(shape(row));
});

// POST /api/items - create an item for the logged-in user
router.post('/', requireAuth, (req, res) => {
  const error = validateBody(req.body);
  if (error) {
    return res.status(400).json({ error });
  }
  const { name, description, category, price, quantity } = req.body;
  const qty = quantity === undefined ? 1 : Number(quantity);
  const info = db
    .prepare(
      'INSERT INTO items (user_id, name, description, category, price, quantity) VALUES (?, ?, ?, ?, ?, ?)'
    )
    .run(req.user.id, name, description, category, Number(price), qty);
  const row = db.prepare('SELECT * FROM items WHERE id = ?').get(info.lastInsertRowid);
  return res.status(201).json(shape(row));
});

// PUT /api/items/:id - update your own item
router.put('/:id', requireAuth, (req, res) => {
  const existing = db.prepare('SELECT * FROM items WHERE id = ?').get(req.params.id);
  if (!existing) {
    return res.status(404).json({ error: 'Item not found' });
  }
  if (existing.user_id !== req.user.id) {
    return res.status(403).json({ error: 'Not allowed' });
  }
  const { name, description, category, price, quantity, is_available } = req.body || {};
  if (price !== undefined && (Number.isNaN(Number(price)) || Number(price) < 0)) {
    return res.status(400).json({ error: 'price must be a number >= 0' });
  }
  if (quantity !== undefined && (!Number.isInteger(Number(quantity)) || Number(quantity) < 1)) {
    return res.status(400).json({ error: 'quantity must be an integer >= 1' });
  }
  const next = {
    name: name === undefined ? existing.name : name,
    description: description === undefined ? existing.description : description,
    category: category === undefined ? existing.category : category,
    price: price === undefined ? existing.price : Number(price),
    quantity: quantity === undefined ? existing.quantity : Number(quantity),
    is_available: is_available === undefined ? existing.is_available : (is_available ? 1 : 0),
  };
  db.prepare(
    'UPDATE items SET name = ?, description = ?, category = ?, price = ?, quantity = ?, is_available = ? WHERE id = ?'
  ).run(next.name, next.description, next.category, next.price, next.quantity, next.is_available, req.params.id);
  const row = db.prepare('SELECT * FROM items WHERE id = ?').get(req.params.id);
  return res.status(200).json(shape(row));
});

// DELETE /api/items/:id - delete your own item
router.delete('/:id', requireAuth, (req, res) => {
  const existing = db.prepare('SELECT * FROM items WHERE id = ?').get(req.params.id);
  if (!existing) {
    return res.status(404).json({ error: 'Item not found' });
  }
  if (existing.user_id !== req.user.id) {
    return res.status(403).json({ error: 'Not allowed' });
  }
  db.prepare('DELETE FROM items WHERE id = ?').run(req.params.id);
  return res.status(200).json({ message: 'Deleted' });
});

module.exports = router;

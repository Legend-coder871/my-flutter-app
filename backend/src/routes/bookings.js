const express = require('express');
const db = require('../db');
const { requireAuth } = require('../middleware/auth');

const router = express.Router();

router.use(requireAuth);

// Check that a string is a valid ISO 8601 date-time in the future
function isFutureIso(value) {
  if (typeof value !== 'string' || !/^\d{4}-\d{2}-\d{2}[T ]\d{2}:\d{2}(:\d{2}(\.\d+)?)?(Z|[+-]\d{2}:\d{2})?$/.test(value)) {
    return false;
  }
  const t = Date.parse(value);
  if (Number.isNaN(t)) return false;
  return t > Date.now();
}

// POST /api/bookings - book an active service as the current user
router.post('/', (req, res) => {
  const { service_id, scheduled_at, note } = req.body || {};
  if (!service_id || !scheduled_at) {
    return res.status(400).json({ error: 'service_id and scheduled_at are required' });
  }
  const service = db
    .prepare('SELECT id, user_id, title, is_active FROM services WHERE id = ?')
    .get(service_id);
  if (!service || !service.is_active) {
    return res.status(404).json({ error: 'Service not found' });
  }
  if (service.user_id === req.user.id) {
    return res.status(400).json({ error: 'You cannot book your own service' });
  }
  if (!isFutureIso(scheduled_at)) {
    return res.status(400).json({ error: 'scheduled_at must be a valid ISO 8601 date-time in the future' });
  }
  const clash = db
    .prepare(
      `SELECT id FROM bookings
       WHERE service_id = ? AND scheduled_at = ? AND status IN ('pending','confirmed')`
    )
    .get(service.id, scheduled_at);
  if (clash) {
    return res.status(409).json({ error: 'That time slot is already taken' });
  }
  const info = db
    .prepare(
      `INSERT INTO bookings (service_id, customer_id, scheduled_at, note, status)
       VALUES (?, ?, ?, ?, 'pending')`
    )
    .run(service.id, req.user.id, scheduled_at, note || null);
  const row = db.prepare('SELECT * FROM bookings WHERE id = ?').get(info.lastInsertRowid);
  return res.status(201).json(row);
});

// GET /api/bookings/mine - bookings made by the current user
router.get('/mine', (req, res) => {
  const rows = db
    .prepare(
      `SELECT b.*, s.title AS service_title, u.name AS provider_name, u.phone AS provider_phone
       FROM bookings b
       JOIN services s ON s.id = b.service_id
       JOIN users u ON u.id = s.user_id
       WHERE b.customer_id = ?
       ORDER BY b.id DESC`
    )
    .all(req.user.id);
  return res.status(200).json(rows);
});

// GET /api/bookings/received - bookings on the current user's services
router.get('/received', (req, res) => {
  const rows = db
    .prepare(
      `SELECT b.*, s.title AS service_title, u.name AS customer_name, u.phone AS customer_phone
       FROM bookings b
       JOIN services s ON s.id = b.service_id
       JOIN users u ON u.id = b.customer_id
       WHERE s.user_id = ?
       ORDER BY b.id DESC`
    )
    .all(req.user.id);
  return res.status(200).json(rows);
});

// PATCH /api/bookings/:id/status - change a booking's status
router.patch('/:id/status', (req, res) => {
  const booking = db
    .prepare('SELECT b.*, s.user_id AS provider_id FROM bookings b JOIN services s ON s.id = b.service_id WHERE b.id = ?')
    .get(req.params.id);
  if (!booking) {
    return res.status(404).json({ error: 'Booking not found' });
  }
  const { status } = req.body || {};
  const isProvider = booking.provider_id === req.user.id;
  const isCustomer = booking.customer_id === req.user.id;
  if (!isProvider && !isCustomer) {
    return res.status(403).json({ error: 'Not allowed' });
  }
  let allowed = false;
  if (isProvider) {
    allowed = booking.status === 'pending' && (status === 'confirmed' || status === 'declined');
  } else {
    allowed =
      (booking.status === 'pending' || booking.status === 'confirmed') && status === 'cancelled';
  }
  if (!allowed) {
    return res.status(400).json({ error: 'Invalid status change' });
  }
  db.prepare('UPDATE bookings SET status = ? WHERE id = ?').run(status, booking.id);
  const row = db.prepare('SELECT * FROM bookings WHERE id = ?').get(booking.id);
  return res.status(200).json(row);
});

module.exports = router;

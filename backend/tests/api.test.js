// Test env must be set before anything from src/ is loaded
process.env.DB_FILE = ':memory:';
process.env.JWT_SECRET = 'test-secret';

const { test } = require('node:test');
const assert = require('node:assert');
const request = require('supertest');
const app = require('../src/app');

const API = '/api';

// Register a user and return their token
async function registerUser(suffix) {
  const res = await request(app)
    .post(`${API}/auth/register`)
    .send({
      name: `User ${suffix}`,
      email: `${suffix}@test.com`,
      password: 'secret123',
      phone: `07111111${suffix.length}${suffix.charCodeAt(0) % 10}`,
    });
  assert.strictEqual(res.status, 201);
  return res.body.token;
}

// The main user used across the suite
let token;
let otherToken;

test('setup: register the two users', async () => {
  token = await registerUser('amina');
  otherToken = await registerUser('bob');
});

test('GET /api/health returns ok', async () => {
  const res = await request(app).get(`${API}/health`);
  assert.strictEqual(res.status, 200);
  assert.deepStrictEqual(res.body, { status: 'ok' });
});

test('register works and never returns password_hash', async () => {
  const res = await request(app)
    .post(`${API}/auth/register`)
    .send({ name: 'Carol', email: 'carol@test.com', password: 'secret123', phone: '0733333333' });
  assert.strictEqual(res.status, 201);
  assert.ok(res.body.token);
  assert.strictEqual(res.body.user.email, 'carol@test.com');
  assert.ok(!('password_hash' in res.body.user));
});

test('duplicate register returns 409', async () => {
  const res = await request(app)
    .post(`${API}/auth/register`)
    .send({ name: 'Amina', email: 'AMINA@test.com', password: 'secret123', phone: '0712345678' });
  assert.strictEqual(res.status, 409);
  assert.deepStrictEqual(res.body, { error: 'Email already registered' });
});

test('login succeeds with correct credentials', async () => {
  const res = await request(app)
    .post(`${API}/auth/login`)
    .send({ email: 'amina@test.com', password: 'secret123' });
  assert.strictEqual(res.status, 200);
  assert.ok(res.body.token);
  assert.strictEqual(res.body.user.name, 'User amina');
});

test('login with wrong password returns 401', async () => {
  const res = await request(app)
    .post(`${API}/auth/login`)
    .send({ email: 'amina@test.com', password: 'wrongpass' });
  assert.strictEqual(res.status, 401);
  assert.deepStrictEqual(res.body, { error: 'Invalid email or password' });
});

test('GET /api/auth/me without a token returns 401', async () => {
  const res = await request(app).get(`${API}/auth/me`);
  assert.strictEqual(res.status, 401);
  assert.deepStrictEqual(res.body, { error: 'Not authenticated' });
});

test('GET /api/auth/me with a token returns the user', async () => {
  const res = await request(app)
    .get(`${API}/auth/me`)
    .set('Authorization', `Bearer ${token}`);
  assert.strictEqual(res.status, 200);
  assert.strictEqual(res.body.user.email, 'amina@test.com');
});

test('creating a service without a token returns 401', async () => {
  const res = await request(app)
    .post(`${API}/services`)
    .send({ title: 'Math tutoring', description: 'Calculus', category: 'Tutoring', price: 500 });
  assert.strictEqual(res.status, 401);
});

test('creating a service with a token returns 201', async () => {
  const res = await request(app)
    .post(`${API}/services`)
    .set('Authorization', `Bearer ${token}`)
    .send({ title: 'Math tutoring', description: 'Calculus and algebra', category: 'Tutoring', price: 500 });
  assert.strictEqual(res.status, 201);
  assert.strictEqual(res.body.title, 'Math tutoring');
  assert.strictEqual(res.body.is_active, true);
});

test('listing services includes provider_phone', async () => {
  const res = await request(app).get(`${API}/services`);
  assert.strictEqual(res.status, 200);
  assert.ok(res.body.length >= 1);
  const svc = res.body.find((s) => s.title === 'Math tutoring');
  assert.ok(svc);
  assert.ok(svc.provider_name);
  assert.ok(svc.provider_phone);
});

test('another user cannot update or delete my service', async () => {
  const list = await request(app).get(`${API}/services`);
  const mine = list.body.find((s) => s.title === 'Math tutoring');

  const put = await request(app)
    .put(`${API}/services/${mine.id}`)
    .set('Authorization', `Bearer ${otherToken}`)
    .send({ price: 1 });
  assert.strictEqual(put.status, 403);
  assert.deepStrictEqual(put.body, { error: 'Not allowed' });

  const del = await request(app)
    .delete(`${API}/services/${mine.id}`)
    .set('Authorization', `Bearer ${otherToken}`);
  assert.strictEqual(del.status, 403);
  assert.deepStrictEqual(del.body, { error: 'Not allowed' });
});

test('creating an item returns 201', async () => {
  const res = await request(app)
    .post(`${API}/items`)
    .set('Authorization', `Bearer ${otherToken}`)
    .send({ name: 'Calculus textbook', description: 'Stewart 8th edition', category: 'Books', price: 1500 });
  assert.strictEqual(res.status, 201);
  assert.strictEqual(res.body.name, 'Calculus textbook');
  assert.strictEqual(res.body.is_available, true);
});

test('search finds the item with seller_phone', async () => {
  const res = await request(app).get(`${API}/items/search?q=calculus`);
  assert.strictEqual(res.status, 200);
  assert.strictEqual(res.body.found, true);
  assert.ok(res.body.results.length >= 1);
  const item = res.body.results.find((i) => i.name === 'Calculus textbook');
  assert.ok(item);
  assert.ok(item.seller_name);
  assert.ok(item.seller_phone);
});

test('search for a missing item says Item not in market', async () => {
  const res = await request(app).get(`${API}/items/search?q=zzzznothing`);
  assert.strictEqual(res.status, 200);
  assert.strictEqual(res.body.found, false);
  assert.strictEqual(res.body.message, 'Item not in market');
  assert.deepStrictEqual(res.body.results, []);
});

test('booking flows: 201, 409, 400, provider confirms, customer cannot confirm', async () => {
  const list = await request(app).get(`${API}/services`);
  const svc = list.body.find((s) => s.title === 'Math tutoring');
  const slot = { service_id: svc.id, scheduled_at: '2030-01-15T10:00:00', note: 'Need help' };

  // another user books it
  const book = await request(app)
    .post(`${API}/bookings`)
    .set('Authorization', `Bearer ${otherToken}`)
    .send(slot);
  assert.strictEqual(book.status, 201);
  assert.strictEqual(book.body.status, 'pending');
  const bookingId = book.body.id;

  // same slot again -> conflict
  const again = await request(app)
    .post(`${API}/bookings`)
    .set('Authorization', `Bearer ${otherToken}`)
    .send(slot);
  assert.strictEqual(again.status, 409);
  assert.deepStrictEqual(again.body, { error: 'That time slot is already taken' });

  // booking your own service -> 400
  const own = await request(app)
    .post(`${API}/bookings`)
    .set('Authorization', `Bearer ${token}`)
    .send({ service_id: svc.id, scheduled_at: '2030-02-15T10:00:00' });
  assert.strictEqual(own.status, 400);
  assert.deepStrictEqual(own.body, { error: 'You cannot book your own service' });

  // provider confirms
  const confirm = await request(app)
    .patch(`${API}/bookings/${bookingId}/status`)
    .set('Authorization', `Bearer ${token}`)
    .send({ status: 'confirmed' });
  assert.strictEqual(confirm.status, 200);
  assert.strictEqual(confirm.body.status, 'confirmed');

  // customer cannot confirm (already confirmed, and not allowed anyway)
  const customerConfirm = await request(app)
    .patch(`${API}/bookings/${bookingId}/status`)
    .set('Authorization', `Bearer ${otherToken}`)
    .send({ status: 'confirmed' });
  assert.ok(customerConfirm.status === 400 || customerConfirm.status === 403);
});

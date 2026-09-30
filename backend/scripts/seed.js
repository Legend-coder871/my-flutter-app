const bcrypt = require('bcryptjs');
const db = require('../src/db');

// Insert demo data only when the users table is empty; never deletes anything
function seed() {
  const count = db.prepare('SELECT COUNT(*) AS n FROM users').get().n;
  if (count > 0) {
    console.log(`Database already has ${count} user(s); nothing to seed.`);
    return;
  }

  const hash = bcrypt.hashSync('password123', 10);

  const insertUser = db.prepare(
    'INSERT INTO users (name, email, password_hash, phone) VALUES (?, ?, ?, ?)'
  );
  const users = [
    ['Amina Kamau', 'amina@demo.com', '0712345678'],
    ['Bob Otieno', 'bob@demo.com', '0722334455'],
    ['Carol Wanjiku', 'carol@demo.com', '0733445566'],
  ];
  const userIds = users.map((u) => insertUser.run(u[0], u[1], hash, u[2]).lastInsertRowid);

  const insertService = db.prepare(
    'INSERT INTO services (user_id, title, description, category, price) VALUES (?, ?, ?, ?, ?)'
  );
  const services = [
    [userIds[0], 'Math tutoring', 'Calculus and algebra, campus friendly', 'Tutoring', 500],
    [userIds[1], 'Web development', 'Landing pages and school projects', 'Tutoring', 2500],
    [userIds[2], 'Laundry service', 'Wash, dry and fold by the kg', 'Errands', 150],
    [userIds[0], 'Hair braiding', 'Home service, book ahead', 'Beauty', 800],
  ];
  services.forEach((s) => insertService.run(...s));

  const insertItem = db.prepare(
    'INSERT INTO items (user_id, name, description, category, price, quantity) VALUES (?, ?, ?, ?, ?, ?)'
  );
  const items = [
    [userIds[0], 'Calculus textbook', 'Stewart 8th edition, good condition', 'Books', 1500, 1],
    [userIds[1], 'Scientific calculator', 'Casio fx-991, barely used', 'Electronics', 1200, 2],
    [userIds[2], 'Hot plate', 'Two burner, works perfectly', 'Electronics', 2000, 1],
    [userIds[0], 'Pack of instant noodles', 'Bulk buy, 24 packs', 'Food', 900, 5],
    [userIds[1], 'Denim jacket', 'Size medium, black', 'Clothing', 1800, 1],
  ];
  items.forEach((i) => insertItem.run(...i));

  console.log('Seeded demo data:');
  console.log(`  users:    ${users.length} (password: password123)`);
  console.log(`  services: ${services.length}`);
  console.log(`  items:    ${items.length} (Books, Electronics, Food, Clothing)`);
}

seed();

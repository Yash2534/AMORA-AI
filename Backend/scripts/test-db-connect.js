const mysql = require('mysql2/promise');

const hosts = ['127.0.0.1', 'localhost'];
const ports = [3307, 3306];
const passwords = [
  { label: 'empty ("")', val: '' },
  { label: 'amora@123', val: 'amora@123' },
  { label: 'Amora@TDS2026', val: 'Amora@TDS2026' },
  { label: 'root', val: 'root' },
  { label: 'admin', val: 'admin' },
  { label: '123456', val: '123456' },
  { label: 'password', val: 'password' },
];
const users = ['root'];

async function testConnections() {
  console.log('Testing XAMPP MySQL connection settings on Port 3307 and 3306...\n');
  let success = false;

  for (const port of ports) {
    for (const host of hosts) {
      for (const user of users) {
        for (const pwd of passwords) {
          try {
            const conn = await mysql.createConnection({
              host,
              port,
              user,
              password: pwd.val,
              connectTimeout: 2000,
            });
            console.log('====================================================');
            console.log(' SUCCESS! Found working MySQL configuration:');
            console.log(` DB_HOST=${host}`);
            console.log(` DB_PORT=${port}`);
            console.log(` DB_USER=${user}`);
            console.log(` DB_PASS=${pwd.val}`);
            console.log('====================================================\n');
            await conn.end();
            success = true;
            return { host, port, user, pass: pwd.val };
          } catch (err) {
            // failed
          }
        }
      }
    }
  }

  if (!success) {
    console.log('----------------------------------------------------');
    console.log('❌ Could not connect to MySQL.');
    console.log('----------------------------------------------------');
  }
}

testConnections();

require('dotenv').config();
const { Pool } = require('pg');

const pool = new Pool({
  connectionString: isProduction
    ? process.env.DATABASE_URL   // Railway 
    : process.env.DB_CONNECTION_STRING, //local .env
  ssl: isProduction ? { rejectUnauthorized: false } : false,
});

pool.on('error', (err) => {
  console.error('Unexpected PG error', err);
  process.exit(1);
});

module.exports = { pool };

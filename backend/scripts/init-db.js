#!/usr/bin/env node
require('dotenv').config();
const { Pool } = require('pg');
const fs = require('fs');
const path = require('path');

const pool = new Pool({
  connectionString: process.env.DB_CONNECTION_STRING,
});

async function initDatabase() {
  try {
    console.log('🔄 Initializing database...');
    
    // Read and execute SQL scripts in order
    const scripts = ['01_init.sql'];
    
    for (const script of scripts) {
      const scriptPath = path.join(__dirname, script);
      const sql = fs.readFileSync(scriptPath, 'utf8');
      
      console.log(`📄 Executing ${script}...`);
      await pool.query(sql);
      console.log(`✅ ${script} completed`);
    }
    
    console.log('🎉 Database initialization completed successfully!');
  } catch (error) {
    console.error('❌ Database initialization failed:', error);
    process.exit(1);
  } finally {
    await pool.end();
  }
}

initDatabase();

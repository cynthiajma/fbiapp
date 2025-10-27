
require('dotenv').config();
const { Pool } = require('pg');

const pool = new Pool({
  connectionString: process.env.DB_CONNECTION_STRING,
});

async function seedTestData() {
  try {
    console.log('🔄 Seeding test data...');
    
    // Clear existing data and reset sequences to ensure consistent IDs
    await pool.query('DELETE FROM logging');
    await pool.query('DELETE FROM parent_child_link');
    await pool.query('DELETE FROM parents');
    await pool.query('DELETE FROM children');
    console.log('🧹 Cleared existing test data');
    
    // Insert children with explicit IDs
    const children = [
      { id: 1, username: 'alice_child', name: 'Alice', age: 8 },
      { id: 2, username: 'bob_child', name: 'Bob', age: 7 },
      { id: 3, username: 'charlie_child', name: 'Charlie', age: 9 },
    ];
    
    const childIds = [];
    for (const child of children) {
      await pool.query(
        'INSERT INTO children (child_id, child_username, child_name, child_age) VALUES ($1, $2, $3, $4)',
        [child.id, child.username, child.name, child.age]
      );
      childIds.push(child.id);
      console.log(`✅ Created child: ${child.name} (ID: ${child.id})`);
    }
    
    // Reset the child sequence
    await pool.query('ALTER SEQUENCE children_child_id_seq RESTART WITH 4');
    
    // Insert parents with explicit IDs
    const parents = [
      { id: 1, username: 'alice_mom', password: 'password123' },
      { id: 2, username: 'alice_dad', password: 'password123' },
      { id: 3, username: 'bob_mom', password: 'password123' },
    ];
    
    const parentIds = [];
    for (const parent of parents) {
      await pool.query(
        'INSERT INTO parents (parent_id, parent_username, hashed_password) VALUES ($1, $2, $3)',
        [parent.id, parent.username, parent.password]
      );
      parentIds.push(parent.id);
      console.log(`✅ Created parent: ${parent.username} (ID: ${parent.id})`);
    }
    
    // Reset the parent sequence
    await pool.query('ALTER SEQUENCE parents_parent_id_seq RESTART WITH 4');
    
    // Link parents to children
    const links = [
      { parentId: 1, childId: 1 }, // Alice's Mom (1) -> Alice (1)
      { parentId: 2, childId: 1 }, // Alice's Dad (2) -> Alice (1)
      { parentId: 3, childId: 2 }, // Bob's Mom (3) -> Bob (2)
    ];
    
    for (const link of links) {
      await pool.query(
        'INSERT INTO parent_child_link (parent_id, child_id) VALUES ($1, $2)',
        [link.parentId, link.childId]
      );
      console.log(`✅ Linked parent ${link.parentId} to child ${link.childId}`);
    }
    
    console.log('🎉 Test data seeded successfully!');
    console.log('\n📊 Summary:');
    console.log(`   - ${childIds.length} children created`);
    console.log(`   - ${parentIds.length} parents created`);
    console.log(`   - ${links.length} parent-child links created`);
    
  } catch (error) {
    console.error('❌ Error seeding test data:', error);
    process.exit(1);
  } finally {
    await pool.end();
  }
}

seedTestData();

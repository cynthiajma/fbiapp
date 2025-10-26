require('dotenv').config();
const { Pool } = require('pg');

const pool = new Pool({
  connectionString: process.env.DB_CONNECTION_STRING,
});

async function seedTestData() {
  try {
    console.log('🔄 Seeding test data...');
    
    // Clear existing data (optional - comment out if you want to keep existing data)
    await pool.query('DELETE FROM logging');
    await pool.query('DELETE FROM parent_child_link');
    await pool.query('DELETE FROM parents');
    await pool.query('DELETE FROM children');
    console.log('🧹 Cleared existing test data');
    
    // Insert children
    const children = [
      { username: 'alice_child', name: 'Alice', age: 8 },
      { username: 'bob_child', name: 'Bob', age: 7 },
      { username: 'charlie_child', name: 'Charlie', age: 9 },
    ];
    
    const childIds = [];
    for (const child of children) {
      const result = await pool.query(
        'INSERT INTO children (child_username, child_name, child_age) VALUES ($1, $2, $3) RETURNING child_id',
        [child.username, child.name, child.age]
      );
      childIds.push(result.rows[0].child_id);
      console.log(`✅ Created child: ${child.name} (ID: ${result.rows[0].child_id})`);
    }
    
    // Insert parents
    const parents = [
      { username: 'alice_mom', password: 'password123' },
      { username: 'alice_dad', password: 'password123' },
      { username: 'bob_mom', password: 'password123' },
    ];
    
    const parentIds = [];
    for (const parent of parents) {
      const result = await pool.query(
        'INSERT INTO parents (parent_username, hashed_password) VALUES ($1, $2) RETURNING parent_id',
        [parent.username, parent.password]
      );
      parentIds.push(result.rows[0].parent_id);
      console.log(`✅ Created parent: ${parent.username} (ID: ${result.rows[0].parent_id})`);
    }
    
    // Link parents to children
    const links = [
      { parentId: parentIds[0], childId: childIds[0] }, // Alice's Mom -> Alice
      { parentId: parentIds[1], childId: childIds[0] }, // Alice's Dad -> Alice
      { parentId: parentIds[2], childId: childIds[1] }, // Bob's Mom -> Bob
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

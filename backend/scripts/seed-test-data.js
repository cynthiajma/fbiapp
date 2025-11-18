
require('dotenv').config();
const { Pool } = require('pg');
const bcrypt = require('bcryptjs');

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
      { id: 1, username: 'alice_child', age: 8 },
      { id: 2, username: 'bob_child', age: 7 },
      { id: 3, username: 'charlie_child', age: 9 },
    ];
    
    const childIds = [];
    for (const child of children) {
      await pool.query(
        'INSERT INTO children (child_id, child_username, child_age) VALUES ($1, $2, $3)',
        [child.id, child.username, child.age]
      );
      childIds.push(child.id);
      console.log(`✅ Created child: ${child.username} (ID: ${child.id})`);
    }
    
    // Reset the child sequence
    await pool.query('ALTER SEQUENCE children_child_id_seq RESTART WITH 4');
    
    // Insert parents with explicit IDs
    const parents = [
      { id: 1, username: 'alice_mom', email: 'alice.mom@example.com', password: 'password123' },
      { id: 2, username: 'alice_dad', email: 'alice.dad@example.com', password: 'password123' },
      { id: 3, username: 'bob_mom', email: 'bob.mom@example.com', password: 'password123' },
    ];
    
    const parentIds = [];
    for (const parent of parents) {
      const hashedPassword = await bcrypt.hash(parent.password, 10);
      await pool.query(
        'INSERT INTO parents (parent_id, parent_username, parent_email, hashed_password) VALUES ($1, $2, $3, $4)',
        [parent.id, parent.username, parent.email, hashedPassword]
      );
      parentIds.push(parent.id);
      console.log(`✅ Created parent: ${parent.username} (${parent.email}) (ID: ${parent.id})`);
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
    
    // Get character IDs from the database
    const characterResult = await pool.query(
      'SELECT character_id, character_name FROM characters ORDER BY character_id LIMIT 5'
    );
    const characters = characterResult.rows;
    
    let logCount = 0;
    if (characters.length === 0) {
      console.log('⚠️  No characters found in database. Please run populate-characters.js first.');
    } else {
      console.log(`📝 Found ${characters.length} characters for logging`);
      
      // Create fake logs with various timestamps
      const now = new Date();
      const logs = [
        // Alice's logs (child_id: 1)
        {
          childId: 1,
          characterId: characters[0]?.character_id || 1,
          characterName: characters[0]?.character_name || 'Henry the Heartbeat',
          level: 7,
          timestamp: new Date(now.getTime() - 2 * 24 * 60 * 60 * 1000), // 2 days ago
        },
        {
          childId: 1,
          characterId: characters[1]?.character_id || 2,
          characterName: characters[1]?.character_name || 'Samantha Sweat',
          level: 5,
          timestamp: new Date(now.getTime() - 1 * 24 * 60 * 60 * 1000), // 1 day ago
        },
        {
          childId: 1,
          characterId: characters[2]?.character_id || 3,
          characterName: characters[2]?.character_name || 'Gassy Gus',
          level: 3,
          timestamp: new Date(now.getTime() - 12 * 60 * 60 * 1000), // 12 hours ago
        },
        {
          childId: 1,
          characterId: characters[0]?.character_id || 1,
          characterName: characters[0]?.character_name || 'Henry the Heartbeat',
          level: 8,
          timestamp: new Date(now.getTime() - 6 * 60 * 60 * 1000), // 6 hours ago
        },
        // Bob's logs (child_id: 2)
        {
          childId: 2,
          characterId: characters[3]?.character_id || 4,
          characterName: characters[3]?.character_name || 'Betty Butterfly',
          level: 6,
          timestamp: new Date(now.getTime() - 3 * 24 * 60 * 60 * 1000), // 3 days ago
        },
        {
          childId: 2,
          characterId: characters[4]?.character_id || 5,
          characterName: characters[4]?.character_name || 'Gerda Gotta Go',
          level: 4,
          timestamp: new Date(now.getTime() - 1 * 24 * 60 * 60 * 1000), // 1 day ago
        },
      ];
      
      for (const log of logs) {
        try {
          await pool.query(
            `INSERT INTO logging (child_id, character_id, character_name, feeling_level, logging_time) 
             VALUES ($1, $2, $3, $4, $5)`,
            [
              log.childId,
              log.characterId,
              log.characterName,
              log.level,
              log.timestamp
            ]
          );
          logCount++;
          console.log(`✅ Created log: ${log.characterName} (Level: ${log.level}) for child ${log.childId}`);
        } catch (error) {
          console.error(`⚠️  Failed to create log for ${log.characterName}:`, error.message);
        }
      }
      
      console.log(`📊 Created ${logCount} log entries`);
    }
    
    console.log('🎉 Test data seeded successfully!');
    console.log('\n📊 Summary:');
    console.log(`   - ${childIds.length} children created`);
    console.log(`   - ${parentIds.length} parents created`);
    console.log(`   - ${links.length} parent-child links created`);
    if (logCount > 0) {
      console.log(`   - ${logCount} log entries created`);
    }
    
  } catch (error) {
    console.error('❌ Error seeding test data:', error);
    process.exit(1);
  } finally {
    await pool.end();
  }
}

seedTestData();

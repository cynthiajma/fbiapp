
require('dotenv').config();
const { Pool } = require('pg');
const bcrypt = require('bcryptjs');

const pool = new Pool({
  connectionString: process.env.DB_CONNECTION_STRING,
});

// Helper function to generate random date within range
function randomDate(daysAgo, daysAgoEnd = 0) {
  const now = new Date();
  const start = new Date(now.getTime() - daysAgo * 24 * 60 * 60 * 1000);
  const end = new Date(now.getTime() - daysAgoEnd * 24 * 60 * 60 * 1000);
  return new Date(start.getTime() + Math.random() * (end.getTime() - start.getTime()));
}

// Helper function to generate random level with some patterns
// Always returns a value between 1 and 10 (never 0)
function generateLevel(baseLevel, variance = 3) {
  // Generate a random offset between -variance and +variance
  const offset = Math.floor(Math.random() * (variance * 2 + 1)) - variance;
  const level = baseLevel + offset;
  // Clamp between 1 and 10 (never allow 0)
  const clampedLevel = Math.max(1, Math.min(10, level));
  return clampedLevel;
}

async function seedTestData() {
  try {
    console.log('🔄 Seeding extensive test data for visualization...');
    
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
      'SELECT character_id, character_name FROM characters ORDER BY character_id'
    );
    const characters = characterResult.rows;
    
    let logCount = 0;
    if (characters.length === 0) {
      console.log('⚠️  No characters found in database. Please run populate-characters.js first.');
    } else {
      console.log(`📝 Found ${characters.length} characters for logging`);
      
      // Generate extensive logs for Alice (child_id: 1)
      // Spanning 90 days (3 months) with realistic patterns
      const aliceLogs = [];
      
      // Week 1 (0-7 days ago) - Recent, more frequent
      for (let day = 0; day < 7; day++) {
        // 2-4 logs per day
        const logsPerDay = 2 + Math.floor(Math.random() * 3);
        for (let i = 0; i < logsPerDay; i++) {
          const charIndex = Math.floor(Math.random() * characters.length);
          aliceLogs.push({
            childId: 1,
            characterId: characters[charIndex].character_id,
            characterName: characters[charIndex].character_name,
            level: generateLevel(5, 3),
            timestamp: randomDate(day + 1, day),
          });
        }
      }
      
      // Week 2-4 (7-30 days ago) - Past month
      for (let day = 7; day < 30; day++) {
        // 1-3 logs per day, some days might have 0
        if (Math.random() > 0.2) { // 80% chance of logging
          const logsPerDay = 1 + Math.floor(Math.random() * 3);
          for (let i = 0; i < logsPerDay; i++) {
            const charIndex = Math.floor(Math.random() * characters.length);
            // Trend: slightly higher anxiety earlier in month
            const baseLevel = day > 20 ? 6 : 5;
            aliceLogs.push({
              childId: 1,
              characterId: characters[charIndex].character_id,
              characterName: characters[charIndex].character_name,
              level: generateLevel(baseLevel, 3),
              timestamp: randomDate(day + 1, day),
            });
          }
        }
      }
      
      // Month 2-3 (30-90 days ago) - Historical data
      for (let day = 30; day < 90; day++) {
        // 0-2 logs per day, less frequent
        if (Math.random() > 0.4) { // 60% chance of logging
          const logsPerDay = Math.floor(Math.random() * 3);
          for (let i = 0; i < logsPerDay; i++) {
            const charIndex = Math.floor(Math.random() * characters.length);
            // Historical trend: started with higher levels, improved over time
            const baseLevel = day > 60 ? 7 : 6;
            aliceLogs.push({
              childId: 1,
              characterId: characters[charIndex].character_id,
              characterName: characters[charIndex].character_name,
              level: generateLevel(baseLevel, 2),
              timestamp: randomDate(day + 1, day),
            });
          }
        }
      }
      
      // Generate logs for Bob (child_id: 2) - Less extensive but still good
      const bobLogs = [];
      
      // Past 60 days for Bob
      for (let day = 0; day < 60; day++) {
        if (Math.random() > 0.3) { // 70% chance of logging
          const logsPerDay = 1 + Math.floor(Math.random() * 2);
          for (let i = 0; i < logsPerDay; i++) {
            const charIndex = Math.floor(Math.random() * characters.length);
            bobLogs.push({
              childId: 2,
              characterId: characters[charIndex].character_id,
              characterName: characters[charIndex].character_name,
              level: generateLevel(4, 3), // Bob generally calmer
              timestamp: randomDate(day + 1, day),
            });
          }
        }
      }
      
      // Generate some logs for Charlie (child_id: 3) - Sparse data
      const charlieLogs = [];
      for (let day = 0; day < 30; day++) {
        if (Math.random() > 0.6) { // 40% chance of logging - less active
          const charIndex = Math.floor(Math.random() * characters.length);
          charlieLogs.push({
            childId: 3,
            characterId: characters[charIndex].character_id,
            characterName: characters[charIndex].character_name,
            level: generateLevel(5, 2),
            timestamp: randomDate(day + 1, day),
          });
        }
      }
      
      // Add some specific patterns for Alice to make visualizations interesting
      // Morning anxiety pattern (Henry the Heartbeat)
      const henryChar = characters.find(c => c.character_name.includes('Henry') || c.character_name.includes('Heartbeat')) || characters[0];
      for (let week = 0; week < 4; week++) {
        for (let weekday = 1; weekday <= 5; weekday++) { // Weekdays only
          const day = week * 7 + weekday;
          if (day < 30) {
            const morningTime = randomDate(day + 1, day);
            morningTime.setHours(7 + Math.floor(Math.random() * 2), Math.floor(Math.random() * 60));
            aliceLogs.push({
              childId: 1,
              characterId: henryChar.character_id,
              characterName: henryChar.character_name,
              level: generateLevel(6, 2), // School day anxiety
              timestamp: morningTime,
            });
          }
        }
      }
      
      // Combine all logs
      const allLogs = [...aliceLogs, ...bobLogs, ...charlieLogs];
      
      // Sort by timestamp descending
      allLogs.sort((a, b) => b.timestamp - a.timestamp);
      
      console.log(`\n📊 Preparing to insert ${allLogs.length} log entries...`);
      console.log(`   - Alice: ${aliceLogs.length} logs`);
      console.log(`   - Bob: ${bobLogs.length} logs`);
      console.log(`   - Charlie: ${charlieLogs.length} logs`);
      
      // Insert all logs
      for (const log of allLogs) {
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
        } catch (error) {
          console.error(`⚠️  Failed to create log:`, error.message);
        }
      }
      
      console.log(`\n✅ Created ${logCount} log entries`);
      
      // Print summary statistics
      console.log('\n📈 Data Summary for Alice (child_id: 1):');
      const aliceStats = await pool.query(`
        SELECT 
          COUNT(*) as total_logs,
          AVG(feeling_level) as avg_level,
          MIN(feeling_level) as min_level,
          MAX(feeling_level) as max_level,
          COUNT(DISTINCT character_name) as unique_characters,
          MIN(logging_time) as earliest_log,
          MAX(logging_time) as latest_log
        FROM logging WHERE child_id = 1
      `);
      const stats = aliceStats.rows[0];
      console.log(`   Total logs: ${stats.total_logs}`);
      console.log(`   Average level: ${parseFloat(stats.avg_level).toFixed(2)}`);
      console.log(`   Level range: ${stats.min_level} - ${stats.max_level}`);
      console.log(`   Unique characters: ${stats.unique_characters}`);
      console.log(`   Date range: ${new Date(stats.earliest_log).toLocaleDateString()} - ${new Date(stats.latest_log).toLocaleDateString()}`);
      
      // Character frequency for Alice
      const charFreq = await pool.query(`
        SELECT character_name, COUNT(*) as count, AVG(feeling_level) as avg_level
        FROM logging WHERE child_id = 1
        GROUP BY character_name
        ORDER BY count DESC
      `);
      console.log('\n   Character frequency:');
      for (const row of charFreq.rows) {
        console.log(`   - ${row.character_name}: ${row.count} logs (avg level: ${parseFloat(row.avg_level).toFixed(1)})`);
      }
    }
    
    console.log('\n🎉 Extensive test data seeded successfully!');
    console.log('\n📊 Final Summary:');
    console.log(`   - ${childIds.length} children created`);
    console.log(`   - ${parentIds.length} parents created`);
    console.log(`   - ${links.length} parent-child links created`);
    console.log(`   - ${logCount} log entries created`);
    console.log('\n💡 Test credentials:');
    console.log('   alice_mom / password123 -> can view alice_child');
    console.log('   alice_dad / password123 -> can view alice_child');
    console.log('   bob_mom / password123 -> can view bob_child');
    
  } catch (error) {
    console.error('❌ Error seeding test data:', error);
    process.exit(1);
  } finally {
    await pool.end();
  }
}

seedTestData();

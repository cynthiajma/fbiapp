require('dotenv').config();
const { Pool } = require('pg');
const fs = require('fs');
const path = require('path');

const pool = new Pool({
  connectionString: process.env.DB_CONNECTION_STRING,
});

async function populateCharacters() {
  try {
    console.log('🔄 Starting character population...');
    
    const characters = [
      {
        name: 'Henry the Heartbeat',
        imagePath: '../../fbi_app/data/characters/henry_heartbeat.png',
        description: 'I am a very powerful machine that pumps blood to all of the parts of your body.'
      },
      {
        name: 'Samantha Sweat',
        imagePath: '../../fbi_app/data/characters/samatha_sweat.png',
        description: 'I like to visit you when your body is preparing for a challenge. I help keep your body cool so you can face the challenge.'
      },
      {
        name: 'Gassy Gus',
        imagePath: '../../fbi_app/data/characters/gassy_gus.png',
        description: 'I someimes cause sharp pains in your stomach that you can get rid of by doing guess what?? FARTING'
      }
    ];
    
    for (const character of characters) {
      const fullImagePath = path.join(__dirname, character.imagePath);
      
      // Check if image file exists
      if (!fs.existsSync(fullImagePath)) {
        console.warn(`⚠️  Image not found: ${character.imagePath}`);
        console.log('📁 Available files in characters directory:');
        const charactersDir = path.join(__dirname, '../../fbi_app/data/characters');
        if (fs.existsSync(charactersDir)) {
          const files = fs.readdirSync(charactersDir);
          console.log(files);
        }
        continue;
      }
      
      const imageBuffer = fs.readFileSync(fullImagePath);
      console.log(`📸 Loading ${character.name}: ${imageBuffer.length} bytes`);
      
      // Insert character with binary image
      await pool.query(
        'INSERT INTO characters (character_name, character_photo, character_description) VALUES ($1, $2, $3) ON CONFLICT (character_name) DO NOTHING',
        [character.name, imageBuffer, character.description]
      );
      
      console.log(`✅ Added ${character.name}`);
    }
    
    console.log('🎉 All characters populated successfully');
    
    // Verify the data was inserted
    const result = await pool.query('SELECT character_id, character_name, LENGTH(character_photo) as photo_size FROM characters ORDER BY character_id');
    console.log('📊 Database verification:');
    result.rows.forEach(row => {
      console.log(`  - ${row.character_name} (ID: ${row.character_id}, Photo: ${row.photo_size} bytes)`);
    });
    
  } catch (error) {
    console.error('❌ Error populating characters:', error);
    process.exit(1);
  } finally {
    await pool.end();
  }
}

populateCharacters();

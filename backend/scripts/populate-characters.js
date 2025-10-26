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
        description: 'I sometimes cause sharp pains in your stomach that you can get rid of by doing guess what?? FARTING'
      },
      {
        name: 'Betty Butterfly',
        imagePath: '../../fbi_app/data/characters/betty_butterfly.png',
        description: 'I flutter in your tummy when you feel excited or nervous. I help you know when something important is happening!'
      },
      {
        name: 'Gerda Gotta Go',
        imagePath: '../../fbi_app/data/characters/gerda_gotta_go.png',
        description: 'I let you know when it\'s time to visit the bathroom. Listen to me so you don\'t have any accidents!'
      },
      {
        name: 'Gordon Gotta Go',
        imagePath: '../../fbi_app/data/characters/gordon_gotta_go.png',
        description: 'I\'m Gordon and I help you know when you need to use the bathroom. Don\'t ignore me!'
      },
      {
        name: 'Patricia the Poop Pain',
        imagePath: '../../fbi_app/data/characters/patricia_the_poop_pain.png',
        description: 'I visit when you haven\'t been drinking enough water or eating enough fiber. I can make going to the bathroom uncomfortable.'
      },
      {
        name: 'Polly Pain',
        imagePath: '../../fbi_app/data/characters/polly_pain.png',
        description: 'I\'m Polly and I help you understand when something hurts in your body. I\'m here to help you communicate about pain.'
      },
      {
        name: 'Ricky the Rock',
        imagePath: '../../fbi_app/data/characters/ricky_the_rock.png',
        description: 'I\'m Ricky and I represent the strong, solid parts of your body like your bones. I help keep you sturdy and standing tall!'
      },
      {
        name: 'Heart',
        imagePath: '../../fbi_app/data/characters/heart.png',
        description: 'I am your heart, the most important muscle in your body. I pump blood to keep you alive and healthy!'
      },
      {
        name: 'Classified',
        imagePath: '../../fbi_app/data/characters/classified.png',
        description: 'I\'m a special character that helps you learn about your body in a fun and mysterious way!'
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

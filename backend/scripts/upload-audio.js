require('dotenv').config();
const { Pool } = require('pg');
const fs = require('fs');
const path = require('path');

const pool = new Pool({
  connectionString: process.env.DB_CONNECTION_STRING,
});

async function uploadAudio() {
  try {
    console.log('🔄 Starting audio upload...');
    
    const audioMappings = [
      {
        characterName: 'Henry the Heartbeat',
        audioPath: '../../fbi_app/data/audio/henry_heartbeat.mp3'
      },
    ];
    
    for (const mapping of audioMappings) {
      const fullAudioPath = path.join(__dirname, mapping.audioPath);
      
      // Check if audio file exists
      if (!fs.existsSync(fullAudioPath)) {
        console.warn(`⚠️  Audio file not found: ${mapping.audioPath}`);
        console.log('   Skipping this character...');
        continue;
      }
      
      const audioBuffer = fs.readFileSync(fullAudioPath);
      console.log(`🎵 Loading ${mapping.characterName}: ${audioBuffer.length} bytes`);
      
      // Update character with audio file
      const result = await pool.query(
        'UPDATE characters SET audio_file = $1 WHERE character_name = $2 RETURNING character_id',
        [audioBuffer, mapping.characterName]
      );
      
      if (result.rows.length > 0) {
        console.log(`✅ Updated ${mapping.characterName} (ID: ${result.rows[0].character_id})`);
      } else {
        console.warn(`⚠️  Character not found: ${mapping.characterName}`);
      }
    }
    
    console.log('🎉 Audio upload complete');
    
    // Verify the data was inserted
    const result = await pool.query(
      'SELECT character_id, character_name, LENGTH(audio_file) as audio_size FROM characters WHERE audio_file IS NOT NULL ORDER BY character_id'
    );
    
    if (result.rows.length > 0) {
      console.log('📊 Characters with audio:');
      result.rows.forEach(row => {
        console.log(`  - ${row.character_name} (ID: ${row.character_id}, Audio: ${row.audio_size} bytes)`);
      });
    } else {
      console.log('📊 No characters have audio files yet');
    }
    
  } catch (error) {
    console.error('❌ Error uploading audio:', error);
    process.exit(1);
  } finally {
    await pool.end();
  }
}

uploadAudio();


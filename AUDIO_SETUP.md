# Audio Feature Setup Guide

This guide explains the audio feature that has been added to the FBI app, allowing you to store MP3 audio files in the characters database and play them in the frontend.

## What Was Changed

### Backend Changes

1. **Database Schema** (`backend/scripts/01_init.sql`)
   - Added `audio_file BYTEA` column to the `characters` table

2. **GraphQL Schema** (`backend/index.js`)
   - Added `audio: String` field to the `Character` type
   - Updated `characterLibrary` resolver to return audio as base64-encoded string

3. **Migration Script** (`backend/scripts/add-audio-column.js`)
   - Script to add the `audio_file` column to existing databases

4. **Upload Script** (`backend/scripts/upload-audio.js`)
   - Script to upload MP3 files to the database for specific characters

### Frontend Changes

1. **Character Service** (`fbi_app/lib/services/character_service.dart`)
   - Updated `Character` model to include `audio` field
   - Updated GraphQL query to fetch `audio` field

2. **Child Data Service** (`fbi_app/lib/services/child_data_service.dart`)
   - Updated character library query to include `audio` field

3. **Heartbeat Page** (`fbi_app/lib/heartbeat.dart`)
   - Added audio playback functionality
   - Added `AudioPlayer` instance to play character voiceovers
   - Fetches Henry the Heartbeat's audio on page load
   - Plays audio when the sound button is pressed

4. **Dependencies** (`fbi_app/pubspec.yaml`)
   - Added `audioplayers: ^5.2.1` package for audio playback

## How to Use

### Step 1: Install Frontend Dependencies

Navigate to the Flutter app directory and install the new audio player package:

```bash
cd fbi_app
flutter pub get
```

### Step 2: Add Audio Column to Database

Run the migration script to add the `audio_file` column to your existing database:

```bash
cd backend
npm run add-audio-column
```

### Step 3: Prepare Your Audio Files

1. Create an audio directory (if it doesn't exist):
   ```bash
   mkdir -p fbi_app/data/audio
   ```

2. Place your MP3 files in this directory. For example:
   - `fbi_app/data/audio/henry_heartbeat.mp3`
   - `fbi_app/data/audio/samantha_sweat.mp3`
   - etc.

### Step 4: Upload Audio Files to Database

1. Edit `backend/scripts/upload-audio.js` and update the `audioMappings` array with your character names and audio file paths:

   ```javascript
   const audioMappings = [
     {
       characterName: 'Henry the Heartbeat',
       audioPath: '../../fbi_app/data/audio/henry_heartbeat.mp3'
     },
     {
       characterName: 'Samantha Sweat',
       audioPath: '../../fbi_app/data/audio/samantha_sweat.mp3'
     },
     // Add more characters...
   ];
   ```

2. Run the upload script:
   ```bash
   npm run upload-audio
   ```

### Step 5: Restart Your Backend Server

If your backend is running, restart it to pick up the schema changes:

```bash
npm start
```

### Step 6: Test the Audio Feature

1. Launch your Flutter app
2. Navigate to the Heartbeat page
3. Click the speaker icon in the top-right corner
4. The audio for Henry the Heartbeat should play!

## How It Works

### Data Flow

1. **Storage**: MP3 files are stored as binary data (BYTEA) in PostgreSQL
2. **Backend**: GraphQL resolver converts binary data to base64 string
3. **Frontend**: Flutter app receives base64 string via GraphQL query
4. **Playback**: `audioplayers` package decodes base64 and plays the audio

### Audio Format

- **Supported formats**: MP3, WAV, OGG, AAC
- **Recommended**: MP3 for best compatibility
- **Storage**: Audio is stored directly in the database (no file system dependencies)

## Troubleshooting

### Audio doesn't play
- Check that the audio file was successfully uploaded (run `npm run upload-audio` and verify the output)
- Verify the character ID in `heartbeat.dart` matches your database
- Check the browser/app console for error messages

### Database error when running migration
- Make sure your database is running and accessible
- Check your `.env` file has the correct `DB_CONNECTION_STRING`

### Audio button is disabled
- Wait for the audio to finish loading (check console for errors)
- Verify that Henry the Heartbeat (character ID 1) has audio data in the database

## Adding Audio to Other Character Pages

To add audio playback to other character pages, follow the pattern in `heartbeat.dart`:

1. Import required packages:
   ```dart
   import 'dart:convert';
   import 'package:audioplayers/audioplayers.dart';
   import 'services/character_service.dart';
   ```

2. Add audio player state:
   ```dart
   final AudioPlayer _audioPlayer = AudioPlayer();
   String? _characterAudio;
   ```

3. Fetch character data and play audio:
   ```dart
   final characters = await CharacterService.getCharacters();
   final character = characters.firstWhere((c) => c.id == 'YOUR_CHARACTER_ID');
   
   if (character.audio != null) {
     final audioBytes = base64Decode(character.audio!);
     await _audioPlayer.play(BytesSource(audioBytes));
   }
   ```

## Database Structure

The `characters` table now has the following structure:

```sql
CREATE TABLE characters (
  character_id          SERIAL PRIMARY KEY,
  character_name        VARCHAR(100) NOT NULL UNIQUE,
  character_photo       BYTEA,
  character_description TEXT,
  audio_file            BYTEA
);
```

## NPM Scripts

The following scripts are available in `backend/package.json`:

- `npm run add-audio-column` - Add audio_file column to existing database
- `npm run upload-audio` - Upload MP3 files to database
- `npm start` - Start the backend server

## Notes

- Audio files are stored as binary data in the database, so they're included in database backups
- Large audio files will increase database size - consider keeping voiceovers short (10-30 seconds)
- The base64 encoding increases data transfer size by ~33%, but this is acceptable for short audio clips
- Audio playback is handled entirely in memory, no temporary files are created


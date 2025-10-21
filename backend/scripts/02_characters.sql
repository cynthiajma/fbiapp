-- Description: This script populates the 'characters' table with character data.
BEGIN;

INSERT INTO characters (character_name, character_photo, character_description)
VALUES
  ('Henry the Heartbeat', '../../fbi_app/data/characters/henry_heartbeat.png', 
   'I am a very powerful machine that pumps blood to all of the parts of your body.');

COMMIT;


SELECT * FROM characters;

// Test helper functions

function createMockChild(id, username, age) {
  return {
    child_id: id,
    child_username: username,
    child_age: age,
  };
}

function createMockParent(id, username, email, hashedPassword) {
  return {
    parent_id: id,
    parent_username: username,
    parent_email: email,
    hashed_password: hashedPassword,
  };
}

function createMockLog(id, childId, characterId, characterName, level, timestamp, investigation) {
  return {
    log_id: id,
    child_id: childId,
    character_id: characterId,
    character_name: characterName,
    feeling_level: level,
    logging_time: timestamp,
    investigation: investigation || null,
  };
}

function createMockCharacter(id, name, photo, description, audio) {
  return {
    character_id: id,
    character_name: name,
    character_photo: photo,
    character_description: description,
    audio_file: audio,
  };
}

module.exports = {
  createMockChild,
  createMockParent,
  createMockLog,
  createMockCharacter,
};


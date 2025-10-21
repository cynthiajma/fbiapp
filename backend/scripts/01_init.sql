BEGIN;

CREATE TABLE IF NOT EXISTS parents (
  parent_id        SERIAL PRIMARY KEY,
  parent_username  VARCHAR(100) NOT NULL UNIQUE,
  hashed_password  VARCHAR(255) NOT NULL
);

CREATE TABLE IF NOT EXISTS children (
  child_id         SERIAL PRIMARY KEY,
  child_username   VARCHAR(100) NOT NULL UNIQUE,
  child_name       VARCHAR(100),
  child_age        INT CHECK (child_age BETWEEN 0 AND 200)
);

CREATE TABLE IF NOT EXISTS parent_child_link (
  parent_id INT NOT NULL REFERENCES parents(parent_id) ON DELETE CASCADE,
  child_id  INT NOT NULL REFERENCES children(child_id) ON DELETE CASCADE,
  PRIMARY KEY (parent_id, child_id)
);

CREATE TABLE IF NOT EXISTS characters (
  character_id          SERIAL PRIMARY KEY,
  character_name        VARCHAR(100) NOT NULL UNIQUE,
  character_photo       BYTEA,
  character_description TEXT
);

CREATE TABLE IF NOT EXISTS logging (
  log_id          SERIAL PRIMARY KEY,
  logging_time    TIMESTAMPTZ NOT NULL DEFAULT now(),
  child_id        INT NOT NULL REFERENCES children(child_id) ON DELETE CASCADE,
  character_id    INT NOT NULL REFERENCES characters(character_id) ON DELETE RESTRICT,
  character_name  VARCHAR(100),
  feeling_level   INT NOT NULL CHECK (feeling_level BETWEEN 0 AND 10)
);

COMMIT;
const { ApolloServer, gql } = require('apollo-server');
const { pool } = require('./db');
const bcrypt = require('bcrypt');

const typeDefs = gql`
  type Query {
    childProfile(id: ID!): Child
    childByUsername(username: String!): Child
    characterLibrary: [Character]
    parentProfile(id: ID!): Parent
    childLogs(childId: ID!, startTime: String, endTime: String): [Log]
  }

  type Mutation {
    logFeeling(childId: ID!, characterId: ID!, level: Int!, investigation: [String!]): Log
    createChild(username: String!, name: String, age: Int): Child
    createParent(username: String!, password: String!, childId: ID): Parent
    loginParent(username: String!, password: String!): Parent
    linkParentChild(parentId: ID!, childId: ID!): Boolean
  }

  type Child {
    id: ID!
    username: String!
    name: String
    age: Int
    parents: [Parent!]
  }

  type Parent {
    id: ID!
    username: String!
    children: [Child!]
  }

  type Character {
    id: ID!
    name: String!
    photo: String
    description: String
    audio: String
  }

  type Log {
    id: ID!
    childId: ID!
    characterId: ID!
    characterName: String
    level: Int!
    timestamp: String!
    investigation: [String!]
  }
`;


const resolvers = {
  Query: {
    childProfile: async (_, { id }) => {
      const result = await pool.query(
        'SELECT child_id, child_username, child_name, child_age FROM children WHERE child_id = $1',
        [id]
      );
      if (result.rows.length === 0) return null;
      const child = result.rows[0];
      return {
        id: child.child_id.toString(),
        username: child.child_username,
        name: child.child_name,
        age: child.child_age,
      };
    },
    childByUsername: async (_, { username }) => {
      const result = await pool.query(
        'SELECT child_id, child_username, child_name, child_age FROM children WHERE child_username = $1',
        [username]
      );
      if (result.rows.length === 0) return null;
      const child = result.rows[0];
      return {
        id: child.child_id.toString(),
        username: child.child_username,
        name: child.child_name,
        age: child.child_age,
      };
    },
    characterLibrary: async () => {
      const result = await pool.query(
        'SELECT character_id, character_name, character_photo, character_description, audio_file FROM characters'
      );
      return result.rows.map(char => ({
        id: char.character_id.toString(),
        name: char.character_name,
        photo: char.character_photo ? Buffer.from(char.character_photo).toString('base64') : null,
        description: char.character_description,
        audio: char.audio_file ? Buffer.from(char.audio_file).toString('base64') : null,
      }));
    },
    parentProfile: async (_, { id }) => {
      const result = await pool.query(
        'SELECT parent_id, parent_username FROM parents WHERE parent_id = $1',
        [id]
      );
      if (result.rows.length === 0) return null;
      const parent = result.rows[0];
      return {
        id: parent.parent_id.toString(),
        username: parent.parent_username,
      };
    },
    childLogs: async (_, { childId, startTime, endTime }) => {
      let query = 'SELECT log_id, child_id, character_id, character_name, feeling_level, logging_time, investigation FROM logging WHERE child_id = $1';
      let params = [childId];
      
      if (startTime && endTime) {
        query += ' AND logging_time BETWEEN $2 AND $3 ORDER BY logging_time DESC';
        params.push(startTime, endTime);
      } else {
        query += ' ORDER BY logging_time DESC';
      }
      
      const result = await pool.query(query, params);
      return result.rows.map(log => ({
        id: log.log_id.toString(),
        childId: log.child_id.toString(),
        characterId: log.character_id.toString(),
        characterName: log.character_name,
        level: log.feeling_level,
        timestamp: log.logging_time.toISOString(),
        investigation: log.investigation || [],
      }));
    },
  },
  Mutation: {
    logFeeling: async (_, { childId, characterId, level, investigation }) => {
      const charNameResult = await pool.query(
        'SELECT character_name FROM characters WHERE character_id = $1',
        [characterId]
      );
      const characterName = charNameResult.rows[0]?.character_name || null;

      const result = await pool.query(
        'INSERT INTO logging (child_id, character_id, character_name, feeling_level, investigation) VALUES ($1, $2, $3, $4, $5) RETURNING log_id, logging_time',
        [childId, characterId, characterName, level, investigation || null]
      );
      const log = result.rows[0];
      return {
        id: log.log_id.toString(),
        childId,
        characterId,
        characterName,
        level,
        timestamp: log.logging_time.toISOString(),
        investigation: investigation || [],
      };
    },
    createChild: async (_, { username, name, age }) => {
      const result = await pool.query(
        'INSERT INTO children (child_username, child_name, child_age) VALUES ($1, $2, $3) RETURNING child_id, child_username, child_name, child_age',
        [username, name, age]
      );
      const child = result.rows[0];
      return {
        id: child.child_id.toString(),
        username: child.child_username,
        name: child.child_name,
        age: child.child_age,
      };
    },
    createParent: async (_, { username, password, childId }) => {
      const hashedPassword = await bcrypt.hash(password, 10);
      const result = await pool.query(
        'INSERT INTO parents (parent_username, hashed_password) VALUES ($1, $2) RETURNING parent_id, parent_username',
        [username, hashedPassword]
      );
      const parent = result.rows[0];
      
      // Auto-link to child if childId is provided
      if (childId) {
        try {
          await pool.query(
            'INSERT INTO parent_child_link (parent_id, child_id) VALUES ($1, $2)',
            [parent.parent_id, childId]
          );
        } catch (error) {
          console.error('Error auto-linking parent and child:', error);
        }
      }

      return {
        id: parent.parent_id.toString(),
        username: parent.parent_username,
      };
    },
    loginParent: async (_, { username, password }) => {
      const result = await pool.query(
        'SELECT parent_id, parent_username, hashed_password FROM parents WHERE parent_username = $1',
        [username]
      );
      
      if (result.rows.length === 0) {
        throw new Error('Parent account not found. Please check your username and try again.');
      }
      
      const parent = result.rows[0];
      
      const isPasswordValid = await bcrypt.compare(password, parent.hashed_password);
      if (!isPasswordValid) {
        throw new Error('Incorrect password. Please try again.');
      }
      
      return {
        id: parent.parent_id.toString(),
        username: parent.parent_username,
      };
    },
    linkParentChild: async (_, { parentId, childId }) => {
      // Check if this link already exists (parent is already linked to this child)
      const existingLink = await pool.query(
        'SELECT parent_id FROM parent_child_link WHERE parent_id = $1 AND child_id = $2',
        [parentId, childId]
      );
      
      if (existingLink.rows.length === 0) {
        // Try to insert the link, but this shouldn't normally happen through the UI
        // since parents should only be able to link to their own children
        await pool.query(
          'INSERT INTO parent_child_link (parent_id, child_id) VALUES ($1, $2)',
          [parentId, childId]
        );
      }
      
      return true;
    },
  },
  
  // Nested field resolvers: 
  Parent: {
    children: async (parent) => {
      const result = await pool.query(`
        SELECT c.child_id, c.child_username, c.child_name, c.child_age 
        FROM children c
        JOIN parent_child_link pcl ON c.child_id = pcl.child_id
        WHERE pcl.parent_id = $1
      `, [parent.id]);
      
      return result.rows.map(child => ({
        id: child.child_id.toString(),
        username: child.child_username,
        name: child.child_name,
        age: child.child_age,
      }));
    }
  },
  
  Child: {
    parents: async (child) => {
      const result = await pool.query(`
        SELECT p.parent_id, p.parent_username
        FROM parents p
        JOIN parent_child_link pcl ON p.parent_id = pcl.parent_id
        WHERE pcl.child_id = $1
      `, [child.id]);
      
      return result.rows.map(parent => ({
        id: parent.parent_id.toString(),
        username: parent.parent_username,
      }));
    }
  }
};

const server = new ApolloServer({ 
  typeDefs, 
  resolvers,
  cors: {
    origin: true,
    credentials: true,
  },
});

server.listen({ port: 3000, host: '0.0.0.0' }).then(({ url }) => {
  console.log(`🚀 Server ready at ${url}`);
}).catch((error) => {
  console.error('❌ Failed to start server:', error);
  process.exit(1);
});

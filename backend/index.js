const { ApolloServer, gql } = require('apollo-server');
const { pool } = require('./db');

const typeDefs = gql`
  type Query {
    childProfile(id: ID!): Child
    characterLibrary: [Character]
    parentProfile(id: ID!): Parent
    childLogs(childId: ID!): [Log]
  }

  type Mutation {
    logFeeling(childId: ID!, characterId: ID!, level: Int!): Log
    createChild(username: String!, name: String, age: Int): Child
    createParent(username: String!, password: String!): Parent
    linkParentChild(parentId: ID!, childId: ID!): Boolean
  }

  type Child {
    id: ID!
    username: String!
    name: String
    age: Int
  }

  type Parent {
    id: ID!
    username: String!
  }

  type Character {
    id: ID!
    name: String!
    photo: String
    description: String
  }

  type Log {
    id: ID!
    childId: ID!
    characterId: ID!
    characterName: String
    level: Int!
    timestamp: String!
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
    characterLibrary: async () => {
      const result = await pool.query(
        'SELECT character_id, character_name, character_photo, character_description FROM characters'
      );
      return result.rows.map(char => ({
        id: char.character_id.toString(),
        name: char.character_name,
        photo: char.character_photo,
        description: char.character_description,
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
    childLogs: async (_, { childId }) => {
      const result = await pool.query(
        'SELECT log_id, child_id, character_id, character_name, feeling_level, logging_time FROM logging WHERE child_id = $1 ORDER BY logging_time DESC',
        [childId]
      );
      return result.rows.map(log => ({
        id: log.log_id.toString(),
        childId: log.child_id.toString(),
        characterId: log.character_id.toString(),
        characterName: log.character_name,
        level: log.feeling_level,
        timestamp: log.logging_time.toISOString(),
      }));
    },
  },
  Mutation: {
    logFeeling: async (_, { childId, characterId, level }) => {
      // Get character name for the log
      const charResult = await pool.query(
        'SELECT character_name FROM characters WHERE character_id = $1',
        [characterId]
      );
      const characterName = charResult.rows[0]?.character_name || null;

      const result = await pool.query(
        'INSERT INTO logging (child_id, character_id, character_name, feeling_level) VALUES ($1, $2, $3, $4) RETURNING log_id, logging_time',
        [childId, characterId, characterName, level]
      );
      const log = result.rows[0];
      return {
        id: log.log_id.toString(),
        childId,
        characterId,
        characterName,
        level,
        timestamp: log.logging_time.toISOString(),
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
    createParent: async (_, { username, password }) => {
      // In a real app, you'd hash the password
      const hashedPassword = password; // TODO: Hash the password properly
      const result = await pool.query(
        'INSERT INTO parents (parent_username, hashed_password) VALUES ($1, $2) RETURNING parent_id, parent_username',
        [username, hashedPassword]
      );
      const parent = result.rows[0];
      return {
        id: parent.parent_id.toString(),
        username: parent.parent_username,
      };
    },
    linkParentChild: async (_, { parentId, childId }) => {
      try {
        await pool.query(
          'INSERT INTO parent_child_link (parent_id, child_id) VALUES ($1, $2)',
          [parentId, childId]
        );
        return true;
      } catch (error) {
        console.error('Error linking parent and child:', error);
        return false;
      }
    },
  },
};

const server = new ApolloServer({ typeDefs, resolvers });

server.listen().then(({ url }) => {
  console.log(`🚀 Server ready at ${url}`);
}).catch((error) => {
  console.error('❌ Failed to start server:', error);
  process.exit(1);
});

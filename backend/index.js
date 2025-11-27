const { ApolloServer } = require('@apollo/server');
const { expressMiddleware } = require('@apollo/server/express4');
const { ApolloServerPluginDrainHttpServer } = require('@apollo/server/plugin/drainHttpServer');
const express = require('express');
const http = require('http');
const cors = require('cors');
const { pool } = require('./db');
const bcrypt = require('bcryptjs');
const crypto = require('crypto');
const { sendPasswordResetEmail } = require('./email-config');

const typeDefs = `
  type Query {
    childProfile(id: ID!): Child
    childByUsername(username: String!): Child
    characterLibrary: [Character]
    parentProfile(id: ID!): Parent
    parentChildren(parentId: ID!): [Child!]
    childLogs(childId: ID!, startTime: String, endTime: String): [Log]
    isParentLinkedToChild(parentId: ID!, childId: ID!): Boolean!
  }

  type Mutation {
    logFeeling(childId: ID!, characterId: ID!, level: Int!, investigation: [String!]): Log
    createChild(username: String!, age: Int): Child
    createParent(username: String!, email: String!, password: String!, childId: ID): Parent
    loginParent(username: String!, password: String!): Parent
    linkParentChild(parentId: ID!, childId: ID!): Boolean
    requestPasswordReset(email: String!, childId: ID): Boolean
    resetPassword(token: String!, newPassword: String!): Boolean
  }

  type Child {
    id: ID!
    username: String!
    age: Int
    parents: [Parent!]
  }

  type Parent {
    id: ID!
    username: String!
    email: String!
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
        'SELECT child_id, child_username, child_age FROM children WHERE child_id = $1',
        [id]
      );
      if (result.rows.length === 0) return null;
      const child = result.rows[0];
      return {
        id: child.child_id.toString(),
        username: child.child_username,
        age: child.child_age,
      };
    },
    childByUsername: async (_, { username }) => {
      const result = await pool.query(
        'SELECT child_id, child_username, child_age FROM children WHERE child_username = $1',
        [username]
      );
      if (result.rows.length === 0) return null;
      const child = result.rows[0];
      return {
        id: child.child_id.toString(),
        username: child.child_username,
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
        'SELECT parent_id, parent_username, parent_email FROM parents WHERE parent_id = $1',
        [id]
      );
      if (result.rows.length === 0) return null;
      const parent = result.rows[0];
      return {
        id: parent.parent_id.toString(),
        username: parent.parent_username,
        email: parent.parent_email,
      };
    },
    parentChildren: async (_, { parentId }) => {
      // Convert string ID to integer for database query
      const parentIdInt = parseInt(parentId, 10);
      if (isNaN(parentIdInt)) {
        return [];
      }
      
      const result = await pool.query(`
        SELECT c.child_id, c.child_username, c.child_age 
        FROM children c
        JOIN parent_child_link pcl ON c.child_id = pcl.child_id
        WHERE pcl.parent_id = $1
      `, [parentIdInt]);
      
      return result.rows.map(child => ({
        id: child.child_id.toString(),
        username: child.child_username,
        age: child.child_age,
      }));
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
    isParentLinkedToChild: async (_, { parentId, childId }) => {
      // Convert string IDs to integers for database queries
      const parentIdInt = parseInt(parentId, 10);
      const childIdInt = parseInt(childId, 10);
      
      if (isNaN(parentIdInt) || isNaN(childIdInt)) {
        return false;
      }
      
      const result = await pool.query(
        'SELECT parent_id FROM parent_child_link WHERE parent_id = $1 AND child_id = $2',
        [parentIdInt, childIdInt]
      );
      return result.rows.length > 0;
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
    createChild: async (_, { username, age }) => {
      const result = await pool.query(
        'INSERT INTO children (child_username, child_age) VALUES ($1, $2) RETURNING child_id, child_username, child_age',
        [username, age]
      );
      const child = result.rows[0];
      return {
        id: child.child_id.toString(),
        username: child.child_username,
        age: child.child_age,
      };
    },
    createParent: async (_, { username, email, password, childId }) => {
      // Check if username already exists
      const usernameCheck = await pool.query(
        'SELECT parent_id FROM parents WHERE parent_username = $1',
        [username]
      );
      if (usernameCheck.rows.length > 0) {
        throw new Error('Username already taken');
      }
      
      // Check if email already exists
      const emailCheck = await pool.query(
        'SELECT parent_id FROM parents WHERE parent_email = $1',
        [email]
      );
      if (emailCheck.rows.length > 0) {
        throw new Error('Email address already registered');
      }

      const hashedPassword = await bcrypt.hash(password, 10);
      
      let result;
      try {
        result = await pool.query(
          'INSERT INTO parents (parent_username, parent_email, hashed_password) VALUES ($1, $2, $3) RETURNING parent_id, parent_username, parent_email',
          [username, email, hashedPassword]
        );
      } catch (dbError) {
        // Catch database constraint violations (race conditions, etc.)
        if (dbError.code === '23505') { // PostgreSQL unique violation error code
          const constraint = dbError.constraint || '';
          if (constraint.includes('parent_username') || dbError.detail?.includes('parent_username')) {
            throw new Error('Username already taken');
          } else if (constraint.includes('parent_email') || dbError.detail?.includes('parent_email')) {
            throw new Error('Email address already registered');
          }
        }
        // Re-throw if it's not a constraint violation we can handle
        throw dbError;
      }
      
      const parent = result.rows[0];
      
      // Auto-link to child if childId is provided
      if (childId) {
        try {
          // Convert string childId to integer for database query
          const childIdInt = parseInt(childId, 10);
          if (isNaN(childIdInt)) {
            console.error(`Invalid childId provided: ${childId}`);
          } else {
            // Check if link already exists
            const existingLink = await pool.query(
              'SELECT parent_id FROM parent_child_link WHERE parent_id = $1 AND child_id = $2',
              [parent.parent_id, childIdInt]
            );
            
            if (existingLink.rows.length === 0) {
              await pool.query(
                'INSERT INTO parent_child_link (parent_id, child_id) VALUES ($1, $2)',
                [parent.parent_id, childIdInt]
              );
              console.log(`✓ Auto-linked parent ${parent.parent_id} to child ${childIdInt}`);
            } else {
              console.log(`Link already exists between parent ${parent.parent_id} and child ${childIdInt}`);
            }
          }
        } catch (error) {
          console.error('Error auto-linking parent and child:', error);
          // Don't throw - parent account is created, link can be added later
        }
      }

      return {
        id: parent.parent_id.toString(),
        username: parent.parent_username,
        email: parent.parent_email,
      };
    },
    loginParent: async (_, { username, password }) => {
      const result = await pool.query(
        'SELECT parent_id, parent_username, parent_email, hashed_password FROM parents WHERE parent_username = $1',
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
        email: parent.parent_email,
      };
    },
    linkParentChild: async (_, { parentId, childId }) => {
      try {
        // Convert string IDs to integers for database queries
        const parentIdInt = parseInt(parentId, 10);
        const childIdInt = parseInt(childId, 10);
        
        if (isNaN(parentIdInt) || isNaN(childIdInt)) {
          throw new Error('Invalid parent or child ID');
        }
        
        // Verify parent exists
        const parentCheck = await pool.query(
          'SELECT parent_id FROM parents WHERE parent_id = $1',
          [parentIdInt]
        );
        if (parentCheck.rows.length === 0) {
          throw new Error('Parent account not found');
        }
        
        // Verify child exists
        const childCheck = await pool.query(
          'SELECT child_id FROM children WHERE child_id = $1',
          [childIdInt]
        );
        if (childCheck.rows.length === 0) {
          throw new Error('Child account not found');
        }
        
        // Check if this link already exists
        const existingLink = await pool.query(
          'SELECT parent_id FROM parent_child_link WHERE parent_id = $1 AND child_id = $2',
          [parentIdInt, childIdInt]
        );
        
        if (existingLink.rows.length === 0) {
          // Create the link
          // Security Note: Currently allows any parent to link to any child if they know the child ID
          // In production, consider adding: child approval, invitation codes, or email verification
          await pool.query(
            'INSERT INTO parent_child_link (parent_id, child_id) VALUES ($1, $2)',
            [parentIdInt, childIdInt]
          );
          console.log(`✓ Linked parent ${parentIdInt} to child ${childIdInt}`);
        } else {
          console.log(`Link already exists between parent ${parentIdInt} and child ${childIdInt}`);
        }
        
        return true;
      } catch (error) {
        console.error('Error linking parent and child:', error);
        throw error;
      }
    },
    requestPasswordReset: async (_, { email, childId }) => {
      try {
        // Find parent by email
        const result = await pool.query(
          'SELECT parent_id, parent_email FROM parents WHERE parent_email = $1',
          [email]
        );
        
        // Check if email exists and throw error if not
        if (result.rows.length === 0) {
          console.log('Password reset requested for non-existent email:', email);
          throw new Error('No account found with this email address. Please check your email or create a new account.');
        }
        
        const parent = result.rows[0];
        
        // Verify that the parent is linked to this child
        if (childId) {
          const linkCheck = await pool.query(
            'SELECT parent_id FROM parent_child_link WHERE parent_id = $1 AND child_id = $2',
            [parent.parent_id, childId]
          );
          
          if (linkCheck.rows.length === 0) {
            console.log('Password reset denied: Parent not linked to child', { parentId: parent.parent_id, childId });
            throw new Error('This parent is not linked to the current child.');
          }
        }
        
        // Generate 6-digit numerical code
        const resetCode = Math.floor(100000 + Math.random() * 900000).toString();
        
        // Code expires in 15 minutes
        const expiryTime = new Date(Date.now() + 15 * 60 * 1000);
        
        // Store code in database
        await pool.query(
          'UPDATE parents SET reset_token = $1, reset_token_expiry = $2 WHERE parent_id = $3',
          [resetCode, expiryTime, parent.parent_id]
        );
        
        // Send reset email with code
        await sendPasswordResetEmail(email, resetCode);
        
        console.log('Password reset code sent to:', email);
        return true;
      } catch (error) {
        console.error('Error requesting password reset:', error);
        throw error;
      }
    },
    resetPassword: async (_, { token, newPassword }) => {
      try {
        // Find parent by reset token
        const result = await pool.query(
          'SELECT parent_id, parent_email, reset_token_expiry FROM parents WHERE reset_token = $1',
          [token]
        );
        
        if (result.rows.length === 0) {
          throw new Error('Invalid or expired reset token');
        }
        
        const parent = result.rows[0];
        
        // Check if token has expired
        if (new Date() > new Date(parent.reset_token_expiry)) {
          throw new Error('Reset token has expired. Please request a new password reset.');
        }
        
        // Hash new password
        const hashedPassword = await bcrypt.hash(newPassword, 10);
        
        // Update password and clear reset token
        await pool.query(
          'UPDATE parents SET hashed_password = $1, reset_token = NULL, reset_token_expiry = NULL WHERE parent_id = $2',
          [hashedPassword, parent.parent_id]
        );
        
        console.log('Password reset successful for:', parent.parent_email);
        return true;
      } catch (error) {
        console.error('Error resetting password:', error);
        throw error;
      }
    },
  },
  
  // Nested field resolvers: 
  Parent: {
    children: async (parent) => {
      const result = await pool.query(`
        SELECT c.child_id, c.child_username, c.child_age 
        FROM children c
        JOIN parent_child_link pcl ON c.child_id = pcl.child_id
        WHERE pcl.parent_id = $1
      `, [parent.id]);
      
      return result.rows.map(child => ({
        id: child.child_id.toString(),
        username: child.child_username,
        age: child.child_age,
      }));
    },
    email: (parent) => parent.email,
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

async function startServer() {
  const app = express();
  const httpServer = http.createServer(app);
  
  const server = new ApolloServer({
    typeDefs,
    resolvers,
    plugins: [ApolloServerPluginDrainHttpServer({ httpServer })],
  });

  await server.start();

  app.use(
    '/graphql',
    cors({
      origin: true,
      credentials: true,
    }),
    express.json(),
    expressMiddleware(server)
  );

  const port = process.env.PORT || 3000;
  await new Promise((resolve) => httpServer.listen({ port, host: '0.0.0.0' }, resolve));
  console.log(`🚀 Server ready at http://0.0.0.0:${port}/graphql`);
}

startServer().catch((error) => {
  console.error('❌ Failed to start server:', error);
  process.exit(1);
});

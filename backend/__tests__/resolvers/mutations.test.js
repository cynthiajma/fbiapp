const { describe, test, expect, beforeEach } = require('@jest/globals');
const bcrypt = require('bcryptjs');
const { createMockChild, createMockParent, createMockLog } = require('../helpers');

// Mock the db and email modules
jest.mock('../../db', () => require('../__mocks__/db'));
jest.mock('../../email-config', () => require('../__mocks__/email-config'));

// Get the mocked modules after mocking
const { pool } = require('../../db');
const { sendPasswordResetEmail } = require('../../email-config');

// Import resolvers after mocking
const { resolvers } = require('../../index');

describe('Mutation Resolvers', () => {
  beforeEach(() => {
    jest.clearAllMocks();
  });

  describe('createChild', () => {
    test('should create child successfully', async () => {
      const mockChild = createMockChild(1, 'newchild', 8);
      pool.query.mockResolvedValueOnce({ rows: [mockChild] });

      const result = await resolvers.Mutation.createChild(null, {
        username: 'newchild',
        age: 8,
      });

      expect(result).toEqual({
        id: '1',
        username: 'newchild',
        age: 8,
      });
      expect(pool.query).toHaveBeenCalledWith(
        'INSERT INTO children (child_username, child_age) VALUES ($1, $2) RETURNING child_id, child_username, child_age',
        ['newchild', 8]
      );
    });

    test('should throw error for duplicate username', async () => {
      const duplicateError = new Error('Duplicate key');
      duplicateError.code = '23505';
      duplicateError.constraint = 'children_child_username_key';
      pool.query.mockRejectedValueOnce(duplicateError);

      await expect(
        resolvers.Mutation.createChild(null, {
          username: 'existingchild',
          age: 8,
        })
      ).rejects.toThrow('This detective name is already taken. Please choose a different name.');
    });
  });

  describe('createParent', () => {
    test('should create parent successfully without childId', async () => {
      const mockParent = createMockParent(1, 'newparent', 'new@example.com', 'hashed');
      pool.query
        .mockResolvedValueOnce({ rows: [] }) // username check
        .mockResolvedValueOnce({ rows: [] }) // email check
        .mockResolvedValueOnce({ rows: [mockParent] }); // insert

      // Mock bcrypt.hash
      const originalHash = bcrypt.hash;
      bcrypt.hash = jest.fn().mockResolvedValue('hashed');

      const result = await resolvers.Mutation.createParent(null, {
        username: 'newparent',
        email: 'new@example.com',
        password: 'password123',
      });

      expect(result).toEqual({
        id: '1',
        username: 'newparent',
        email: 'new@example.com',
      });
      expect(bcrypt.hash).toHaveBeenCalledWith('password123', 10);

      bcrypt.hash = originalHash;
    });

    test('should throw error when username already exists', async () => {
      pool.query.mockResolvedValueOnce({ rows: [{ parent_id: 1 }] }); // username exists

      await expect(
        resolvers.Mutation.createParent(null, {
          username: 'existing',
          email: 'new@example.com',
          password: 'password123',
        })
      ).rejects.toThrow('Username already taken');
    });
  });

  describe('loginParent', () => {
    test('should login successfully with correct credentials', async () => {
      const hashedPassword = await bcrypt.hash('password123', 10);
      const mockParent = createMockParent(1, 'testparent', 'test@example.com', hashedPassword);
      pool.query.mockResolvedValueOnce({ rows: [mockParent] });

      const result = await resolvers.Mutation.loginParent(null, {
        username: 'testparent',
        password: 'password123',
      });

      expect(result).toEqual({
        id: '1',
        username: 'testparent',
        email: 'test@example.com',
      });
    });

    test('should throw error when username not found', async () => {
      pool.query.mockResolvedValueOnce({ rows: [] });

      await expect(
        resolvers.Mutation.loginParent(null, {
          username: 'nonexistent',
          password: 'password123',
        })
      ).rejects.toThrow('Parent account not found');
    });

    test('should throw error when password is incorrect', async () => {
      const hashedPassword = await bcrypt.hash('correctpassword', 10);
      const mockParent = createMockParent(1, 'testparent', 'test@example.com', hashedPassword);
      pool.query.mockResolvedValueOnce({ rows: [mockParent] });

      await expect(
        resolvers.Mutation.loginParent(null, {
          username: 'testparent',
          password: 'wrongpassword',
        })
      ).rejects.toThrow('Incorrect password');
    });
  });

  describe('logFeeling', () => {
    test('should log feeling successfully', async () => {
      const mockCharacter = { character_name: 'Henry' };
      const mockLog = createMockLog(1, 1, 1, 'Henry', 5, new Date('2024-01-01'), ['test']);
      
      pool.query
        .mockResolvedValueOnce({ rows: [mockCharacter] }) // character name lookup
        .mockResolvedValueOnce({ rows: [mockLog] }); // insert log

      const result = await resolvers.Mutation.logFeeling(null, {
        childId: '1',
        characterId: '1',
        level: 5,
        investigation: ['test'],
      });

      expect(result).toEqual({
        id: '1',
        childId: '1',
        characterId: '1',
        characterName: 'Henry',
        level: 5,
        timestamp: expect.any(String),
        investigation: ['test'],
      });
    });

    test('should handle null investigation array', async () => {
      const mockCharacter = { character_name: 'Henry' };
      const mockLog = createMockLog(1, 1, 1, 'Henry', 5, new Date('2024-01-01'), null);
      
      pool.query
        .mockResolvedValueOnce({ rows: [mockCharacter] })
        .mockResolvedValueOnce({ rows: [mockLog] });

      const result = await resolvers.Mutation.logFeeling(null, {
        childId: '1',
        characterId: '1',
        level: 5,
        investigation: null,
      });

      expect(result.investigation).toEqual([]);
    });
  });

  describe('linkParentChild', () => {
    test('should link parent to child successfully', async () => {
      pool.query
        .mockResolvedValueOnce({ rows: [{ parent_id: 1 }] }) // parent exists
        .mockResolvedValueOnce({ rows: [{ child_id: 1 }] }) // child exists
        .mockResolvedValueOnce({ rows: [] }) // link doesn't exist
        .mockResolvedValueOnce({ rows: [] }); // insert link

      const result = await resolvers.Mutation.linkParentChild(null, {
        parentId: '1',
        childId: '1',
      });

      expect(result).toBe(true);
    });

    test('should throw error when parent does not exist', async () => {
      pool.query.mockResolvedValueOnce({ rows: [] }); // parent not found

      await expect(
        resolvers.Mutation.linkParentChild(null, {
          parentId: '999',
          childId: '1',
        })
      ).rejects.toThrow('Parent account not found');
    });
  });
});


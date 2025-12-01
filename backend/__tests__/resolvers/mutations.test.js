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

    test('should create child successfully without age', async () => {
      const mockChild = createMockChild(1, 'newchild', null);
      pool.query.mockResolvedValueOnce({ rows: [mockChild] });

      const result = await resolvers.Mutation.createChild(null, {
        username: 'newchild',
        age: null,
      });

      expect(result.age).toBeNull();
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

    test('should re-throw other database errors', async () => {
      const otherError = new Error('Database connection error');
      pool.query.mockRejectedValueOnce(otherError);

      await expect(
        resolvers.Mutation.createChild(null, {
          username: 'newchild',
          age: 8,
        })
      ).rejects.toThrow('Database connection error');
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

    test('should create parent and auto-link to child when childId provided', async () => {
      const mockParent = createMockParent(1, 'newparent', 'new@example.com', 'hashed');
      pool.query
        .mockResolvedValueOnce({ rows: [] }) // username check
        .mockResolvedValueOnce({ rows: [] }) // email check
        .mockResolvedValueOnce({ rows: [mockParent] }) // insert parent
        .mockResolvedValueOnce({ rows: [] }) // link doesn't exist
        .mockResolvedValueOnce({ rows: [] }); // insert link

      const originalHash = bcrypt.hash;
      bcrypt.hash = jest.fn().mockResolvedValue('hashed');

      const result = await resolvers.Mutation.createParent(null, {
        username: 'newparent',
        email: 'new@example.com',
        password: 'password123',
        childId: '1',
      });

      expect(result).toEqual({
        id: '1',
        username: 'newparent',
        email: 'new@example.com',
      });
      // Verify link was attempted
      expect(pool.query).toHaveBeenCalledWith(
        'SELECT parent_id FROM parent_child_link WHERE parent_id = $1 AND child_id = $2',
        [1, 1]
      );

      bcrypt.hash = originalHash;
    });

    test('should not create duplicate link if already exists', async () => {
      const mockParent = createMockParent(1, 'newparent', 'new@example.com', 'hashed');
      pool.query
        .mockResolvedValueOnce({ rows: [] }) // username check
        .mockResolvedValueOnce({ rows: [] }) // email check
        .mockResolvedValueOnce({ rows: [mockParent] }) // insert parent
        .mockResolvedValueOnce({ rows: [{ parent_id: 1 }] }); // link already exists

      const originalHash = bcrypt.hash;
      bcrypt.hash = jest.fn().mockResolvedValue('hashed');

      const result = await resolvers.Mutation.createParent(null, {
        username: 'newparent',
        email: 'new@example.com',
        password: 'password123',
        childId: '1',
      });

      expect(result).toBeDefined();
      // Should not call INSERT for link
      expect(pool.query).not.toHaveBeenCalledWith(
        'INSERT INTO parent_child_link',
        expect.anything()
      );

      bcrypt.hash = originalHash;
    });

    test('should handle invalid childId gracefully', async () => {
      const mockParent = createMockParent(1, 'newparent', 'new@example.com', 'hashed');
      pool.query
        .mockResolvedValueOnce({ rows: [] }) // username check
        .mockResolvedValueOnce({ rows: [] }) // email check
        .mockResolvedValueOnce({ rows: [mockParent] }); // insert parent

      const originalHash = bcrypt.hash;
      bcrypt.hash = jest.fn().mockResolvedValue('hashed');

      const result = await resolvers.Mutation.createParent(null, {
        username: 'newparent',
        email: 'new@example.com',
        password: 'password123',
        childId: 'invalid',
      });

      expect(result).toBeDefined();
      // Should not attempt to link with invalid ID

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

    test('should throw error when email already exists', async () => {
      pool.query
        .mockResolvedValueOnce({ rows: [] }) // username check
        .mockResolvedValueOnce({ rows: [{ parent_id: 1 }] }); // email exists

      await expect(
        resolvers.Mutation.createParent(null, {
          username: 'newuser',
          email: 'existing@example.com',
          password: 'password123',
        })
      ).rejects.toThrow('Email address already registered');
    });

    test('should handle database constraint violation for username', async () => {
      const mockParent = createMockParent(1, 'newparent', 'new@example.com', 'hashed');
      const dbError = new Error('Unique violation');
      dbError.code = '23505';
      dbError.constraint = 'parents_parent_username_key';
      dbError.detail = 'Key (parent_username)=(newparent) already exists.';

      pool.query
        .mockResolvedValueOnce({ rows: [] }) // username check
        .mockResolvedValueOnce({ rows: [] }) // email check
        .mockRejectedValueOnce(dbError); // insert fails

      const originalHash = bcrypt.hash;
      bcrypt.hash = jest.fn().mockResolvedValue('hashed');

      await expect(
        resolvers.Mutation.createParent(null, {
          username: 'newparent',
          email: 'new@example.com',
          password: 'password123',
        })
      ).rejects.toThrow('Username already taken');

      bcrypt.hash = originalHash;
    });

    test('should handle database constraint violation for email', async () => {
      const mockParent = createMockParent(1, 'newparent', 'new@example.com', 'hashed');
      const dbError = new Error('Unique violation');
      dbError.code = '23505';
      dbError.constraint = 'parents_parent_email_key';
      dbError.detail = 'Key (parent_email)=(new@example.com) already exists.';

      pool.query
        .mockResolvedValueOnce({ rows: [] }) // username check
        .mockResolvedValueOnce({ rows: [] }) // email check
        .mockRejectedValueOnce(dbError); // insert fails

      const originalHash = bcrypt.hash;
      bcrypt.hash = jest.fn().mockResolvedValue('hashed');

      await expect(
        resolvers.Mutation.createParent(null, {
          username: 'newparent',
          email: 'new@example.com',
          password: 'password123',
        })
      ).rejects.toThrow('Email address already registered');

      bcrypt.hash = originalHash;
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

    test('should not create duplicate link if already exists', async () => {
      pool.query
        .mockResolvedValueOnce({ rows: [{ parent_id: 1 }] }) // parent exists
        .mockResolvedValueOnce({ rows: [{ child_id: 1 }] }) // child exists
        .mockResolvedValueOnce({ rows: [{ parent_id: 1 }] }); // link already exists

      const result = await resolvers.Mutation.linkParentChild(null, {
        parentId: '1',
        childId: '1',
      });

      expect(result).toBe(true);
      // Should not call INSERT
      expect(pool.query).not.toHaveBeenCalledWith(
        'INSERT INTO parent_child_link',
        expect.anything()
      );
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

    test('should throw error when child does not exist', async () => {
      pool.query
        .mockResolvedValueOnce({ rows: [{ parent_id: 1 }] }) // parent exists
        .mockResolvedValueOnce({ rows: [] }); // child not found

      await expect(
        resolvers.Mutation.linkParentChild(null, {
          parentId: '1',
          childId: '999',
        })
      ).rejects.toThrow('Child account not found');
    });

    test('should throw error for invalid parent ID', async () => {
      await expect(
        resolvers.Mutation.linkParentChild(null, {
          parentId: 'invalid',
          childId: '1',
        })
      ).rejects.toThrow('Invalid parent or child ID');
    });

    test('should throw error for invalid child ID', async () => {
      await expect(
        resolvers.Mutation.linkParentChild(null, {
          parentId: '1',
          childId: 'invalid',
        })
      ).rejects.toThrow('Invalid parent or child ID');
    });
  });

  describe('requestPasswordReset', () => {
    test('should generate reset code and send email successfully', async () => {
      const mockParent = createMockParent(1, 'testparent', 'test@example.com', 'hashed');
      pool.query
        .mockResolvedValueOnce({ rows: [mockParent] }) // find parent by email
        .mockResolvedValueOnce({ rows: [] }); // update reset token

      sendPasswordResetEmail.mockResolvedValueOnce(true);

      const result = await resolvers.Mutation.requestPasswordReset(null, {
        email: 'test@example.com',
      });

      expect(result).toBe(true);
      expect(sendPasswordResetEmail).toHaveBeenCalledWith(
        'test@example.com',
        expect.stringMatching(/^\d{6}$/)
      );
    });

    test('should throw error when email not found', async () => {
      pool.query.mockResolvedValueOnce({ rows: [] }); // email not found

      await expect(
        resolvers.Mutation.requestPasswordReset(null, {
          email: 'nonexistent@example.com',
        })
      ).rejects.toThrow('No account found with this email address');
    });

    test('should throw error when parent not linked to child', async () => {
      const mockParent = createMockParent(1, 'testparent', 'test@example.com', 'hashed');
      pool.query
        .mockResolvedValueOnce({ rows: [mockParent] }) // find parent by email
        .mockResolvedValueOnce({ rows: [] }); // link check fails

      await expect(
        resolvers.Mutation.requestPasswordReset(null, {
          email: 'test@example.com',
          childId: '1',
        })
      ).rejects.toThrow('This parent is not linked to the current child');
    });

    test('should throw error when email sending fails', async () => {
      const mockParent = createMockParent(1, 'testparent', 'test@example.com', 'hashed');
      pool.query
        .mockResolvedValueOnce({ rows: [mockParent] }) // find parent by email
        .mockResolvedValueOnce({ rows: [] }); // update reset token

      sendPasswordResetEmail.mockRejectedValueOnce(new Error('Email service unavailable'));

      await expect(
        resolvers.Mutation.requestPasswordReset(null, {
          email: 'test@example.com',
        })
      ).rejects.toThrow('Failed to send reset code email');
    });
  });

  describe('resetPassword', () => {
    test('should reset password successfully with valid token', async () => {
      const expiryTime = new Date(Date.now() + 15 * 60 * 1000); // 15 minutes from now
      const mockParent = {
        parent_id: 1,
        parent_email: 'test@example.com',
        reset_token_expiry: expiryTime,
      };
      pool.query
        .mockResolvedValueOnce({ rows: [mockParent] }) // find by token
        .mockResolvedValueOnce({ rows: [] }); // update password

      const originalHash = bcrypt.hash;
      bcrypt.hash = jest.fn().mockResolvedValue('newhashed');

      const result = await resolvers.Mutation.resetPassword(null, {
        token: '123456',
        newPassword: 'newpassword123',
      });

      expect(result).toBe(true);
      expect(bcrypt.hash).toHaveBeenCalledWith('newpassword123', 10);
      expect(pool.query).toHaveBeenCalledWith(
        expect.stringContaining('UPDATE parents SET hashed_password'),
        expect.arrayContaining(['newhashed', 1])
      );

      bcrypt.hash = originalHash;
    });

    test('should throw error when token not found', async () => {
      pool.query.mockResolvedValueOnce({ rows: [] }); // token not found

      await expect(
        resolvers.Mutation.resetPassword(null, {
          token: 'invalid',
          newPassword: 'newpassword123',
        })
      ).rejects.toThrow('Invalid or expired reset token');
    });

    test('should throw error when token expired', async () => {
      const expiredTime = new Date(Date.now() - 1000); // 1 second ago
      const mockParent = {
        parent_id: 1,
        parent_email: 'test@example.com',
        reset_token_expiry: expiredTime,
      };
      pool.query.mockResolvedValueOnce({ rows: [mockParent] }); // find by token

      await expect(
        resolvers.Mutation.resetPassword(null, {
          token: '123456',
          newPassword: 'newpassword123',
        })
      ).rejects.toThrow('Reset token has expired');
    });
  });
});


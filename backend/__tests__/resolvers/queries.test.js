const { describe, test, expect, beforeEach } = require('@jest/globals');
const { createMockChild, createMockParent, createMockLog, createMockCharacter } = require('../helpers');

// Mock the db module before importing resolvers
jest.mock('../../db', () => require('../__mocks__/db'));

// Get the mocked pool after mocking
const { pool } = require('../../db');

// Import resolvers after mocking
const { resolvers } = require('../../index');

describe('Query Resolvers', () => {
  beforeEach(() => {
    jest.clearAllMocks();
  });

  describe('childProfile', () => {
    test('should return child profile when child exists', async () => {
      const mockChild = createMockChild(1, 'testchild', 8);
      pool.query.mockResolvedValueOnce({ rows: [mockChild] });

      const result = await resolvers.Query.childProfile(null, { id: '1' });

      expect(result).toEqual({
        id: '1',
        username: 'testchild',
        age: 8,
      });
      expect(pool.query).toHaveBeenCalledWith(
        'SELECT child_id, child_username, child_age FROM children WHERE child_id = $1',
        ['1']
      );
    });

    test('should return null when child does not exist', async () => {
      pool.query.mockResolvedValueOnce({ rows: [] });

      const result = await resolvers.Query.childProfile(null, { id: '999' });

      expect(result).toBeNull();
    });
  });

  describe('childByUsername', () => {
    test('should return child when username exists', async () => {
      const mockChild = createMockChild(1, 'testchild', 8);
      pool.query.mockResolvedValueOnce({ rows: [mockChild] });

      const result = await resolvers.Query.childByUsername(null, { username: 'testchild' });

      expect(result).toEqual({
        id: '1',
        username: 'testchild',
        age: 8,
      });
    });

    test('should return null when username does not exist', async () => {
      pool.query.mockResolvedValueOnce({ rows: [] });

      const result = await resolvers.Query.childByUsername(null, { username: 'nonexistent' });

      expect(result).toBeNull();
    });
  });

  describe('parentProfile', () => {
    test('should return parent profile when parent exists', async () => {
      const mockParent = createMockParent(1, 'testparent', 'test@example.com', 'hashed');
      pool.query.mockResolvedValueOnce({ rows: [mockParent] });

      const result = await resolvers.Query.parentProfile(null, { id: '1' });

      expect(result).toEqual({
        id: '1',
        username: 'testparent',
        email: 'test@example.com',
      });
    });

    test('should return null when parent does not exist', async () => {
      pool.query.mockResolvedValueOnce({ rows: [] });

      const result = await resolvers.Query.parentProfile(null, { id: '999' });

      expect(result).toBeNull();
    });
  });

  describe('parentChildren', () => {
    test('should return linked children for valid parent ID', async () => {
      const mockChildren = [
        createMockChild(1, 'child1', 8),
        createMockChild(2, 'child2', 9),
      ];
      pool.query.mockResolvedValueOnce({ rows: mockChildren });

      const result = await resolvers.Query.parentChildren(null, { parentId: '1' });

      expect(result).toHaveLength(2);
      expect(result[0]).toEqual({
        id: '1',
        username: 'child1',
        age: 8,
      });
    });

    test('should return empty array for invalid parent ID', async () => {
      const result = await resolvers.Query.parentChildren(null, { parentId: 'invalid' });

      expect(result).toEqual([]);
      expect(pool.query).not.toHaveBeenCalled();
    });
  });

  describe('childLogs', () => {
    test('should return logs without time filter', async () => {
      const mockLog = createMockLog(1, 1, 1, 'Henry', 5, new Date('2024-01-01'), ['test']);
      pool.query.mockResolvedValueOnce({ rows: [mockLog] });

      const result = await resolvers.Query.childLogs(null, { childId: '1' });

      expect(result).toHaveLength(1);
      expect(result[0].id).toBe('1');
      expect(result[0].investigation).toEqual(['test']);
    });

    test('should return logs with time filter', async () => {
      const mockLog = createMockLog(1, 1, 1, 'Henry', 5, new Date('2024-01-01'), null);
      pool.query.mockResolvedValueOnce({ rows: [mockLog] });

      const result = await resolvers.Query.childLogs(null, {
        childId: '1',
        startTime: '2024-01-01',
        endTime: '2024-01-02',
      });

      expect(result[0].investigation).toEqual([]);
      expect(pool.query).toHaveBeenCalledWith(
        expect.stringContaining('BETWEEN'),
        ['1', '2024-01-01', '2024-01-02']
      );
    });

    test('should return empty array when no logs exist', async () => {
      pool.query.mockResolvedValueOnce({ rows: [] });

      const result = await resolvers.Query.childLogs(null, { childId: '1' });

      expect(result).toEqual([]);
    });
  });

  describe('characterLibrary', () => {
    test('should return all characters with base64 encoded photo and audio', async () => {
      const photoBuffer = Buffer.from('photo-data');
      const audioBuffer = Buffer.from('audio-data');
      const mockCharacter = createMockCharacter(1, 'Henry', photoBuffer, 'Description', audioBuffer);
      pool.query.mockResolvedValueOnce({ rows: [mockCharacter] });

      const result = await resolvers.Query.characterLibrary(null, {});

      expect(result).toHaveLength(1);
      expect(result[0]).toEqual({
        id: '1',
        name: 'Henry',
        photo: photoBuffer.toString('base64'),
        description: 'Description',
        audio: audioBuffer.toString('base64'),
      });
    });

    test('should return null for photo and audio when not present', async () => {
      const mockCharacter = createMockCharacter(1, 'Henry', null, 'Description', null);
      pool.query.mockResolvedValueOnce({ rows: [mockCharacter] });

      const result = await resolvers.Query.characterLibrary(null, {});

      expect(result[0].photo).toBeNull();
      expect(result[0].audio).toBeNull();
    });

    test('should return empty array when no characters exist', async () => {
      pool.query.mockResolvedValueOnce({ rows: [] });

      const result = await resolvers.Query.characterLibrary(null, {});

      expect(result).toEqual([]);
    });
  });

  describe('isParentLinkedToChild', () => {
    test('should return true when link exists', async () => {
      pool.query.mockResolvedValueOnce({ rows: [{ parent_id: 1 }] });

      const result = await resolvers.Query.isParentLinkedToChild(null, {
        parentId: '1',
        childId: '2',
      });

      expect(result).toBe(true);
      expect(pool.query).toHaveBeenCalledWith(
        'SELECT parent_id FROM parent_child_link WHERE parent_id = $1 AND child_id = $2',
        [1, 2]
      );
    });

    test('should return false when link does not exist', async () => {
      pool.query.mockResolvedValueOnce({ rows: [] });

      const result = await resolvers.Query.isParentLinkedToChild(null, {
        parentId: '1',
        childId: '2',
      });

      expect(result).toBe(false);
    });

    test('should return false for invalid parent ID', async () => {
      const result = await resolvers.Query.isParentLinkedToChild(null, {
        parentId: 'invalid',
        childId: '2',
      });

      expect(result).toBe(false);
      expect(pool.query).not.toHaveBeenCalled();
    });

    test('should return false for invalid child ID', async () => {
      const result = await resolvers.Query.isParentLinkedToChild(null, {
        parentId: '1',
        childId: 'invalid',
      });

      expect(result).toBe(false);
      expect(pool.query).not.toHaveBeenCalled();
    });
  });
});


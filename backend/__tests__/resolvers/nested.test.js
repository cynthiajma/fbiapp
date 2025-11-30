const { describe, test, expect, beforeEach } = require('@jest/globals');
const { pool } = require('../../db');
const { createMockChild, createMockParent } = require('../helpers');

// Mock the db module
jest.mock('../../db', () => require('../__mocks__/db'));

// Import resolvers after mocking
const { resolvers } = require('../../index');

describe('Nested Resolvers', () => {
  beforeEach(() => {
    jest.clearAllMocks();
  });

  describe('Parent.children', () => {
    test('should return linked children for parent', async () => {
      const mockChildren = [
        createMockChild(1, 'child1', 8),
        createMockChild(2, 'child2', 9),
      ];
      pool.query.mockResolvedValueOnce({ rows: mockChildren });

      const parent = { id: '1' };
      const result = await resolvers.Parent.children(parent);

      expect(result).toHaveLength(2);
      expect(result[0]).toEqual({
        id: '1',
        username: 'child1',
        age: 8,
      });
      expect(result[1]).toEqual({
        id: '2',
        username: 'child2',
        age: 9,
      });
    });

    test('should return empty array when parent has no children', async () => {
      pool.query.mockResolvedValueOnce({ rows: [] });

      const parent = { id: '1' };
      const result = await resolvers.Parent.children(parent);

      expect(result).toEqual([]);
    });
  });

  describe('Child.parents', () => {
    test('should return linked parents for child', async () => {
      const mockParents = [
        createMockParent(1, 'parent1', 'parent1@example.com', 'hashed'),
        createMockParent(2, 'parent2', 'parent2@example.com', 'hashed'),
      ];
      pool.query.mockResolvedValueOnce({ rows: mockParents });

      const child = { id: '1' };
      const result = await resolvers.Child.parents(child);

      expect(result).toHaveLength(2);
      expect(result[0]).toEqual({
        id: '1',
        username: 'parent1',
      });
      expect(result[1]).toEqual({
        id: '2',
        username: 'parent2',
      });
    });

    test('should return empty array when child has no parents', async () => {
      pool.query.mockResolvedValueOnce({ rows: [] });

      const child = { id: '1' };
      const result = await resolvers.Child.parents(child);

      expect(result).toEqual([]);
    });
  });

  describe('Parent.email', () => {
    test('should return parent email', () => {
      const parent = { email: 'test@example.com' };
      const result = resolvers.Parent.email(parent);

      expect(result).toBe('test@example.com');
    });
  });
});


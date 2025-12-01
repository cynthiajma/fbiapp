const { describe, test, expect, beforeEach, afterEach } = require('@jest/globals');

// Mock pg module before any imports
jest.mock('pg', () => {
  const mockPoolInstance = {
    on: jest.fn(),
    query: jest.fn(),
    end: jest.fn(),
  };
  
  return {
    Pool: jest.fn(() => mockPoolInstance),
  };
});

// Mock dotenv
jest.mock('dotenv', () => ({
  config: jest.fn(),
}));

const { Pool } = require('pg');

describe('db.js', () => {
  let originalEnv;
  let mockPoolInstance;

  beforeEach(() => {
    // Save original environment
    originalEnv = { ...process.env };
    
    // Create mock pool instance
    mockPoolInstance = {
      on: jest.fn(),
      query: jest.fn(),
      end: jest.fn(),
    };
    
    Pool.mockImplementation(() => mockPoolInstance);
    Pool.mockClear();
    
    // Clear module cache to re-import with new env
    delete require.cache[require.resolve('../db')];
    jest.resetModules();
  });

  afterEach(() => {
    // Restore original environment
    process.env = originalEnv;
    delete require.cache[require.resolve('../db')];
    jest.resetModules();
  });

  test('should export pool instance', () => {
    const db = require('../db');
    
    expect(db).toHaveProperty('pool');
    expect(db.pool).toBeDefined();
    expect(typeof db.pool.on).toBe('function');
  });
});


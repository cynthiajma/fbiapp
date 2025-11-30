// Mock database pool for testing
const mockPool = {
  query: jest.fn(),
};

module.exports = {
  pool: mockPool,
};


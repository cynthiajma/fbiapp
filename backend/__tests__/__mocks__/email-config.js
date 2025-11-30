// Mock email service for testing
const sendPasswordResetEmail = jest.fn().mockResolvedValue(true);

module.exports = {
  sendPasswordResetEmail,
};


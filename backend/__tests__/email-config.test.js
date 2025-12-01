const { describe, test, expect, beforeEach, afterEach } = require('@jest/globals');
const sgMail = require('@sendgrid/mail');

// Mock @sendgrid/mail
jest.mock('@sendgrid/mail', () => ({
  setApiKey: jest.fn(),
  send: jest.fn(),
}));

describe('email-config.js', () => {
  let originalEnv;
  let originalConsoleLog;
  let originalConsoleError;

  beforeEach(() => {
    // Save original environment and console methods
    originalEnv = { ...process.env };
    originalConsoleLog = console.log;
    originalConsoleError = console.error;
    
    // Mock console methods
    console.log = jest.fn();
    console.error = jest.fn();
    
    // Clear mocks
    jest.clearAllMocks();
    jest.resetModules();
  });

  afterEach(() => {
    // Restore original environment and console
    process.env = originalEnv;
    console.log = originalConsoleLog;
    console.error = originalConsoleError;
    jest.resetModules();
  });

  describe('sendPasswordResetEmail - Development Mode', () => {
    test('should log email to console in development mode', async () => {
      process.env.NODE_ENV = 'development';
      delete process.env.SENDGRID_API_KEY;
      
      const { sendPasswordResetEmail } = require('../email-config');
      
      const result = await sendPasswordResetEmail('test@example.com', '123456');
      
      expect(result).toBe(true);
      expect(console.log).toHaveBeenCalledWith('\n========== PASSWORD RESET EMAIL ==========');
      expect(console.log).toHaveBeenCalledWith('To:', 'test@example.com');
      expect(console.log).toHaveBeenCalledWith('Reset Code:', '123456');
      expect(sgMail.send).not.toHaveBeenCalled();
    });

    test('should log email to console when SENDGRID_API_KEY is missing', async () => {
      delete process.env.NODE_ENV;
      delete process.env.SENDGRID_API_KEY;
      
      const { sendPasswordResetEmail } = require('../email-config');
      
      const result = await sendPasswordResetEmail('test@example.com', '789012');
      
      expect(result).toBe(true);
      expect(console.log).toHaveBeenCalled();
      expect(sgMail.send).not.toHaveBeenCalled();
    });
  });

  describe('SendGrid initialization', () => {
    test('should not initialize SendGrid when API key is missing', () => {
      delete process.env.SENDGRID_API_KEY;
      sgMail.setApiKey.mockClear();
      
      delete require.cache[require.resolve('../email-config')];
      require('../email-config');
      
      // setApiKey should not be called if API key is missing
      expect(sgMail.setApiKey).not.toHaveBeenCalled();
      
      // Verify the module loads and function is available
      const { sendPasswordResetEmail } = require('../email-config');
      expect(sendPasswordResetEmail).toBeDefined();
    });
  });
});


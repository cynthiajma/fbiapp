const nodemailer = require('nodemailer');

const createTransporter = () => {
  // For development: log emails to console instead of sending
  if (process.env.NODE_ENV === 'development' || !process.env.EMAIL_HOST) {
    console.log('Email service running in DEVELOPMENT mode - emails will be logged to console');
    return nodemailer.createTransport({
      streamTransport: true,
      newline: 'unix',
      buffer: true,
    });
  }

  // For production: use actual SMTP server (SendGrid, Gmail, etc.)
  return nodemailer.createTransport({
    host: process.env.EMAIL_HOST,
    port: parseInt(process.env.EMAIL_PORT || '587'),
    secure: process.env.EMAIL_PORT === '465', // true for 465, false for other ports
    auth: {
      user: process.env.EMAIL_USER,
      pass: process.env.EMAIL_PASSWORD,
    },
    connectionTimeout: 10000, // 10 seconds
    greetingTimeout: 10000, // 10 seconds
    socketTimeout: 10000, // 10 seconds
  });
};

const transporter = createTransporter();

/**
 * Send password reset email
 * @param {string} email - Recipient email address
 * @param {string} resetCode - Password reset code (6 digits)
 * @returns {Promise<boolean>} - Success status
 */
const sendPasswordResetEmail = async (email, resetCode) => {
  try {
    const mailOptions = {
      from: process.env.EMAIL_FROM || 'noreply@fbiapp.com',
      to: email,
      subject: 'Password Reset Code - FBI App',
      html: `
        <!DOCTYPE html>
        <html>
        <head>
          <style>
            body { font-family: Arial, sans-serif; line-height: 1.6; color: #333; }
            .container { max-width: 600px; margin: 0 auto; padding: 20px; }
            .header { background-color: #4a90e2; color: white; padding: 20px; text-align: center; border-radius: 5px 5px 0 0; }
            .content { background-color: #f9f9f9; padding: 30px; border: 1px solid #ddd; border-radius: 0 0 5px 5px; text-align: center; }
            .code { font-size: 48px; font-weight: bold; letter-spacing: 8px; color: #4a90e2; background-color: #fff; padding: 20px; margin: 20px 0; border: 2px dashed #4a90e2; border-radius: 8px; }
            .footer { text-align: center; padding: 20px; color: #666; font-size: 12px; }
          </style>
        </head>
        <body>
          <div class="container">
            <div class="header">
              <h1>Password Reset Code</h1>
            </div>
            <div class="content">
              <p>Hello,</p>
              <p>We received a request to reset your password for your FBI App parent account.</p>
              <p><strong>Your password reset code is:</strong></p>
              <div class="code">${resetCode}</div>
              <p>Enter this code in the app to reset your password.</p>
              <p><strong>This code will expire in 15 minutes.</strong></p>
              <p>If you didn't request a password reset, you can safely ignore this email.</p>
            </div>
            <div class="footer">
              <p>This is an automated message from FBI App. Please do not reply to this email.</p>
            </div>
          </div>
        </body>
        </html>
      `,
      text: `
Password Reset Code

Hello,

We received a request to reset your password for your FBI App parent account.

Your password reset code is: ${resetCode}

Enter this code in the app to reset your password.

This code will expire in 15 minutes.

If you didn't request a password reset, you can safely ignore this email.

---
This is an automated message from FBI App. Please do not reply to this email.
      `,
    };

    // Add timeout wrapper (15 seconds max)
    const emailPromise = transporter.sendMail(mailOptions);
    const timeoutPromise = new Promise((_, reject) => 
      setTimeout(() => reject(new Error('Email sending timeout after 15 seconds')), 15000)
    );
    
    const info = await Promise.race([emailPromise, timeoutPromise]);

    // In development mode, log the email content
    if (process.env.NODE_ENV === 'development' || !process.env.EMAIL_HOST) {
      console.log('\n========== PASSWORD RESET EMAIL ==========');
      console.log('To:', email);
      console.log('Reset Code:', resetCode);
      console.log('=========================================\n');
    } else {
      console.log('Password reset email sent successfully:', info.messageId);
    }

    return true;
  } catch (error) {
    console.error('Error sending password reset email:', error);
    console.error('Error details:', {
      message: error.message,
      code: error.code,
      command: error.command,
    });
    throw new Error(`Failed to send email: ${error.message}`);
  }
};

module.exports = {
  sendPasswordResetEmail,
};


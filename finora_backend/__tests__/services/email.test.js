'use strict';

// Mock nodemailer before requiring the email service
const mockSendMail = jest.fn();
const mockVerify = jest.fn();

jest.mock('nodemailer', () => ({
  createTransport: jest.fn(() => ({
    sendMail: mockSendMail,
    verify: mockVerify,
  })),
}));

// Also mock db to avoid real DB calls from user.js (which does ALTER TABLE at module load)
jest.mock('../../services/db', () => require('../helpers/mockDb'));

describe('Email Service', () => {
  let emailService;

  beforeAll(() => {
    emailService = require('../../services/email');
  });

  beforeEach(() => {
    jest.clearAllMocks();
  });

  // ── verifyConnection ──────────────────────────────────────────────────────
  describe('verifyConnection', () => {
    it('returns true when SMTP is connected', async () => {
      mockVerify.mockResolvedValueOnce(true);

      const result = await emailService.verifyConnection();

      expect(result).toBe(true);
      expect(mockVerify).toHaveBeenCalledTimes(1);
    });

    it('returns false when SMTP connection fails', async () => {
      mockVerify.mockRejectedValueOnce(new Error('SMTP connection refused'));

      const result = await emailService.verifyConnection();

      expect(result).toBe(false);
    });
  });

  // ── sendVerificationEmail ─────────────────────────────────────────────────
  describe('sendVerificationEmail', () => {
    it('calls transporter with correct recipient and template', async () => {
      const messageId = 'test-message-id-123';
      mockSendMail.mockResolvedValueOnce({ messageId });

      const result = await emailService.sendVerificationEmail(
        'user@example.com',
        'Test User',
        'verify-token-abc'
      );

      expect(result.success).toBe(true);
      expect(result.messageId).toBe(messageId);
      expect(mockSendMail).toHaveBeenCalledTimes(1);

      const mailOptions = mockSendMail.mock.calls[0][0];
      expect(mailOptions.to).toBe('user@example.com');
      expect(mailOptions.subject).toMatch(/verifi/i);
      expect(mailOptions.html).toContain('Test User');
      expect(mailOptions.html).toContain('verify-token-abc');
    });

    it('handles SMTP errors gracefully and returns error result', async () => {
      mockSendMail.mockRejectedValueOnce(new Error('SMTP authentication failed'));

      const result = await emailService.sendVerificationEmail(
        'user@example.com',
        'Test User',
        'verify-token-abc'
      );

      expect(result.success).toBe(false);
      expect(result.error).toMatch(/SMTP authentication failed/);
    });
  });

  // ── sendPasswordResetEmail ────────────────────────────────────────────────
  describe('sendPasswordResetEmail', () => {
    it('calls transporter with correct template for password reset', async () => {
      mockSendMail.mockResolvedValueOnce({ messageId: 'reset-msg-id' });

      const result = await emailService.sendPasswordResetEmail(
        'user@example.com',
        'Test User',
        'reset-token-xyz'
      );

      expect(result.success).toBe(true);
      expect(mockSendMail).toHaveBeenCalledTimes(1);

      const mailOptions = mockSendMail.mock.calls[0][0];
      expect(mailOptions.to).toBe('user@example.com');
      expect(mailOptions.subject).toMatch(/contrase/i);
      expect(mailOptions.html).toContain('Test User');
      expect(mailOptions.html).toContain('reset-token-xyz');
    });

    it('handles SMTP errors gracefully', async () => {
      mockSendMail.mockRejectedValueOnce(new Error('Connection timeout'));

      const result = await emailService.sendPasswordResetEmail(
        'user@example.com',
        'Test User',
        'reset-token-xyz'
      );

      expect(result.success).toBe(false);
      expect(result.error).toBeTruthy();
    });
  });

  // ── sendWelcomeEmail ──────────────────────────────────────────────────────
  describe('sendWelcomeEmail', () => {
    it('sends welcome email successfully', async () => {
      mockSendMail.mockResolvedValueOnce({ messageId: 'welcome-msg-id' });

      const result = await emailService.sendWelcomeEmail('user@example.com', 'Test User');

      expect(result.success).toBe(true);
      expect(mockSendMail).toHaveBeenCalledTimes(1);

      const mailOptions = mockSendMail.mock.calls[0][0];
      expect(mailOptions.to).toBe('user@example.com');
      expect(mailOptions.html).toContain('Test User');
    });

    it('handles SMTP errors gracefully', async () => {
      mockSendMail.mockRejectedValueOnce(new Error('Rate limit exceeded'));

      const result = await emailService.sendWelcomeEmail('user@example.com', 'Test User');

      expect(result.success).toBe(false);
    });
  });

  // ── MailHog transporter branch ────────────────────────────────────────────
  describe('createTransporter — MailHog branch', () => {
    it('creates MailHog transporter when SMTP_HOST is mailhog', () => {
      jest.resetModules();
      const originalHost = process.env.SMTP_HOST;
      process.env.SMTP_HOST = 'mailhog';

      // Re-require AFTER resetModules so we get the fresh mock instance
      require('../../services/email');
      const freshNodemailer = require('nodemailer');

      expect(freshNodemailer.createTransport).toHaveBeenCalledWith(
        expect.objectContaining({ host: 'mailhog', secure: false })
      );

      process.env.SMTP_HOST = originalHost;
      jest.resetModules();
    });

    it('creates MailHog transporter when SMTP_HOST is localhost', () => {
      jest.resetModules();
      const originalHost = process.env.SMTP_HOST;
      process.env.SMTP_HOST = 'localhost';

      require('../../services/email');
      const freshNodemailer = require('nodemailer');

      expect(freshNodemailer.createTransport).toHaveBeenCalledWith(
        expect.objectContaining({ host: 'localhost', secure: false })
      );

      process.env.SMTP_HOST = originalHost;
      jest.resetModules();
    });
  });
});

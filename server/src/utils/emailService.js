
const nodemailer = require("nodemailer");
const { Resend } = require("resend");

// In-memory mock storage used exclusively by automated tests.
let mockSentEmails = [];

function resetMockEmails() {
  mockSentEmails = [];
}

function getMockEmails() {
  return [...mockSentEmails];
}

/**
 * Check SMTP configuration.
 * Retained for compatibility with existing diagnostics.
 * Production OTP emails are sent through Resend.
 */
function getSmtpStatus() {
  const host = process.env.SMTP_HOST?.trim();
  const port = process.env.SMTP_PORT?.trim() || "587";
  const user = process.env.SMTP_USER?.trim();
  const pass = process.env.SMTP_PASS?.trim();
  const from = process.env.EMAIL_FROM?.trim();

  const missing = [];
  if (!host) missing.push("SMTP_HOST");
  if (!user) missing.push("SMTP_USER");
  if (!pass) missing.push("SMTP_PASS");

  return {
    isConfigured: missing.length === 0,
    missing,
    host: host || null,
    port: parseInt(port, 10),
    hasUser: Boolean(user),
    hasPass: Boolean(pass),
    hasFrom: Boolean(from),
  };
}

/**
 * Retain the existing SMTP transporter for compatibility
 * with existing diagnostics and automated tests.
 */
function getTransporter() {
  if (process.env.NODE_ENV === "test") {
    return {
      sendMail: async (mailOptions) => {
        mockSentEmails.push({
          to: mailOptions.to,
          subject: mailOptions.subject,
          text: mailOptions.text,
          html: mailOptions.html,
          timestamp: new Date(),
        });

        return {
          messageId: `mock-${Date.now()}`,
          accepted: [mailOptions.to],
          rejected: [],
        };
      },
      verify: async () => true,
    };
  }

  const status = getSmtpStatus();

  if (!status.isConfigured) {
    const error = new Error(
      `SMTP email service is not configured. Missing variables: ${status.missing.join(", ")}`
    );
    error.code = "SMTP_NOT_CONFIGURED";
    error.missing = status.missing;
    throw error;
  }

  const transportOptions = {
    host: status.host,
    port: status.port,
    secure: status.port === 465,
    auth: {
      user: process.env.SMTP_USER.trim(),
      pass: process.env.SMTP_PASS.trim(),
    },
    connectionTimeout: 10000,
    greetingTimeout: 10000,
    socketTimeout: 15000,
  };

  if (status.port === 587) {
    transportOptions.requireTLS = true;
  }

  return nodemailer.createTransport(transportOptions);
}

/**
 * Verify the SMTP connection.
 * This is a diagnostic helper; OTP sending uses Resend.
 */
async function verifySmtpConnection() {
  const status = getSmtpStatus();

  if (!status.isConfigured) {
    return {
      success: false,
      code: "SMTP_NOT_CONFIGURED",
      message: `SMTP configuration incomplete. Missing: ${status.missing.join(", ")}`,
      missing: status.missing,
    };
  }

  try {
    const transporter = getTransporter();
    await transporter.verify();

    return {
      success: true,
      message: `Successfully connected to SMTP server (${status.host}:${status.port}).`,
    };
  } catch (err) {
    let message = err.message || "Failed to connect to SMTP server";

    if (err.code === "EAUTH") {
      message =
        "SMTP authentication failed. Check your SMTP credentials.";
    } else if (
      err.code === "ESOCKET" ||
      err.code === "ETIMEDOUT" ||
      err.code === "ECONNECTION"
    ) {
      message = `Connection timed out connecting to ${status.host}:${status.port}.`;
    }

    return {
      success: false,
      code: err.code || "SMTP_CONNECTION_ERROR",
      message,
    };
  }
}

/**
 * Generate the existing verification email template.
 */
function buildOtpEmailTemplate(otp) {
  const html = `
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>Your Verification Code - DevOps Learning Platform</title>
</head>
<body style="margin: 0; padding: 0; font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Helvetica, Arial, sans-serif; background-color: #090d16; color: #f8fafc;">
  <table role="presentation" width="100%" cellspacing="0" cellpadding="0" style="background-color: #090d16; padding: 40px 20px;">
    <tr>
      <td align="center">
        <table role="presentation" width="100%" style="max-width: 520px; background-color: #0f172a; border: 1px solid #1e293b; border-radius: 16px; overflow: hidden; box-shadow: 0 10px 30px rgba(0,0,0,0.6);">
          <tr>
            <td style="background: linear-gradient(135deg, #82535D 0%, #60343D 100%); padding: 32px 30px; text-align: center;">
              <h1 style="margin: 0; color: #ffffff; font-size: 24px; font-weight: 700; letter-spacing: -0.5px;">DevOps Learning Platform</h1>
              <p style="margin: 8px 0 0 0; color: #e7d4d7; font-size: 14px;">Master CI/CD, Kubernetes, and Cloud Architecture</p>
            </td>
          </tr>
          <tr>
            <td style="padding: 36px 32px;">
              <h2 style="margin: 0 0 16px 0; color: #f8fafc; font-size: 20px; font-weight: 600;">Confirm your email address</h2>
              <p style="margin: 0 0 24px 0; color: #94a3b8; font-size: 15px; line-height: 1.6;">
                Thank you for creating an account. Please use the following 6-digit confirmation code to complete your registration:
              </p>
              <div style="background-color: #1e293b; border: 1.5px solid #60343d; border-radius: 12px; padding: 24px; text-align: center; margin-bottom: 24px;">
                <div style="font-family: 'Courier New', Courier, monospace; font-size: 38px; font-weight: 700; letter-spacing: 12px; color: #e7d4d7; text-shadow: 0 0 14px rgba(184, 138, 145, 0.4);">
                  ${otp}
                </div>
                <div style="margin-top: 10px; color: #94a3b8; font-size: 13px;">
                  This code expires in <strong style="color: #f8fafc;">10 minutes</strong>
                </div>
              </div>
              <div style="border-left: 3px solid #82535d; padding-left: 14px; margin-bottom: 24px;">
                <p style="margin: 0; color: #94a3b8; font-size: 13px; line-height: 1.5;">
                  <strong style="color: #b88a91;">Security Notice:</strong> Never share this verification code with anyone. Platform support will never request your code. If you did not request this registration, please disregard this email.
                </p>
              </div>
              <p style="margin: 0; color: #64748b; font-size: 12px; line-height: 1.5; border-top: 1px solid #1e293b; padding-top: 20px;">
                Automated security notification from DevOps Learning Platform.
              </p>
            </td>
          </tr>
        </table>
      </td>
    </tr>
  </table>
</body>
</html>
  `.trim();

  const text = `
DevOps Learning Platform - Email Verification

Your 6-digit verification code is: ${otp}

This code will expire in 10 minutes.

Security Notice: Never share this code with anyone. Platform administrators will never ask for your verification code.

If you did not attempt to register on the DevOps Learning Platform, please disregard this email.
  `.trim();

  return { html, text };
}

/**
 * Send OTP email through Resend in production.
 */
async function sendOtpEmail(recipientEmail, otp) {
  const { html, text } = buildOtpEmailTemplate(otp);

  // Preserve the existing mock behavior in automated tests.
  if (process.env.NODE_ENV === "test") {
    const transporter = getTransporter();

    return transporter.sendMail({
      from: process.env.EMAIL_FROM || "DevOps Learning Platform",
      to: recipientEmail,
      subject: "Your Verification Code - DevOps Learning Platform",
      text,
      html,
    });
  }

  const apiKey = process.env.RESEND_API_KEY?.trim();

  if (!apiKey) {
    const error = new Error("RESEND_API_KEY is not configured");
    error.code = "RESEND_NOT_CONFIGURED";
    throw error;
  }

  const from =
    process.env.RESEND_FROM_EMAIL?.trim() ||
    process.env.EMAIL_FROM?.trim() ||
    "DevOps Learning Platform <onboarding@resend.dev>";

  const resend = new Resend(apiKey);

  const { data, error } = await resend.emails.send({
    from,
    to: [recipientEmail],
    subject: "Your Verification Code - DevOps Learning Platform",
    text,
    html,
  });

  if (error) {
    const sendError = new Error(`Resend email failed: ${error.message}`);
    sendError.code = error.name || "RESEND_SEND_FAILED";
    throw sendError;
  }

  if (!data?.id) {
    throw new Error("Resend did not return an email ID");
  }

  return {
    messageId: data.id,
    accepted: [recipientEmail],
    rejected: [],
  };
}

module.exports = {
  sendOtpEmail,
  getTransporter,
  getSmtpStatus,
  verifySmtpConnection,
  resetMockEmails,
  getMockEmails,
};

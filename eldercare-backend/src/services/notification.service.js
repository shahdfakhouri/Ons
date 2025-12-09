const nodemailer = require("nodemailer");
const twilio = require("twilio");
const db = require("../config/db");

// ✅ Twilio setup
const client = twilio(process.env.TWILIO_ACCOUNT_SID, process.env.TWILIO_AUTH_TOKEN);

// ✅ Gmail setup
const transporter = nodemailer.createTransport({
  service: "Gmail",
  auth: {
    user: process.env.EMAIL_USER,
    pass: process.env.EMAIL_PASS,
  },
});

// ✉️ Send email
async function sendEmail(to, subject, text) {
  try {
    await transporter.sendMail({
      from: `"ElderCare Notifications" <${process.env.EMAIL_USER}>`,
      to,
      subject,
      text,
    });
    console.log(`📧 Email sent to ${to}`);
  } catch (error) {
    console.error("❌ Email error:", error.message);
  }
}

// 📱 Send SMS
async function sendSMS(to, text) {
  try {
    await client.messages.create({
      from: process.env.TWILIO_PHONE_NUMBER,
      to,
      body: text,
    });
    console.log(`📱 SMS sent to ${to}`);
  } catch (error) {
    console.error("❌ SMS error:", error.message);
  }
}

// 💾 Store notification in DB
function createNotification(type, message, userId = null, severity = "info") {
  const sql = `
    INSERT INTO admin_notifications (type, message, user_id, severity, status)
    VALUES (?, ?, ?, ?, 'open')
  `;
  db.query(sql, [type, message, userId, severity], (err) => {
    if (err) console.error("❌ Error saving notification:", err);
    else console.log(`💾 Notification saved: [${severity}] ${type} → ${message}`);
  });
}
// 🧠 Unified notification
async function notify({ type, message, email, phone, userId, severity = "info" }) {
  createNotification(type, message, userId, severity);
  if (email) await sendEmail(email, `ElderCare: ${type}`, message);
  if (phone) await sendSMS(phone, message);
}

module.exports = { notify, sendEmail, sendSMS };


const nodemailer = require("nodemailer");
const twilio = require("twilio");
const db = require("../config/db");

const client = twilio(process.env.TWILIO_ACCOUNT_SID, process.env.TWILIO_AUTH_TOKEN);

const transporter = nodemailer.createTransport({
  service: "Gmail",
  auth: {
    user: process.env.EMAIL_USER,
    pass: process.env.EMAIL_PASS,
  },
});

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


// 💾 Store notification in DB with logic to prevent "Admin Spam"
function createNotification({ type, message, userId = null, elder_id = null, sender_id = null, sender_role = 'system', severity = "info" }) {
  // 🚀 Logic: Define which types actually need to go to the Admin Dashboard
  const adminTypes = ['emergency', 'health_alert', 'payment', 'new_user', 'report'];
  
  if (!adminTypes.includes(type)) {
    console.log(`ℹ️ Internal notification [${type}] skipped for Admin Dashboard.`);
    return; // Don't clutter the admin table with routine reminders
  }

  const sql = `
    INSERT INTO admin_notifications 
    (type, message, user_id, elder_id, sender_id, sender_role, severity, status)
    VALUES (?, ?, ?, ?, ?, ?, ?, 'open')
  `;

  db.query(sql, [type, message, userId, elder_id, sender_id, sender_role, severity], (err) => {
    if (err) console.error("❌ Error saving notification:", err);
    else console.log(`💾 Organized: [${severity}] ${type} sent to Admin Triage.`);
  });
}

// 🧠 Unified notification
async function notify(data) {
  const { type, email, phone, message } = data;

  // 🚀 Step 1: Route to the appropriate Admin Tab based on type
  createNotification(data);

  // Step 2: External Alerts
  if (email) await sendEmail(email, `ElderCare: ${type}`, message);
  if (phone) await sendSMS(phone, message);
}

module.exports = { notify, sendEmail, sendSMS };
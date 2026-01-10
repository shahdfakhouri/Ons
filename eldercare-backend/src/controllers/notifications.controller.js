const db = require("../config/db");
const { notify } = require("../services/notification.service");

// 🔔 Get all admin notifications
exports.getAdminNotifications = (req, res) => {
  const sql = `
    SELECT id, type, message, is_read, created_at 
    FROM admin_notifications
    ORDER BY created_at DESC;
  `;
  db.query(sql, (err, results) => {
    if (err) return res.status(500).json({ msg: "Error fetching notifications", err });
    res.status(200).json({ msg: "Notifications retrieved", notifications: results });
  });
};

// ✅ Mark as read
exports.markAsRead = (req, res) => {
  const { id } = req.params;
  db.query("UPDATE admin_notifications SET is_read = 1 WHERE id = ?", [id], (err) => {
    if (err) return res.status(500).json({ msg: "Error marking notification as read", err });
    res.status(200).json({ msg: "Notification marked as read" });
  });
};

// 🚀 Example trigger (you can call this inside any other controller)
exports.triggerExampleNotification = async (req, res) => {
  const message = "A new caregiver has submitted a weekly report.";
  await notify({
    type: "report",
    message,
    email: "admin@example.com",
    phone: "0593021660",
    userId: 1,
  });
  res.status(200).json({ msg: "Notification sent" });
};
// ❤️ Filter only health alert notifications
exports.getHealthAlerts = (req, res) => {
  const status = req.query.status || "open"; // 'open' or 'resolved' or 'all'

  let sql = `
    SELECT id, type, message, severity, status, is_read, user_id, created_at, resolved_at
    FROM admin_notifications
    WHERE type = 'health_alert'
  `;

  const params = [];
  if (status !== "all") {
    sql += " AND status = ?";
    params.push(status);
  }
  sql += " ORDER BY created_at DESC";

  db.query(sql, params, (err, results) => {
    if (err) {
      console.error("Error fetching health alerts:", err);
      return res.status(500).json({ msg: "Error fetching health alerts", err });
    }
    res.status(200).json({ msg: "Health alerts retrieved", alerts: results });
  });
};

// ✅ Resolve / close a health alert (or any notification)
exports.resolveAlert = (req, res) => {
  const { id } = req.params;
  const adminId = req.user.id; // from JWT

  const sql = `
    UPDATE admin_notifications
    SET status = 'resolved',
        resolved_at = NOW(),
        resolved_by_admin_id = ?
    WHERE id = ?
  `;

  db.query(sql, [adminId, id], (err, result) => {
    if (err) {
      console.error("Error resolving alert:", err);
      return res.status(500).json({ msg: "Error resolving alert", err });
    }

    if (result.affectedRows === 0) {
      return res.status(404).json({ msg: "Alert not found" });
    }

    res.status(200).json({ msg: "Alert marked as resolved" });
  });
};
// 🔔 Get my notifications (family/caregiver/elder/home/admin if you want)
exports.getMyNotifications = (req, res) => {
  const userId = req.user.id;

  const sql = `
    SELECT id, type, message, severity, status, is_read, created_at, resolved_at
    FROM admin_notifications
    WHERE user_id = ?
    ORDER BY created_at DESC
  `;

  db.query(sql, [userId], (err, results) => {
    if (err) return res.status(500).json({ msg: "Error fetching my notifications", err });
    res.status(200).json({ msg: "My notifications retrieved ✅", notifications: results });
  });
};

// ✅ Mark my notification as read (ownership check)
exports.markMyAsRead = (req, res) => {
  const userId = req.user.id;
  const { id } = req.params;

  db.query(
    "UPDATE admin_notifications SET is_read = 1 WHERE id = ? AND user_id = ?",
    [id, userId],
    (err, result) => {
      if (err) return res.status(500).json({ msg: "Error marking notification as read", err });
      if (result.affectedRows === 0) {
        return res.status(404).json({ msg: "Notification not found (or not yours)" });
      }
      res.status(200).json({ msg: "Notification marked as read ✅" });
    }
  );
};
// ELDER CONTROLLER
// GET /api/notifications  (elder inbox)
exports.getElderNotifications = (req, res) => {
  const elder_id = req.user.elder_id;

  db.query(
    `SELECT notification_id, category, title, message, is_read, read_at, created_at
     FROM notifications
     WHERE recipient_role = 'elder' AND recipient_id = ?
     ORDER BY created_at DESC
     LIMIT 200`,
    [elder_id],
    (err, rows) => {
      if (err) {
        console.error("Get elder notifications DB error:", err);
        return res.status(500).json({ msg: "DB error", details: err.message });
      }
      res.json(rows);
    }
  );
};

// PATCH /api/notifications/:notification_id/read
exports.markElderNotificationRead = (req, res) => {
  const elder_id = req.user.elder_id;
  const { notification_id } = req.params;

  db.query(
    `UPDATE notifications
     SET is_read = 1, read_at = NOW()
     WHERE notification_id = ?
       AND recipient_role = 'elder'
       AND recipient_id = ?`,
    [notification_id, elder_id],
    (err, result) => {
      if (err) {
        console.error("Mark elder notification read DB error:", err);
        return res.status(500).json({ msg: "DB error", details: err.message });
      }

      if (result.affectedRows === 0) {
        return res.status(404).json({ msg: "Notification not found" });
      }

      res.json({ msg: "Notification marked as read" });
    }
  );
};
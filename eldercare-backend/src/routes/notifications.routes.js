const express = require("express");
const router = express.Router();
const notificationsController = require("../controllers/notifications.controller");
const verifyToken = require("../middleware/authmiddleware");
const isAdmin = require("../middleware/adminMiddleware");
const { notify } = require("../services/notification.service");


router.post("/test", async (req, res) => {
  try {
    await notify({
      type: "Test Notification",
      message: "This is a test alert from ElderCare! Everything works perfectly 💙",
      email: process.env.TEST_EMAIL,
      phone: process.env.TEST_PHONE,
      userId: 1,
    });

    res.status(200).json({ msg: "✅ Test notification sent successfully!" });
  } catch (err) {
    console.error(err);
    res.status(500).json({ msg: "❌ Failed to send test notification", error: err.message });
  }
});


// 🔔 All notifications (admin)
router.get( "/admin", verifyToken, isAdmin, notificationsController.getAdminNotifications );

// ❤️ Health alerts only
router.get( "/admin/health", verifyToken, isAdmin, notificationsController.getHealthAlerts );

// ✅ Mark one notification as read
router.patch( "/admin/:id/read", verifyToken, isAdmin, notificationsController.markAsRead );
// ✅ Mark one notification as resolved
router.patch("/admin/:id/resolve", verifyToken, isAdmin, notificationsController.resolveAlert);

module.exports = router;

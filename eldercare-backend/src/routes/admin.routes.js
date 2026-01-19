// src/routes/admin.routes.js
const express = require("express");
const router = express.Router();
const adminController = require("../controllers/admin.controller");
const verifyToken = require("../middleware/authmiddleware");
const isAdmin = require("../middleware/adminMiddleware");
const upload = require("../middleware/uploadMiddleware");
const trackerController = require("../controllers/tracker.controller");

//full overview
router.get("/dashboard/overview-full", verifyToken, isAdmin, adminController.getAdminOverview);

// ✅ Get pending approvals
router.get("/approvals", verifyToken, isAdmin, adminController.getPendingApprovals);

// ✅ Approve user (caregiver or retirement home)
router.put("/approve/:role/:id", verifyToken, isAdmin, adminController.approveUser);

// ✅ Reject user (optional)
router.put("/reject/:role/:id", verifyToken, isAdmin, adminController.rejectUser);

// 📊 Charts-friendly analytics
router.get(
  "/analytics/health-alerts",
  verifyToken,
  isAdmin,
  adminController.getHealthAlertsTimeline
);

router.get(
  "/analytics/revenue",
  verifyToken,
  isAdmin,
  adminController.getRevenueTimeline
);

router.get(
  "/analytics/users",
  verifyToken,
  isAdmin,
  adminController.getUserGrowthTimeline
);





router.get("/active-users", verifyToken, isAdmin, adminController.getActiveUsers);
router.put("/user/:role/:id", verifyToken, isAdmin, adminController.updateUserRoleOrStatus);
router.get("/assignments", verifyToken, isAdmin, adminController.getElderAssignments);
router.get("/health-summary", verifyToken, isAdmin, adminController.getElderHealthSummary);
router.get("/export/health", verifyToken, isAdmin, adminController.exportHealthData);
// View matches for a family
router.get("/matches/:family_id", verifyToken, isAdmin, adminController.getFamilyMatches);

// Approve or reject a selected match
router.post("/matches/:match_id/approve", verifyToken, isAdmin, adminController.approveMatch);
router.post("/matches/:match_id/reject", verifyToken, isAdmin, adminController.rejectMatch);

// 💰 Financial Dashboard
router.get("/dashboard/overview", verifyToken, isAdmin, adminController.getFinancialOverview);
router.get("/dashboard/revenue-by-role", verifyToken, isAdmin, adminController.getRevenueByRole);
router.get("/dashboard/users", verifyToken, isAdmin, adminController.getUserStats);
router.get("/dashboard/payments", verifyToken, isAdmin, adminController.getPaymentStatusStats);
// 📅 Weekly caregiver reports
router.get("/reports", verifyToken, isAdmin, adminController.getWeeklyReports);
router.get("/reports/export", verifyToken, isAdmin, adminController.exportWeeklyReports);
router.post("/reports/analyze/:report_id", verifyToken, isAdmin, adminController.analyzeWeeklyReport);


router.post("/check-cv/:id", verifyToken, isAdmin, adminController.checkCaregiverCV);




// 📊 Admin Analytics
router.get("/analytics", verifyToken, isAdmin, adminController.getAdminAnalytics);

// 🧭 GPS overview for all elders
router.get("/gps/overview", verifyToken, isAdmin, adminController.getElderLocationOverview);

// 🕒 GPS history for specific elder
router.get("/gps/history/:elder_id", verifyToken, isAdmin, adminController.getElderLocationHistory);

// (distance is already in /api/tracker, you can also expose a shortcut for admin if you want)
router.get("/gps/distance/:elder_id/:caregiver_id", verifyToken, isAdmin, trackerController.getDistanceToCaregiver);

router.get("/caregivers/:id/cv", adminController.viewCaregiverCV);




module.exports = router;
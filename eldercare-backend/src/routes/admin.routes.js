// src/routes/admin.routes.js
const express = require("express");
const router = express.Router();
const adminController = require("../controllers/admin.controller");
const verifyToken = require("../middleware/authmiddleware");
const isAdmin = require("../middleware/adminMiddleware");
const upload = require("../middleware/uploadMiddleware");



// ✅ Get pending approvals
router.get("/approvals", verifyToken, isAdmin, adminController.getPendingApprovals);

// ✅ Approve user (caregiver or retirement home)
router.put("/approve/:role/:id", verifyToken, isAdmin, adminController.approveUser);

// ✅ Reject user (optional)
router.put("/reject/:role/:id", verifyToken, isAdmin, adminController.rejectUser);


// ✅ New AI-powered CV checker route
router.post(
  "/check-cv/:id",
  verifyToken,
  isAdmin,
  upload.single("cv"),
  adminController.checkCaregiverCV
);

// View matches for a family
router.get("/matches/:family_id", verifyToken, isAdmin, adminController.getFamilyMatches);

// Approve or reject a selected match
router.post("/matches/:match_id/approve", verifyToken, isAdmin, adminController.approveMatch);
router.post("/matches/:match_id/reject", verifyToken, isAdmin, adminController.rejectMatch);
router.get("/active-users", verifyToken, isAdmin, adminController.getActiveUsers);
router.put("/user/:role/:id", verifyToken, isAdmin, adminController.updateUserRoleOrStatus);
router.get("/assignments", verifyToken, isAdmin, adminController.getElderAssignments);
router.get("/health-summary", verifyToken, isAdmin, adminController.getElderHealthSummary);
router.get("/export/health", verifyToken, isAdmin, adminController.exportHealthData);

module.exports = router;

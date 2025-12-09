const express = require("express");
const router = express.Router();

const deviceHealthController = require("../controllers/deviceHealth.controller");
const verifyToken = require("../middleware/authmiddleware");
const allowRoles = require("../middleware/roleMiddleware");

// Roles allowed to send device data
const ALLOWED_ROLES = ["elder", "caregiver", "family", "admin"];

// POST /api/health/device
router.post(
  "/device",
  verifyToken,
  allowRoles(ALLOWED_ROLES),
  deviceHealthController.logDeviceHealth
);

module.exports = router;

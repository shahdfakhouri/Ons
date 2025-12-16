const express = require("express");
const router = express.Router();

const verifyToken = require("../middleware/authmiddleware");
const allowRoles = require("../middleware/roleMiddleware");

const emergencyController = require("../controllers/emergency.controller");

// Trigger emergency (elder/family/caregiver/admin allowed)
router.post(
  "/",
  verifyToken,
  allowRoles(["elder", "family", "caregiver", "admin", "retirement_home"]),
  emergencyController.createEmergency
);

module.exports = router;

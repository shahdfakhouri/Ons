const express = require("express");
const router = express.Router();

const verifyToken = require("../middleware/authmiddleware");
const allowRoles = require("../middleware/roleMiddleware");
const allowedRoles = ["elder", "family", "caregiver", "admin", "retirement_home"];
const emergencyController = require("../controllers/emergency.controller");

// Trigger emergency (elder/family/caregiver/admin allowed)
router.post("/", verifyToken, allowRoles(allowedRoles), emergencyController.createEmergency);
router.post("/trigger", verifyToken, allowRoles(allowedRoles), emergencyController.createEmergency);

module.exports = router;

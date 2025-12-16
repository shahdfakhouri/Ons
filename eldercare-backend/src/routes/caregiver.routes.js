const express = require("express");
const router = express.Router();
const caregiverController = require("../controllers/caregiver.controller");
const verifyToken = require("../middleware/authmiddleware");
const medicationController = require("../controllers/medication.controller");

// 💊 Medication logging (caregiver)
router.post(
  "/elders/:elder_id/medication-log",
  verifyToken,
  medicationController.logMedication
);

router.get("/", verifyToken, caregiverController.getDashboard);
router.put("/update", verifyToken, caregiverController.updateProfile);

router.post("/health-log", verifyToken, caregiverController.logElderHealth);

module.exports = router;

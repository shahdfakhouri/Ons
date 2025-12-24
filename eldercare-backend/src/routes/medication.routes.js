const express = require("express");
const router = express.Router();

const verifyToken = require("../middleware/authmiddleware");
const allowRoles = require("../middleware/roleMiddleware");

const medicationController = require("../controllers/medication.controller");

// ✅ Retirement home / Admin: create medication plan & view meds/logs
router.post(
  "/elders/:elder_id/medications",
  verifyToken,
  allowRoles(["retirement_home", "admin"]),
  medicationController.createMedication
);

router.get(
  "/elders/:elder_id/medications",
  verifyToken,
  allowRoles(["retirement_home", "admin"]),
  medicationController.getElderMedications
);

router.get(
  "/elders/:elder_id/medication-logs",
  verifyToken,
  allowRoles(["retirement_home", "admin"]),
  medicationController.getMedicationLogs
);

// ✅ Caregiver: log taken/missed/skipped
router.post(
  "/elders/:elder_id/medication-log",
  verifyToken,
  allowRoles(["caregiver"]),
  medicationController.logMedication
);

module.exports = router;

const express = require("express");
const router = express.Router();

const verifyToken = require("../middleware/authmiddleware");
const allowRoles = require("../middleware/roleMiddleware");
const ensureAssignedToElder = require("../middleware/ensureAssignedToElder");

const caregiverController = require("../controllers/caregiver.controller");

// 🔐 lock all caregiver routes
router.use(verifyToken, allowRoles(["caregiver"]));

// 1) dashboard + profile
router.get("/dashboard", caregiverController.getDashboard);
router.get("/me", caregiverController.getMyProfile);
router.put("/me", caregiverController.updateProfile);

// 2) assigned elders
router.get("/elders", caregiverController.getAssignedElders);
router.get("/elders/:elder_id", ensureAssignedToElder, caregiverController.getElderDetails);

// 3) health logging & history
router.post("/elders/:elder_id/health-log", ensureAssignedToElder, caregiverController.logElderHealth);
router.get("/elders/:elder_id/health-logs", ensureAssignedToElder, caregiverController.getElderHealthLogs);

// 4) medication: plan + today checklist + history
router.get("/elders/:elder_id/medications", ensureAssignedToElder, caregiverController.getElderMedicationPlan);
router.get("/elders/:elder_id/medications/today", ensureAssignedToElder, caregiverController.getTodayMedicationChecklist);
router.get("/elders/:elder_id/medication-logs", ensureAssignedToElder, caregiverController.getMedicationLogs);

// 5) daily summary (caregiver creates it)
router.post("/elders/:elder_id/daily-summary", ensureAssignedToElder, caregiverController.upsertDailySummary);
router.get("/elders/:elder_id/daily-summary", ensureAssignedToElder, caregiverController.getDailySummary);

// 6) incidents (works for internal; for freelance we’ll allow but home_id may be null if your schema allows it)
router.post("/elders/:elder_id/incidents", ensureAssignedToElder, caregiverController.createIncident);
router.get("/incidents", caregiverController.getMyIncidents);

// 7) check-ins
router.post("/elders/:elder_id/checkin", ensureAssignedToElder, caregiverController.checkInElder);

// 8) shifts (internal caregivers only)
router.post("/shifts/start", caregiverController.startMyShift);
router.post("/shifts/end", caregiverController.endMyShift);
router.get("/shifts/active", caregiverController.getMyActiveShift);
router.get("/shifts/history", caregiverController.getMyShiftHistory);

module.exports = router;

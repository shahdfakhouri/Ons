const express = require("express");
const router = express.Router();

const retirementController = require("../controllers/retirement.controller");
const emergencyController = require("../controllers/emergency.controller");

const verifyToken = require("../middleware/authmiddleware");
const allowRoles = require("../middleware/roleMiddleware");

// 🔐 GLOBAL GUARD — applies to ALL routes below
router.use(verifyToken, allowRoles(["retirement_home"]));

/* =======================
   DASHBOARD & PROFILE
======================= */
router.get("/", retirementController.getDashboard);
router.put("/update", retirementController.updateProfile);

/* =======================
   EMERGENCIES (HOME SIDE)
======================= */
router.get("/emergencies", emergencyController.getHomeEmergencies);
router.patch("/emergencies/:emergency_id/accept", emergencyController.acceptEmergency);
router.patch("/emergencies/:emergency_id/reject", emergencyController.rejectEmergency);

/* =======================
   CAREGIVER MANAGEMENT
======================= */
router.get("/caregivers", retirementController.getHomeCaregivers);
router.get("/caregivers/available", retirementController.getAvailableCaregivers);
router.post("/caregivers/add", retirementController.addCaregiverToHome);
router.delete("/caregivers/:id", retirementController.removeCaregiverFromHome);

/* =======================
   ASSIGNMENTS
======================= */
router.get("/assignments", retirementController.getElderAssignments);
router.post("/assignments/add", retirementController.assignCaregiverToElder);
router.delete("/assignments", retirementController.removeElderAssignment);

/* =======================
   ELDERS MONITORING
======================= */
router.get("/elders", retirementController.getHomeEldersMonitoring);
router.get("/elders/:elder_id", retirementController.getHomeElderDetails);
router.get("/elders/:elder_id/health-logs", retirementController.getHomeElderHealthLogs);
router.get("/elders/:elder_id/location-history", retirementController.getHomeElderLocationHistory);
router.get("/alerts", retirementController.getHomeAlerts);

/* =======================
   ATTENDANCE (CHECK-IN/OUT)
======================= */
router.patch("/elders/:elder_id/check-in", retirementController.checkInElder);
router.patch("/elders/:elder_id/check-out", retirementController.checkOutElder);
router.get("/elders/:elder_id/attendance", retirementController.getElderAttendance);

/* =======================
   CAREGIVER SHIFTS
======================= */
router.post("/caregivers/:caregiver_id/shift/start", retirementController.startCaregiverShift);
router.post("/caregivers/:caregiver_id/shift/end", retirementController.endCaregiverShift);
router.get("/shifts/active", retirementController.getActiveShifts);
router.get("/caregivers/:caregiver_id/shifts", retirementController.getCaregiverShiftHistory);

/* =======================
   DAILY SUMMARIES
======================= */
router.post("/elders/:elder_id/daily-summary", retirementController.upsertDailySummary);
router.get("/elders/:elder_id/daily-summary", retirementController.getDailySummary);
router.get("/daily-summaries", retirementController.getHomeDailySummaries);

/* =======================
   PAYMENTS & TRANSACTIONS
======================= */
router.get("/payments", retirementController.getHomePayments);
router.get("/payments/:payment_id", retirementController.getHomePaymentById);
router.get("/transactions", retirementController.getHomeTransactions);

/* =======================
   INCIDENTS
======================= */
router.post("/incidents", retirementController.createIncident);
router.get("/incidents", retirementController.getHomeIncidents);
router.get("/incidents/:incident_id", retirementController.getIncidentById);
router.patch("/incidents/:incident_id/status", retirementController.updateIncidentStatus);

module.exports = router;

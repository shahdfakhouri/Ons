const express = require("express");
const router = express.Router();



const verifyToken = require("../middleware/authmiddleware");
const upload = require("../middleware/uploadMiddleware"); // ✅ ADD THIS

const allowRoles = require("../middleware/roleMiddleware");
const ensureAssignedToElder = require("../middleware/ensureAssignedToElder");

const caregiverController = require("../controllers/caregiver.controller");

// 🔐 lock all caregiver routes
router.use(verifyToken, allowRoles(["caregiver"]));

// 1) dashboard + profile
router.get("/dashboard", caregiverController.getDashboard);
router.get("/me", caregiverController.getMyProfile);
router.put("/me", caregiverController.updateProfile);
router.get("/elders/:elder_id/status", ensureAssignedToElder, caregiverController.getElderStatus);

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
router.get("/elders/:elder_id/medications/stats", ensureAssignedToElder, caregiverController.getMedicationStats);

// 5) daily summary (caregiver creates it)
router.post("/elders/:elder_id/daily-summary", ensureAssignedToElder, caregiverController.upsertDailySummary);
router.get("/elders/:elder_id/daily-summary", ensureAssignedToElder, caregiverController.getDailySummary);

// 6) incidents (works for internal; for freelance we’ll allow but home_id may be null if your schema allows it)
router.post("/elders/:elder_id/incidents", ensureAssignedToElder, caregiverController.createIncident);
router.get("/incidents", caregiverController.getMyIncidents);
router.put("/incidents/:incident_id/status", caregiverController.updateIncidentStatus);
router.get("/incidents/:incident_id", caregiverController.getIncidentById);


// 7) check-ins + location updates + history
router.post("/elders/:elder_id/checkin", ensureAssignedToElder, caregiverController.checkInElder);
router.post("/elders/:elder_id/location", ensureAssignedToElder, caregiverController.updateElderLocation);
router.get("/elders/:elder_id/location/history", ensureAssignedToElder, caregiverController.getElderLocationHistory);

// 8) shifts (internal caregivers only)
router.post("/shifts/start", caregiverController.startMyShift);
router.post("/shifts/end", caregiverController.endMyShift);
router.get("/shifts/active", caregiverController.getMyActiveShift);
router.get("/shifts/history", caregiverController.getMyShiftHistory);

// 9) communication hooks
router.get("/visits/upcoming", caregiverController.getMyUpcomingVisits);
router.get("/elders/:elder_id/visits/upcoming", ensureAssignedToElder, caregiverController.getElderUpcomingVisits);
router.get("/elders/:elder_id/family-contacts", ensureAssignedToElder, caregiverController.getElderFamilyContacts);
router.post("/elders/:elder_id/visits/request", ensureAssignedToElder, caregiverController.requestVisit);

//alerts 
router.get("/alerts", caregiverController.getMyAlerts);
router.get("/elders/:elder_id/alerts", ensureAssignedToElder, caregiverController.getElderAlerts);

// =====================
// Family <-> Caregiver Chat
// =====================
router.get("/chats", caregiverController.listMyChats);
router.get("/chats/:conversation_id/messages", caregiverController.getChatMessages);
router.post("/chats/:conversation_id/messages", caregiverController.sendChatMessage);
router.patch("/chats/:conversation_id/read", caregiverController.markChatRead);


router.post("/me/cv", verifyToken, upload.single("cv"), caregiverController.uploadMyCV);


module.exports = router;

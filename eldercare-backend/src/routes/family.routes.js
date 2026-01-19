const express = require("express");
const router = express.Router();

const familyController = require("../controllers/family.controller");
const verifyToken = require("../middleware/authmiddleware");
const allowRoles = require("../middleware/roleMiddleware");
const ensureFamilyOwnsElder = require("../middleware/ensureFamilyOwnsElder");
const ensureElderConsent = require("../middleware/ensureElderConsent");
const mediaUpload = require("../middleware/mediaUploadMiddleware");

// All family routes require login + family role
router.use(verifyToken, allowRoles(["family"]));

// Dashboard + profile
router.get("/", familyController.getDashboard);
router.get("/me", familyController.getMyProfile);
router.put("/update", familyController.updateProfile);

// Elders management
router.post("/elders", familyController.createElder);
router.get("/elders", familyController.listMyElders);
router.get("/elders/:elder_id", familyController.getOneElder);
router.put("/elders/:elder_id", familyController.updateElder);

// Matching (no family_id param; uses token)
router.post("/match", familyController.runMatch);
router.get("/matches", familyController.getMatches);

// Selection / assignment
router.post("/assign-caregiver", familyController.assignCaregiver);
router.post("/select-home", familyController.selectHome);
router.get("/assignments", familyController.getAssignments);

// Monitoring
router.get("/elders/:elder_id/health-logs", ensureFamilyOwnsElder, ensureElderConsent, familyController.getHealthLogs);
router.get("/elders/:elder_id/medications", ensureFamilyOwnsElder, ensureElderConsent, familyController.getMedications);
router.get("/elders/:elder_id/medication-logs", ensureFamilyOwnsElder, ensureElderConsent, familyController.getMedicationLogs);
router.get("/elders/:elder_id/medication-stats", ensureFamilyOwnsElder, ensureElderConsent, familyController.getMedicationStats);

// Alerts (all elders)
router.get("/alerts", familyController.getAlertsAll);
router.get("/elders/:elder_id/alerts", ensureFamilyOwnsElder, ensureElderConsent, familyController.getElderAlerts);

// Location
router.get("/elders/:elder_id/location/latest", ensureFamilyOwnsElder, ensureElderConsent, familyController.getLatestLocation);
router.get("/elders/:elder_id/location/history", ensureFamilyOwnsElder, ensureElderConsent, familyController.getLocationHistory);
router.get("/elders/:elder_id/safe-zones", ensureFamilyOwnsElder, ensureElderConsent, familyController.getSafeZones);

// Visits
router.post("/elders/:elder_id/visits", ensureFamilyOwnsElder, familyController.requestVisit);
router.get("/visits", familyController.getMyVisits);
router.get("/elders/:elder_id/visits", ensureFamilyOwnsElder, familyController.getElderVisits);

// Daily summaries
router.get("/elders/:elder_id/daily-summary/today", ensureFamilyOwnsElder, ensureElderConsent, familyController.getTodaySummary);
router.get("/elders/:elder_id/daily-summaries", ensureFamilyOwnsElder, ensureElderConsent, familyController.getSummariesRange);

// Payments + transactions history
router.get("/payments", familyController.getPaymentHistory);
router.get("/transactions", familyController.getTransactionHistory);

//// Elder PIN + consent
router.put("/elders/:elder_id/reset-pin", ensureFamilyOwnsElder, familyController.resetElderPin);
router.put("/elders/:elder_id/consent", ensureFamilyOwnsElder, familyController.setElderConsent);

// Calls
router.post("/calls/request", familyController.requestCall);
router.get("/calls/history", familyController.getCallHistory);

// Contacts
router.get("/elders/:elder_id/caregiver-contact", ensureFamilyOwnsElder, familyController.getCaregiverContact);
router.get("/elders/:elder_id/home-contact", ensureFamilyOwnsElder, familyController.getHomeContact);

// Media gallery
router.post("/elders/:elder_id/gallery", ensureFamilyOwnsElder, mediaUpload.single("media"), familyController.uploadGalleryMedia);
router.get("/elders/:elder_id/gallery", ensureFamilyOwnsElder, familyController.getElderGallery);
router.delete("/gallery/:media_id", familyController.deleteGalleryMedia);

//Dialy summary comments
router.post("/elders/:elder_id/daily-summary/:summary_id/comment", ensureFamilyOwnsElder, familyController.addDailySummaryComment);
router.get("/elders/:elder_id/daily-summary/:summary_id/comments", ensureFamilyOwnsElder, familyController.getDailySummaryComments);

//Fmaily notes
router.post("/elders/:elder_id/notes", ensureFamilyOwnsElder, familyController.addFamilyNote);
router.get("/elders/:elder_id/notes", ensureFamilyOwnsElder, familyController.getFamilyNotes);

//Reviews and ratings
router.post("/reviews", familyController.createReview);
router.get("/reviews", familyController.getMyReviews);

//Emergency requests
router.post("/emergency", familyController.createEmergencyRequest);
router.get("/emergency/history", familyController.getEmergencyHistory);
router.put("/emergency/:emergency_id/cancel", familyController.cancelEmergencyRequest);

//Events
router.post("/events", familyController.createEvent);
router.get("/events", familyController.getEvents);
router.put("/events/:event_id", familyController.updateEvent);
router.delete("/events/:event_id", familyController.deleteEvent);

// Combined shared calendar feed (events + visits)
router.get("/calendar", familyController.getCalendar);

// =====================
// Family <-> Caregiver Chat
// =====================
router.post("/chats/caregiver/:caregiver_id", verifyToken, allowRoles(["family"]), familyController.getOrCreateChatWithCaregiver);
router.get("/chats", verifyToken, allowRoles(["family"]), familyController.listMyChats);
router.get("/chats/:conversation_id/messages", verifyToken, allowRoles(["family"]), familyController.getChatMessages);
router.post("/chats/:conversation_id/messages", verifyToken, allowRoles(["family"]), familyController.sendChatMessage);
router.patch("/chats/:conversation_id/read", verifyToken, allowRoles(["family"]), familyController.markChatRead);
router.post("/matches/:match_id/select", familyController.selectMatch);

// Future work endpoints (optional placeholders)
//router.post("/calls/request", familyController.futureNotImplemented);
//router.get("/calls/history", familyController.futureNotImplemented);
//router.post("/elders/:elder_id/gallery", familyController.futureNotImplemented);
//router.get("/elders/:elder_id/gallery", familyController.futureNotImplemented);
//router.post("/reviews", familyController.futureNotImplemented);
//router.get("/reviews", familyController.futureNotImplemented);

module.exports = router;

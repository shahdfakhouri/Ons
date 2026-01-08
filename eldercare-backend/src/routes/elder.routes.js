const express = require("express");
const router = express.Router();
const emergencyController = require("../controllers/emergency.controller");
const elderController = require("../controllers/elder.controller");
const medicationController = require("../controllers/medication.controller");
const trackerController = require("../controllers/tracker.controller");
// Middlewares
const verifyToken = require("../middleware/authmiddleware");
const roleMiddleware = require("../middleware/roleMiddleware");
const upload = require("../middleware/mediaUploadMiddleware");

// 1) AUTH (PIN-based)
// // PIN login (NO token required)
router.post("/auth/pin-login", elderController.pinLogin);

// Change PIN (elder only)
router.patch("/auth/pin", verifyToken, roleMiddleware(["elder"]), elderController.changePin);


//2) PROFILE & ACCESSIBILITY
router.get("/me", verifyToken, roleMiddleware(["elder"]), elderController.getMyProfile);

router.patch("/me", verifyToken, roleMiddleware(["elder"]), elderController.updateMyProfile);


// 3) CONSENT / PRIVACY
router.get("/consent", verifyToken, roleMiddleware(["elder"]), elderController.getConsent);

router.patch("/consent", verifyToken, roleMiddleware(["elder"]), elderController.updateConsent);


//4) MOOD & SYMPTOMS (SELF-REPORT)
router.post("/mood", verifyToken, roleMiddleware(["elder"]), elderController.addMood);

router.get("/mood", verifyToken, roleMiddleware(["elder"]), elderController.getMoodHistory);

router.post("/symptoms", verifyToken, roleMiddleware(["elder"]), elderController.addSymptom);

router.get("/symptoms", verifyToken, roleMiddleware(["elder"]), elderController.getSymptoms);

//5) CALL REQUESTS (COMMUNICATION HOOKS)

router.post("/calls/request", verifyToken,roleMiddleware(["elder"]), elderController.requestCall);

router.get("/calls", verifyToken, roleMiddleware(["elder"]), elderController.getCallHistory);

//6) GALLERY / MEDIA 
router.get( "/gallery", verifyToken, roleMiddleware(["elder"]), elderController.getGallery);

router.post("/gallery/upload", verifyToken, roleMiddleware(["elder"]), upload.single("file"), elderController.uploadMyMedia);

router.delete("/gallery/:media_id", verifyToken, roleMiddleware(["elder"]), elderController.deleteMyMedia);

//7) ENTERTAINMENT / CONTENT FEED (OPTIONAL)
router.get("/content/feed", verifyToken, roleMiddleware(["elder"]), elderController.getContentFeed);

// 8) EMERGENCY ALERTS
router.post("/panic", verifyToken, roleMiddleware(["elder"]), emergencyController.elderPanic);

router.get("/emergencies", verifyToken, roleMiddleware(["elder"]), emergencyController.getMyEmergencies);

router.patch("/emergencies/:emergency_id/cancel", verifyToken, roleMiddleware(["elder"]), emergencyController.cancelMyEmergency);

// 9) MEDICATION REMINDERS & LOGGINGS
router.get("/medication/today", verifyToken, roleMiddleware(["elder"]), medicationController.getElderTodaySchedule);

router.get("/medication/history", verifyToken, roleMiddleware(["elder"]), medicationController.getElderMedicationHistory);

router.post("/medication/confirm", verifyToken, roleMiddleware(["elder"]), medicationController.confirmElderMedicationTaken);

// 10) LOCATION (elder read-only)
router.get("/location/current", verifyToken, roleMiddleware(["elder"]), trackerController.getElderCurrentLocation);
router.get("/safe-zones", verifyToken, roleMiddleware(["elder"]), trackerController.getElderSafeZones);
router.post("/location/request-help", verifyToken, roleMiddleware(["elder"]), trackerController.elderRequestHelp);

// 11) CALLS
router.patch("/calls/:call_id/accept", verifyToken, roleMiddleware(["elder"]), elderController.acceptCallRequest);

router.patch("/calls/:call_id/decline", verifyToken, roleMiddleware(["elder"]), elderController.declineCallRequest);

router.get("/contacts", verifyToken, roleMiddleware(["elder"]), elderController.getMyContacts);

module.exports = router;

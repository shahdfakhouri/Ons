const express = require("express");
const router = express.Router();
const trackerController = require("../controllers/tracker.controller");
const verifyToken = require("../middleware/authmiddleware");
const isAdmin = require("../middleware/adminMiddleware");

// 🔁 GPS updates (caregiver / family / admin can call)
router.post("/location", verifyToken, trackerController.updateLocation);

// 🧱 Safe zones – admin only for now
router.post("/safe-zones", verifyToken, isAdmin, trackerController.createSafeZone);
router.get("/safe-zones/:elder_id", verifyToken, isAdmin, trackerController.getSafeZones);
router.patch("/safe-zones/:zone_id", verifyToken, isAdmin, trackerController.toggleSafeZone);

// 🕒 Route history for one elder
router.get("/history/:elder_id", verifyToken, trackerController.getRouteHistory);

// 📏 Distance between elder and caregiver
router.get("/distance/:elder_id/:caregiver_id", verifyToken, trackerController.getDistanceToCaregiver);

module.exports = router;

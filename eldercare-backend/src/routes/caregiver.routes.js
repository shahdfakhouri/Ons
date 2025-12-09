const express = require("express");
const router = express.Router();
const caregiverController = require("../controllers/caregiver.controller");
const verifyToken = require("../middleware/authmiddleware");

router.get("/", verifyToken, caregiverController.getDashboard);
router.put("/update", verifyToken, caregiverController.updateProfile);

router.post("/health-log", verifyToken, caregiverController.logElderHealth);

module.exports = router;

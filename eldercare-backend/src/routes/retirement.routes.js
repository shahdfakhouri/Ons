const express = require("express");
const router = express.Router();
const retirementController = require("../controllers/retirement.controller");
const verifyToken = require("../middleware/authmiddleware");

router.get("/", verifyToken, retirementController.getDashboard);
router.put("/update", verifyToken, retirementController.updateProfile);

// 🧑‍⚕️ Caregiver Management
router.get("/caregivers", verifyToken, retirementController.getHomeCaregivers);
router.post("/caregivers/add", verifyToken, retirementController.addCaregiverToHome);
router.delete("/caregivers/:id", verifyToken, retirementController.removeCaregiverFromHome);
router.get("/caregivers/available", verifyToken, retirementController.getAvailableCaregivers);

// 🧓 Elder-Caregiver Assignments
router.get("/assignments", verifyToken, retirementController.getElderAssignments);
router.post("/assignments/add", verifyToken, retirementController.assignCaregiverToElder);
router.delete("/assignments", verifyToken, retirementController.removeElderAssignment);

module.exports = router;

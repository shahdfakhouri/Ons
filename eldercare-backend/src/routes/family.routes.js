const express = require("express");
const router = express.Router();
const familyController = require("../controllers/family.controller");
const verifyToken = require("../middleware/authmiddleware");

router.get("/", verifyToken, familyController.getDashboard);
router.put("/update", verifyToken, familyController.updateProfile);

module.exports = router;

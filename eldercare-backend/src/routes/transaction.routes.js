const express = require("express");
const router = express.Router();
const transactionController = require("../controllers/transaction.controller");
const verifyToken = require("../middleware/authmiddleware");

// ✅ Pay freelancer caregiver
router.post("/pay-freelancer", verifyToken, transactionController.payFreelancer);

// ✅ Pay retirement home (and its caregiver)
router.post("/pay-home", verifyToken, transactionController.payRetirementHome);

// ✅ Pay for medicine
router.post("/pay-medicine", verifyToken, transactionController.payMedicine);

module.exports = router;

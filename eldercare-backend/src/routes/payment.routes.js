const express = require("express");
const router = express.Router();
const paymentController = require("../controllers/payment.controller");
const verifyToken = require("../middleware/authmiddleware");

// Family
router.get("/pending", verifyToken, paymentController.getPendingPayments);
router.post("/execute", verifyToken, paymentController.executePayment);

// Admin
router.get("/platform-revenue", verifyToken, paymentController.getPlatformRevenue);

// Caregiver / Retirement Home
router.get("/receiver-revenue", verifyToken, paymentController.getReceiverRevenue);

// PayPal
router.post("/create", verifyToken, paymentController.createPayment);
router.get("/capture", paymentController.capturePayment);

module.exports = router;

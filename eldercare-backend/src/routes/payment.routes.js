    // /routes/payment.routes.js
    const express = require("express");
    const router = express.Router();
    const paymentController = require("../controllers/payment.controller");
    const verifyToken = require("../middleware/authmiddleware");
    const allowRoles = require("../middleware/roleMiddleware");

    // Family
    router.get("/pending", verifyToken, paymentController.getPendingPayments);

    // Admin
    router.get("/platform-revenue", verifyToken, paymentController.getPlatformRevenue);

    // Caregiver / Retirement Home
    router.get("/receiver-revenue", verifyToken, allowRoles(["caregiver", "retirement_home"]), paymentController.getReceiverRevenue);
    router.get("/receiver-transactions", verifyToken, allowRoles(["caregiver", "retirement_home"]), paymentController.getReceiverTransactions);

    // PayPal (APP FLOW)
    router.post("/create", verifyToken, paymentController.createPayment);
    router.get("/capture", verifyToken, paymentController.capturePayment);

    module.exports = router;
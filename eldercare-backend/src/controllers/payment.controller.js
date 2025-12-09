const db = require("../config/db");
const paypal = require("@paypal/checkout-server-sdk");
const { client } = require("../paypalConfig");

// 🟢 Get all pending payments (for family)
exports.getPendingPayments = (req, res) => {
  const userId = req.user.id;
  const sql = "SELECT * FROM payments WHERE status='pending' AND payer_id=?";
  db.query(sql, [userId], (err, result) => {
    if (err) return res.status(500).json({ msg: "Error retrieving payments", err });
    res.status(200).json(result);
  });
};

// 🟡 Execute payment (PayPal or on-arrival)
exports.executePayment = (req, res) => {
  const { paymentId, method } = req.body;
  const userId = req.user.id;

  if (!["paypal", "on_arrival"].includes(method))
    return res.status(400).json({ msg: "Invalid payment method" });

  db.query(
    "SELECT * FROM payments WHERE payment_id=? AND payer_id=? AND status='pending'",
    [paymentId, userId],
    (err, results) => {
      if (err) return res.status(500).json({ msg: "Database error", err });
      if (results.length === 0)
        return res.status(404).json({ msg: "Payment not found or already completed" });

      const payment = results[0];
      const status = method === "on_arrival" ? "completed" : "pending";

      db.query(
        "UPDATE payments SET method=?, status=? WHERE payment_id=?",
        [method, status, paymentId],
        (err2) => {
          if (err2) return res.status(500).json({ msg: "Error updating payment", err2 });
          res.status(200).json({ msg: `Payment ${status} via ${method}` });
        }
      );
    }
  );
};

// 💰 Get platform total revenue (Admin only)
exports.getPlatformRevenue = (req, res) => {
  const sql = "SELECT SUM(amount) AS total_revenue FROM transactions WHERE type='platform_fee'";
  db.query(sql, (err, result) => {
    if (err) return res.status(500).json({ msg: "Error fetching revenue", err });
    res.status(200).json({ totalRevenue: result[0].total_revenue || 0 });
  });
};

// 🧾 Get caregiver/facility revenue
exports.getReceiverRevenue = (req, res) => {
  const userId = req.user.id;
  db.query(
    "SELECT SUM(amount) AS total_revenue FROM transactions WHERE user_id=? AND type='payout'",
    [userId],
    (err, result) => {
      if (err) return res.status(500).json({ msg: "Error fetching revenue", err });
      res.status(200).json({ totalRevenue: result[0].total_revenue || 0 });
    }
  );
};

// 🧩 Create PayPal order
exports.createPayment = async (req, res) => {
  const { amount } = req.body;

  const request = new paypal.orders.OrdersCreateRequest();
  request.requestBody({
    intent: "CAPTURE",
    purchase_units: [{ amount: { currency_code: "USD", value: amount.toFixed(2) } }],
    application_context: {
      brand_name: "ElderCare",
      return_url: "http://localhost:5000/api/payments/capture",
      cancel_url: "http://localhost:5000/api/payments/cancel",
    },
  });

  try {
    const order = await client().execute(request);
    const approveUrl = order.result.links.find((link) => link.rel === "approve").href;
    res.status(200).json({ approveUrl });
  } catch (error) {
    console.error("PayPal error:", error);
    res.status(500).json({ msg: "Error creating PayPal payment" });
  }
};

// 🟢 Capture PayPal payment
exports.capturePayment = async (req, res) => {
  const { orderId, paymentId } = req.query;
  if (!orderId || !paymentId)
    return res.status(400).json({ msg: "Missing PayPal order or payment ID" });

  const captureRequest = new paypal.orders.OrdersCaptureRequest(orderId);
  captureRequest.requestBody({});

  try {
    const capture = await client().execute(captureRequest);
    if (capture.result.status === "COMPLETED") {
      db.query("UPDATE payments SET status='completed' WHERE payment_id=?", [paymentId]);
      res.status(200).json({ msg: "Payment completed successfully" });
    } else {
      res.status(400).json({ msg: "Payment not completed" });
    }
  } catch (error) {
    console.error("Capture error:", error);
    res.status(500).json({ msg: "Error capturing PayPal payment" });
  }
};

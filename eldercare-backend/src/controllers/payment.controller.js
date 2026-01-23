// /controllers/payment.controller.js
const db = require("../config/db");
const paypal = require("@paypal/checkout-server-sdk");
const { client } = require("../paypalConfig");

// 🟢 Get all pending payments (for family)
exports.getPendingPayments = (req, res) => {
  const familyId = req.user.id;
  const sql = "SELECT * FROM payments WHERE status='pending' AND family_id=?";
  db.query(sql, [familyId], (err, result) => {
    if (err) return res.status(500).json({ msg: "Error retrieving payments", err });
    res.status(200).json({ payments: result });
  });
};

// 🧩 Create PayPal order (linked to a paymentId)
exports.createPayment = async (req, res) => {
  const familyId = req.user.id;
  const { amount, paymentId } = req.body;

  if (!paymentId || !amount) {
    return res.status(400).json({ msg: "paymentId and amount are required" });
  }

  // ✅ Verify payment belongs to this family and is pending
  db.query(
    "SELECT * FROM payments WHERE payment_id=? AND family_id=? AND status='pending'",
    [paymentId, familyId],
    async (err, rows) => {
      if (err) return res.status(500).json({ msg: "Database error", err });
      if (!rows.length) return res.status(404).json({ msg: "Pending payment not found for this user" });

      const request = new paypal.orders.OrdersCreateRequest();
      request.requestBody({
        intent: "CAPTURE",
        purchase_units: [{ amount: { currency_code: "USD", value: Number(amount).toFixed(2) } }],
        application_context: {
          brand_name: "ONS ElderCare",
          // Not used by the app flow; the app will call /capture itself
          return_url: "http://localhost:5000/",
          cancel_url: "http://localhost:5000/",
        },
      });

      try {
        const order = await client().execute(request);
        const approveUrl = order.result.links.find((link) => link.rel === "approve").href;

        res.status(200).json({
          approveUrl,
          orderId: order.result.id, // ✅ IMPORTANT for capture
        });
      } catch (error) {
        console.error("PayPal error:", error);
        res.status(500).json({ msg: "Error creating PayPal order" });
      }
    }
  );
};

// 🟢 Capture PayPal payment + finalize DB transactions
exports.capturePayment = async (req, res) => {
  const familyId = req.user.id;
  const { orderId, paymentId } = req.query;

  if (!orderId || !paymentId) {
    return res.status(400).json({ msg: "Missing PayPal orderId or paymentId" });
  }

  // ✅ Verify payment belongs to this family and is pending
  db.query(
    "SELECT * FROM payments WHERE payment_id=? AND family_id=? AND status='pending'",
    [paymentId, familyId],
    async (err, rows) => {
      if (err) return res.status(500).json({ msg: "Database error", err });
      if (!rows.length) return res.status(404).json({ msg: "Pending payment not found" });

      const payment = rows[0];

      const captureRequest = new paypal.orders.OrdersCaptureRequest(orderId);
      captureRequest.requestBody({});

      try {
        const capture = await client().execute(captureRequest);

        if (capture.result.status !== "COMPLETED") {
          return res.status(400).json({ msg: "PayPal capture not completed" });
        }

        // ✅ Mark payment completed
        db.query("UPDATE payments SET status='completed', method='paypal' WHERE payment_id=?", [paymentId]);

        // ✅ If transactions already exist for this payment, don't duplicate
        db.query(
          "SELECT COUNT(*) AS cnt FROM transactions WHERE payment_id=?",
          [paymentId],
          (err2, cntRows) => {
            if (err2) return res.status(500).json({ msg: "Error checking transactions", err: err2 });

            if ((cntRows[0].cnt || 0) > 0) {
              return res.status(200).json({ msg: "Payment completed ✅ (transactions already recorded)" });
            }

            const amount = Number(payment.amount);
            const family = payment.family_id;
            const targetId = payment.target_id;

            // Finalize transactions based on target_type
            if (payment.target_type === "caregiver") {
              const caregiverShare = (amount * 0.9).toFixed(2);
              const platformFee = (amount * 0.1).toFixed(2);

              const sql = `
                INSERT INTO transactions (payment_id, from_role, to_role, from_id, to_id, amount, type)
                VALUES
                (?, 'family', 'caregiver', ?, ?, ?, 'payout'),
                (?, 'family', 'system', ?, NULL, ?, 'platform_fee')
              `;
              return db.query(
                sql,
                [paymentId, family, targetId, caregiverShare, paymentId, family, platformFee],
                (e3) => {
                  if (e3) return res.status(500).json({ msg: "Error finalizing transactions", err: e3 });
                  res.status(200).json({ msg: "Payment completed ✅" });
                }
              );
            }

            if (payment.target_type === "pharmacy") {
              const platformFee = (amount * 0.05).toFixed(2);
              const pharmacyShare = (amount * 0.95).toFixed(2);

              const sql = `
                INSERT INTO transactions (payment_id, from_role, to_role, from_id, to_id, amount, type)
                VALUES
                (?, 'family', 'pharmacy', ?, ?, ?, 'medicine'),
                (?, 'family', 'system', ?, NULL, ?, 'platform_fee')
              `;
              return db.query(
                sql,
                [paymentId, family, targetId, pharmacyShare, paymentId, family, platformFee],
                (e3) => {
                  if (e3) return res.status(500).json({ msg: "Error finalizing transactions", err: e3 });
                  res.status(200).json({ msg: "Payment completed ✅" });
                }
              );
            }

            // retirement_home PayPal is blocked in transactions controller; just in case:
            return res.status(200).json({
              msg: "Payment completed ✅ (no transaction rule for this target_type)",
            });
          }
        );
      } catch (error) {
        console.error("Capture error:", error);
        res.status(500).json({ msg: "Error capturing PayPal payment" });
      }
    }
  );
};

// 🟣 Admin: Platform revenue (sum of system platform fees)
exports.getPlatformRevenue = (req, res) => {
  // If you have roles in req.user, you can enforce admin here
  // if (req.user.role !== "admin") return res.status(403).json({ msg: "Forbidden" });

  const sql = `
    SELECT IFNULL(SUM(amount), 0) AS platform_revenue
    FROM transactions
    WHERE to_role = 'system' AND type = 'platform_fee'
  `;

  db.query(sql, (err, rows) => {
    if (err) return res.status(500).json({ msg: "Error fetching platform revenue", err });
    res.status(200).json({ platform_revenue: rows[0]?.platform_revenue ?? 0 });
  });
};

// 🟣 Caregiver/Retirement Home: Receiver revenue (sum of payouts/medicine sent to them)
exports.getReceiverRevenue = (req, res) => {
  const receiverId = req.user.id;
  const receiverRole = req.user.role; // must be 'caregiver' or 'retirement_home'

  const sql = `
    SELECT IFNULL(SUM(amount), 0) AS receiver_revenue
    FROM transactions
    WHERE to_role = ? AND to_id = ?
  `;

  db.query(sql, [receiverRole, receiverId], (err, rows) => {
    if (err) return res.status(500).json({ msg: "Error fetching receiver revenue", err });
    res.status(200).json({ receiver_revenue: rows[0]?.receiver_revenue ?? 0 });
  });
};

// 🟣 Caregiver/Retirement Home: Receiver transactions list (WITH SENDER NAMES)
exports.getReceiverTransactions = (req, res) => {
  const receiverId = req.user.id;
  const receiverRole = req.user.role;

  const limit = Math.min(parseInt(req.query.limit || "50", 10) || 50, 200);

  const sql = `
    SELECT
      t.transaction_id,
      t.payment_id,
      t.from_role,
      t.from_id,
      t.to_role,
      t.to_id,
      t.amount,
      t.type,
      t.created_at,

      -- Sender name (who paid)
      COALESCE(
        CASE WHEN t.from_role = 'family' THEN fm.name END,
        CASE WHEN t.from_role = 'caregiver' THEN cg.name END,
        CASE WHEN t.from_role = 'retirement_home' THEN rh.name END,
        CASE WHEN t.from_role = 'system' THEN 'Platform' END,
        CONCAT(t.from_role, ' #', t.from_id)
      ) AS from_name,

      -- Optional: receiver name (who receives)
      COALESCE(
        CASE WHEN t.to_role = 'caregiver' THEN cg2.name END,
        CASE WHEN t.to_role = 'retirement_home' THEN rh2.name END,
        CASE WHEN t.to_role = 'system' THEN 'Platform' END,
        CONCAT(t.to_role, ' #', t.to_id)
      ) AS to_name

    FROM transactions t
    LEFT JOIN family_members fm ON t.from_role = 'family' AND fm.family_id = t.from_id
    LEFT JOIN caregivers cg     ON t.from_role = 'caregiver' AND cg.caregiver_id = t.from_id
    LEFT JOIN retirement_homes rh ON t.from_role = 'retirement_home' AND rh.home_id = t.from_id

    LEFT JOIN caregivers cg2     ON t.to_role = 'caregiver' AND cg2.caregiver_id = t.to_id
    LEFT JOIN retirement_homes rh2 ON t.to_role = 'retirement_home' AND rh2.home_id = t.to_id

    WHERE t.to_role = ? AND t.to_id = ?
    ORDER BY t.transaction_id DESC
    LIMIT ${limit};
  `;

  db.query(sql, [receiverRole, receiverId], (err, rows) => {
    if (err) return res.status(500).json({ msg: "Error fetching receiver transactions", err });
    res.status(200).json({ transactions: rows });
  });
};


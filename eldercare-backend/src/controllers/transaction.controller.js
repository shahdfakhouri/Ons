// /controllers/transaction.controller.js
const db = require("../config/db");

const normalizeMethod = (m) => {
  const x = (m || "").toLowerCase().trim();
  if (x === "cash") return "on_arrival"; // UI has cash, DB doesn't
  return x;
};

//
// 🟢 FAMILY → CAREGIVER (freelancer)
//
exports.payFreelancer = (req, res) => {
  const { caregiver_id, amount } = req.body;
  let { method } = req.body;
  const familyId = req.user.id;

  method = normalizeMethod(method);

  if (!caregiver_id || !amount) {
    return res.status(400).json({ msg: "caregiver_id and amount are required" });
  }
  if (!["paypal", "on_arrival"].includes(method)) {
    return res.status(400).json({ msg: "Invalid payment method" });
  }

  const status = method === "paypal" ? "pending" : "completed";

  const paymentSql = `
    INSERT INTO payments (family_id, target_type, target_id, amount, method, status, purpose)
    VALUES (?, 'caregiver', ?, ?, ?, ?, 'care')
  `;

  db.query(paymentSql, [familyId, caregiver_id, amount, method, status], (err, result) => {
    if (err) return res.status(500).json({ msg: "Error creating payment", err });

    const paymentId = result.insertId;

    // ✅ If PayPal: stop here; frontend must call /payments/create then /payments/capture
    if (method === "paypal") {
      return res.status(200).json({
        msg: "Payment created (pending PayPal approval)",
        paymentId,
        status: "pending",
      });
    }

    // ✅ Non-paypal: record transactions immediately
    const caregiverShare = (amount * 0.9).toFixed(2);
    const platformFee = (amount * 0.1).toFixed(2);

    const transactionSql = `
      INSERT INTO transactions (payment_id, from_role, to_role, from_id, to_id, amount, type)
      VALUES
      (?, 'family', 'caregiver', ?, ?, ?, 'payout'),
      (?, 'family', 'system', ?, NULL, ?, 'platform_fee')
    `;

    db.query(
      transactionSql,
      [paymentId, familyId, caregiver_id, caregiverShare, paymentId, familyId, platformFee],
      (err2) => {
        if (err2) return res.status(500).json({ msg: "Error recording transaction", err2 });
        res.status(200).json({ msg: "Freelancer paid successfully", paymentId, status: "completed" });
      }
    );
  });
};

//
// 🟡 FAMILY → RETIREMENT HOME → CAREGIVER (employee)
// ⚠️ DB payments table does NOT store employee caregiver_id, so PayPal here cannot finalize correctly.
// We'll block PayPal for this route until you add a place to store caregiver_id.
//
exports.payRetirementHome = (req, res) => {
  const { home_id, caregiver_id, amount } = req.body;
  let { method } = req.body;
  const familyId = req.user.id;

  method = normalizeMethod(method);

  if (!home_id || !caregiver_id || !amount) {
    return res.status(400).json({ msg: "home_id, caregiver_id and amount are required" });
  }
  if (!["paypal", "on_arrival"].includes(method)) {
    return res.status(400).json({ msg: "Invalid payment method" });
  }

  if (method === "paypal") {
    return res.status(400).json({
      msg: "PayPal not supported for home payments yet (missing caregiver_id storage in payments table). Use on_arrival for now.",
    });
  }

  const paymentSql = `
    INSERT INTO payments (family_id, target_type, target_id, amount, method, status, purpose)
    VALUES (?, 'retirement_home', ?, ?, ?, 'completed', 'service')
  `;

  db.query(paymentSql, [familyId, home_id, amount, method], (err, result) => {
    if (err) return res.status(500).json({ msg: "Error creating payment", err });

    const paymentId = result.insertId;
    const homeShare = (amount * 0.85).toFixed(2);
    const caregiverShare = (amount * 0.1).toFixed(2);
    const platformFee = (amount * 0.05).toFixed(2);

    const transactionSql = `
      INSERT INTO transactions (payment_id, from_role, to_role, from_id, to_id, amount, type)
      VALUES
      (?, 'family', 'retirement_home', ?, ?, ?, 'transfer'),
      (?, 'retirement_home', 'caregiver', ?, ?, ?, 'payout'),
      (?, 'family', 'system', ?, NULL, ?, 'platform_fee')
    `;

    db.query(
      transactionSql,
      [
        paymentId, familyId, home_id, homeShare,
        paymentId, home_id, caregiver_id, caregiverShare,
        paymentId, familyId, platformFee,
      ],
      (err2) => {
        if (err2) return res.status(500).json({ msg: "Error recording home transactions", err2 });
        res.status(200).json({ msg: "Retirement home and caregiver paid successfully", paymentId, status: "completed" });
      }
    );
  });
};

//
// 💊 FAMILY → PHARMACY (medicine)
// ✅ PayPal supported because target_id is stored in payments table.
//
exports.payMedicine = (req, res) => {
  const { medicine_id, amount } = req.body;
  let { method } = req.body;
  const familyId = req.user.id;

  method = normalizeMethod(method);

  if (!medicine_id || !amount) {
    return res.status(400).json({ msg: "medicine_id and amount are required" });
  }
  if (!["paypal", "on_arrival"].includes(method)) {
    return res.status(400).json({ msg: "Invalid payment method" });
  }

  const status = method === "paypal" ? "pending" : "completed";

  const sql = `
    INSERT INTO payments (family_id, target_type, target_id, amount, method, status, purpose)
    VALUES (?, 'pharmacy', ?, ?, ?, ?, 'medicine')
  `;

  db.query(sql, [familyId, medicine_id, amount, method, status], (err, result) => {
    if (err) return res.status(500).json({ msg: "Error creating medicine payment", err });

    const paymentId = result.insertId;

    if (method === "paypal") {
      return res.status(200).json({
        msg: "Payment created (pending PayPal approval)",
        paymentId,
        status: "pending",
      });
    }

    const platformFee = (amount * 0.05).toFixed(2);
    const pharmacyShare = (amount * 0.95).toFixed(2);

    const transactionSql = `
      INSERT INTO transactions (payment_id, from_role, to_role, from_id, to_id, amount, type)
      VALUES
      (?, 'family', 'pharmacy', ?, ?, ?, 'medicine'),
      (?, 'family', 'system', ?, NULL, ?, 'platform_fee')
    `;

    db.query(
      transactionSql,
      [paymentId, familyId, medicine_id, pharmacyShare, paymentId, familyId, platformFee],
      (err2) => {
        if (err2) return res.status(500).json({ msg: "Error recording medicine transaction", err2 });
        res.status(200).json({ msg: "Medicine payment completed", paymentId, status: "completed" });
      }
    );
  });
};
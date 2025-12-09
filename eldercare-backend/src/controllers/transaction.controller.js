const db = require("../config/db");

//
// 🟢 FAMILY → CAREGIVER (freelancer)
//
exports.payFreelancer = (req, res) => {
  const { caregiver_id, amount, method } = req.body;
  const familyId = req.user.id;

  const paymentSql = `
    INSERT INTO payments (family_id, target_type, target_id, amount, method, status)
    VALUES (?, 'caregiver', ?, ?, ?, 'completed')
  `;
  db.query(paymentSql, [familyId, caregiver_id, amount, method], (err, result) => {
    if (err) return res.status(500).json({ msg: "Error creating payment", err });

    const paymentId = result.insertId;
    const caregiverShare = (amount * 0.9).toFixed(2);
    const platformFee = (amount * 0.1).toFixed(2);

    const transactionSql = `
      INSERT INTO transactions (payment_id, from_role, to_role, from_id, to_id, amount, type)
      VALUES
      (?, 'family', 'caregiver', ?, ?, ?, 'payout'),
      (?, 'family', 'system', ?, NULL, ?, 'platform_fee')
    `;
    db.query(transactionSql, [paymentId, familyId, caregiver_id, caregiverShare, paymentId, familyId, platformFee], (err2) => {
      if (err2) return res.status(500).json({ msg: "Error recording transaction", err2 });
      res.status(200).json({ msg: "Freelancer paid successfully" });
    });
  });
};

//
// 🟡 FAMILY → RETIREMENT HOME → CAREGIVER (employee)
//
exports.payRetirementHome = (req, res) => {
  const { home_id, caregiver_id, amount, method } = req.body;
  const familyId = req.user.id;

  const paymentSql = `
    INSERT INTO payments (family_id, target_type, target_id, amount, method, status)
    VALUES (?, 'retirement_home', ?, ?, ?, 'completed')
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
        paymentId, familyId, platformFee
      ],
      (err2) => {
        if (err2) return res.status(500).json({ msg: "Error recording home transactions", err2 });
        res.status(200).json({ msg: "Retirement home and caregiver paid successfully" });
      }
    );
  });
};

//
// 💊 FAMILY → MEDICINE / OTHER SERVICES
//
exports.payMedicine = (req, res) => {
  const { medicine_id, amount, method } = req.body;
  const familyId = req.user.id;

  const sql = `
    INSERT INTO payments (family_id, target_type, target_id, amount, method, status, purpose)
    VALUES (?, 'pharmacy', ?, ?, ?, 'completed', 'medicine')
  `;
  db.query(sql, [familyId, medicine_id, amount, method], (err, result) => {
    if (err) return res.status(500).json({ msg: "Error creating medicine payment", err });

    const paymentId = result.insertId;
    const platformFee = (amount * 0.05).toFixed(2);
    const pharmacyShare = (amount * 0.95).toFixed(2);

    const transactionSql = `
      INSERT INTO transactions (payment_id, from_role, to_role, from_id, to_id, amount, type)
      VALUES
      (?, 'family', 'pharmacy', ?, ?, ?, 'medicine'),
      (?, 'family', 'system', ?, NULL, ?, 'platform_fee')
    `;
    db.query(transactionSql, [paymentId, familyId, medicine_id, pharmacyShare, paymentId, familyId, platformFee], (err2) => {
      if (err2) return res.status(500).json({ msg: "Error recording medicine transaction", err2 });
      res.status(200).json({ msg: "Medicine payment completed" });
    });
  });
};

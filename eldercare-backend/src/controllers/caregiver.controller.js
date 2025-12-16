const db = require("../config/db");
const { saveHealthLogAndAlert } = require("../services/healthService");

exports.getDashboard = (req, res) => {
  res.status(200).json({ msg: "Caregiver dashboard working ✅" });
};

exports.updateProfile = (req, res) => {
  res.status(200).json({ msg: "Caregiver profile update endpoint ready 🛠️" });
};


// 🩺 Caregiver logs elder health
// 🩺 Caregiver logs elder health
exports.logElderHealth = async (req, res) => {
  const caregiverId = req.user.id; // from JWT
  const { elder_id, blood_pressure, blood_sugar, temperature, notes } = req.body;

  if (!elder_id) {
    return res.status(400).json({ msg: "elder_id is required" });
  }

  try {
    // ✅ IMPORTANT: healthService expects ONE object (log)
    const result = await saveHealthLogAndAlert({
      caregiver_id: caregiverId,
      elder_id: Number(elder_id),
      blood_pressure: blood_pressure || null,
      blood_sugar: blood_sugar || null,
      temperature: temperature || null,
      notes: notes || null,
    });

    res.status(201).json({
      msg: "Health log saved ✅",
      logId: result.insertId,
      alerts: result.alerts,
    });
  } catch (error) {
    console.error("Error logging health:", error);
    res.status(500).json({
      msg: "Error logging health",
      error: error.message || "Unknown error",
    });
  }
};
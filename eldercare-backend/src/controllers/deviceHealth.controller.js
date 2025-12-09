const { saveHealthLogAndAlert } = require("../services/healthService");

// POST /api/health/device
// Used by mobile / watch apps (through your backend) to send health data for an elder
exports.logDeviceHealth = async (req, res) => {
  try {
    const role = req.user.role?.toLowerCase();
    const userId = req.user.id;

    // Data coming from frontend
    const {
      elder_id,        // optional if elder is sending their own data
      heart_rate,
      blood_pressure,  // e.g. "130/85"
      blood_sugar,     // e.g. "180 mg/dL"
      temperature,     // e.g. "37.8 C"
      notes,           // optional free text
      steps,           // optional extra info
      sleep_hours,     // optional extra info
      falls,           // optional (number of detected falls)
      mood             // optional text, e.g. "sad", "normal"
    } = req.body;

    // Decide which elder this data belongs to:
    // - If elder is logged in: use their own id
    // - Otherwise require elder_id in body
    let targetElderId = elder_id;

    if (!targetElderId && role === "elder") {
      targetElderId = userId;
    }

    if (!targetElderId) {
      return res.status(400).json({
        msg: "elder_id is required (unless the logged-in user is an elder).",
      });
    }

    // If caregiver is sending data, we can link it to them
    const caregiverId = role === "caregiver" ? userId : null;

    // Build an extended notes field so we don't lose useful device info
    const extraParts = [];
    if (steps !== undefined) extraParts.push(`Steps: ${steps}`);
    if (sleep_hours !== undefined) extraParts.push(`Sleep hours: ${sleep_hours}`);
    if (falls !== undefined) extraParts.push(`Falls detected: ${falls}`);
    if (mood) extraParts.push(`Mood: ${mood}`);

    const combinedNotes = [
      notes || "",
      extraParts.length ? `Device data → ${extraParts.join(" | ")}` : "",
    ]
      .filter(Boolean)
      .join(" | ");

    // Call your existing smart health logic
    const result = await saveHealthLogAndAlert({
      caregiver_id: caregiverId,
      elder_id: targetElderId,
      blood_pressure: blood_pressure || null,
      blood_sugar: blood_sugar || null,
      temperature: temperature || null,
      notes: combinedNotes || null,
      heart_rate: heart_rate || null,
    });

    return res.status(201).json({
      msg: "Health data logged from device",
      logId: result.insertId,
      alerts: result.alerts, // any alerts triggered by your rules
    });
  } catch (error) {
    console.error("Error logging device health:", error);
    return res.status(500).json({
      msg: "Error logging device health",
      error: error.message,
    });
  }
};

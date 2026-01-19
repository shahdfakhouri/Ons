const db = require("../config/db");
const { notify } = require("./notification.service");

// helper parsers
function parseBloodPressure(bpStr) {
  if (!bpStr) return null;
  const match = bpStr.match(/(\d+)\s*\/\s*(\d+)/);
  if (!match) return null;
  return { systolic: Number(match[1]), diastolic: Number(match[2]) };
}

function parseNumber(value) {
  if (value === undefined || value === null || value === "") return null;
  if (typeof value === "number") return Number.isNaN(value) ? null : value;
  const str = String(value);
  const match = str.match(/(\d+(\.\d+)?)/);
  return match ? Number(match[1]) : null;
}

exports.saveHealthLogAndAlert = async (log) => {
  return new Promise((resolve, reject) => {
    const {
      caregiver_id,
      elder_id,
      blood_pressure,
      blood_sugar,
      temperature,
      notes,
      heart_rate,
    } = log;

    const sql = `
      INSERT INTO health_logs (caregiver_id, elder_id, blood_pressure, blood_sugar, temperature, notes)
      VALUES (?, ?, ?, ?, ?, ?)
    `;

    db.query(
      sql,
      [caregiver_id, elder_id, blood_pressure, blood_sugar, temperature, notes],
      async (err, result) => {
        if (err) {
          console.error("Error inserting health log:", err);
          return reject(err);
        }

        const alerts = [];

        // 1) Blood pressure rules - Removed "elder ${elder_id}"
        const bp = parseBloodPressure(blood_pressure);
        if (bp) {
          if (bp.systolic >= 180 || bp.diastolic >= 120) {
            alerts.push({ 
              severity: "critical", 
              msg: `Dangerously high blood pressure detected: ${bp.systolic}/${bp.diastolic}. Possible hypertensive crisis.` 
            });
          } else if (bp.systolic >= 160 || bp.diastolic >= 100) {
            alerts.push({ 
              severity: "warning", 
              msg: `High blood pressure detected: ${bp.systolic}/${bp.diastolic}.` 
            });
          }
        }

        // 2) Blood sugar rules - Removed "elder ${elder_id}"
        const sugar = parseNumber(blood_sugar);
        if (sugar !== null) {
          if (sugar >= 300) {
            alerts.push({ 
              severity: "critical", 
              msg: `Very high blood sugar detected: ${sugar} mg/dL.` 
            });
          } else if (sugar >= 250 || sugar <= 70) {
            alerts.push({ 
              severity: "warning", 
              msg: `Abnormal blood sugar detected: ${sugar} mg/dL.` 
            });
          }
        }

        // 3) Temperature rules - Removed "elder ${elder_id}"
        const temp = parseNumber(temperature);
        if (temp !== null) {
          if (temp >= 39.0) {
            alerts.push({ 
              severity: "critical", 
              msg: `High fever detected: ${temp}°C.` 
            });
          } else if (temp >= 38.0) {
            alerts.push({ 
              severity: "warning", 
              msg: `Fever detected: ${temp}°C.` 
            });
          }
        }

        // 4) Unified Notification Loop
        for (const alert of alerts) {
          await notify({
            type: "health_alert",
            message: alert.msg,
            email: process.env.TEST_EMAIL,
            phone: process.env.TEST_PHONE,
            elder_id: elder_id,      // Still pass the ID for relational DB linking
            sender_id: caregiver_id, // Still pass the ID for relational DB linking
            sender_role: 'caregiver',
            severity: alert.severity,
            userId: null 
          });
        }

        resolve({ insertId: result.insertId, alerts });
      }
    );
  });
};
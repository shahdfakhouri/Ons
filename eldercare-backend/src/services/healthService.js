const db = require("../config/db");
const { notify } = require("./notification.service");

// helper parsers
function parseBloodPressure(bpStr) {
  if (!bpStr) return null;
  const match = bpStr.match(/(\d+)\s*\/\s*(\d+)/);
  if (!match) return null;
  return { systolic: Number(match[1]), diastolic: Number(match[2]) };
}

function parseNumber(str) {
  if (!str) return null;
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
      heart_rate, // optional, if you include it
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

        // ---- SMART ALERT RULES ----
        const alerts = [];

        // 1) Blood pressure rules
        const bp = parseBloodPressure(blood_pressure);
        if (bp) {
          if (bp.systolic >= 180 || bp.diastolic >= 120) {
            alerts.push({
              severity: "critical",
              msg: `Dangerously high blood pressure for elder ${elder_id}: ${bp.systolic}/${bp.diastolic}. Possible hypertensive crisis.`,
            });
          } else if (bp.systolic >= 160 || bp.diastolic >= 100) {
            alerts.push({
              severity: "warning",
              msg: `High blood pressure for elder ${elder_id}: ${bp.systolic}/${bp.diastolic}.`,
            });
          }
        }

        // 2) Blood sugar rules
        const sugar = parseNumber(blood_sugar);
        if (sugar !== null) {
          if (sugar >= 300) {
            alerts.push({
              severity: "critical",
              msg: `Very high blood sugar for elder ${elder_id}: ${sugar} mg/dL.`,
            });
          } else if (sugar >= 250 || sugar <= 70) {
            alerts.push({
              severity: "warning",
              msg: `Abnormal blood sugar for elder ${elder_id}: ${sugar} mg/dL.`,
            });
          }
        }

        // 3) Temperature rules
        const temp = parseNumber(temperature);
        if (temp !== null) {
          if (temp >= 39.0) {
            alerts.push({
              severity: "critical",
              msg: `High fever for elder ${elder_id}: ${temp}°C.`,
            });
          } else if (temp >= 38.0) {
            alerts.push({
              severity: "warning",
              msg: `Fever for elder ${elder_id}: ${temp}°C.`,
            });
          } else if (temp <= 35.0) {
            alerts.push({
              severity: "warning",
              msg: `Low body temperature for elder ${elder_id}: ${temp}°C.`,
            });
          }
        }

        // 4) Heart rate (from manual log or Apple data later)
        const hr = heart_rate ? Number(heart_rate) : null;
        if (hr) {
          if (hr >= 130 || hr <= 40) {
            alerts.push({
              severity: "critical",
              msg: `Abnormal heart rate for elder ${elder_id}: ${hr} bpm.`,
            });
          } else if (hr >= 110) {
            alerts.push({
              severity: "warning",
              msg: `Elevated heart rate for elder ${elder_id}: ${hr} bpm.`,
            });
          }
        }

        // 5) Notes keywords (chest pain, dizziness, etc.)
        const text = (notes || "").toLowerCase();
        if (
          text.includes("chest pain") ||
          text.includes("shortness of breath") ||
          text.includes("difficulty breathing")
        ) {
          alerts.push({
            severity: "critical",
            msg: `Elder ${elder_id} reported possible cardiac symptoms: "${notes}".`,
          });
        } else if (
          text.includes("dizzy") ||
          text.includes("fall") ||
          text.includes("fell")
        ) {
          alerts.push({
            severity: "warning",
            msg: `Elder ${elder_id} reported fall / dizziness: "${notes}".`,
          });
        }

        // send notifications for all alerts
        for (const alert of alerts) {
          await notify({
            type: "health_alert",
            message: alert.msg,
            email: process.env.TEST_EMAIL,
            phone: process.env.TEST_PHONE,
            userId: elder_id,
            severity: alert.severity,
          });
        }

        resolve({ insertId: result.insertId, alerts });
      }
    );
  });
};

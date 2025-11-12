// src/controllers/admin.controller.js
const db = require("../config/db");
const fs = require("fs");
const path = require("path");
const OpenAI = require("openai");

// ✅ Initialize OpenAI client
const openai = new OpenAI({
  apiKey: process.env.OPENAI_API_KEY,
});

// ✅ Dynamically import pdf-parse for Node v22+ compatibility
const pdf = require("pdf-parse-fixed");


// 🧾 Get all users (caregivers + retirement homes + families + elders)
exports.getAllUsers = async (req, res) => {
  try {
    const queries = [
      "SELECT caregiver_id AS id, name, email, phone, 'caregiver' AS role FROM caregivers",
      "SELECT home_id AS id, name, contact_email AS email, contact_phone AS phone, 'retirement_home' AS role FROM retirement_homes",
      "SELECT family_id AS id, name, email, phone, 'family' AS role FROM family_members",
      "SELECT elder_id AS id, name, NULL AS email, 'elder' AS role FROM elders"
    ];

    let allUsers = [];

    for (const query of queries) {
      const [rows] = await new Promise((resolve, reject) => {
        db.query(query, (err, result) => {
          if (err) reject(err);
          else resolve([result]);
        });
      });
      allUsers = allUsers.concat(rows);
    }

    res.status(200).json({ msg: "Users retrieved successfully", users: allUsers });
  } catch (error) {
    console.error("🔥 SQL Error:", error);
    res.status(500).json({ msg: "Server error fetching users", error });
  }
};

// ✅ Get pending approvals (caregivers + retirement homes)
exports.getPendingApprovals = (req, res) => {
  const queries = [
    "SELECT caregiver_id AS id, name, email, phone, 'caregiver' AS role FROM caregivers WHERE is_approved = 0",
    "SELECT home_id AS id, name, contact_email AS email, contact_phone AS phone, 'retirement_home' AS role FROM retirement_homes WHERE is_approved = 0"
  ];

  let pending = [];

  Promise.all(
    queries.map(
      (query) =>
        new Promise((resolve, reject) => {
          db.query(query, (err, results) => {
            if (err) reject(err);
            else resolve(results);
          });
        })
    )
  )
    .then((results) => {
      results.forEach((r) => (pending = pending.concat(r)));
      res.status(200).json({ msg: "Pending approvals retrieved", pending });
    })
    .catch((error) => {
      console.error("🔥 SQL Error:", error);
      res.status(500).json({ msg: "Error fetching pending approvals", error });
    });
};

// ✅ Approve user (caregiver or retirement home)
exports.approveUser = (req, res) => {
  const { role, id } = req.params;

  let table, idField;

  if (role === "caregiver") {
    table = "caregivers";
    idField = "caregiver_id";
  } else if (role === "retirement_home") {
    table = "retirement_homes";
    idField = "home_id";
  } else {
    return res.status(400).json({ msg: "Invalid role" });
  }

  const sql = `UPDATE ${table} SET is_approved = 1 WHERE ${idField} = ?`;

  db.query(sql, [id], (err, result) => {
    if (err) return res.status(500).json({ msg: "Error approving user", err });

    if (result.affectedRows === 0)
      return res.status(404).json({ msg: "User not found" });

    res.status(200).json({ msg: `${role} approved successfully` });
  });
};

// ✅ Reject user
exports.rejectUser = (req, res) => {
  const { role, id } = req.params;

  let table, idField;

  if (role === "caregiver") {
    table = "caregivers";
    idField = "caregiver_id";
  } else if (role === "retirement_home") {
    table = "retirement_homes";
    idField = "home_id";
  } else {
    return res.status(400).json({ msg: "Invalid role" });
  }

  const sql = `DELETE FROM ${table} WHERE ${idField} = ?`;

  db.query(sql, [id], (err, result) => {
    if (err) return res.status(500).json({ msg: "Error rejecting user", err });

    if (result.affectedRows === 0)
      return res.status(404).json({ msg: "User not found" });

    res.status(200).json({ msg: `${role} rejected and removed successfully` });
  });
};

// 🧠 Analyze Caregiver CV with AI
exports.checkCaregiverCV = async (req, res) => {
  try {
    // ✅ Ensure file uploaded
    if (!req.file || req.file.mimetype !== "application/pdf") {
      return res.status(400).json({ msg: "Please upload a caregiver CV in PDF format." });
    }

    // ✅ Read PDF file
    const filePath = req.file.path;
    const dataBuffer = fs.readFileSync(filePath);

    // 🧾 Parse PDF text
    const pdfData = await pdf(dataBuffer);
    const text = pdfData.text.trim();

    if (!text || text.length < 100) {
      return res.status(400).json({ msg: "The CV is empty or unreadable. Please upload a valid PDF." });
    }

    // 🧠 Send CV text to OpenAI
    const prompt = `
You are an HR AI assistant evaluating a caregiver's resume. 
Based on the following CV text, rate how well this candidate fits a professional caregiver role for elderly people.
Consider skills like nursing, first aid, elderly care, empathy, experience in retirement homes, and communication.

Return ONLY a JSON object with:
{
  "score": number (0-100),
  "feedback": "string",
  "approved": boolean (true if score > 70)
}

CV Text:
${text}
`;

    const aiResponse = await openai.chat.completions.create({
      model: "gpt-4o-mini",
      messages: [{ role: "user", content: prompt }],
      temperature: 0.4,
    });

    const responseText = aiResponse.choices[0].message.content;
    console.log("🧠 AI Evaluation:", responseText);

    // ✅ Try to parse AI JSON output safely
    let result;
    try {
      result = JSON.parse(responseText);
    } catch (err) {
      result = { score: 50, feedback: responseText, approved: false };
    }

    // ✅ Update caregiver approval status + feedback in DB if approved
    const caregiverId = req.params.id;
    const feedback = result.feedback || "No feedback provided";
    const score = result.score || 0;
    const approved = result.approved ? 1 : 0;

    db.query(
      "UPDATE caregivers SET is_approved = ?, ai_score = ?, ai_feedback = ? WHERE caregiver_id = ?",
      [approved, score, feedback, caregiverId],
      (err) => {
        if (err) console.error("DB update error:", err);
      }
    );

    res.status(200).json({
      msg: "CV analyzed successfully",
      result,
    });
  } catch (error) {
    console.error("Error analyzing PDF:", error);
    res.status(500).json({ msg: "Failed to analyze CV", error: error.message });
  }
};

// 🧩 View all matches for a family
exports.getFamilyMatches = (req, res) => {
  const { family_id } = req.params;

  const sql = `
    SELECT m.match_id, m.family_id, m.matched_id, m.matched_role, m.score,
           m.selected_by_family, m.approved_by_admin, m.status,
           CASE
             WHEN m.matched_role = 'caregiver' THEN c.name
             WHEN m.matched_role = 'retirement_home' THEN r.name
           END AS matched_name,
           CASE
             WHEN m.matched_role = 'caregiver' THEN c.city
             WHEN m.matched_role = 'retirement_home' THEN r.city
           END AS city
    FROM matches m
    LEFT JOIN caregivers c ON m.matched_id = c.caregiver_id AND m.matched_role = 'caregiver'
    LEFT JOIN retirement_homes r ON m.matched_id = r.home_id AND m.matched_role = 'retirement_home'
    WHERE m.family_id = ?;
  `;

  db.query(sql, [family_id], (err, results) => {
    if (err) return res.status(500).json({ msg: "DB error fetching matches", err });
    res.status(200).json({ msg: "Family matches retrieved successfully", matches: results });
  });
};

// ✅ Approve a selected match
exports.approveMatch = (req, res) => {
  const { match_id } = req.params;

  const sql = `
    UPDATE matches
    SET approved_by_admin = 1, status = 'approved'
    WHERE match_id = ?;
  `;

  db.query(sql, [match_id], (err, result) => {
    if (err) return res.status(500).json({ msg: "DB error approving match", err });
    if (result.affectedRows === 0) return res.status(404).json({ msg: "Match not found" });
    res.status(200).json({ msg: "Match approved successfully" });
  });
};

// ❌ Reject a selected match
exports.rejectMatch = (req, res) => {
  const { match_id } = req.params;

  const sql = `
    UPDATE matches
    SET approved_by_admin = 0, status = 'rejected'
    WHERE match_id = ?;
  `;

  db.query(sql, [match_id], (err, result) => {
    if (err) return res.status(500).json({ msg: "DB error rejecting match", err });
    if (result.affectedRows === 0) return res.status(404).json({ msg: "Match not found" });
    res.status(200).json({ msg: "Match rejected successfully" });
  });
};

//✅ Approve Match + Auto-assign
exports.approveMatch = (req, res) => {
  const { match_id } = req.params;

  const sqlGet = "SELECT * FROM matches WHERE match_id = ?";
  db.query(sqlGet, [match_id], (err, results) => {
    if (err) return res.status(500).json({ msg: "Error fetching match", err });
    if (results.length === 0) return res.status(404).json({ msg: "Match not found" });

    const match = results[0];

    db.query(
      "UPDATE matches SET approved_by_admin = 1, status = 'approved' WHERE match_id = ?",
      [match_id],
      (err) => {
        if (err) return res.status(500).json({ msg: "Error approving match", err });

        if (match.matched_role === "caregiver") {
          // Assign caregiver
          db.query(
            "UPDATE caregivers SET status = 'assigned' WHERE caregiver_id = ?",
            [match.matched_id]
          );
        }

        db.query(
          "INSERT INTO elder_assignments (elder_id, caregiver_id, home_id, assigned_by) VALUES (?, ?, ?, 1)",
          [match.family_id, match.matched_role === "caregiver" ? match.matched_id : null,
           match.matched_role === "retirement_home" ? match.matched_id : null],
          (err2) => {
            if (err2) console.error("Assignment error:", err2);
          }
        );

        res.status(200).json({ msg: "Match approved & caregiver/home assigned successfully" });
      }
    );
  });
};

//👥 See all active users
exports.getActiveUsers = (req, res) => {
  const sql = `
    SELECT 'caregiver' AS role, name, email, phone, status FROM caregivers
    UNION
    SELECT 'retirement_home' AS role, name, contact_email, contact_phone, 'active' AS status FROM retirement_homes
    UNION
    SELECT 'family' AS role, name, email, phone, 'active' AS status FROM family_members
  `;
  db.query(sql, (err, results) => {
    if (err) return res.status(500).json({ msg: "DB error fetching active users", err });
    res.status(200).json({ msg: "Active users retrieved", users: results });
  });
};

//🔐 Manage roles / account status
exports.updateUserRoleOrStatus = (req, res) => {
  const { role, id } = req.params;
  const { new_role, new_status } = req.body;

  let table, idField;
  if (role === "caregiver") { table = "caregivers"; idField = "caregiver_id"; }
  else if (role === "retirement_home") { table = "retirement_homes"; idField = "home_id"; }
  else if (role === "family") { table = "family_members"; idField = "family_id"; }
  else return res.status(400).json({ msg: "Invalid role" });

  const sql = `UPDATE ${table} SET status = ? WHERE ${idField} = ?`;
  db.query(sql, [new_status, id], (err) => {
    if (err) return res.status(500).json({ msg: "Error updating status", err });
    res.status(200).json({ msg: `${role} updated successfully` });
  });
};

//🧓 Elders & Assigned Caregivers
exports.getElderAssignments = (req, res) => {
  const sql = `
    SELECT e.elder_id, e.name AS elder_name, 
           c.name AS caregiver_name, c.status AS caregiver_status,
           r.name AS home_name,
           ea.assigned_at
    FROM elder_assignments ea
    LEFT JOIN elders e ON ea.elder_id = e.elder_id
    LEFT JOIN caregivers c ON ea.caregiver_id = c.caregiver_id
    LEFT JOIN retirement_homes r ON ea.home_id = r.home_id
    ORDER BY ea.assigned_at DESC;
  `;
  db.query(sql, (err, results) => {
    if (err) return res.status(500).json({ msg: "Error fetching assignments", err });
    res.status(200).json({ msg: "Elder assignments retrieved", data: results });
  });
};

//🕒 Last check-in & health summary
exports.getElderHealthSummary = (req, res) => {
  const sql = `
    SELECT e.elder_id, e.name AS elder_name,
           MAX(ch.checkin_time) AS last_checkin,
           hl.blood_pressure, hl.blood_sugar, hl.temperature, hl.notes, hl.date
    FROM elders e
    LEFT JOIN checkins ch ON e.elder_id = ch.elder_id
    LEFT JOIN health_logs hl ON e.elder_id = hl.elder_id
    GROUP BY e.elder_id
    ORDER BY e.elder_id;
  `;
  db.query(sql, (err, results) => {
    if (err) return res.status(500).json({ msg: "Error fetching health summaries", err });
    res.status(200).json({ msg: "Elder health summaries", summaries: results });
  });
};



//📤 Export Data (CSV)
const { Parser } = require("@json2csv/plainjs");

exports.exportHealthData = (req, res) => {
  db.query("SELECT * FROM health_logs", (err, results) => {
    if (err) return res.status(500).json({ msg: "Error fetching data", err });

    if (!results || results.length === 0) {
      return res.status(404).json({ msg: "No health logs found to export" });
    }

    try {
      const parser = new Parser();
      const csv = parser.parse(results);

      res.header("Content-Type", "text/csv");
      res.attachment("health_logs.csv");
      res.send(csv);
    } catch (error) {
      res.status(500).json({ msg: "Error generating CSV", error });
    }
  });
};


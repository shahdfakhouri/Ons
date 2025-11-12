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

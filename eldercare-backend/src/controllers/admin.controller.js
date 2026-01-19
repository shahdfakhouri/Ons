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
      // 🛠️ Added city column
      "SELECT caregiver_id AS id, name, email, phone, city, 'caregiver' AS role FROM caregivers",
      "SELECT home_id AS id, name, contact_email AS email, contact_phone AS phone, city, 'retirement_home' AS role FROM retirement_homes",
      "SELECT family_id AS id, name, email, phone, city, 'family' AS role FROM family_members",
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
    // 🛠️ Added city to the caregiver query
    "SELECT caregiver_id AS id, name, email, phone, employment_type, ai_score, ai_feedback, city, 'caregiver' AS role FROM caregivers WHERE is_approved = 0",
    
    // City is already here for retirement homes
"SELECT home_id AS id, name, contact_email AS email, contact_phone AS phone, city, services, 'retirement_home' AS role FROM retirement_homes WHERE is_approved = 0"  ];
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
// ✅ Approve a selected match
exports.approveMatch = (req, res) => {
  const { match_id } = req.params;

  // get match first (so we know family_id)
  db.query(`SELECT * FROM matches WHERE match_id=? LIMIT 1`, [match_id], (e1, rows) => {
    if (e1) return res.status(500).json({ msg: "DB error", err: e1 });
    if (!rows.length) return res.status(404).json({ msg: "Match not found" });

    const match = rows[0];

    db.query(
      `UPDATE matches SET approved_by_admin = 1, status = 'approved' WHERE match_id = ?;`,
      [match_id],
      (e2, result) => {
        if (e2) return res.status(500).json({ msg: "DB error approving match", err: e2 });

        // ✅ notify family
        db.query(
          `INSERT INTO notifications (recipient_role, recipient_id, category, title, message)
           VALUES ('family', ?, 'system', 'Match Approved ✅', ?)`,
          [
            match.family_id,
            `Your match request was approved. You can now assign the ${match.matched_role}. (match_id=${match_id})`
          ],
          () => {}
        );

        res.status(200).json({ msg: "Match approved successfully" });
      }
    );
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
// src/controllers/admin.controller.js
// src/controllers/admin.controller.js

// src/controllers/admin.controller.js

// src/controllers/admin.controller.js

exports.getElderHealthSummary = (req, res) => {
  const sql = `
    SELECT 
      e.elder_id, 
      e.name AS elder_name,
      -- Use the column you showed in your screenshot!
      e.last_check_in AS last_checkin, 
      hl.blood_pressure, 
      hl.blood_sugar, 
      hl.temperature, 
      hl.notes, 
      hl.date
    FROM elders e
    -- JOIN with health_logs to get the most recent vitals
    LEFT JOIN health_logs hl ON hl.elder_id = e.elder_id 
      AND hl.log_id = (SELECT MAX(log_id) FROM health_logs WHERE elder_id = e.elder_id)
    ORDER BY e.name ASC;
  `;

  db.query(sql, (err, results) => {
    if (err) return res.status(500).json({ msg: "Error fetching summaries", err });
    res.status(200).json(results);
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
// ==========================================
// 📅 WEEKLY CAREGIVER REPORTS
// ==========================================





// 🧾 View weekly reports (optional filters)
exports.getWeeklyReports = (req, res) => {
  const { caregiver_id, from, to } = req.query;

  let sql = `
    SELECT wr.*, c.name AS caregiver_name, e.name AS elder_name
    FROM weekly_reports wr
    JOIN caregivers c ON wr.caregiver_id = c.caregiver_id
    JOIN elders e ON wr.elder_id = e.elder_id
  `;

  const filters = [];
  const params = [];

  if (caregiver_id) {
    filters.push("wr.caregiver_id = ?");
    params.push(caregiver_id);
  }
  if (from && to) {
    filters.push("DATE(wr.created_at) BETWEEN ? AND ?");
    params.push(from, to);
  }

  if (filters.length) sql += " WHERE " + filters.join(" AND ");
  sql += " ORDER BY wr.created_at DESC";

  db.query(sql, params, (err, results) => {
    if (err) return res.status(500).json({ msg: "Error fetching reports", err });
    res.status(200).json({
      msg: "Weekly caregiver reports retrieved successfully",
      reports: results
    });
  });
};

// 📤 Export reports as CSV
exports.exportWeeklyReports = (req, res) => {
  db.query(
    `
    SELECT wr.report_id, c.name AS caregiver_name, e.name AS elder_name,
           wr.week_start, wr.week_end, wr.summary, wr.ai_feedback, wr.created_at
    FROM weekly_reports wr
    JOIN caregivers c ON wr.caregiver_id = c.caregiver_id
    JOIN elders e ON wr.elder_id = e.elder_id
    ORDER BY wr.created_at DESC
    `,
    (err, results) => {
      if (err) return res.status(500).json({ msg: "Error exporting reports", err });
      if (!results || results.length === 0)
        return res.status(404).json({ msg: "No reports found to export" });

      try {
        const parser = new Parser();
        const csv = parser.parse(results);
        res.header("Content-Type", "text/csv");
        res.attachment("weekly_reports.csv");
        res.send(csv);
      } catch (error) {
        res.status(500).json({ msg: "Error generating CSV", error });
      }
    }
  );
};


// 🤖 AI analysis of a specific report
exports.analyzeWeeklyReport = async (req, res) => {
  const { report_id } = req.params;

  db.query(
    "SELECT summary FROM weekly_reports WHERE report_id = ?",
    [report_id],
    async (err, results) => {
      if (err) return res.status(500).json({ msg: "Error fetching report", err });
      if (results.length === 0) return res.status(404).json({ msg: "Report not found" });

      const summary = results[0].summary;
      const prompt = `
You are a senior healthcare assistant AI.
Analyze the caregiver’s weekly report and identify:
- Elder's overall health and emotional state
- Any potential warning signs
- One actionable recommendation

Return in JSON:
{
  "feedback": "short summary",
  "risk_level": "low" | "medium" | "high"
}

Weekly Report:
${summary}
`;

      try {
        const aiResponse = await openai.chat.completions.create({
          model: "gpt-4o-mini",
          messages: [{ role: "user", content: prompt }],
          temperature: 0.3
        });

        const text = aiResponse.choices[0].message.content;
        let feedback = {};
        try {
          feedback = JSON.parse(text);
        } catch {
          feedback = { feedback: text, risk_level: "unknown" };
        }

        db.query(
          "UPDATE weekly_reports SET ai_feedback = ? WHERE report_id = ?",
          [feedback.feedback, report_id]
        );

        res.status(200).json({
          msg: "AI analysis complete",
          analysis: feedback
        });
      } catch (error) {
        console.error("AI error:", error);
        res.status(500).json({ msg: "Failed to analyze report", error });
      }
    }
  );
};


// ===============================
// 📊 ADMIN FINANCIAL DASHBOARD (with date filters)
// ===============================

// 🧾 Helper: build WHERE clause dynamically
function buildDateFilter(from, to) {
  let filter = "";
  const params = [];

  if (from && to) {
    filter = "WHERE DATE(created_at) BETWEEN ? AND ?";
    params.push(from, to);
  } else if (from) {
    filter = "WHERE DATE(created_at) >= ?";
    params.push(from);
  } else if (to) {
    filter = "WHERE DATE(created_at) <= ?";
    params.push(to);
  }

  return { filter, params };
}

// 🧾 1️⃣ Total platform overview
// 🧾 1️⃣ Total platform overview (fixed)
exports.getFinancialOverview = (req, res) => {
  const { from, to } = req.query;
  const { filter, params } = buildDateFilter(from, to);

  // Add "WHERE" if filter is empty (so we can safely add AND later)
  const txFilter = filter ? `${filter} AND` : "WHERE";

  const sql = `
    SELECT
      (SELECT COUNT(*) FROM payments ${filter}) AS total_payments,
      (SELECT SUM(amount) FROM payments ${filter}) AS total_revenue,
      (SELECT COUNT(*) FROM transactions ${filter}) AS total_transactions,
      (SELECT SUM(amount) FROM transactions ${txFilter} type='platform_fee') AS platform_revenue,
      (SELECT SUM(amount) FROM transactions ${txFilter} type='payout') AS caregiver_payouts
  `;

  db.query(sql, [...params, ...params, ...params, ...params, ...params], (err, results) => {
    if (err) return res.status(500).json({ msg: "Error fetching overview", err });
    res.status(200).json({
      msg: "Financial overview retrieved successfully",
      overview: results[0],
      date_range: { from, to },
    });
  });
};

// 💳 2️⃣ Revenue grouped by role
exports.getRevenueByRole = (req, res) => {
  const { from, to } = req.query;
  const { filter, params } = buildDateFilter(from, to);

  const sql = `
    SELECT
      to_role AS role,
      SUM(amount) AS total_earned
    FROM transactions
    ${filter}
    GROUP BY to_role
    ORDER BY total_earned DESC
  `;
  db.query(sql, params, (err, results) => {
    if (err) return res.status(500).json({ msg: "Error fetching revenue by role", err });
    res.status(200).json({
      msg: "Revenue per role retrieved successfully",
      results,
      date_range: { from, to }
    });
  });
};

// 👥 3️⃣ Active users by role (unfiltered)
exports.getUserStats = (req, res) => {
  const sql = `
    SELECT 'caregivers' AS role, COUNT(*) AS total FROM caregivers
    UNION ALL
    SELECT 'family_members', COUNT(*) FROM family_members
    UNION ALL
    SELECT 'retirement_homes', COUNT(*) FROM retirement_homes
    UNION ALL
    SELECT 'elders', COUNT(*) FROM elders
  `;
  db.query(sql, (err, results) => {
    if (err) return res.status(500).json({ msg: "Error fetching user stats", err });
    res.status(200).json({
      msg: "User stats retrieved successfully",
      results
    });
  });
};

// 💸 4️⃣ Pending vs completed payments
exports.getPaymentStatusStats = (req, res) => {
  const { from, to } = req.query;
  const { filter, params } = buildDateFilter(from, to);

  const sql = `
    SELECT status, COUNT(*) AS total
    FROM payments
    ${filter}
    GROUP BY status
  `;
  db.query(sql, params, (err, results) => {
    if (err) return res.status(500).json({ msg: "Error fetching payment stats", err });
    res.status(200).json({
      msg: "Payment status stats retrieved successfully",
      results,
      date_range: { from, to }
    });
  });
};

// 📊 Admin Analytics Dashboard
exports.getAdminAnalytics = (req, res) => {
  try {
    const queries = {
      totalUsersByRole: `
        SELECT 'caregiver' AS role, COUNT(*) AS count FROM caregivers
        UNION ALL
        SELECT 'retirement_home', COUNT(*) FROM retirement_homes
        UNION ALL
        SELECT 'family', COUNT(*) FROM family_members
        UNION ALL
        SELECT 'elder', COUNT(*) FROM elders;
      `,
      activeCaregivers: `
        SELECT COUNT(*) AS active_caregivers FROM caregivers WHERE status = 'active';
      `,
      pendingApprovals: `
        SELECT 
          (SELECT COUNT(*) FROM caregivers WHERE is_approved = 0) +
          (SELECT COUNT(*) FROM retirement_homes WHERE is_approved = 0)
          AS pending_approvals;
      `,
      elderAssignments: `
        SELECT 
          (SELECT COUNT(*) FROM elder_assignments) AS assigned,
          (SELECT COUNT(*) FROM elders) - (SELECT COUNT(*) FROM elder_assignments) AS unassigned;
      `,
      averageHealthMetrics: `
        SELECT 
          ROUND(AVG(SUBSTRING_INDEX(blood_pressure, '/', 1))) AS avg_systolic,
          ROUND(AVG(SUBSTRING_INDEX(blood_pressure, '/', -1))) AS avg_diastolic,
          ROUND(AVG(CAST(REPLACE(blood_sugar, ' mg/dL', '') AS DECIMAL(5,2)))) AS avg_blood_sugar,
          ROUND(AVG(CAST(REPLACE(temperature, '°C', '') AS DECIMAL(4,2))), 1) AS avg_temperature
        FROM health_logs;
      `,
      weeklyReportsCount: `
        SELECT COUNT(*) AS weekly_reports FROM weekly_reports;
      `
    };

    const results = {};

    // Execute all queries in parallel
    const promises = Object.entries(queries).map(([key, sql]) => {
      return new Promise((resolve, reject) => {
        db.query(sql, (err, rows) => {
          if (err) return reject(err);
          results[key] = rows;
          resolve();
        });
      });
    });

    Promise.all(promises)
      .then(() => {
        res.status(200).json({
          msg: "Admin analytics retrieved successfully",
          analytics: results,
        });
      })
      .catch((err) => {
        console.error("❌ Error fetching analytics:", err);
        res.status(500).json({ msg: "Error retrieving analytics", error: err });
      });

  } catch (error) {
    console.error("❌ Server error in getAdminAnalytics:", error);
    res.status(500).json({ msg: "Server error", error });
  }
};
//helth alerts
exports.getHealthAlerts = (req, res) => {
  const sql = `
    SELECT id, type, message, is_read, created_at
    FROM admin_notifications
    WHERE type = 'health_alert'
    ORDER BY created_at DESC
  `;
  db.query(sql, (err, results) => {
    if (err) return res.status(500).json({ msg: "Error fetching health alerts", err });
    res.status(200).json({ msg: "Health alerts retrieved", alerts: results });
  });
};
// 🧭 GPS: overview for all elders
exports.getElderLocationOverview = (req, res) => {
  const sql = `
    SELECT 
      e.elder_id,
      e.name AS elder_name,
      MAX(l.recorded_at) AS last_seen,
      l.latitude,
      l.longitude
    FROM elders e
    LEFT JOIN elder_location l ON e.elder_id = l.elder_id
    GROUP BY e.elder_id
    ORDER BY last_seen DESC;
  `;

  db.query(sql, (err, rows) => {
    if (err) {
      console.error("Error fetching GPS overview:", err);
      return res
        .status(500)
        .json({ msg: "Error fetching GPS overview", err });
    }

    res.status(200).json({
      msg: "Elder GPS overview retrieved",
      data: rows,
    });
  });
};

// 🕒 GPS: full location history for one elder
exports.getElderLocationHistory = (req, res) => {
  const { elder_id } = req.params;

  const sql = `
    SELECT 
      location_id,
      elder_id,
      latitude,
      longitude,
      recorded_at
    FROM elder_location
    WHERE elder_id = ?
    ORDER BY recorded_at DESC
    LIMIT 200;
  `;

  db.query(sql, [elder_id], (err, rows) => {
    if (err) {
      console.error("Error fetching GPS history:", err);
      return res
        .status(500)
        .json({ msg: "Error fetching GPS history", err });
    }

    res.status(200).json({
      msg: "Elder GPS history retrieved",
      elder_id,
      history: rows,
    });
  });
};
exports.getAdminOverview = (req, res) => {
  const data = {
    users: {},
    health: {},
    gps: {},
    community: {},
    finance: {}
  };

  // 1) User stats
  const userSql = `
    SELECT 
      (SELECT COUNT(*) FROM elders) AS total_elders,
      (SELECT COUNT(*) FROM caregivers) AS total_caregivers,
      (SELECT COUNT(*) FROM caregivers WHERE is_approved = 0) AS pending_caregivers,
      (SELECT COUNT(*) FROM family_members) AS total_families,
      (SELECT COUNT(*) FROM retirement_homes WHERE is_approved = 0) AS pending_homes
  `;

  db.query(userSql, (err, rows) => {
    if (err) return res.status(500).json({ msg: "Users summary error", err });
    data.users = rows[0];

    // 2) Health alerts
    const healthSql = `
      SELECT 
        (SELECT COUNT(*) FROM admin_notifications WHERE type='health_alert') AS total_alerts,
        (SELECT COUNT(*) FROM admin_notifications WHERE type='health_alert' AND status='open') AS open_alerts,
        (SELECT COUNT(*) FROM admin_notifications WHERE severity='critical') AS critical_alerts
    `;

    db.query(healthSql, (err2, rows2) => {
      if (err2) return res.status(500).json({ msg: "Health summary error", err2 });
      data.health = rows2[0];

      // Also fetch last 5 alerts
      const lastAlertsSql = `
        SELECT id, message, severity, created_at
        FROM admin_notifications
        WHERE type='health_alert'
        ORDER BY created_at DESC
        LIMIT 5
      `;
      db.query(lastAlertsSql, (err3, alerts) => {
        data.health.recent = alerts;

        // 3) GPS stats
        const gpsSql = `
          SELECT COUNT(*) AS breaches_today
          FROM elder_safe_zones
          WHERE status='breached'
            AND DATE(updated_at) = CURDATE()
        `;
        db.query(gpsSql, (err4, rows4) => {
          data.gps.breaches_today = rows4 ? rows4[0].breaches_today : 0;

          // last known locations
          const locationsSql = `
            SELECT elder_id, latitude, longitude, recorded_at
            FROM elder_location
            ORDER BY recorded_at DESC
          `;
          db.query(locationsSql, (err5, locs) => {
            data.gps.last_locations = locs || [];

            // 4) Community stats
            const communitySql = `
              SELECT 
                (SELECT COUNT(*) FROM community_posts) AS total_posts,
                (SELECT COUNT(*) FROM community_posts WHERE is_approved = 0) AS pending_posts
            `;
            db.query(communitySql, (err6, rows6) => {
              data.community = rows6[0];

              // 5) Finance stats
              const financeSql = `
                SELECT 
                  (SELECT SUM(amount) FROM transactions WHERE type='platform_fee') AS total_revenue,
                  (SELECT SUM(amount) FROM transactions WHERE DATE(created_at)=CURDATE()) AS revenue_today,
                  (SELECT SUM(amount) FROM transactions WHERE MONTH(created_at)=MONTH(CURDATE())) AS revenue_month
              `;
              db.query(financeSql, (err7, rows7) => {
                data.finance = rows7[0];

                return res.status(200).json({
                  msg: "Admin overview loaded",
                  overview: data
                });
              });
            });
          });
        });
      });
    });
  });
};

// 📊 Health alerts timeline (last 30 days)
exports.getHealthAlertsTimeline = (req, res) => {
  const sql = `
    SELECT 
      DATE(created_at) AS day,
      SUM(CASE WHEN severity = 'critical' THEN 1 ELSE 0 END) AS critical_count,
      SUM(CASE WHEN severity = 'warning' THEN 1 ELSE 0 END) AS warning_count,
      COUNT(*) AS total_alerts
    FROM admin_notifications
    WHERE type = 'health_alert'
      AND created_at >= DATE_SUB(CURDATE(), INTERVAL 30 DAY)
    GROUP BY DATE(created_at)
    ORDER BY day ASC
  `;

  db.query(sql, (err, rows) => {
    if (err) {
      console.error("Error fetching health alerts timeline:", err);
      return res.status(500).json({ msg: "Error fetching health alerts timeline", err });
    }

    res.status(200).json({
      msg: "Health alerts timeline loaded",
      data: rows, // [{ day: '2025-02-01', critical_count: 2, warning_count: 3, total_alerts: 5 }, ...]
    });
  });
};
// 📊 Revenue timeline (last 30 days)
exports.getRevenueTimeline = (req, res) => {
  const sql = `
    SELECT 
      DATE(created_at) AS day,
      SUM(CASE WHEN type = 'platform_fee' THEN amount ELSE 0 END) AS platform_revenue,
      SUM(CASE WHEN type = 'payout' THEN amount ELSE 0 END) AS payouts
    FROM transactions
    WHERE created_at >= DATE_SUB(CURDATE(), INTERVAL 30 DAY)
    GROUP BY DATE(created_at)
    ORDER BY day ASC
  `;

  db.query(sql, (err, rows) => {
    if (err) {
      console.error("Error fetching revenue timeline:", err);
      return res.status(500).json({ msg: "Error fetching revenue timeline", err });
    }

    res.status(200).json({
      msg: "Revenue timeline loaded",
      data: rows, // [{ day: '2025-02-01', platform_revenue: 30.5, payouts: 250.0 }, ...]
    });
  });
};
// 📊 User growth timeline (last 12 months, by role)
exports.getUserGrowthTimeline = (req, res) => {
  const sql = `
    SELECT role, ym, SUM(cnt) AS count
    FROM (
      SELECT 'elder' AS role,
             DATE_FORMAT(created_at, '%Y-%m') AS ym,
             COUNT(*) AS cnt
      FROM elders
      WHERE created_at >= DATE_SUB(CURDATE(), INTERVAL 12 MONTH)
      GROUP BY ym

      UNION ALL

      SELECT 'caregiver' AS role,
             DATE_FORMAT(created_at, '%Y-%m') AS ym,
             COUNT(*) AS cnt
      FROM caregivers
      WHERE created_at >= DATE_SUB(CURDATE(), INTERVAL 12 MONTH)
      GROUP BY ym

      UNION ALL

      SELECT 'family' AS role,
             DATE_FORMAT(created_at, '%Y-%m') AS ym,
             COUNT(*) AS cnt
      FROM family_members
      WHERE created_at >= DATE_SUB(CURDATE(), INTERVAL 12 MONTH)
      GROUP BY ym

      UNION ALL

      SELECT 'retirement_home' AS role,
             DATE_FORMAT(created_at, '%Y-%m') AS ym,
             COUNT(*) AS cnt
      FROM retirement_homes
      WHERE created_at >= DATE_SUB(CURDATE(), INTERVAL 12 MONTH)
      GROUP BY ym
    ) AS t
    GROUP BY role, ym
    ORDER BY ym ASC, role ASC
  `;

  db.query(sql, (err, rows) => {
    if (err) {
      console.error("Error fetching user growth timeline:", err);
      return res.status(500).json({ msg: "Error fetching user growth timeline", err });
    }

    res.status(200).json({
      msg: "User growth timeline loaded",
      data: rows,
      /*
        Example:
        [
          { role: 'elder', ym: '2025-01', count: 3 },
          { role: 'family', ym: '2025-01', count: 5 },
          { role: 'caregiver', ym: '2025-02', count: 2 },
          ...
        ]
      */
    });
  });
};


exports.searchAllUsers = (req, res) => {
  const query = req.query.name || '';
  const sql = `SELECT * FROM master_user_list WHERE name LIKE ? LIMIT 20`;
  
  db.query(sql, [`%${query}%`], (err, results) => {
    if (err) return res.status(500).json({ msg: "Search failed", err });
    res.status(200).json(results);
  });
};





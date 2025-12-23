const db = require("../config/db");
const bcrypt = require("bcryptjs");

// --------------------
// 1) Profile
// --------------------
exports.getDashboard = (req, res) => {
  res.status(200).json({ msg: "Family dashboard working ✅", family_id: req.user.id });
};

exports.getMyProfile = (req, res) => {
  const familyId = req.user.id;
  db.query(
    `SELECT family_id, name, email, phone, city, budget, preference, skills_required, hours_needed, created_at
     FROM family_members
     WHERE family_id = ?`,
    [familyId],
    (err, rows) => {
      if (err) return res.status(500).json({ msg: "Error fetching profile", err });
      if (!rows.length) return res.status(404).json({ msg: "Family not found" });
      res.status(200).json({ profile: rows[0] });
    }
  );
};

exports.updateProfile = (req, res) => {
  const familyId = req.user.id;
  const { name, phone, city, budget, preference, skills_required, hours_needed } = req.body || {};

  const sql = `
    UPDATE family_members
    SET
      name = COALESCE(?, name),
      phone = COALESCE(?, phone),
      city = COALESCE(?, city),
      budget = COALESCE(?, budget),
      preference = COALESCE(?, preference),
      skills_required = COALESCE(?, skills_required),
      hours_needed = COALESCE(?, hours_needed)
    WHERE family_id = ?
  `;

  db.query(
    sql,
    [name || null, phone || null, city || null, budget ?? null, preference || null, skills_required || null, hours_needed ?? null, familyId],
    (err, result) => {
      if (err) return res.status(500).json({ msg: "Error updating profile", err });
      res.status(200).json({ msg: "Profile updated ✅" });
    }
  );
};

// --------------------
// 2) Elder account management (family creates elder)
// Tables used: elders + elder_family
// --------------------
exports.createElder = (req, res) => {
  const familyId = req.user.id;
  const { name, dob, gender, age, relation, is_primary } = req.body || {};

  if (!name) return res.status(400).json({ msg: "name is required" });

  const insertElderSql = `
    INSERT INTO elders (name, dob, gender, age, home_id, location)
    VALUES (?, ?, ?, ?, NULL, NULL)
  `;

  db.query(insertElderSql, [name, dob || null, gender || null, age ?? null], (err, result) => {
    if (err) return res.status(500).json({ msg: "Error creating elder", err });

    const elderId = result.insertId;

    const linkSql = `
      INSERT INTO elder_family (elder_id, family_id, relation, is_primary)
      VALUES (?, ?, ?, ?)
    `;
    db.query(linkSql, [elderId, familyId, relation || null, is_primary ? 1 : 1], (err2) => {
      if (err2) return res.status(500).json({ msg: "Elder created but linking failed", err: err2 });

      res.status(201).json({
        msg: "Elder account created ✅",
        elder_id: elderId,
      });
    });
  });
};

exports.listMyElders = (req, res) => {
  const familyId = req.user.id;

  const sql = `
    SELECT e.elder_id, e.name, e.dob, e.gender, e.age, e.home_id, e.location, e.last_check_in, e.created_at,
           ef.relation, ef.is_primary
    FROM elder_family ef
    JOIN elders e ON e.elder_id = ef.elder_id
    WHERE ef.family_id = ?
    ORDER BY ef.is_primary DESC, e.elder_id DESC
  `;

  db.query(sql, [familyId], (err, rows) => {
    if (err) return res.status(500).json({ msg: "Error fetching elders", err });
    res.status(200).json({ elders: rows });
  });
};

exports.getOneElder = (req, res) => {
  const familyId = req.user.id;
  const elderId = req.params.elder_id;

  const sql = `
    SELECT e.elder_id, e.name, e.dob, e.gender, e.age, e.home_id, e.location, e.last_check_in, e.created_at,
           ef.relation, ef.is_primary
    FROM elder_family ef
    JOIN elders e ON e.elder_id = ef.elder_id
    WHERE ef.family_id = ? AND e.elder_id = ?
    LIMIT 1
  `;

  db.query(sql, [familyId, elderId], (err, rows) => {
    if (err) return res.status(500).json({ msg: "Error fetching elder", err });
    if (!rows.length) return res.status(404).json({ msg: "Elder not found for this family" });
    res.status(200).json({ elder: rows[0] });
  });
};

exports.updateElder = (req, res) => {
  const familyId = req.user.id;
  const elderId = req.params.elder_id;
  const { name, dob, gender, age, location } = req.body || {};

  // UPDATE with JOIN ensures family ownership in the same query
  const sql = `
    UPDATE elders e
    JOIN elder_family ef ON ef.elder_id = e.elder_id
    SET
      e.name = COALESCE(?, e.name),
      e.dob = COALESCE(?, e.dob),
      e.gender = COALESCE(?, e.gender),
      e.age = COALESCE(?, e.age),
      e.location = COALESCE(?, e.location)
    WHERE ef.family_id = ? AND e.elder_id = ?
  `;

  db.query(sql, [name || null, dob || null, gender || null, age ?? null, location || null, familyId, elderId], (err, result) => {
    if (err) return res.status(500).json({ msg: "Error updating elder", err });
    if (!result.affectedRows) return res.status(404).json({ msg: "Elder not found for this family" });
    res.status(200).json({ msg: "Elder updated ✅" });
  });
};


// --------------------
// 3) Matching + selection
// Uses: family_members + caregivers/retirement_homes + matches + elder_assignments + elders.home_id
// --------------------
exports.runMatch = (req, res) => {
  const familyId = req.user.id;

  db.query("SELECT * FROM family_members WHERE family_id = ?", [familyId], (err, families) => {
    if (err) return res.status(500).json({ msg: "DB error fetching family", err });
    if (!families.length) return res.status(404).json({ msg: "Family not found" });

    const family = families[0];
    const { preference, city, budget } = family;

    if (!preference || !city || !budget) {
      return res.status(400).json({ msg: "Incomplete family data for matching (need preference/city/budget)." });
    }

    let sql, params;

    if (preference === "caregiver") {
      sql = `
        SELECT caregiver_id AS id, name, city, skills, expected_salary, hours_per_day,
          (100 -
            (ABS(expected_salary - ?) / ? * 40) -
            (CASE WHEN city = ? THEN 0 ELSE 20 END)
          ) AS score
        FROM caregivers
        WHERE is_approved = 1
        ORDER BY score DESC
        LIMIT 5
      `;
      params = [budget, budget, city];
    } else {
      sql = `
        SELECT home_id AS id, name, city, monthly_cost,
          (100 -
            (ABS(monthly_cost - ?) / ? * 40) -
            (CASE WHEN city = ? THEN 0 ELSE 20 END)
          ) AS score
        FROM retirement_homes
        WHERE is_approved = 1
        ORDER BY score DESC
        LIMIT 5
      `;
      params = [budget, budget, city];
    }

    db.query(sql, params, (err2, matches) => {
      if (err2) return res.status(500).json({ msg: "Error running match query", err: err2 });
      if (!matches.length) return res.status(404).json({ msg: "No suitable matches found." });

      // Save top match
      const top = matches[0];
      db.query(
        "INSERT INTO matches (family_id, matched_id, matched_role, score) VALUES (?, ?, ?, ?)",
        [familyId, top.id, preference, top.score],
        (insertErr) => {
          if (insertErr) console.error("Failed to save match:", insertErr);
        }
      );

      res.status(200).json({ msg: `Top ${matches.length} matches found`, matches });
    });
  });
};

exports.getMatches = (req, res) => {
  const familyId = req.user.id;
  db.query(
    `SELECT * FROM matches WHERE family_id = ? ORDER BY created_at DESC`,
    [familyId],
    (err, rows) => {
      if (err) return res.status(500).json({ msg: "Error fetching matches", err });
      res.status(200).json({ matches: rows });
    }
  );
};

exports.assignCaregiver = (req, res) => {
  const familyId = req.user.id;
  const { elder_id, caregiver_id } = req.body || {};
  if (!elder_id || !caregiver_id) return res.status(400).json({ msg: "elder_id and caregiver_id are required" });

  // Ensure elder belongs to family first
  db.query(
    `SELECT 1 FROM elder_family WHERE family_id = ? AND elder_id = ? LIMIT 1`,
    [familyId, elder_id],
    (err, ok) => {
      if (err) return res.status(500).json({ msg: "DB error", err });
      if (!ok.length) return res.status(403).json({ msg: "Access denied: elder not linked to this family" });

      const sql = `
        INSERT INTO elder_assignments (elder_id, caregiver_id, home_id, assigned_by)
        VALUES (?, ?, NULL, ?)
      `;
      db.query(sql, [elder_id, caregiver_id, familyId], (err2, result) => {
        if (err2) return res.status(500).json({ msg: "Error assigning caregiver", err: err2 });
        res.status(201).json({ msg: "Caregiver assigned ✅", assignment_id: result.insertId });
      });
    }
  );
};

exports.selectHome = (req, res) => {
  const familyId = req.user.id;
  const { elder_id, home_id } = req.body || {};
  if (!elder_id || !home_id) return res.status(400).json({ msg: "elder_id and home_id are required" });

  db.query(
    `SELECT 1 FROM elder_family WHERE family_id = ? AND elder_id = ? LIMIT 1`,
    [familyId, elder_id],
    (err, ok) => {
      if (err) return res.status(500).json({ msg: "DB error", err });
      if (!ok.length) return res.status(403).json({ msg: "Access denied: elder not linked to this family" });

      // Update elders.home_id
      db.query(`UPDATE elders SET home_id = ? WHERE elder_id = ?`, [home_id, elder_id], (err2) => {
        if (err2) return res.status(500).json({ msg: "Error linking elder to home", err: err2 });

        // Add assignment row too (home assignment)
        const sql = `
          INSERT INTO elder_assignments (elder_id, caregiver_id, home_id, assigned_by)
          VALUES (?, NULL, ?, ?)
        `;
        db.query(sql, [elder_id, home_id, familyId], (err3, result) => {
          if (err3) return res.status(500).json({ msg: "Home linked but assignment insert failed", err: err3 });
          res.status(201).json({ msg: "Retirement home selected ✅", assignment_id: result.insertId });
        });
      });
    }
  );
};

exports.getAssignments = (req, res) => {
  const familyId = req.user.id;
  const sql = `
    SELECT ea.*
    FROM elder_assignments ea
    WHERE ea.elder_id IN (SELECT elder_id FROM elder_family WHERE family_id = ?)
    ORDER BY ea.assigned_at DESC
  `;
  db.query(sql, [familyId], (err, rows) => {
    if (err) return res.status(500).json({ msg: "Error fetching assignments", err });
    res.status(200).json({ assignments: rows });
  });
};

// --------------------
// 4) Monitoring: health, meds, alerts
// --------------------
exports.getHealthLogs = (req, res) => {
  const elderId = req.elder_id;
  db.query(
    `SELECT * FROM health_logs WHERE elder_id = ? ORDER BY date DESC, log_id DESC`,
    [elderId],
    (err, rows) => {
      if (err) return res.status(500).json({ msg: "Error fetching health logs", err });
      res.status(200).json({ health_logs: rows });
    }
  );
};

exports.getMedications = (req, res) => {
  const elderId = req.elder_id;
  db.query(
    `SELECT * FROM medications WHERE elder_id = ? ORDER BY active DESC, medication_id DESC`,
    [elderId],
    (err, rows) => {
      if (err) return res.status(500).json({ msg: "Error fetching medications", err });
      res.status(200).json({ medications: rows });
    }
  );
};

exports.getMedicationLogs = (req, res) => {
  const elderId = req.elder_id;
  const sql = `
    SELECT ml.*, m.name AS medication_name, m.dosage, m.frequency
    FROM medication_logs ml
    JOIN medications m ON m.medication_id = ml.medication_id
    WHERE ml.elder_id = ?
    ORDER BY ml.created_at DESC
  `;
  db.query(sql, [elderId], (err, rows) => {
    if (err) return res.status(500).json({ msg: "Error fetching medication logs", err });
    res.status(200).json({ medication_logs: rows });
  });
};

exports.getMedicationStats = (req, res) => {
  const elderId = req.elder_id;
  const from = req.query.from || "2000-01-01";
  const to = req.query.to || "2100-01-01";

  const sql = `
    SELECT
      SUM(CASE WHEN status='taken' THEN 1 ELSE 0 END) AS taken,
      SUM(CASE WHEN status='missed' THEN 1 ELSE 0 END) AS missed,
      SUM(CASE WHEN status='skipped' THEN 1 ELSE 0 END) AS skipped,
      COUNT(*) AS total
    FROM medication_logs
    WHERE elder_id = ?
      AND DATE(created_at) BETWEEN ? AND ?
  `;
  db.query(sql, [elderId, from, to], (err, rows) => {
    if (err) return res.status(500).json({ msg: "Error fetching stats", err });
    res.status(200).json({ stats: rows[0] });
  });
};

// Alerts: based on schema you currently have -> incidents + emergency_requests
exports.getAlertsAll = (req, res) => {
  const familyId = req.user.id;

  const sql = `
    SELECT 'incident' AS alert_type,
           i.incident_id AS id,
           i.elder_id,
           i.type,
           i.severity,
           i.status,
           i.title,
           i.created_at
    FROM incidents i
    WHERE i.elder_id IN (SELECT elder_id FROM elder_family WHERE family_id = ?)

    UNION ALL

    SELECT 'emergency' AS alert_type,
           er.emergency_id AS id,
           er.elder_id,
           er.emergency_type AS type,
           er.severity,
           er.status,
           er.address_text AS title,
           er.created_at
    FROM emergency_requests er
    WHERE er.elder_id IN (SELECT elder_id FROM elder_family WHERE family_id = ?)

    ORDER BY created_at DESC
  `;

  db.query(sql, [familyId, familyId], (err, rows) => {
    if (err) return res.status(500).json({ msg: "Error fetching alerts", err });
    res.status(200).json({ alerts: rows });
  });
};

exports.getElderAlerts = (req, res) => {
  const elderId = req.elder_id;

  const sql = `
    SELECT 'incident' AS alert_type,
           i.incident_id AS id,
           i.elder_id,
           i.type,
           i.severity,
           i.status,
           i.title,
           i.created_at
    FROM incidents i
    WHERE i.elder_id = ?

    UNION ALL

    SELECT 'emergency' AS alert_type,
           er.emergency_id AS id,
           er.elder_id,
           er.emergency_type AS type,
           er.severity,
           er.status,
           er.address_text AS title,
           er.created_at
    FROM emergency_requests er
    WHERE er.elder_id = ?

    ORDER BY created_at DESC
  `;

  db.query(sql, [elderId, elderId], (err, rows) => {
    if (err) return res.status(500).json({ msg: "Error fetching elder alerts", err });
    res.status(200).json({ alerts: rows });
  });
};

// --------------------
// 5) Location tracking
// --------------------
exports.getLatestLocation = (req, res) => {
  const elderId = req.elder_id;
  db.query(
    `SELECT * FROM elder_location WHERE elder_id = ? ORDER BY recorded_at DESC LIMIT 1`,
    [elderId],
    (err, rows) => {
      if (err) return res.status(500).json({ msg: "Error fetching location", err });
      if (!rows.length) return res.status(404).json({ msg: "No location found yet" });
      res.status(200).json({ latest: rows[0] });
    }
  );
};

exports.getLocationHistory = (req, res) => {
  const elderId = req.elder_id;
  db.query(
    `SELECT * FROM elder_location WHERE elder_id = ? ORDER BY recorded_at DESC`,
    [elderId],
    (err, rows) => {
      if (err) return res.status(500).json({ msg: "Error fetching location history", err });
      res.status(200).json({ history: rows });
    }
  );
};

exports.getSafeZones = (req, res) => {
  const elderId = req.elder_id;
  db.query(
    `SELECT * FROM elder_safe_zones WHERE elder_id = ? ORDER BY zone_id DESC`,
    [elderId],
    (err, rows) => {
      if (err) return res.status(500).json({ msg: "Error fetching safe zones", err });
      res.status(200).json({ zones: rows });
    }
  );
};

// --------------------
// 6) Visits scheduling (family requests)
// --------------------
exports.requestVisit = (req, res) => {
  const familyId = req.user.id;
  const elderId = req.elder_id;
  const { scheduled_at, duration_minutes, notes } = req.body || {};

  if (!scheduled_at) return res.status(400).json({ msg: "scheduled_at is required (YYYY-MM-DD HH:MM:SS)" });

  // determine home_id from elders table (since visits.home_id is NOT NULL)
  db.query(`SELECT home_id FROM elders WHERE elder_id = ?`, [elderId], (err, rows) => {
    if (err) return res.status(500).json({ msg: "DB error", err });
    if (!rows.length) return res.status(404).json({ msg: "Elder not found" });

    const homeId = rows[0].home_id;
    if (!homeId) return res.status(400).json({ msg: "Elder is not linked to a retirement home yet (home_id is NULL)" });

    const sql = `
      INSERT INTO visits (home_id, elder_id, family_id, scheduled_at, duration_minutes, status, notes, created_by_role, created_by_id)
      VALUES (?, ?, ?, ?, ?, 'pending', ?, 'family', ?)
    `;

    db.query(sql, [homeId, elderId, familyId, scheduled_at, duration_minutes || 60, notes || null, familyId], (err2, result) => {
      if (err2) return res.status(500).json({ msg: "Error requesting visit", err: err2 });
      res.status(201).json({ msg: "Visit request sent ✅", visit_id: result.insertId });
    });
  });
};

exports.getMyVisits = (req, res) => {
  const familyId = req.user.id;
  const sql = `
    SELECT v.*, e.name AS elder_name, rh.name AS home_name
    FROM visits v
    JOIN elders e ON e.elder_id = v.elder_id
    LEFT JOIN retirement_homes rh ON rh.home_id = v.home_id
    WHERE v.elder_id IN (SELECT elder_id FROM elder_family WHERE family_id = ?)
    ORDER BY v.scheduled_at DESC
  `;
  db.query(sql, [familyId], (err, rows) => {
    if (err) return res.status(500).json({ msg: "Error fetching visits", err });
    res.status(200).json({ visits: rows });
  });
};

exports.getElderVisits = (req, res) => {
  const familyId = req.user.id;
  const elderId = req.elder_id;

  const sql = `
    SELECT v.*, rh.name AS home_name
    FROM visits v
    LEFT JOIN retirement_homes rh ON rh.home_id = v.home_id
    WHERE v.elder_id = ?
      AND v.elder_id IN (SELECT elder_id FROM elder_family WHERE family_id = ?)
    ORDER BY v.scheduled_at DESC
  `;
  db.query(sql, [elderId, familyId], (err, rows) => {
    if (err) return res.status(500).json({ msg: "Error fetching elder visits", err });
    res.status(200).json({ visits: rows });
  });
};

// --------------------
// 7) Daily summaries (caregiver -> family)
// --------------------
exports.getTodaySummary = (req, res) => {
  const elderId = req.elder_id;
  const sql = `
    SELECT * FROM daily_summaries
    WHERE elder_id = ?
      AND summary_date = CURDATE()
    ORDER BY summary_id DESC
    LIMIT 1
  `;
  db.query(sql, [elderId], (err, rows) => {
    if (err) return res.status(500).json({ msg: "Error fetching today summary", err });
    res.status(200).json({ summary: rows[0] || null });
  });
};

exports.getSummariesRange = (req, res) => {
  const elderId = req.elder_id;
  const from = req.query.from || "2000-01-01";
  const to = req.query.to || "2100-01-01";

  const sql = `
    SELECT * FROM daily_summaries
    WHERE elder_id = ?
      AND summary_date BETWEEN ? AND ?
    ORDER BY summary_date DESC, summary_id DESC
  `;
  db.query(sql, [elderId, from, to], (err, rows) => {
    if (err) return res.status(500).json({ msg: "Error fetching summaries", err });
    res.status(200).json({ summaries: rows });
  });
};

// --------------------
// 9) Payments history (uses your payments + transactions tables)
// --------------------
exports.getPaymentHistory = (req, res) => {
  const familyId = req.user.id;
  db.query(
    `SELECT * FROM payments WHERE family_id = ? ORDER BY created_at DESC`,
    [familyId],
    (err, rows) => {
      if (err) return res.status(500).json({ msg: "Error fetching payments", err });
      res.status(200).json({ payments: rows });
    }
  );
};

exports.getTransactionHistory = (req, res) => {
  const familyId = req.user.id;
  db.query(
    `SELECT * FROM transactions WHERE from_role='family' AND from_id = ? ORDER BY created_at DESC`,
    [familyId],
    (err, rows) => {
      if (err) return res.status(500).json({ msg: "Error fetching transactions", err });
      res.status(200).json({ transactions: rows });
    }
  );
};

// --------------------
// 10) Gallery / Reviews / Calls
// Not in your current SQL schema -> keep as future work
// --------------------
exports.futureNotImplemented = (req, res) => {
  res.status(501).json({
    msg: "Not implemented yet (needs DB tables + integration).",
    hint: "Add tables for gallery_media, reviews, call_logs (or use Vonage/Twilio tokens).",
  });
};
//the elders account 
// Reset PIN (family-only, for elders they own)
exports.resetElderPin = async (req, res) => {
  const elderId = req.elder_id; // from ensureFamilyOwnsElder
  const { pin } = req.body || {};

  if (!pin || String(pin).length < 4) {
    return res.status(400).json({ msg: "PIN is required (min 4 digits)" });
  }

  try {
    const pinHash = await bcrypt.hash(String(pin), 10);

    db.query(
      "UPDATE elders SET pin_hash = ? WHERE elder_id = ?",
      [pinHash, elderId],
      (err, result) => {
        if (err) return res.status(500).json({ msg: "DB error", err });
        if (!result.affectedRows) return res.status(404).json({ msg: "Elder not found" });

        res.status(200).json({ msg: "Elder PIN reset ✅" });
      }
    );
  } catch (e) {
    return res.status(500).json({ msg: "Hashing error", err: e.message });
  }
};

// Consent toggle/set
exports.setElderConsent = (req, res) => {
  const elderId = req.elder_id;
  const { consent } = req.body || {};

  // If consent provided -> set it
  // If not provided -> toggle
  if (typeof consent === "boolean") {
    db.query(
      "UPDATE elders SET visibility_consent = ? WHERE elder_id = ?",
      [consent ? 1 : 0, elderId],
      (err, result) => {
        if (err) return res.status(500).json({ msg: "DB error", err });
        if (!result.affectedRows) return res.status(404).json({ msg: "Elder not found" });

        return res.status(200).json({ msg: "Consent updated ✅", visibility_consent: consent ? 1 : 0 });
      }
    );
    return;
  }

  // Toggle mode
  db.query(
    "UPDATE elders SET visibility_consent = 1 - visibility_consent WHERE elder_id = ?",
    [elderId],
    (err, result) => {
      if (err) return res.status(500).json({ msg: "DB error", err });
      if (!result.affectedRows) return res.status(404).json({ msg: "Elder not found" });

      db.query(
        "SELECT visibility_consent FROM elders WHERE elder_id = ?",
        [elderId],
        (err2, rows) => {
          if (err2) return res.status(500).json({ msg: "DB error", err: err2 });
          res.status(200).json({ msg: "Consent toggled ✅", visibility_consent: rows[0].visibility_consent });
        }
      );
    }
  );
};

// POST /api/family/calls/request
// Body: { elder_id, target_role: "elder"|"caregiver"|"retirement_home", type: "voice"|"video", notes? }
exports.requestCall = (req, res) => {
  const familyId = req.user.id;
  const { elder_id, target_role, type, notes } = req.body || {};

  if (!elder_id) return res.status(400).json({ msg: "elder_id is required" });
  if (!target_role || !["elder","caregiver","retirement_home"].includes(target_role))
    return res.status(400).json({ msg: "target_role must be elder/caregiver/retirement_home" });

  const callType = (type && ["voice","video"].includes(type)) ? type : "voice";

  // Ensure elder belongs to family
  db.query(
    "SELECT 1 FROM elder_family WHERE family_id = ? AND elder_id = ? LIMIT 1",
    [familyId, elder_id],
    (err, ok) => {
      if (err) return res.status(500).json({ msg: "DB error", err });
      if (!ok.length) return res.status(403).json({ msg: "Access denied: elder not linked to this family" });

      // Determine receiver_id based on target_role
      if (target_role === "elder") {
        return insertCallLog(familyId, elder_id, "elder", elder_id, callType, notes, res);
      }

      if (target_role === "caregiver") {
        const sql = `
          SELECT caregiver_id
          FROM elder_assignments
          WHERE elder_id = ? AND caregiver_id IS NOT NULL
          ORDER BY assigned_at DESC
          LIMIT 1
        `;
        return db.query(sql, [elder_id], (err2, rows) => {
          if (err2) return res.status(500).json({ msg: "DB error", err: err2 });
          if (!rows.length) return res.status(404).json({ msg: "No caregiver assigned to this elder" });

          return insertCallLog(familyId, elder_id, "caregiver", rows[0].caregiver_id, callType, notes, res);
        });
      }

      // target_role === "retirement_home"
      db.query("SELECT home_id FROM elders WHERE elder_id = ? LIMIT 1", [elder_id], (err3, rows) => {
        if (err3) return res.status(500).json({ msg: "DB error", err: err3 });
        if (!rows.length) return res.status(404).json({ msg: "Elder not found" });
        if (!rows[0].home_id) return res.status(404).json({ msg: "Elder is not linked to a retirement home" });

        return insertCallLog(familyId, elder_id, "retirement_home", rows[0].home_id, callType, notes, res);
      });
    }
  );
};

function insertCallLog(familyId, elderId, receiverRole, receiverId, callType, notes, res) {
  const sql = `
    INSERT INTO call_logs (family_id, elder_id, receiver_role, receiver_id, call_type, status, notes)
    VALUES (?, ?, ?, ?, ?, 'requested', ?)
  `;
  db.query(sql, [familyId, elderId, receiverRole, receiverId, callType, notes || null], (err, result) => {
    if (err) return res.status(500).json({ msg: "Error creating call request", err });
    res.status(201).json({
      msg: "Call request created ✅",
      call_id: result.insertId,
      receiver_role: receiverRole,
      receiver_id: receiverId,
      call_type: callType,
      status: "requested",
    });
  });
}

// GET /api/family/calls/history?elder_id=&from=&to=
exports.getCallHistory = (req, res) => {
  const familyId = req.user.id;
  const { elder_id, from, to } = req.query;

  let sql = `SELECT * FROM call_logs WHERE family_id = ?`;
  const params = [familyId];

  if (elder_id) {
    sql += ` AND elder_id = ?`;
    params.push(elder_id);
  }

  if (from && to) {
    sql += ` AND DATE(created_at) BETWEEN ? AND ?`;
    params.push(from, to);
  }

  sql += ` ORDER BY created_at DESC`;

  db.query(sql, params, (err, rows) => {
    if (err) return res.status(500).json({ msg: "Error fetching call history", err });
    res.status(200).json({ calls: rows });
  });
};

// GET /api/family/elders/:elder_id/caregiver-contact
exports.getCaregiverContact = (req, res) => {
  const elderId = req.elder_id; // from ensureFamilyOwnsElder

  const sql = `
    SELECT c.caregiver_id, c.name, c.phone, c.email, c.employment_type, c.home_id
    FROM elder_assignments ea
    JOIN caregivers c ON c.caregiver_id = ea.caregiver_id
    WHERE ea.elder_id = ? AND ea.caregiver_id IS NOT NULL
    ORDER BY ea.assigned_at DESC
    LIMIT 1
  `;

  db.query(sql, [elderId], (err, rows) => {
    if (err) return res.status(500).json({ msg: "Error fetching caregiver contact", err });
    if (!rows.length) return res.status(404).json({ msg: "No caregiver assigned to this elder" });
    res.status(200).json({ caregiver: rows[0] });
  });
};

// GET /api/family/elders/:elder_id/home-contact
exports.getHomeContact = (req, res) => {
  const elderId = req.elder_id;

  const sql = `
    SELECT rh.home_id, rh.name, rh.contact_phone, rh.contact_email, rh.address, rh.city
    FROM elders e
    JOIN retirement_homes rh ON rh.home_id = e.home_id
    WHERE e.elder_id = ?
    LIMIT 1
  `;

  db.query(sql, [elderId], (err, rows) => {
    if (err) return res.status(500).json({ msg: "Error fetching home contact", err });
    if (!rows.length) return res.status(404).json({ msg: "Elder is not linked to a retirement home" });
    res.status(200).json({ home: rows[0] });
  });
};
// POST /api/family/elders/:elder_id/gallery
exports.uploadGalleryMedia = (req, res) => {
  const familyId = req.user.id;
  const elderId = req.elder_id; // from ensureFamilyOwnsElder
  const caption = req.body?.caption || null;

  if (!req.file) return res.status(400).json({ msg: "No file uploaded (field name should be 'media')" });

  const mime = req.file.mimetype || "";
  const mediaType = mime.startsWith("video/") ? "video" : "photo";

  // store relative path so it works on any machine
  const filePath = `/uploads/gallery/${req.file.filename}`;

  db.query(
    `INSERT INTO elder_gallery (elder_id, uploaded_by_family_id, file_path, media_type, caption)
     VALUES (?, ?, ?, ?, ?)`,
    [elderId, familyId, filePath, mediaType, caption],
    (err, result) => {
      if (err) return res.status(500).json({ msg: "Error saving gallery media", err });

      res.status(201).json({
        msg: "Media uploaded ✅",
        media_id: result.insertId,
        elder_id: elderId,
        file_path: filePath,
        media_type: mediaType,
        caption,
      });
    }
  );
};

// GET /api/family/elders/:elder_id/gallery
exports.getElderGallery = (req, res) => {
  const elderId = req.elder_id;

  db.query(
    `SELECT media_id, elder_id, uploaded_by_family_id, file_path, media_type, caption, created_at
     FROM elder_gallery
     WHERE elder_id = ?
     ORDER BY created_at DESC, media_id DESC`,
    [elderId],
    (err, rows) => {
      if (err) return res.status(500).json({ msg: "Error fetching gallery", err });
      res.status(200).json({ gallery: rows });
    }
  );
};

// DELETE /api/family/gallery/:media_id  (ownership check)
exports.deleteGalleryMedia = (req, res) => {
  const familyId = req.user.id;
  const mediaId = Number(req.params.media_id);

  if (Number.isNaN(mediaId)) return res.status(400).json({ msg: "Invalid media_id" });

  db.query(
    `DELETE FROM elder_gallery
     WHERE media_id = ? AND uploaded_by_family_id = ?`,
    [mediaId, familyId],
    (err, result) => {
      if (err) return res.status(500).json({ msg: "Error deleting media", err });
      if (!result.affectedRows) return res.status(404).json({ msg: "Media not found or not owned by this family" });

      res.status(200).json({ msg: "Media deleted ✅" });
    }
  );
};
// POST /api/family/elders/:elder_id/daily-summary/:summary_id/comment
exports.addDailySummaryComment = (req, res) => {
  const familyId = req.user.id;
  const elderId = req.elder_id; // from ensureFamilyOwnsElder
  const summaryId = Number(req.params.summary_id);
  const { comment_text } = req.body || {};

  if (!comment_text || !comment_text.trim())
    return res.status(400).json({ msg: "comment_text is required" });

  if (Number.isNaN(summaryId))
    return res.status(400).json({ msg: "Invalid summary_id" });

  // Ensure summary belongs to that elder
  db.query(
    "SELECT 1 FROM daily_summaries WHERE summary_id = ? AND elder_id = ? LIMIT 1",
    [summaryId, elderId],
    (err, rows) => {
      if (err) return res.status(500).json({ msg: "DB error", err });
      if (!rows.length) return res.status(404).json({ msg: "Daily summary not found for this elder" });

      db.query(
        `INSERT INTO summary_comments (summary_id, elder_id, family_id, comment_text)
         VALUES (?, ?, ?, ?)`,
        [summaryId, elderId, familyId, comment_text.trim()],
        (err2, result) => {
          if (err2) return res.status(500).json({ msg: "Error saving comment", err: err2 });

          res.status(201).json({
            msg: "Comment added ✅",
            comment_id: result.insertId,
            summary_id: summaryId,
            elder_id: elderId,
          });
        }
      );
    }
  );
};

// (Optional but recommended) GET comments for a summary
exports.getDailySummaryComments = (req, res) => {
  const elderId = req.elder_id;
  const summaryId = Number(req.params.summary_id);

  if (Number.isNaN(summaryId)) return res.status(400).json({ msg: "Invalid summary_id" });

  db.query(
    `SELECT comment_id, summary_id, elder_id, family_id, comment_text, created_at
     FROM summary_comments
     WHERE summary_id = ? AND elder_id = ?
     ORDER BY created_at ASC`,
    [summaryId, elderId],
    (err, rows) => {
      if (err) return res.status(500).json({ msg: "Error fetching comments", err });
      res.status(200).json({ comments: rows });
    }
  );
};
// POST /api/family/elders/:elder_id/notes
exports.addFamilyNote = (req, res) => {
  const familyId = req.user.id;
  const elderId = req.elder_id;
  const { note_text } = req.body || {};

  if (!note_text || !note_text.trim())
    return res.status(400).json({ msg: "note_text is required" });

  db.query(
    `INSERT INTO family_notes (elder_id, family_id, note_text)
     VALUES (?, ?, ?)`,
    [elderId, familyId, note_text.trim()],
    (err, result) => {
      if (err) return res.status(500).json({ msg: "Error saving note", err });
      res.status(201).json({ msg: "Note added ✅", note_id: result.insertId });
    }
  );
};

// GET /api/family/elders/:elder_id/notes
exports.getFamilyNotes = (req, res) => {
  const familyId = req.user.id;
  const elderId = req.elder_id;

  db.query(
    `SELECT note_id, elder_id, family_id, note_text, created_at
     FROM family_notes
     WHERE elder_id = ? AND family_id = ?
     ORDER BY created_at DESC`,
    [elderId, familyId],
    (err, rows) => {
      if (err) return res.status(500).json({ msg: "Error fetching notes", err });
      res.status(200).json({ notes: rows });
    }
  );
};
// POST /api/family/reviews
// Body: { target_role: "caregiver"|"retirement_home", target_id: number, rating: 1..5, comment?: string }
exports.createReview = (req, res) => {
  const familyId = req.user.id;
  const { target_role, target_id, rating, comment } = req.body || {};

  if (!target_role || !["caregiver", "retirement_home"].includes(target_role)) {
    return res.status(400).json({ msg: "target_role must be caregiver or retirement_home" });
  }

  const targetIdNum = Number(target_id);
  const ratingNum = Number(rating);

  if (!targetIdNum || Number.isNaN(targetIdNum)) return res.status(400).json({ msg: "target_id is required" });
  if (Number.isNaN(ratingNum) || ratingNum < 1 || ratingNum > 5)
    return res.status(400).json({ msg: "rating must be between 1 and 5" });

  // Optional: prevent reviewing someone you never matched/assigned with
  // We'll do a minimal check:
  const allowSql =
    target_role === "caregiver"
      ? `SELECT 1
         FROM elder_family ef
         JOIN elder_assignments ea ON ea.elder_id = ef.elder_id
         WHERE ef.family_id = ? AND ea.caregiver_id = ?
         LIMIT 1`
      : `SELECT 1
         FROM elder_family ef
         JOIN elders e ON e.elder_id = ef.elder_id
         WHERE ef.family_id = ? AND e.home_id = ?
         LIMIT 1`;

  db.query(allowSql, [familyId, targetIdNum], (err, ok) => {
    if (err) return res.status(500).json({ msg: "DB error", err });
    if (!ok.length) {
      return res.status(403).json({
        msg: "You can only review a caregiver/home that served one of your elders.",
      });
    }

    db.query(
      `INSERT INTO reviews (family_id, target_role, target_id, rating, comment)
       VALUES (?, ?, ?, ?, ?)`,
      [familyId, target_role, targetIdNum, ratingNum, comment || null],
      (err2, result) => {
        if (err2) return res.status(500).json({ msg: "Error creating review", err: err2 });

        res.status(201).json({
          msg: "Review submitted ✅",
          review_id: result.insertId,
        });
      }
    );
  });
};

// GET /api/family/reviews (my submitted reviews)
exports.getMyReviews = (req, res) => {
  const familyId = req.user.id;

  db.query(
    `SELECT review_id, family_id, target_role, target_id, rating, comment, created_at
     FROM reviews
     WHERE family_id = ?
     ORDER BY created_at DESC, review_id DESC`,
    [familyId],
    (err, rows) => {
      if (err) return res.status(500).json({ msg: "Error fetching reviews", err });
      res.status(200).json({ reviews: rows });
    }
  );
};
// POST /api/family/emergency
// Body: { elder_id, emergency_type?, severity?, description? }
exports.createEmergencyRequest = (req, res) => {
  const familyId = req.user.id;
  const { elder_id, emergency_type, severity, description } = req.body || {};

  const elderIdNum = Number(elder_id);
  if (!elderIdNum || Number.isNaN(elderIdNum)) {
    return res.status(400).json({ msg: "elder_id is required" });
  }

  const type = emergency_type || "panic";
  const allowedSeverity = ["low", "medium", "high", "critical"];
  const sev = allowedSeverity.includes(severity) ? severity : "high";

  // Ensure elder belongs to this family
  db.query(
    "SELECT 1 FROM elder_family WHERE family_id = ? AND elder_id = ? LIMIT 1",
    [familyId, elderIdNum],
    (err, ok) => {
      if (err) return res.status(500).json({ msg: "DB error", err });
      if (!ok.length) return res.status(403).json({ msg: "Access denied: elder not linked to this family" });

      db.query(
        `INSERT INTO emergency_requests (elder_id, family_id, emergency_type, severity, status, description)
         VALUES (?, ?, ?, ?, 'open', ?)`,
        [elderIdNum, familyId, type, sev, description || null],
        (err2, result) => {
          if (err2) return res.status(500).json({ msg: "Error creating emergency request", err: err2 });

          res.status(201).json({
            msg: "Emergency request created 🚨",
            emergency_id: result.insertId,
            elder_id: elderIdNum,
            status: "open",
          });
        }
      );
    }
  );
};

// GET /api/family/emergency/history?elder_id=&status=&from=&to=
exports.getEmergencyHistory = (req, res) => {
  const familyId = req.user.id;
  const { elder_id, status, from, to } = req.query || {};

  let sql = `
    SELECT emergency_id, elder_id, family_id, emergency_type, severity, status, description, created_at, updated_at
    FROM emergency_requests
    WHERE family_id = ?
  `;
  const params = [familyId];

  if (elder_id) {
    sql += " AND elder_id = ?";
    params.push(Number(elder_id));
  }

  if (status) {
    sql += " AND status = ?";
    params.push(status);
  }

  if (from && to) {
    sql += " AND DATE(created_at) BETWEEN ? AND ?";
    params.push(from, to);
  }

  sql += " ORDER BY created_at DESC, emergency_id DESC";

  db.query(sql, params, (err, rows) => {
    if (err) return res.status(500).json({ msg: "Error fetching emergency history", err });
    res.status(200).json({ emergencies: rows });
  });
};
exports.cancelEmergencyRequest = (req, res) => {
  const familyId = req.user.id;
  const emergencyId = Number(req.params.emergency_id);

  if (Number.isNaN(emergencyId)) return res.status(400).json({ msg: "Invalid emergency_id" });

  db.query(
    `UPDATE emergency_requests
     SET status = 'cancelled'
     WHERE emergency_id = ? AND family_id = ? AND status = 'open'`,
    [emergencyId, familyId],
    (err, result) => {
      if (err) return res.status(500).json({ msg: "Error cancelling emergency", err });
      if (!result.affectedRows) {
        return res.status(404).json({ msg: "Emergency not found, not yours, or not open" });
      }
      res.status(200).json({ msg: "Emergency cancelled ✅" });
    }
  );
};
// POST /api/family/events
exports.createEvent = (req, res) => {
  const familyId = req.user.id;
  const {
    elder_id,
    title,
    description,
    event_type,
    start_time,
    end_time,
    is_all_day,
    location
  } = req.body || {};

  if (!title || !start_time) return res.status(400).json({ msg: "title and start_time are required" });

  const allowedTypes = ["birthday","family_event","appointment","visit","medication_refill","other"];
  const type = allowedTypes.includes(event_type) ? event_type : "family_event";

  // If elder_id provided, verify it belongs to this family
  const insert = () => {
    db.query(
      `INSERT INTO family_events
       (family_id, elder_id, title, description, event_type, start_time, end_time, is_all_day, location)
       VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)`,
      [
        familyId,
        elder_id || null,
        title,
        description || null,
        type,
        start_time,
        end_time || null,
        is_all_day ? 1 : 0,
        location || null
      ],
      (err, result) => {
        if (err) return res.status(500).json({ msg: "Error creating event", err });
        res.status(201).json({ msg: "Event created ✅", event_id: result.insertId });
      }
    );
  };

  if (!elder_id) return insert();

  db.query(
    "SELECT 1 FROM elder_family WHERE family_id = ? AND elder_id = ? LIMIT 1",
    [familyId, elder_id],
    (err, ok) => {
      if (err) return res.status(500).json({ msg: "DB error", err });
      if (!ok.length) return res.status(403).json({ msg: "Access denied: elder not linked to this family" });
      insert();
    }
  );
};

// GET /api/family/events?from=&to=&elder_id=
exports.getEvents = (req, res) => {
  const familyId = req.user.id;
  const { from, to, elder_id } = req.query || {};

  let sql = `
    SELECT event_id, family_id, elder_id, title, description, event_type,
           start_time, end_time, is_all_day, location, created_at, updated_at
    FROM family_events
    WHERE family_id = ?
  `;
  const params = [familyId];

  if (elder_id) {
    sql += " AND elder_id = ?";
    params.push(Number(elder_id));
  }

  if (from && to) {
    sql += " AND start_time BETWEEN ? AND ?";
    params.push(from, to);
  }

  sql += " ORDER BY start_time ASC";

  db.query(sql, params, (err, rows) => {
    if (err) return res.status(500).json({ msg: "Error fetching events", err });
    res.status(200).json({ events: rows });
  });
};

// PUT /api/family/events/:event_id
exports.updateEvent = (req, res) => {
  const familyId = req.user.id;
  const eventId = Number(req.params.event_id);
  if (Number.isNaN(eventId)) return res.status(400).json({ msg: "Invalid event_id" });

  const {
    title, description, event_type, start_time, end_time, is_all_day, location
  } = req.body || {};

  const allowedTypes = ["birthday","family_event","appointment","visit","medication_refill","other"];
  const type = event_type && allowedTypes.includes(event_type) ? event_type : undefined;

  db.query(
    `UPDATE family_events
     SET
       title = COALESCE(?, title),
       description = COALESCE(?, description),
       event_type = COALESCE(?, event_type),
       start_time = COALESCE(?, start_time),
       end_time = COALESCE(?, end_time),
       is_all_day = COALESCE(?, is_all_day),
       location = COALESCE(?, location)
     WHERE event_id = ? AND family_id = ?`,
    [
      title ?? null,
      description ?? null,
      type ?? null,
      start_time ?? null,
      end_time ?? null,
      (is_all_day === undefined ? null : (is_all_day ? 1 : 0)),
      location ?? null,
      eventId,
      familyId
    ],
    (err, result) => {
      if (err) return res.status(500).json({ msg: "Error updating event", err });
      if (!result.affectedRows) return res.status(404).json({ msg: "Event not found (or not yours)" });
      res.status(200).json({ msg: "Event updated ✅" });
    }
  );
};

// DELETE /api/family/events/:event_id
exports.deleteEvent = (req, res) => {
  const familyId = req.user.id;
  const eventId = Number(req.params.event_id);
  if (Number.isNaN(eventId)) return res.status(400).json({ msg: "Invalid event_id" });

  db.query(
    "DELETE FROM family_events WHERE event_id = ? AND family_id = ?",
    [eventId, familyId],
    (err, result) => {
      if (err) return res.status(500).json({ msg: "Error deleting event", err });
      if (!result.affectedRows) return res.status(404).json({ msg: "Event not found (or not yours)" });
      res.status(200).json({ msg: "Event deleted ✅" });
    }
  );
};
// POST /api/family/events
exports.createEvent = (req, res) => {
  const familyId = req.user.id;
  const {
    elder_id,
    title,
    description,
    event_type,
    start_time,
    end_time,
    is_all_day,
    location,
  } = req.body || {};

  if (!title || !start_time) {
    return res.status(400).json({ msg: "title and start_time are required" });
  }

  const allowedTypes = ["birthday","family_event","appointment","visit","medication_refill","other"];
  const type = allowedTypes.includes(event_type) ? event_type : "family_event";

  const insert = () => {
    db.query(
      `INSERT INTO family_events
       (family_id, elder_id, title, description, event_type, start_time, end_time, is_all_day, location)
       VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)`,
      [
        familyId,
        elder_id || null,
        title,
        description || null,
        type,
        start_time,
        end_time || null,
        is_all_day ? 1 : 0,
        location || null,
      ],
      (err, result) => {
        if (err) return res.status(500).json({ msg: "Error creating event", err });
        res.status(201).json({ msg: "Event created ✅", event_id: result.insertId });
      }
    );
  };

  // If event linked to elder, ensure the elder belongs to this family
  if (!elder_id) return insert();

  db.query(
    "SELECT 1 FROM elder_family WHERE family_id = ? AND elder_id = ? LIMIT 1",
    [familyId, elder_id],
    (err, ok) => {
      if (err) return res.status(500).json({ msg: "DB error", err });
      if (!ok.length) return res.status(403).json({ msg: "Access denied: elder not linked to this family" });
      insert();
    }
  );
};

// GET /api/family/events?from=&to=&elder_id=
exports.getEvents = (req, res) => {
  const familyId = req.user.id;
  const { from, to, elder_id } = req.query || {};

  let sql = `
    SELECT event_id, family_id, elder_id, title, description, event_type,
           start_time, end_time, is_all_day, location, created_at, updated_at
    FROM family_events
    WHERE family_id = ?
  `;
  const params = [familyId];

  if (elder_id) {
    sql += " AND elder_id = ?";
    params.push(Number(elder_id));
  }

  if (from && to) {
    sql += " AND start_time BETWEEN ? AND ?";
    params.push(from, to);
  }

  sql += " ORDER BY start_time ASC";

  db.query(sql, params, (err, rows) => {
    if (err) return res.status(500).json({ msg: "Error fetching events", err });
    res.status(200).json({ events: rows });
  });
};

// PUT /api/family/events/:event_id
exports.updateEvent = (req, res) => {
  const familyId = req.user.id;
  const eventId = Number(req.params.event_id);
  if (Number.isNaN(eventId)) return res.status(400).json({ msg: "Invalid event_id" });

  const {
    title,
    description,
    event_type,
    start_time,
    end_time,
    is_all_day,
    location
  } = req.body || {};

  const allowedTypes = ["birthday","family_event","appointment","visit","medication_refill","other"];
  const type = (event_type && allowedTypes.includes(event_type)) ? event_type : null;

  db.query(
    `UPDATE family_events
     SET
       title = COALESCE(?, title),
       description = COALESCE(?, description),
       event_type = COALESCE(?, event_type),
       start_time = COALESCE(?, start_time),
       end_time = COALESCE(?, end_time),
       is_all_day = COALESCE(?, is_all_day),
       location = COALESCE(?, location)
     WHERE event_id = ? AND family_id = ?`,
    [
      title ?? null,
      description ?? null,
      type,
      start_time ?? null,
      end_time ?? null,
      (is_all_day === undefined ? null : (is_all_day ? 1 : 0)),
      location ?? null,
      eventId,
      familyId,
    ],
    (err, result) => {
      if (err) return res.status(500).json({ msg: "Error updating event", err });
      if (!result.affectedRows) return res.status(404).json({ msg: "Event not found (or not yours)" });
      res.status(200).json({ msg: "Event updated ✅" });
    }
  );
};

// DELETE /api/family/events/:event_id
exports.deleteEvent = (req, res) => {
  const familyId = req.user.id;
  const eventId = Number(req.params.event_id);
  if (Number.isNaN(eventId)) return res.status(400).json({ msg: "Invalid event_id" });

  db.query(
    "DELETE FROM family_events WHERE event_id = ? AND family_id = ?",
    [eventId, familyId],
    (err, result) => {
      if (err) return res.status(500).json({ msg: "Error deleting event", err });
      if (!result.affectedRows) return res.status(404).json({ msg: "Event not found (or not yours)" });
      res.status(200).json({ msg: "Event deleted ✅" });
    }
  );
};

// GET /api/family/calendar?from=&to=&elder_id=
// Returns BOTH: family_events + visits in one response (shared calendar feed)
exports.getCalendar = (req, res) => {
  const familyId = req.user.id;
  const { from, to, elder_id } = req.query || {};

  if (!from || !to) return res.status(400).json({ msg: "from and to are required" });

  // 1) Events
  let eventsSql = `
    SELECT event_id AS id, 'event' AS item_type, elder_id,
           title, description, event_type,
           start_time, end_time, is_all_day, location, created_at
    FROM family_events
    WHERE family_id = ? AND start_time BETWEEN ? AND ?
  `;
  const eventsParams = [familyId, from, to];

  if (elder_id) {
    eventsSql += " AND elder_id = ?";
    eventsParams.push(Number(elder_id));
  }

  // 2) Visits (adapt column names if your visits table differs)
  // Assumes: visits has visit_id, elder_id, scheduled_at, status, notes or reason
  let visitsSql = `
    SELECT v.visit_id AS id, 'visit' AS item_type, v.elder_id,
           CONCAT('Visit (', v.status, ')') AS title,
           v.reason AS description,
           'visit' AS event_type,
           v.scheduled_at AS start_time,
           NULL AS end_time,
           0 AS is_all_day,
           NULL AS location,
           v.created_at
    FROM visits v
    JOIN elder_family ef ON ef.elder_id = v.elder_id
    WHERE ef.family_id = ? AND v.scheduled_at BETWEEN ? AND ?
  `;
  const visitsParams = [familyId, from, to];

  if (elder_id) {
    visitsSql += " AND v.elder_id = ?";
    visitsParams.push(Number(elder_id));
  }

  db.query(eventsSql, eventsParams, (err, events) => {
    if (err) return res.status(500).json({ msg: "Error fetching events", err });

    db.query(visitsSql, visitsParams, (err2, visits) => {
      if (err2) return res.status(500).json({ msg: "Error fetching visits", err: err2 });

      const combined = [...events, ...visits].sort(
        (a, b) => new Date(a.start_time) - new Date(b.start_time)
      );

      res.status(200).json({ calendar: combined });
    });
  });
};
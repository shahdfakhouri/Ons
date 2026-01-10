const db = require("../config/db");
//const { generateToken } = require("./auth.controller");
const jwt = require("jsonwebtoken");

const JWT_SECRET = "2003"; // MUST match authmiddleware
// simple keyword lists (edit anytime)
const RED_FLAG_KEYWORDS = [
  "chest pain", "can't breathe", "cannot breathe", "shortness of breath",
  "faint", "passed out", "stroke", "seizure", "bleeding", "unconscious",
  "ألم صدر", "ضيق تنفس", "اختناق", "إغماء", "نزيف", "جلطة", "تشنج"
];

function containsRedFlag(text = "") {
  const t = String(text).toLowerCase();
  return RED_FLAG_KEYWORDS.some(k => t.includes(k.toLowerCase()));
}


// create admin notification
function createAdminHealthAlert(db, { elder_id, message, severity = "warning" }, cb) {
  db.query(
    `INSERT INTO admin_notifications (type, message, user_id, severity, status)
     VALUES ('health_alert', ?, ?, ?, 'open')`,
    [message, elder_id, severity],
    cb
  );
}


// create emergency escalation
function createMedicalEmergencyFromLatestLocation(db, elder_id, description, cb) {
  db.query(
    `SELECT latitude, longitude
     FROM elder_location
     WHERE elder_id = ?
     ORDER BY recorded_at DESC
     LIMIT 1`,
    [elder_id],
    (err, locRows) => {
      if (err) return cb(err);

      // emergency_requests latitude/longitude are NOT NULL in your schema
      const lat = locRows.length ? (locRows[0].latitude ?? 0) : 0;
      const lng = locRows.length ? (locRows[0].longitude ?? 0) : 0;

      db.query(
        `INSERT INTO emergency_requests
          (elder_id, triggered_by_role, triggered_by_id, emergency_type, severity,
           latitude, longitude, status, description)
         VALUES (?, 'system', NULL, 'medical', 'critical', ?, ?, 'open', ?)`,
        [elder_id, lat, lng, description],
        cb
      );
    }
  );
}

//PIN LOGIN
exports.pinLogin = (req, res) => {
  const { elder_id, pin } = req.body;

  if (!elder_id || !pin) {
    return res.status(400).json({ msg: "Elder ID and PIN required" });
  }

  db.query(
    "SELECT elder_id FROM elders WHERE elder_id = ? AND pin = ?",
    [elder_id, pin],
    (err, rows) => {
      if (err) {
        console.error("PIN login DB error:", err);
        return res.status(500).json({ msg: "DB error" });
      }

      if (!rows.length) {
        return res.status(401).json({ msg: "Invalid PIN" });
      }

      // 🔐 SIGN TOKEN WITH SAME SECRET
      const token = jwt.sign(
        {
          elder_id: rows[0].elder_id,
          role: "elder"
        },
        JWT_SECRET,
        { expiresIn: "7d" }
      );

      res.json({ token });
    }
  );
};

//CHANGE PIN 
exports.changePin = (req, res) => {
  const { newPin } = req.body;

  if (!newPin) {
    return res.status(400).json({ msg: "New PIN required" });
  }

  db.query(
    "UPDATE elders SET pin = ?, pin_updated_at = NOW() WHERE elder_id = ?",
    [newPin, req.user.elder_id],
    (err) => {
      if (err) {
        console.error("Change PIN DB error:", err);
        return res.status(500).json({ msg: "DB error" });
      }
      res.json({ msg: "PIN updated successfully" });
    }
  );
};

//GET MY PROFILE 
exports.getMyProfile = (req, res) => {
  db.query(
    `SELECT 
      name,
      age,
      gender,
      font_size,
      language,
      voice_mode
     FROM elders
     WHERE elder_id = ?`,
    [req.user.elder_id],
    (err, rows) => {
      if (err) {
        console.error("Get profile DB error:", err);
        return res.status(500).json({ msg: "DB error" });
      }

      if (!rows.length) {
        return res.status(404).json({ msg: "Elder not found" });
      }

      res.json(rows[0]);
    }
  );
};

//UPDATE MY PROFILE
exports.updateMyProfile = (req, res) => {
  const { font_size, language, voice_mode } = req.body;

  db.query(
    `UPDATE elders 
     SET font_size = ?, language = ?, voice_mode = ?
     WHERE elder_id = ?`,
    [font_size, language, voice_mode, req.user.elder_id],
    (err) => {
      if (err) {
        console.error("Update profile DB error:", err);
        return res.status(500).json({ msg: "DB error" });
      }
      res.json({ msg: "Profile updated" });
    }
  );
};

//GET CONSENT 
exports.getConsent = (req, res) => {
  db.query(
    `SELECT 
      share_location,
      share_health,
      share_media,
      share_summary
     FROM elders
     WHERE elder_id = ?`,
    [req.user.elder_id],
    (err, rows) => {
      if (err) {
        console.error("Get consent DB error:", err);
        return res.status(500).json({ msg: "DB error" });
      }
      if (!rows.length) {
        return res.status(404).json({ msg: "Elder not found" });
      }
      res.json(rows[0]);
    }
  );
};

//UPDATE CONSENT 
exports.updateConsent = (req, res) => {
  const { share_location, share_health, share_media, share_summary } = req.body;

  db.query(
    `UPDATE elders SET
      share_location = ?,
      share_health = ?,
      share_media = ?,
      share_summary = ?
     WHERE elder_id = ?`,
    [share_location, share_health, share_media, share_summary, req.user.elder_id],
    (err) => {
      if (err) {
        console.error("Update consent DB error:", err);
        return res.status(500).json({ msg: "DB error" });
      }
      res.json({ msg: "Consent updated" });
    }
  );
};

//ADD MOOD 
exports.addMood = (req, res) => {
  const elder_id = req.user.elder_id;
  const { mood_level, notes } = req.body;

  const level = Number(mood_level);
  if (!Number.isInteger(level) || level < 1 || level > 5) {
    return res.status(400).json({ msg: "mood_level must be an integer between 1 and 5" });
  }

  db.query(
    `INSERT INTO elder_moods (elder_id, mood_level, notes)
     VALUES (?, ?, ?)`,
    [elder_id, level, notes || null],
    (err) => {
      if (err) {
        console.error("Add mood DB error:", err);
        return res.status(500).json({ msg: "DB error", details: err.message });
      }

      // Alert if very low mood
      if (level <= 2) {
        const msg = `Low mood detected (level=${level}) for elder_id=${elder_id}. Notes: ${notes || "N/A"}`;

        createAdminHealthAlert(db, { elder_id, message: msg, severity: "warning" }, (aErr) => {
          if (aErr) console.error("Admin mood alert error:", aErr);
          return res.json({ msg: "Mood saved (alert triggered)" });
        });
      } else {
        return res.json({ msg: "Mood saved" });
      }
    }
  );
};

//MOOD HISTORY 
exports.getMoodHistory = (req, res) => {
  db.query(
    `SELECT mood_level, notes, created_at
     FROM elder_moods
     WHERE elder_id = ?
     ORDER BY created_at DESC`,
    [req.user.elder_id],
    (err, rows) => {
      if (err) {
        console.error("Mood history DB error:", err);
        return res.status(500).json({ msg: "DB error" });
      }
      res.json(rows);
    }
  );
};

//ADD SYMPTOM
exports.addSymptom = (req, res) => {
  const elder_id = req.user.elder_id;
  const { symptom, severity, notes } = req.body;

  const allowedSev = ["low", "medium", "high"];
  const sev = severity ? String(severity).toLowerCase() : null;

  if (!symptom) {
    return res.status(400).json({ msg: "symptom is required" });
  }
  if (sev && !allowedSev.includes(sev)) {
    return res.status(400).json({ msg: "severity must be one of: low, medium, high" });
  }

  db.query(
    `INSERT INTO elder_symptoms (elder_id, symptom, severity, notes)
     VALUES (?, ?, ?, ?)`,
    [elder_id, symptom, sev, notes || null],
    (err) => {
      if (err) {
        console.error("Add symptom DB error:", err);
        return res.status(500).json({ msg: "DB error", details: err.message });
      }

      const redFlag = containsRedFlag(`${symptom} ${notes || ""}`);
      const isHigh = sev === "high";

      // Admin alert if high OR red-flag
      if (isHigh || redFlag) {
        const adminSeverity = redFlag ? "critical" : "warning";
        const adminMsg =
          `Symptom reported for elder_id=${elder_id}. symptom=${symptom}. severity=${sev || "N/A"}. notes=${notes || "N/A"}`;

        createAdminHealthAlert(db, { elder_id, message: adminMsg, severity: adminSeverity }, (aErr) => {
          if (aErr) console.error("Admin symptom alert error:", aErr);

          // Escalate to emergency only on red flag
          if (redFlag) {
            createMedicalEmergencyFromLatestLocation(db, elder_id, adminMsg, (eErr, eRes) => {
              if (eErr) {
                console.error("Emergency escalation error:", eErr);
                return res.json({ msg: "Symptom saved (alert triggered, escalation failed)" });
              }

              return res.status(201).json({
                msg: "Symptom saved (alert + emergency escalated)",
                emergency_id: eRes.insertId
              });
            });
          } else {
            return res.json({ msg: "Symptom saved (alert triggered)" });
          }
        });
      } else {
        return res.json({ msg: "Symptom submitted" });
      }
    }
  );
};


//SYMPTOM HISTORY 
exports.getSymptoms = (req, res) => {
  db.query(
    `SELECT symptom, severity, notes, created_at
     FROM elder_symptoms
     WHERE elder_id = ?
     ORDER BY created_at DESC`,
    [req.user.elder_id],
    (err, rows) => {
      if (err) {
        console.error("Symptoms history DB error:", err);
        return res.status(500).json({ msg: "DB error" });
      }
      res.json(rows);
    }
  );
};

//REQUEST CALL
exports.requestCall = (req, res) => {
  const { target_user_id, target_role } = req.body;

  if (!target_user_id || !target_role) {
    return res.status(400).json({ msg: "target_user_id and target_role required" });
  }

  db.query(
    `INSERT INTO call_requests (elder_id, target_user_id, target_role)
     VALUES (?, ?, ?)`,
    [req.user.elder_id, target_user_id, target_role],
    (err) => {
      if (err) {
        console.error("Request call DB error:", err);
        return res.status(500).json({ msg: "DB error" });
      }
      res.json({ msg: "Call request sent" });
    }
  );
};

//CALL HISTORY
exports.getCallHistory = (req, res) => {
  db.query(
    `SELECT target_role, status, created_at
     FROM call_requests
     WHERE elder_id = ?
     ORDER BY created_at DESC`,
    [req.user.elder_id],
    (err, rows) => {
      if (err) {
        console.error("Call history DB error:", err);
        return res.status(500).json({ msg: "DB error" });
      }
      res.json(rows);
    }
  );
};

//GALLERY READ ONLY 
exports.getGallery = (req, res) => {
  db.query(
    `SELECT 
      media_id,
      file_path,
      media_type,
      caption,
      created_at,
      uploaded_by_family_id
     FROM elder_gallery
     WHERE elder_id = ?
     ORDER BY created_at DESC`,
    [req.user.elder_id],
    (err, rows) => {
      if (err) {
        console.error("Gallery DB error:", err);
        return res.status(500).json({ msg: "DB error", details: err.message });
      }
      res.json(rows);
    }
  );
};

//CONTENT FEED
exports.getContentFeed = async (req, res) => {
  res.json([
    {
      type: "video",
      title: "Relaxing Music",
      url: "https://youtube.com/..."
    },
    {
      type: "podcast",
      title: "Daily News",
      url: "https://spotify.com/..."
    }
  ]);
};

// CALL REQUESTS

// Accept: pending -> accepted
exports.acceptCallRequest = (req, res) => {
  const elder_id = req.user.elder_id;
  const { call_id } = req.params;

  db.query(
    `UPDATE call_requests
     SET status = 'accepted'
     WHERE call_id = ? AND elder_id = ? AND status = 'pending'`,
    [call_id, elder_id],
    (err, result) => {
      if (err) {
        console.error("Accept call request DB error:", err);
        return res.status(500).json({ msg: "DB error", details: err.message });
      }

      if (result.affectedRows === 0) {
        return res.status(404).json({ msg: "Call request not found or not pending" });
      }

      res.json({ msg: "Call request accepted" });
    }
  );
};

// Decline: pending -> declined
exports.declineCallRequest = (req, res) => {
  const elder_id = req.user.elder_id;
  const { call_id } = req.params;

  db.query(
    `UPDATE call_requests
     SET status = 'declined'
     WHERE call_id = ? AND elder_id = ? AND status = 'pending'`,
    [call_id, elder_id],
    (err, result) => {
      if (err) {
        console.error("Decline call request DB error:", err);
        return res.status(500).json({ msg: "DB error", details: err.message });
      }

      if (result.affectedRows === 0) {
        return res.status(404).json({ msg: "Call request not found or not pending" });
      }

      res.json({ msg: "Call request declined" });
    }
  );
};
// GET MY CONTACTS
exports.getMyContacts = (req, res) => {
  const elder_id = req.user.elder_id;

  const response = { family: [], caregiver: [], retirement_home: [] };

  // 1) Families linked to this elder
  db.query(
    `SELECT fm.family_id, fm.name, fm.phone, fm.email
     FROM elder_family ef
     JOIN family_members fm ON fm.family_id = ef.family_id
     WHERE ef.elder_id = ?`,
    [elder_id],
    (err, famRows) => {
      if (err) {
        console.error("Contacts family DB error:", err);
        return res.status(500).json({ msg: "DB error", details: err.message });
      }
      response.family = famRows || [];

      // 2) Latest assignment (caregiver/home)
      db.query(
        `SELECT caregiver_id, home_id
         FROM elder_assignments
         WHERE elder_id = ?
         ORDER BY assigned_at DESC
         LIMIT 1`,
        [elder_id],
        (err2, assignRows) => {
          if (err2) {
            console.error("Contacts assignment DB error:", err2);
            return res.status(500).json({ msg: "DB error", details: err2.message });
          }

          if (!assignRows.length) {
            return res.json(response);
          }

          const { caregiver_id, home_id } = assignRows[0];

          // 2a) Fetch caregiver (if assigned)
          const fetchCaregiver = (cb) => {
            if (!caregiver_id) return cb(null);

            db.query(
              `SELECT caregiver_id, name, phone, email
               FROM caregivers
               WHERE caregiver_id = ?
               LIMIT 1`,
              [caregiver_id],
              (errC, careRows) => {
                if (errC) return cb(errC);
                response.caregiver = careRows || [];
                cb(null);
              }
            );
          };

          // 2b) Fetch retirement home (if assigned)
          const fetchHome = (cb) => {
            if (!home_id) return cb(null);

            db.query(
              `SELECT home_id, name, contact_phone, contact_email, address
               FROM retirement_homes
               WHERE home_id = ?
               LIMIT 1`,
              [home_id],
              (errH, homeRows) => {
                if (errH) return cb(errH);
                response.retirement_home = homeRows || [];
                cb(null);
              }
            );
          };

          fetchCaregiver((errC) => {
            if (errC) {
              console.error("Contacts caregiver DB error:", errC);
              return res.status(500).json({ msg: "DB error", details: errC.message });
            }

            fetchHome((errH) => {
              if (errH) {
                console.error("Contacts home DB error:", errH);
                return res.status(500).json({ msg: "DB error", details: errH.message });
              }

              return res.json(response);
            });
          });
        }
      );
    }
  );
};
// Upload MEDIA
exports.uploadMyMedia = (req, res) => {
  const elder_id = req.user.elder_id;

  if (!req.file) {
    return res.status(400).json({ msg: "File is required (field name: file)" });
  }

  // Save relative path so frontend can use: /uploads/...
  const filePath = `/uploads/${req.file.filename}`;

  // photo vs video vs other
  const mime = req.file.mimetype || "";
  let mediaType = "photo";
  if (mime.startsWith("video/")) mediaType = "video";
  else if (!mime.startsWith("image/")) mediaType = "photo"; // keep default

  const { caption } = req.body;

  db.query(
    `INSERT INTO elder_gallery
      (elder_id, uploaded_by_family_id, file_path, media_type, caption, uploaded_by_role, uploaded_by_elder_id)
     VALUES (?, NULL, ?, ?, ?, 'elder', ?)`,
    [elder_id, filePath, mediaType, caption || null, elder_id],
    (err, result) => {
      if (err) {
        console.error("Upload media DB error:", err);
        return res.status(500).json({ msg: "DB error", details: err.message });
      }

      res.status(201).json({
        msg: "Media uploaded",
        media_id: result.insertId,
        file_path: filePath,
        media_type: mediaType
      });
    }
  );
};
const fs = require("fs");
const path = require("path");

exports.deleteMyMedia = (req, res) => {
  const elder_id = req.user.elder_id;
  const { media_id } = req.params;

  // 1) find the media row and confirm it belongs to elder + uploaded by elder
  db.query(
    `SELECT media_id, file_path
     FROM elder_gallery
     WHERE media_id = ?
       AND elder_id = ?
       AND uploaded_by_role = 'elder'
       AND uploaded_by_elder_id = ?`,
    [media_id, elder_id, elder_id],
    (err, rows) => {
      if (err) {
        console.error("Delete media lookup DB error:", err);
        return res.status(500).json({ msg: "DB error", details: err.message });
      }

      if (!rows.length) {
        return res.status(404).json({ msg: "Media not found (or not yours)" });
      }

      const filePath = rows[0].file_path; // like /uploads/xyz.jpg
      const absolutePath = path.join(__dirname, "..", "..", filePath); // resolves from src/controllers/ -> project

      // 2) delete DB row first (source of truth)
      db.query(
        `DELETE FROM elder_gallery
         WHERE media_id = ? AND elder_id = ? AND uploaded_by_role = 'elder' AND uploaded_by_elder_id = ?`,
        [media_id, elder_id, elder_id],
        (err2, result) => {
          if (err2) {
            console.error("Delete media DB error:", err2);
            return res.status(500).json({ msg: "DB error", details: err2.message });
          }

          // 3) best-effort file delete (don’t fail request if file missing)
          fs.unlink(absolutePath, (unlinkErr) => {
            if (unlinkErr) console.warn("File delete warning:", unlinkErr.message);
            return res.json({ msg: "Media deleted" });
          });
        }
      );
    }
  );
};

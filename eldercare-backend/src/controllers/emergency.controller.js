const db = require("../config/db");
const { notify } = require("../services/notification.service");

// Haversine distance (km)
function haversineKm(lat1, lon1, lat2, lon2) {
  const toRad = (x) => (x * Math.PI) / 180;
  const R = 6371; // km
  const dLat = toRad(lat2 - lat1);
  const dLon = toRad(lon2 - lon1);

  const a =
    Math.sin(dLat / 2) ** 2 +
    Math.cos(toRad(lat1)) * Math.cos(toRad(lat2)) * Math.sin(dLon / 2) ** 2;

  return 2 * R * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
}

/**
 * POST /api/emergency
 * Triggered by elder/family/caregiver/admin/system
 * Creates emergency request + notifies closest retirement homes (top N)
 */
exports.createEmergency = (req, res) => {
  const role = req.user?.role || "system";
  const triggeredById = req.user?.id || null;

  const {
    elder_id,
    family_id,
    emergency_type,
    severity,
    latitude,
    longitude,
    address_text,
    notes,
    notify_top = 3, // how many homes to notify
  } = req.body || {};

  if (latitude === undefined || longitude === undefined) {
    return res.status(400).json({ msg: "latitude and longitude are required" });
  }

  const lat = Number(latitude);
  const lng = Number(longitude);
  if (Number.isNaN(lat) || Number.isNaN(lng)) {
    return res.status(400).json({ msg: "latitude/longitude must be numbers" });
  }

  const insertSql = `
    INSERT INTO emergency_requests
    (elder_id, family_id, triggered_by_role, triggered_by_id, emergency_type, severity,
     latitude, longitude, address_text, status, notes)
    VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, 'open', ?)
  `;

  db.query(
    insertSql,
    [
      elder_id || null,
      family_id || null,
      role,
      triggeredById,
      emergency_type || "breakdown",
      severity || "critical",
      lat,
      lng,
      address_text || null,
      notes || null,
    ],
    (err, result) => {
      if (err) return res.status(500).json({ msg: "Error creating emergency", err });

      const emergencyId = result.insertId;

      // Get all approved retirement homes with coordinates
      const homesSql = `
        SELECT home_id, name, city, contact_email, contact_phone, latitude, longitude
        FROM retirement_homes
        WHERE is_approved = 1
          AND latitude IS NOT NULL
          AND longitude IS NOT NULL
      `;

      db.query(homesSql, async (err2, homes) => {
        if (err2) return res.status(500).json({ msg: "Error fetching homes", err: err2 });
        if (!homes.length) {
          return res.status(201).json({
            msg: "Emergency created ✅ but no approved homes with coordinates found",
            emergency_id: emergencyId,
          });
        }

        // Compute distances and pick closest N
        const ranked = homes
          .map((h) => ({
            ...h,
            distance_km: haversineKm(lat, lng, Number(h.latitude), Number(h.longitude)),
          }))
          .sort((a, b) => a.distance_km - b.distance_km)
          .slice(0, Math.max(1, Math.min(Number(notify_top) || 3, 10)));

        // Insert notification rows
        const notifInsertSql = `
          INSERT INTO emergency_notifications (emergency_id, home_id, distance_km)
          VALUES ?
        `;
        const values = ranked.map((h) => [emergencyId, h.home_id, h.distance_km.toFixed(2)]);

        db.query(notifInsertSql, [values], async (err3) => {
          if (err3) console.error("Error inserting emergency_notifications:", err3);

          // Send actual notifications (email/SMS) using your notify()
          for (const h of ranked) {
            const msg = `🚨 URGENT Emergency nearby!\nEmergency ID: ${emergencyId}\nType: ${
              emergency_type || "breakdown"
            }\nLocation: (${lat}, ${lng})\nDistance: ${h.distance_km.toFixed(
              2
            )} km\n${address_text ? "Address: " + address_text + "\n" : ""}${
              notes ? "Notes: " + notes : ""
            }`;

            await notify({
              type: "emergency",
              message: msg,
              userId: elder_id || null,
              severity: severity || "critical",
              email: h.contact_email || null,
              phone: h.contact_phone ? String(h.contact_phone) : null,
            });
          }

          return res.status(201).json({
            msg: "Emergency created ✅ closest retirement homes notified",
            emergency_id: emergencyId,
            notified_homes: ranked.map((h) => ({
              home_id: h.home_id,
              name: h.name,
              distance_km: Number(h.distance_km.toFixed(2)),
            })),
          });
        });
      });
    }
  );
};

/**
 * GET /api/retirement/emergencies?status=open|assigned|all
 * Retirement home views emergencies that notified them
 */
exports.getHomeEmergencies = (req, res) => {
  const homeId = req.user.id;
  const status = (req.query.status || "open").toLowerCase();

  let sql = `
    SELECT
      er.emergency_id, er.elder_id, er.family_id, er.emergency_type, er.severity,
      er.latitude, er.longitude, er.address_text, er.status,
      er.assigned_home_id, er.created_at,
      en.distance_km, en.response, en.notified_at, en.responded_at
    FROM emergency_notifications en
    JOIN emergency_requests er ON er.emergency_id = en.emergency_id
    WHERE en.home_id = ?
  `;
  const params = [homeId];

  if (status !== "all") {
    sql += " AND er.status = ? ";
    params.push(status);
  }

  sql += " ORDER BY er.created_at DESC";

  db.query(sql, params, (err, rows) => {
    if (err) return res.status(500).json({ msg: "Error fetching emergencies", err });
    res.status(200).json({ msg: "Home emergencies retrieved ✅", emergencies: rows });
  });
};

/**
 * PATCH /api/retirement/emergencies/:emergency_id/accept
 * First home to accept becomes assigned home
 */
exports.acceptEmergency = (req, res) => {
  const homeId = req.user.id;
  const emergencyId = req.params.emergency_id;

  // Mark this home accepted (if it was notified)
  const updateNotif = `
    UPDATE emergency_notifications
    SET response = 'accepted', responded_at = NOW()
    WHERE emergency_id = ? AND home_id = ? AND response = 'pending'
  `;

  db.query(updateNotif, [emergencyId, homeId], (err, result) => {
    if (err) return res.status(500).json({ msg: "Error accepting notification", err });
    if (result.affectedRows === 0) {
      return res.status(400).json({ msg: "You were not pending/notified for this emergency (or already responded)" });
    }

    // Assign the emergency to this home if still unassigned
    const assignSql = `
      UPDATE emergency_requests
      SET status = 'assigned', assigned_home_id = ?, assigned_at = NOW()
      WHERE emergency_id = ? AND (assigned_home_id IS NULL) AND status IN ('open','assigned')
    `;

    db.query(assignSql, [homeId, emergencyId], async (err2, assignRes) => {
      if (err2) return res.status(500).json({ msg: "Error assigning emergency", err: err2 });

      if (assignRes.affectedRows === 0) {
        // someone else already assigned
        return res.status(409).json({ msg: "Emergency already assigned to another home" });
      }

      // Optional: mark other notified homes as rejected/no_response
      const rejectOthers = `
        UPDATE emergency_notifications
        SET response = 'rejected', responded_at = NOW()
        WHERE emergency_id = ? AND home_id <> ? AND response = 'pending'
      `;
      db.query(rejectOthers, [emergencyId, homeId], (e) => {
        if (e) console.error("Error rejecting other homes:", e);
      });

      res.status(200).json({ msg: "Emergency accepted and assigned ✅", emergency_id: Number(emergencyId), assigned_home_id: homeId });
    });
  });
};

/**
 * PATCH /api/retirement/emergencies/:emergency_id/reject
 */
exports.rejectEmergency = (req, res) => {
  const homeId = req.user.id;
  const emergencyId = req.params.emergency_id;

  const sql = `
    UPDATE emergency_notifications
    SET response = 'rejected', responded_at = NOW()
    WHERE emergency_id = ? AND home_id = ? AND response = 'pending'
  `;

  db.query(sql, [emergencyId, homeId], (err, result) => {
    if (err) return res.status(500).json({ msg: "Error rejecting emergency", err });
    if (result.affectedRows === 0) return res.status(400).json({ msg: "Not pending/notified or already responded" });
    res.status(200).json({ msg: "Emergency rejected ✅" });
  });
};

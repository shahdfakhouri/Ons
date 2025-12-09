// src/controllers/tracker.controller.js
const db = require("../config/db");
const { updateElderLocation } = require("../services/locationService");

// 🔁 called by caregiver/family/app to update current GPS
exports.updateLocation = async (req, res) => {
  try {
    const { elder_id, latitude, longitude } = req.body;

    if (!elder_id || !latitude || !longitude) {
      return res
        .status(400)
        .json({ msg: "elder_id, latitude and longitude are required" });
    }

    const result = await updateElderLocation(
      elder_id,
      Number(latitude),
      Number(longitude)
    );

    res.status(200).json({
      msg: "Location updated",
      ...result,
    });
  } catch (error) {
    console.error("Error updating location:", error);
    res.status(500).json({ msg: "Error updating location", error: error.message });
  }
};

// 🧱 Create a safe zone (admin for now)
exports.createSafeZone = (req, res) => {
  const { elder_id, name, center_lat, center_lng, radius_m } = req.body;

  if (!elder_id || !name || !center_lat || !center_lng || !radius_m) {
    return res.status(400).json({
      msg: "elder_id, name, center_lat, center_lng, radius_m are required"
    });
  }

  const sql = `
    INSERT INTO elder_safe_zones (elder_id, name, center_lat, center_lng, radius_m)
    VALUES (?, ?, ?, ?, ?)
  `;

  db.query(
    sql,
    [elder_id, name, center_lat, center_lng, radius_m],
    (err, result) => {
      if (err) {
        console.error("Error creating safe zone:", err);
        return res.status(500).json({ msg: "Error creating safe zone", err });
      }
      res.status(201).json({
        msg: "Safe zone created",
        zone_id: result.insertId
      });
    }
  );
};

// 📄 List safe zones for one elder
exports.getSafeZones = (req, res) => {
  const { elder_id } = req.params;

  const sql = "SELECT * FROM elder_safe_zones WHERE elder_id = ?";
  db.query(sql, [elder_id], (err, rows) => {
    if (err) {
      console.error("Error fetching safe zones:", err);
      return res.status(500).json({ msg: "Error fetching safe zones", err });
    }
    res.status(200).json({ zones: rows });
  });
};

// ✅ Enable / disable a safe zone
exports.toggleSafeZone = (req, res) => {
  const { zone_id } = req.params;
  const { active } = req.body; // 1 or 0

  const sql = "UPDATE elder_safe_zones SET active = ? WHERE zone_id = ?";
  db.query(sql, [active ? 1 : 0, zone_id], (err, result) => {
    if (err) {
      console.error("Error updating safe zone:", err);
      return res.status(500).json({ msg: "Error updating safe zone", err });
    }
    if (result.affectedRows === 0) {
      return res.status(404).json({ msg: "Safe zone not found" });
    }
    res.status(200).json({ msg: "Safe zone updated" });
  });
};
// 📍 Get route history for an elder (movement over time)
exports.getRouteHistory = (req, res) => {
  const { elder_id } = req.params;

  const sql = `
    SELECT latitude, longitude, recorded_at
    FROM elder_location
    WHERE elder_id = ?
    ORDER BY recorded_at DESC
  `;

  db.query(sql, [elder_id], (err, rows) => {
    if (err) {
      console.error("Error fetching route history:", err);
      return res
        .status(500)
        .json({ msg: "Error fetching route history", err });
    }

    res.status(200).json({
      msg: "Route history fetched",
      history: rows,
    });
  });
};
// Haversine formula (distance in meters between 2 GPS points)
function haversineDistance(lat1, lon1, lat2, lon2) {
  const toRad = (deg) => (deg * Math.PI) / 180;
  const R = 6371000; // meters

  const dLat = toRad(lat2 - lat1);
  const dLon = toRad(lon2 - lon1);

  const a =
    Math.sin(dLat / 2) ** 2 +
    Math.cos(toRad(lat1)) *
      Math.cos(toRad(lat2)) *
      Math.sin(dLon / 2) ** 2;

  const c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
  return R * c;
}

// 📏 Distance between elder and caregiver
exports.getDistanceToCaregiver = (req, res) => {
  const { elder_id, caregiver_id } = req.params;

  // 1. Get elder latest location
  db.query(
    "SELECT latitude, longitude FROM elder_location WHERE elder_id = ? ORDER BY recorded_at DESC LIMIT 1",
    [elder_id],
    (err, elderRows) => {
      if (err) {
        console.error("Error fetching elder location:", err);
        return res.status(500).json({ msg: "DB error", err });
      }
      if (!elderRows.length) {
        return res.status(404).json({ msg: "Elder location not found" });
      }

      const elder = elderRows[0];

      // 2. Get caregiver location (⚠️ needs latitude/longitude columns on caregivers table)
      db.query(
        "SELECT latitude, longitude FROM caregivers WHERE caregiver_id = ?",
        [caregiver_id],
        (err2, cRows) => {
          if (err2) {
            console.error("Error fetching caregiver location:", err2);
            return res.status(500).json({ msg: "DB error", err: err2 });
          }
          if (!cRows.length) {
            return res
              .status(404)
              .json({ msg: "Caregiver location not found" });
          }

          const caregiver = cRows[0];

          const distance = haversineDistance(
            Number(elder.latitude),
            Number(elder.longitude),
            Number(caregiver.latitude),
            Number(caregiver.longitude)
          );

          res.status(200).json({
            msg: "Distance calculated",
            distance_meters: distance,
            distance_km: (distance / 1000).toFixed(2),
          });
        }
      );
    }
  );
};
// src/services/locationService.js
const db = require("../config/db");
const { notify } = require("./notification.service");

// Haversine distance in meters
function haversineDistance(lat1, lon1, lat2, lon2) {
  const toRad = (deg) => (deg * Math.PI) / 180;

  const R = 6371000; // Earth radius in meters
  const dLat = toRad(lat2 - lat1);
  const dLon = toRad(lon2 - lon1);

  const a =
    Math.sin(dLat / 2) * Math.sin(dLat / 2) +
    Math.cos(toRad(lat1)) *
      Math.cos(toRad(lat2)) *
      Math.sin(dLon / 2) *
      Math.sin(dLon / 2);

  const c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
  return R * c;
}

// 1) Save location + update elder last_check_in
function saveElderLocation(elderId, latitude, longitude) {
  return new Promise((resolve, reject) => {
    const insertSql =
      "INSERT INTO elder_location (elder_id, latitude, longitude) VALUES (?, ?, ?)";
    db.query(insertSql, [elderId, latitude, longitude], (err) => {
      if (err) return reject(err);

      const updateSql =
        "UPDATE elders SET location = CONCAT(?, ',', ?), last_check_in = NOW() WHERE elder_id = ?";
      db.query(updateSql, [latitude, longitude, elderId], (err2) => {
        if (err2) return reject(err2);
        resolve();
      });
    });
  });
}

// 2) Load active safe zones for that elder
function getSafeZonesForElder(elderId) {
  return new Promise((resolve, reject) => {
    const sql =
      "SELECT * FROM elder_safe_zones WHERE elder_id = ? AND active = 1";
    db.query(sql, [elderId], (err, rows) => {
      if (err) return reject(err);
      resolve(rows);
    });
  });
}

// 3) Check if outside any safe zone + send alert
async function checkSafeZonesAndAlert(elderId, lat, lng) {
  const zones = await getSafeZonesForElder(elderId);
  if (!zones.length) return { outOfZones: [] }; // no zones defined

  const outOfZones = [];

  zones.forEach((zone) => {
    const distance = haversineDistance(
      Number(lat),
      Number(lng),
      Number(zone.center_lat),
      Number(zone.center_lng)
    );

    if (distance > zone.radius_m) {
      outOfZones.push({ zone, distance });
    }
  });

  if (outOfZones.length > 0) {
    const zoneNames = outOfZones.map((z) => z.zone.name).join(", ");
    const message = `🚨 Elder ${elderId} left safe zone(s): ${zoneNames}. Current location: (${lat}, ${lng}).`;

    // For now send to TEST email / phone + store in admin_notifications
    await notify({
      type: "alert",
      message,
      email: process.env.TEST_EMAIL,
      phone: process.env.TEST_PHONE,
      userId: elderId, // or null / family id later
    });
  }

  return { outOfZones };
}

// Public function used by controller
async function updateElderLocation(elderId, latitude, longitude) {
  await saveElderLocation(elderId, latitude, longitude);
  const result = await checkSafeZonesAndAlert(elderId, latitude, longitude);
  return result;
}
function haversineDistance(lat1, lon1, lat2, lon2) {
  const toRad = deg => (deg * Math.PI) / 180;
  const R = 6371000; // meters

  const dLat = toRad(lat2 - lat1);
  const dLon = toRad(lon2 - lon1);

  const a =
    Math.sin(dLat / 2) ** 2 +
    Math.cos(toRad(lat1)) *
    Math.cos(toRad(lat2)) *
    Math.sin(dLon / 2) ** 2;

  const c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));

  return R * c; // distance in meters
}

// 🗺️ Get driving directions using MapQuest (requires MAPQUEST_API_KEY in .env)
const axios = require("axios");

async function getDirections(fromLat, fromLng, toLat, toLng) {
  if (!process.env.MAPQUEST_API_KEY) {
    throw new Error("MAPQUEST_API_KEY is not set");
  }

  const url = "http://www.mapquestapi.com/directions/v2/route";

  const response = await axios.get(url, {
    params: {
      key: process.env.MAPQUEST_API_KEY,
      from: `${fromLat},${fromLng}`,
      to: `${toLat},${toLng}`,
      unit: "k",
    },
  });

  const steps = response.data.route.legs[0].maneuvers.map(
    (m) => m.narrative
  );
  const time = response.data.route.formattedTime;
  const distance = response.data.route.distance;

  return { steps, time, distance };
}


module.exports = {
  updateElderLocation,
  // other exports...
  getDirections, // <-- add this
};

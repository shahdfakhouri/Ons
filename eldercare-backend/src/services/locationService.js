const axios = require("axios");

// 🔁 Reverse geocode using OpenStreetMap (Nominatim)
async function reverseGeocode(lat, lon) {
  try {
    const res = await axios.get(
      "https://nominatim.openstreetmap.org/reverse",
      {
        params: {
          format: "jsonv2",
          lat,
          lon,
        },
        headers: {
          "User-Agent": "ONS-ElderCare/1.0 (admin@ons.app)", // REQUIRED by OSM
        },
        timeout: 5000,
      }
    );

    return (
      res.data?.display_name ||
      null
    );
  } catch (err) {
    console.error("🌍 Reverse geocode failed:", err.message);
    return null;
  }
}

module.exports = {
  reverseGeocode,
};
const db = require("../config/db");

exports.getDashboard = (req, res) => {
  res.status(200).json({ msg: "Caregiver dashboard working ✅" });
};

exports.updateProfile = (req, res) => {
  res.status(200).json({ msg: "Caregiver profile update endpoint ready 🛠️" });
};

const db = require("../config/db");

exports.getDashboard = (req, res) => {
  res.status(200).json({ msg: "Family dashboard working ✅" });
};

exports.updateProfile = (req, res) => {
  res.status(200).json({ msg: "Family profile update endpoint ready 🛠️" });
};

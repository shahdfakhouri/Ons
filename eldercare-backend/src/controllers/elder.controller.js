const db = require("../config/db");

exports.getDashboard = (req, res) => {
  res.status(200).json({ msg: "Elder dashboard working ✅" });
};

exports.updateProfile = (req, res) => {
  res.status(200).json({ msg: "Elder profile update endpoint ready 🛠️" });
};

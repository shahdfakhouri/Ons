const db = require("../config/db");

exports.getDashboard = (req, res) => {
  res.status(200).json({ msg: "Retirement home dashboard working ✅" });
};

exports.updateProfile = (req, res) => {
  res.status(200).json({ msg: "Retirement home profile update endpoint ready 🛠️" });
};

// src/middleware/adminMiddleware.js
const isAdmin = (req, res, next) => {
  try {
    if (req.user && req.user.role && req.user.role.toLowerCase() === "admin") {
      return next(); // ✅ proceed if user is admin
    }
    return res.status(403).json({ msg: "Access denied. Admins only." });
  } catch (error) {
    console.error("Admin check error:", error.message);
    res.status(500).json({ msg: "Server error while verifying admin role" });
  }
};

module.exports = isAdmin;

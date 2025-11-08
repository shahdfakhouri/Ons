const jwt = require("jsonwebtoken");
const JWT_SECRET = "2003"; // should match AuthController

// 🧩 Middleware: Verify JWT token for protected routes
const verifyToken = (req, res, next) => {
  const authHeader = req.headers.authorization;

  // Check if Authorization header exists
  if (!authHeader) {
    return res.status(401).json({ error: "Access denied. No token provided." });
  }

  // Extract token (expects "Bearer <token>")
  const token = authHeader.split(" ")[1];
  if (!token) {
    return res.status(401).json({ error: "Access denied. Token missing." });
  }

  // Verify token
  jwt.verify(token, JWT_SECRET, (err, decoded) => {
    if (err) {
      console.error("JWT verification error:", err.message);
      return res.status(403).json({ error: "Invalid token", details: err.message });
    }

    // Attach user data to request
    req.user = decoded;
    next();
  });
};

module.exports = verifyToken;

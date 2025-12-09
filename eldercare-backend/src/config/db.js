const mysql = require("mysql");

// ✅ Create a connection pool
const pool = mysql.createPool({
  connectionLimit: 10,
  host: "127.0.0.1",
  user: "root",
  password: "",
  database: "ons", // ✅ your DB name
  port: 3306
});

// ✅ Test connection
pool.getConnection((err, connection) => {
  if (err) {
    console.error("❌ Error connecting to MySQL:", err.message);
  } else {
    console.log("✅ MySQL connection pool created successfully (ons)");
    connection.release();
  }
});

module.exports = pool; // ✅ make sure you export the pool

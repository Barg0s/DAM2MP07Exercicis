const path = require('path');
const sqlite3 = require('sqlite3').verbose();

// __dirname apunta a 'exercici04/lib/'
const dbPath = path.join(__dirname, '..', 'database', 'bargados.db');

const db = new sqlite3.Database(dbPath, (err) => {
  if (err) {
    console.error("Error abriendo la base de datos:", err.message);
  } else {
    console.log("Base de datos conectada correctamente!");
  }
});

module.exports = db;

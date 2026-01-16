const express = require('express');
const cors = require('cors');
const fs = require('fs');       
const path = require('path');

const app = express();
const port = 3000;

app.use(express.static('public'))

// Configurar direcció ‘/’ 
app.get('/', async (req, res) => {
    res.send(`Hello World /`)
})


app.post('/categories', (req, res) => {
  const filePath = path.join(__dirname, 'data', 'database.json');
  fs.readFile(filePath, 'utf8', (err, data) => {
    if (err) {
      console.error('Error al leer categories.json', err);
      return res.status(500).json({ error: 'No se pudo leer el archiv o' });
    }
    const categories = JSON.parse(data);
    res.json(categories);
  });
});

// Activar el servidor
const httpServer = app.listen(port, appListen)
function appListen () {
    console.log(`Example app listening on: http://0.0.0.0:${port}`)
}

process.on('SIGTERM', shutDown);
process.on('SIGINT', shutDown);
function shutDown() {
    
    console.log('Received kill signal, shutting down gracefully');
    httpServer.close()
    process.exit(0);
}

const express = require('express');
const cors = require('cors');
const fs = require('fs');
const path = require('path');

const app = express();
app.use(cors());
app.use(express.json());

// Leer databse.json
const dataPath = path.join(__dirname, 'data', 'database.json');
const items = JSON.parse(fs.readFileSync(dataPath, 'utf8'));

// Ruta POST para obtener todos los items
app.post('/getItems', (req, res) => {
    res.json(items);
});

// Ruta GET para obtener un item por id (opcional, para detalle)
app.post('/getItem', (req, res) => {
    const id = req.body.id;
    const item = items.find(i => i.id == id);
    if (item) res.json(item);
    else res.status(404).json({error: 'Item no encontrado'});
});

// Servir imágenes desde public/Images usando GET
app.get('/images/:imgName', (req, res) => {
    const { imgName } = req.params;
    const imgPath = path.join(__dirname, 'public', 'Images', imgName);
    res.sendFile(imgPath);
});

// Iniciar servidor
app.listen(3000, () => console.log('Servidor escuchando en http://localhost:3000'));

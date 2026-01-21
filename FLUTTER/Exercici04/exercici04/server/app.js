const express = require('express');
const cors = require('cors');
const fs = require('fs');
const path = require('path');

const app = express();
const port = 3000;

app.use(cors());
app.use(express.json());

// Servir imágenes desde public/images
app.use('/images', express.static(path.join(__dirname, 'public/images')));

// Función para leer el JSON
function readData() {
  const filePath = path.join(__dirname, 'data', 'database.json');
  const raw = fs.readFileSync(filePath, 'utf8');
  return JSON.parse(raw);
}

// 👉 RUTA CORRECTA DE CATEGORIES
app.post('/categories', (req, res) => {
  try {
    const data = readData();
    res.json(data.categories); 
  } catch (err) {
    res.status(500).json({ error: 'Error leyendo categories' });
  }
});
app.post('/characters', (req, res) => {
  const { categoryId } = req.body;

  if (!categoryId) {
    return res.status(400).json({ error: 'categoryId requerido' });
  }

  try {
    const data = readData();
    const characters = data.characters.filter(
      c => c.categoryId === categoryId
    );
    res.json(characters);
  } catch (err) {
    res.status(500).json({ error: 'Error leyendo personajes' });
  }
});

// Iniciar servidor
app.listen(port, () => {
  console.log(`Server running at http://localhost:${port}`);
});

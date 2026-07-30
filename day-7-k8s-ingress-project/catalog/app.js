const express = require('express');
const app = express();
const PORT = process.env.PORT || 80;

app.get('/', (req, res) => {
  res.json([
    { id: 1, name: "Laptop", price: 1200 },
    { id: 2, name: "Headphones", price: 200 },
    { id: 3, name: "Keyboard", price: 100 }
  ]);
});

app.listen(PORT, () => {
  console.log(`Catalog service running on port ${PORT}`);
});
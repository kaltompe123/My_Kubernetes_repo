const express = require('express');
const app = express();
const PORT = process.env.PORT || 80;

app.get('/', (req, res) => {
  res.send('<h1>Welcome to the Online Store</h1><p>Navigate to /catalog or /orders</p>');
});

app.listen(PORT, () => {
  console.log(`Frontend running on port ${PORT}`);
});
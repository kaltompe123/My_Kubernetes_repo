const express = require('express');
const app = express();
const PORT = process.env.PORT || 80;

app.get('/', (req, res) => {
  res.send("Order Service is running! You can place an order here.");
});

app.listen(PORT, () => {
  console.log(`Orders service running on port ${PORT}`);
});
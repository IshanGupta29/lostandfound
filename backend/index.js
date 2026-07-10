
require('dotenv').config(); 
const express = require('express');
const mongoose = require('mongoose');
const cors = require('cors');

const authRoutes = require('./routes/auth');
const itemRoutes = require('./routes/item.route'); 

const app = express();
const PORT = process.env.PORT || 5000;
app.use(cors());

app.use(express.json());
// The Doorbell Logger
app.use((req, res, next) => {
  console.log(`[DOORBELL] Someone knocked: ${req.method} ${req.url}`);
  next();
});

app.use('/api/auth', authRoutes);
app.use('/api/item', itemRoutes);

mongoose.connect(process.env.MONGO_URI)
  .then(() => {
    console.log("🚀 Connected to Database Successfully!");
  })
  .catch((err) => {
    console.error("❌ Database connection error:", err);
  });

app.get('/', (req, res) => {
  res.send('Server is alive and breathing!');
});

//app.listen(PORT, '127.0.0.1', () => {
  //console.log(`📡 Server running on port ${PORT}`);
module.exports=app;

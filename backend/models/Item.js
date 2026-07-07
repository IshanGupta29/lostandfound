const mongoose = require('mongoose');

const itemSchema = new mongoose.Schema({
  userId: { type: String, required: true }, 
  title: { type: String, required: true },
  description: { type: String, required: true },
  location: { type: String, required: true },
  imageUrl: { type: String }, 
  type: { type: String, enum: ['lost', 'found'], required: true },
  status: { type: String, enum: ['active', 'claimed'], default: 'active' },
  createdAt: { type: Date, default: Date.now }
});

module.exports = mongoose.model('Item', itemSchema);
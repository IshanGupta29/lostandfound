const express = require('express');
const router = express.Router();
const jwt = require('jsonwebtoken');
const Item = require('../models/item'); // Importing your Blueprint!

// This must match the secret key you used in auth.js
const JWT_SECRET = process.env.JWT_SECRET || 'your_super_secret_campus_key';

// MIDDLEWARE: Checks if the request has a valid token
const verifyToken = (req, res, next) => {
    // Flutter will send the token in the headers
    const token = req.header('Authorization');
    if (!token) return res.status(401).json({ message: 'Access denied. No token provided.' });

    try {
        // Strip the word "Bearer " if it's there and verify
        const verified = jwt.verify(token.replace('Bearer ', ''), JWT_SECRET);
        req.user = verified; // Attach the user info to the request
        next(); // Move on to the route logic
    } catch (err) {
        res.status(400).json({ message: 'Invalid token.' });
    }
};

// 1. POST ROUTE: Create a new Lost/Found Item
router.post('/', verifyToken, async (req, res) => {
    try {
        // Build a new item using your Model blueprint
        const newItem = new Item({
            itemName: req.body.itemName,
            description: req.body.description,
            category: req.body.category,
            imageURL: req.body.imageURL || '', // Optional
            status: req.body.status,
            location: req.body.location,
            createdBy: req.user.userId // We get this safely from the verified token!
        });

        // Save it to MongoDB
        const savedItem = await newItem.save();
        res.status(201).json(savedItem);
    } catch (error) {
        res.status(500).json({ error: error.message });
    }
});

// 2. GET ROUTE: Fetch all items for the main feed
router.get('/', verifyToken, async (req, res) => {
    try {
        // Find all items, sort by newest first
        // .populate() pulls in the creator's name and email so people can contact them!
        const items = await Item.find()
            .sort({ date: -1 })
            .populate('createdBy', 'name email'); 
            
        res.status(200).json(items);
    } catch (error) {
        res.status(500).json({ error: error.message });
    }
});

module.exports = router;
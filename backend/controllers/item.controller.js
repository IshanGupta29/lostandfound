const Item = require('../models/Item');

// POST: Create a new lost/found item report
exports.createItem = async (req, res) => {
    try {
        const newItem = new Item(req.body);
        const savedItem = await newItem.save();
        res.status(201).json(savedItem);
    } catch (error) {
        res.status(500).json({ message: 'Error creating item', error: error.message });
    }
};

// GET: Fetch all reported items
exports.getAllItems = async (req, res) => {
    try {
        // Fetches all items, sorting the newest ones to the top
        const items = await Item.find().sort({ createdAt: -1 });
        res.status(200).json(items);
    } catch (error) {
        res.status(500).json({ message: 'Error fetching items', error: error.message });
    }
};

// PUT: Update item details or status
exports.updateItem = async (req, res) => {
    try {
        // Expects the frontend to send the itemId alongside the updated fields
        const { itemId, ...updateData } = req.body;
        const updatedItem = await Item.findByIdAndUpdate(itemId, updateData, { new: true });
        
        if (!updatedItem) {
            return res.status(404).json({ message: 'Item not found' });
        }
        res.status(200).json(updatedItem);
    } catch (error) {
        res.status(500).json({ message: 'Error updating item', error: error.message });
    }
};
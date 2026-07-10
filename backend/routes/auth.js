const express = require('express');
const router = express.Router();
const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');
const user = require('../models/user'); 

const JWT_SECRET = process.env.JWT_SECRET || 'your_super_secret_campus_key';

router.post('/login', async (req, res) => {
    try {
        const { email, password } = req.body;

        const user = await User.findOne({ email });
        if (!user) {
            return res.status(400).json({ message: 'Invalid email or password.' });
        }

        const isMatch = await bcrypt.compare(password, user.password);
        if (!isMatch) {
            return res.status(400).json({ message: 'Invalid email or password.' });
        }

        const token = jwt.sign(
            { userId: user._id }, 
            JWT_SECRET, 
            { expiresIn: '7d' } 
        );

        res.status(200).json({
            message: 'Login successful',
            token,
            user: {
                id: user._id,
                name: user.name,
                email: user.email
            }
        });

    } catch (error) {
        res.status(500).json({ message: 'Server error', error: error.message });
    }
});
// --- NEW REGISTER ROUTE ---
router.post('/register', async (req, res) => {
    try {
        const { name, email, password } = req.body;

        // 1. Check if the student already has an account
        const existingUser = await User.findOne({ email });
        if (existingUser) {
            return res.status(400).json({ message: 'An account with this email already exists.' });
        }

        // 2. Hash the password for security
        const salt = await bcrypt.genSalt(10);
        const hashedPassword = await bcrypt.hash(password, salt);

        // 3. Create the new user and save to database
        const newUser = new User({
            name,
            email,
            password: hashedPassword
        });
        
        await newUser.save();

        // 4. Send success signal back to Flutter
        res.status(201).json({ message: 'Registration successful!' });

    } catch (error) {
        console.error("Registration Error:", error);
        res.status(500).json({ message: 'Server error', error: error.message });
    }
});

module.exports = router;
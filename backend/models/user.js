const mongoose = require('mongoose');
const userSchema = new mongoose.Schema({
    name: {
        type: String,
        required: true
    },
    email: {
        type: String,
        required: true,
        unique: true, 
        match: [/^.+@goa\.bits-pilani\.ac\.in$/, 'You must use a valid BITS Pilani Goa email address']
    },
    password: {
        type: String,
        required: true
    }
});
module.exports = mongoose.model('User', userSchema);

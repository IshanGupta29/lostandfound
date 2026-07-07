const express = require('express');
const router = express.Router();
const itemController = require('../controllers/item.controller');

router.post('/create', itemController.createItem);
router.get('/all', itemController.getAllItems);
router.put('/update', itemController.updateItem);

module.exports = router;
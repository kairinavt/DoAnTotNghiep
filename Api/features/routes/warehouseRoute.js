const express = require('express');
const router = express.Router();
const WarehouseService = require('../services/warehouseService');
const service = new WarehouseService();

// Tồn kho — bỏ /:warehouseId
router.get('/get-inventory', async (req, res) => {
    try {
        res.json(await service.GetInventory());
    } catch (e) {
        res.status(500).send(e.message);
    }
});

router.get('/get-low-stock', async (req, res) => {
    try {
        res.json(await service.GetLowStockInventory());
    } catch (e) {
        res.status(500).send(e.message);
    }
});

router.put('/set-min-quantity', async (req, res) => {
    try {
        const { productId, minQuantity } = req.body;
        res.json(await service.SetMinQuantity(productId, minQuantity));
    } catch (e) {
        res.status(500).send(e.message);
    }
});

// Nhập / xuất — bỏ warehouseId
router.post('/import-stock', async (req, res) => {
    try {
        const { productId, quantity, note, accountId } = req.body;
        res.json(await service.ImportStock(productId, quantity, note, accountId));
    } catch (e) {
        res.status(500).send(e.message);
    }
});

router.post('/export-stock', async (req, res) => {
    try {
        const { productId, quantity, note, accountId } = req.body;
        res.json(await service.ExportStock(productId, quantity, note, accountId));
    } catch (e) {
        res.status(500).send(e.message);
    }
});

// Lịch sử
router.get('/get-stock-history', async (req, res) => {
    try {
        res.json(await service.GetStockHistory(req.query));
    } catch (e) {
        res.status(500).send(e.message);
    }
});

module.exports = router;
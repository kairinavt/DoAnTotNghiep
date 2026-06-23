const InvoiceController = require("../controllers/invoice/invoiceController");
const GenericHttpResponse = require('../generics/genericHttpResponse');
const express = require('express');
const router = express.Router();

const invoiceController = new InvoiceController();
const genericHttpResponse = new GenericHttpResponse();

router.post('/find-invoice', async (req, res) => {
    return invoiceController.FindInvoice(req.body, res);
});

router.post('/addnew-invoice', async (req, res) => {
    var result = await invoiceController.NewInvoice(req.body, res);
    if (result) genericHttpResponse.success(res, result);
    else genericHttpResponse.fail(res, result);
});

router.get('/getbyid-invoice/:id', async (req, res) => {
    var result = await invoiceController.GetInvoiceById(req, res);
    if (result) genericHttpResponse.success(res, result);
    else genericHttpResponse.fail(res, result);
});

router.get('/getall-invoice', async (req, res) => {
    var result = await invoiceController.GetAllInvoices(req, res);
    if (result) genericHttpResponse.success(res, result);
    else genericHttpResponse.fail(res, result);
});

router.get('/get-by-accountId/:accountId', async (req, res) => {
    var result = await invoiceController.GetInvoiceByAccountId(req, res);
    if (result) genericHttpResponse.success(res, result);
    else genericHttpResponse.fail(res, result);
});

// Route hủy đơn hàng
router.put('/cancel-invoice/:id', async (req, res) => {
    try {
        var result = await invoiceController.CancelInvoice(req, res); 
        if (result) genericHttpResponse.success(res, result);
        else genericHttpResponse.fail(res, result);
    } catch (e) {
        res.status(500).json({ message: e.message });
    }
});


router.put('/complete/:id', async (req, res) => {
    try {
        var result = await invoiceController.CompleteInvoice(req, res);
        if (result) genericHttpResponse.success(res, result);
        else genericHttpResponse.fail(res, result);
    } catch (e) {
        res.status(500).json({ message: e.message });
    }
});
module.exports = router;
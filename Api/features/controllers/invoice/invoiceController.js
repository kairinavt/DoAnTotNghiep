const InvoiceService = require("../../services/invoiceService");
const invoiceService = new InvoiceService();

class InvoiceController {
    constructor() {}

    async NewInvoice(req, res) {
        const { nameInvoice, details, productId, quantity, price, address, date, accountId } = req;
        return await invoiceService.NewInvoice(nameInvoice, details, productId, quantity, price, address, date, accountId);
    }

    async FindInvoice(req, res) {
        const { accountId } = req;
        return await invoiceService.FindInvoice(accountId);
    }

    async GetInvoiceById(req, res) {
        return await invoiceService.GetInvoiceById(req.params.id);
    }

    async GetAllInvoices(req, res) {
        return await invoiceService.GetAllInvoices();
    }

    async GetInvoiceByAccountId(req, res) {
        return await invoiceService.GetInvoiceByAccountId(req.params.accountId);
    }

    // Hủy đơn hàng
    async CancelInvoice(req, res) {
        const { id } = req.params;
        const { cancelReason } = req.body;
        return await invoiceService.CancelInvoice(id, cancelReason);
    }

    // Hoàn thành đơn hàng
    async CompleteInvoice(req, res) {
        const { id } = req.params;
        return await invoiceService.CompleteInvoice(id);
    }
}

module.exports = InvoiceController;
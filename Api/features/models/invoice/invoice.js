const { Schema, model } = require('mongoose');

const DetailInvoiceSchema = new Schema({
    productId: { type: String, required: true },
    product: { type: Schema.Types.ObjectId, required: true, ref: 'Product' },
    quantity: { type: Number, required: true },
    price: { type: Number, required: true },
    address: { type: String, required: true },
    date: { type: String, required: true },
});
const DetailInvoiceModel = model('DetailInvoice', DetailInvoiceSchema);

const InvoiceSchema = new Schema({
    nameInvoice: { type: String, required: true },
    details: [{ type: Schema.Types.ObjectId, ref: 'DetailInvoice' }],
    accountId: { type: String, required: true },
    account: { type: Schema.Types.ObjectId, ref: 'Accounts' },
    status: { type: String, enum: ['active', 'cancelled', 'completed'], default: 'active' },
    cancelReason: { type: String },
    completedAt: { type: Date }
});

const InvoiceModel = model('Invoice', InvoiceSchema);
module.exports = { InvoiceModel, DetailInvoiceModel };
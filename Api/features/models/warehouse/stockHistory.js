const mongoose = require('mongoose');
const { Schema } = mongoose;

const stockHistorySchema = new Schema({
    productId: { type: Schema.Types.ObjectId, ref: 'Product', required: true },
    type: { type: String, enum: ['import', 'export'], required: true },
    quantity: { type: Number, required: true },
    note: { type: String },
    accountId: { type: Schema.Types.ObjectId, ref: 'Accounts' },
    date: { type: Date, default: Date.now }
});

const StockHistoryModel = mongoose.model('StockHistory', stockHistorySchema);
module.exports = { StockHistoryModel };
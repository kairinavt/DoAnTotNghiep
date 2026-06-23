const mongoose = require('mongoose');
const { Schema } = mongoose;

const inventorySchema = new Schema({
    productId: { type: Schema.Types.ObjectId, ref: 'Product', required: true, unique: true },
    quantity: { type: Number, default: 0 },
    minQuantity: { type: Number, default: 10 }
}, { timestamps: true });

const InventoryModel = mongoose.model('Inventory', inventorySchema);
module.exports = { InventoryModel };
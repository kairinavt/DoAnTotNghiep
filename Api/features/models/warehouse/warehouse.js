const mongoose = require('mongoose');
const { Schema } = mongoose;

const warehouseSchema = new Schema({
    name: { type: String, required: true },     // Tên kho/chi nhánh
    address: { type: String },
    isActive: { type: Boolean, default: true }
}, { timestamps: true });

const WarehouseModel = mongoose.model('Warehouse', warehouseSchema);
module.exports = { WarehouseModel };
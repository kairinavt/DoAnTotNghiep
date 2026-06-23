const { InventoryModel } = require('../models/warehouse/inventory');
const { StockHistoryModel } = require('../models/warehouse/stockHistory');
const { ProductModel } = require('../models/product/product');

class WarehouseService {
    constructor() {}

    async GetOrCreateInventory(productId) {
        let inv = await InventoryModel.findOne({ productId }).exec();
        if (!inv) {
            inv = new InventoryModel({ productId, quantity: 0 });
            await inv.save();
        }
        return inv;
    }

   
  async SyncProductQuantity(productId, quantity) {
    const mongoose = require('mongoose');
    const result = await ProductModel.collection.updateOne(
        { _id: new mongoose.Types.ObjectId(productId) },
        { $set: { quantity: quantity } }
    );
    console.log('Kết quả đồng bộ:', result.modifiedCount);
}

    async GetInventory() {
        try {
            return await InventoryModel.find().populate('productId').exec();
        } catch (e) {
            throw new Error('Lỗi lấy tồn kho: ' + e.message);
        }
    }

    async SetMinQuantity(productId, minQuantity) {
        try {
            const inv = await this.GetOrCreateInventory(productId);
            inv.minQuantity = minQuantity;
            await inv.save();
            return inv;
        } catch (e) {
            throw new Error('Lỗi cập nhật ngưỡng cảnh báo: ' + e.message);
        }
    }

    async ImportStock(productId, quantity, note, accountId) {
        try {
            if (quantity <= 0) throw new Error('Số lượng nhập phải lớn hơn 0');

            const inv = await this.GetOrCreateInventory(productId);
            inv.quantity += quantity;
            await inv.save();

            await this.SyncProductQuantity(productId, inv.quantity);

            await StockHistoryModel.create({
                productId, type: 'import', quantity, note, accountId
            });

            return inv;
        } catch (e) {
            throw new Error('Lỗi nhập hàng: ' + e.message);
        }
    }

    async ExportStock(productId, quantity, note, accountId) {
        try {
            if (quantity <= 0) throw new Error('Số lượng xuất phải lớn hơn 0');

            const inv = await this.GetOrCreateInventory(productId);
            if (inv.quantity < quantity) {
                throw new Error('Số lượng trong kho không đủ (còn ' + inv.quantity + ')');
            }

            inv.quantity -= quantity;
            await inv.save();

            await this.SyncProductQuantity(productId, inv.quantity);

            await StockHistoryModel.create({
                productId, type: 'export', quantity, note, accountId
            });

            return inv;
        } catch (e) {
            throw new Error('Lỗi xuất hàng: ' + e.message);
        }
    }

    async GetLowStockInventory() {
        try {
            return await InventoryModel.find({
                $expr: { $lte: ['$quantity', '$minQuantity'] }
            }).populate('productId').exec();
        } catch (e) {
            throw new Error('Lỗi lấy danh sách sắp hết hàng: ' + e.message);
        }
    }

    async GetStockHistory(filter = {}) {
        try {
            const query = {};
            if (filter.productId) query.productId = filter.productId;
            if (filter.type) query.type = filter.type;
            if (filter.fromDate || filter.toDate) {
                query.date = {};
                if (filter.fromDate) query.date.$gte = new Date(filter.fromDate);
                if (filter.toDate) query.date.$lte = new Date(filter.toDate);
            }

            return await StockHistoryModel.find(query)
                .populate('productId')
                .populate('accountId')
                .sort({ date: -1 })
                .exec();
        } catch (e) {
            throw new Error('Lỗi lấy lịch sử: ' + e.message);
        }
    }
}

module.exports = WarehouseService;
const { InvoiceModel, DetailInvoiceModel } = require('../models/invoice/invoice');
const WarehouseService = require('./warehouseService');
const warehouseService = new WarehouseService();
const nodemailer = require('nodemailer');

// Cấu hình Gmail SMTP
const transporter = nodemailer.createTransport({
    service: 'gmail',
    auth: {
        user: 'dkhai0309@gmail.com',
        pass: 'kepu guox wwog cyfs'
    }
});

class InvoiceService {
    constructor() {}

    async NewInvoice(nameInvoice, details, productId, quantity, price, address, date, accountId) {
        try {
            let newDetailIds = [];

            if (details != null && details instanceof Array) {
                for (let index = 0; index < details.length; index++) {
                    const element = details[index];
                    const { productId, quantity, price, address, date } = element;

                    let detail = new DetailInvoiceModel({
                        productId, quantity, price, address, date, product: productId
                    });
                    const newDetail = await detail.save();
                    newDetailIds.push(newDetail._id);

                    // Xuất kho tự động
                    try {
                        await warehouseService.ExportStock(productId, quantity, 'Xuất theo hóa đơn', accountId);
                    } catch (stockErr) {
                        console.warn(`Cảnh báo tồn kho cho sản phẩm ${productId}:`, stockErr.message);
                    }
                }
            }

            const i = await InvoiceModel.find().exec();
            nameInvoice = `HD${i.length + 1}`;

            const invoice = new InvoiceModel({
                nameInvoice, details: newDetailIds, productId, quantity,
                price, address, date, accountId, account: accountId
            });
            const res = await invoice.save();
            return await this.GetInvoiceById(res._id);
        } catch (e) {
            throw new Error('Lỗi tạo hóa đơn: ' + e.message);
        }
    }

    // ===== HỦY ĐƠN HÀNG =====
    async CancelInvoice(invoiceId, cancelReason) {
        try {
            const invoice = await InvoiceModel.findById(invoiceId)
                .populate('account')
                .populate({ path: 'details', populate: { path: 'product' } })
                .exec();

            if (!invoice) throw new Error('Không tìm thấy hóa đơn');
            if (invoice.status === 'cancelled') throw new Error('Đơn hàng đã bị hủy trước đó');

            invoice.status = 'cancelled';
            invoice.cancelReason = cancelReason || 'Khách hàng hủy đơn';
            await invoice.save();

            // Hoàn kho cho từng sản phẩm
            for (const detail of invoice.details) {
                try {
                    await warehouseService.ImportStock(
                        detail.productId,
                        detail.quantity,
                        `Hoàn kho do hủy đơn ${invoice.nameInvoice}`,
                        null
                    );
                } catch (stockErr) {
                    console.warn('Lỗi hoàn kho:', stockErr.message);
                }
            }

            if (invoice.account?.email) {
                await this.SendCancelEmail(invoice);
            }

            return invoice;
        } catch (e) {
            throw new Error('Lỗi hủy đơn hàng: ' + e.message);
        }
    }

    async SendCancelEmail(invoice) {
        try {
            const name = invoice.account?.name || 'Quý khách';
            const email = invoice.account?.email;

            let proList = '';
            let totalQuan = 0;
            let totalPrice = 0;

            for (const detail of invoice.details) {
                const proName = detail.product?.nameProduct || 'Sản phẩm';
                totalQuan += detail.quantity;
                totalPrice += detail.quantity * detail.price;
                proList += `
                    <tr>
                        <td>${proName}</td>
                        <td>${detail.quantity}</td>
                        <td>${detail.price.toLocaleString('vi-VN')} đ</td>
                    </tr>`;
            }

            const html = `
<!DOCTYPE html>
<html lang="vi">
<head>
    <meta charset="UTF-8">
    <style>
        body { font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif; background-color: #f4f7f6; margin: 0; padding: 20px; }
        .wrapper { max-width: 600px; margin: 0 auto; background: #ffffff; border-radius: 16px; overflow: hidden; box-shadow: 0 4px 15px rgba(0,0,0,0.1); }
        .header { background: #888; color: #ffffff; padding: 30px; text-align: center; }
        .header h1 { margin: 0; font-size: 24px; letter-spacing: 1px; }
        .content { padding: 30px; }
        .info-box { background: #f8f9fa; padding: 15px; border-radius: 10px; margin-bottom: 20px; font-size: 14px; color: #555; }
        .item-table { width: 100%; border-collapse: collapse; table-layout: fixed; margin-top: 10px; }
        .item-table th { background: #f1f1f1; padding: 12px; text-align: left; font-size: 13px; color: #333; }
        .item-table td { padding: 12px; border-bottom: 1px solid #eee; font-size: 14px; word-wrap: break-word; }
        .total-row { background: #f5f5f5; font-weight: bold; }
        .footer { text-align: center; padding: 20px; font-size: 12px; color: #999; }
        .cancel-badge { display: inline-block; background: #dc3545; color: white; padding: 6px 16px; border-radius: 20px; font-weight: bold; margin-bottom: 16px; }
    </style>
</head>
<body>
    <div class="wrapper">
        <div class="header">
            <h1>THÔNG BÁO HỦY ĐƠN HÀNG</h1>
        </div>
        <div class="content">
            <p>Chào <strong>${name}</strong>,</p>
            <span class="cancel-badge">ĐÃ HỦY</span>
            <p>Đơn hàng của bạn tại <b>Yummy Deli Canteen</b> đã được hủy thành công.</p>
            <div class="info-box">
                <p>🧾 <b>Mã đơn:</b> ${invoice.nameInvoice}</p>
                <p>❌ <b>Lý do hủy:</b> ${invoice.cancelReason}</p>
            </div>
            <table class="item-table">
                <thead>
                    <tr>
                        <th width="50%">Sản phẩm</th>
                        <th width="20%">SL</th>
                        <th width="30%">Giá</th>
                    </tr>
                </thead>
                <tbody>
                    ${proList}
                    <tr class="total-row">
                        <td>TỔNG CỘNG</td>
                        <td>${totalQuan} món</td>
                        <td>${totalPrice.toLocaleString('vi-VN')} đ</td>
                    </tr>
                </tbody>
            </table>
        </div>
        <div class="footer">
            <p>Yummy Deli Canteen | Hotline: 1900 1234</p>
            <p>&copy; 2026 CANTEEN YUMMY DELI. All rights reserved.</p>
        </div>
    </div>
</body>
</html>`;

            await transporter.sendMail({
                from: '"Yummy Deli noreply" <dkhai0309@gmail.com>',
                to: email,
                subject: `[Yummy Deli] Đơn hàng ${invoice.nameInvoice} đã bị hủy`,
                html
            });

            console.log('Đã gửi email hủy đơn đến:', email);
        } catch (e) {
            console.warn('Lỗi gửi email hủy đơn:', e.message);
        }
    }

    // ===== HOÀN THÀNH ĐƠN HÀNG =====
    async CompleteInvoice(invoiceId) {
        try {
            const invoice = await InvoiceModel.findById(invoiceId)
                .populate('account')
                .populate({ path: 'details', populate: { path: 'product' } })
                .exec();

            if (!invoice) throw new Error('Không tìm thấy hóa đơn');
            if (invoice.status === 'cancelled') throw new Error('Đơn hàng đã bị hủy, không thể hoàn thành');
            if (invoice.status === 'completed') throw new Error('Đơn hàng đã hoàn thành trước đó');

            invoice.status = 'completed';
            invoice.completedAt = new Date();
            await invoice.save();

            if (invoice.account?.email) {
                await this.SendCompleteEmail(invoice);
            }

            return invoice;
        } catch (e) {
            throw new Error('Lỗi hoàn thành đơn hàng: ' + e.message);
        }
    }

    async SendCompleteEmail(invoice) {
        try {
            const name = invoice.account?.name || 'Quý khách';
            const email = invoice.account?.email;

            let proList = '';
            let totalQuan = 0;
            let totalPrice = 0;

            for (const detail of invoice.details) {
                const proName = detail.product?.nameProduct || 'Sản phẩm';
                totalQuan += detail.quantity;
                totalPrice += detail.quantity * detail.price;
                proList += `
                    <tr>
                        <td>${proName}</td>
                        <td>${detail.quantity}</td>
                        <td>${detail.price.toLocaleString('vi-VN')} đ</td>
                    </tr>`;
            }

            const html = `
<!DOCTYPE html>
<html lang="vi">
<head>
    <meta charset="UTF-8">
    <style>
        body { font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif; background-color: #f4f7f6; margin: 0; padding: 20px; }
        .wrapper { max-width: 600px; margin: 0 auto; background: #ffffff; border-radius: 16px; overflow: hidden; box-shadow: 0 4px 15px rgba(0,0,0,0.1); }
        .header { background: #28a745; color: #ffffff; padding: 30px; text-align: center; }
        .header h1 { margin: 0; font-size: 24px; letter-spacing: 1px; }
        .content { padding: 30px; }
        .info-box { background: #f8f9fa; padding: 15px; border-radius: 10px; margin-bottom: 20px; font-size: 14px; color: #555; }
        .item-table { width: 100%; border-collapse: collapse; table-layout: fixed; margin-top: 10px; }
        .item-table th { background: #f1f1f1; padding: 12px; text-align: left; font-size: 13px; color: #333; }
        .item-table td { padding: 12px; border-bottom: 1px solid #eee; font-size: 14px; word-wrap: break-word; }
        .total-row { background: #f5f5f5; font-weight: bold; }
        .footer { text-align: center; padding: 20px; font-size: 12px; color: #999; }
        .complete-badge { display: inline-block; background: #28a745; color: white; padding: 6px 16px; border-radius: 20px; font-weight: bold; margin-bottom: 16px; }
    </style>
</head>
<body>
    <div class="wrapper">
        <div class="header">
            <h1>🎉 ĐƠN HÀNG HOÀN THÀNH</h1>
        </div>
        <div class="content">
            <p>Chào <strong>${name}</strong>,</p>
            <span class="complete-badge">HOÀN THÀNH</span>
            <p>Đơn hàng của bạn tại <b>Yummy Deli Canteen</b> đã được hoàn thành. Cảm ơn bạn đã tin tưởng sử dụng dịch vụ!</p>
            <div class="info-box">
                <p>🧾 <b>Mã đơn:</b> ${invoice.nameInvoice}</p>
                <p>✅ <b>Trạng thái:</b> Hoàn thành</p>
                <p>🕐 <b>Thời gian:</b> ${new Date().toLocaleString('vi-VN')}</p>
            </div>
            <table class="item-table">
                <thead>
                    <tr>
                        <th width="50%">Sản phẩm</th>
                        <th width="20%">SL</th>
                        <th width="30%">Giá</th>
                    </tr>
                </thead>
                <tbody>
                    ${proList}
                    <tr class="total-row">
                        <td>TỔNG CỘNG</td>
                        <td>${totalQuan} món</td>
                        <td>${totalPrice.toLocaleString('vi-VN')} đ</td>
                    </tr>
                </tbody>
            </table>
        </div>
        <div class="footer">
            <p>Yummy Deli Canteen | Hotline: 1900 1234</p>
            <p>&copy; 2026 CANTEEN YUMMY DELI. All rights reserved.</p>
        </div>
    </div>
</body>
</html>`;

            await transporter.sendMail({
                from: '"Yummy Deli noreply" <dkhai0309@gmail.com>',
                to: email,
                subject: `[Yummy Deli] Đơn hàng ${invoice.nameInvoice} đã hoàn thành`,
                html
            });

            console.log('Đã gửi email hoàn thành đơn đến:', email);
        } catch (e) {
            console.warn('Lỗi gửi email hoàn thành đơn:', e.message);
        }
    }

    async FindInvoice(accountId) {
        try {
            return await InvoiceModel.findOne({ accountId }).exec();
        } catch (e) {
            throw new Error('Lỗi tìm hóa đơn: ' + e.message);
        }
    }

    async GetInvoiceById(id) {
        try {
            return await InvoiceModel.findById(id)
                .populate('account')
                .populate({ path: 'details', populate: { path: 'product' } })
                .exec();
        } catch (e) {
            throw new Error('Lỗi lấy hóa đơn: ' + e.message);
        }
    }

    async GetAllInvoices() {
        try {
            return await InvoiceModel.find()
                .populate('account')
                .populate({ path: 'details', populate: { path: 'product' } })
                .exec();
        } catch (e) {
            throw new Error('Lỗi lấy danh sách hóa đơn: ' + e.message);
        }
    }

    async GetInvoiceByAccountId(accountId) {
        try {
            return await InvoiceModel.find({ accountId })
                .populate('account')
                .populate({ path: 'details', populate: { path: 'product' } })
                .exec();
        } catch (e) {
            throw new Error('Lỗi lấy hóa đơn theo tài khoản: ' + e.message);
        }
    }
}

module.exports = InvoiceService;
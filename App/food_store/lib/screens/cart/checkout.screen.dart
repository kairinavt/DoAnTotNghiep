import 'package:food_store/data/api_repository.dart';
import 'package:food_store/models/authorize/signup.model.dart';
import 'package:food_store/screens/cart/cart.screen.dart';
import 'package:food_store/screens/cart/vietqrpayment.screen.dart';
import 'package:food_store/screens/mainpage/mainpage.screen.dart';
import 'package:food_store/screens/setting/address.search.screen.dart';
import 'package:food_store/services/mail.service.dart';
import 'package:food_store/services/sqlite.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:intl/intl.dart';
import 'package:food_store/models/cart.dart';
import 'package:food_store/services/share_pre.dart';

class CheckoutPage extends StatefulWidget {
  final List<Cart> cartItems;

  const CheckoutPage({super.key, required this.cartItems});

  @override
  State<CheckoutPage> createState() => _CheckoutPageState();
}

class _CheckoutPageState extends State<CheckoutPage> {
  final DatabaseHelper _databaseHelper = DatabaseHelper();
  final APIRepository _apiRepository = APIRepository();
  final SharedPreferencesService _sharedPreferencesService =
      SharedPreferencesService();

  String addressLine1 = '';
  String _selectedPaymentMethod = 'vietqr'; // 'vietqr' hoặc 'cod'

  // Hàm chuyển sang màn hình tìm địa chỉ kiểu Grab và hứng kết quả trả về
  Future<void> _navigateToAddressScreen() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddressSearchScreen(currentAddress: addressLine1),
      ),
    );

    if (result != null && result is String) {
      setState(() {
        addressLine1 = result;
      });
    }
  }

  // Hàm bóc tách chuỗi món ăn kèm
  Map<String, dynamic> _parseCartItemName(String fullName) {
    if (fullName.contains('(') && fullName.contains(')')) {
      final startIndex = fullName.indexOf('(');
      final endIndex = fullName.indexOf(')');

      final mainName = fullName.substring(0, startIndex).trim();
      final extrasString = fullName.substring(startIndex + 1, endIndex);
      final extrasList = extrasString
          .split(',')
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .toList();

      return {
        'mainName': mainName,
        'hasExtras': true,
        'extras': extrasList,
      };
    }
    return {
      'mainName': fullName,
      'hasExtras': false,
      'extras': <String>[],
    };
  }

  String formatCurrency(double amount) {
    final formatter = NumberFormat.currency(locale: 'vi_VN', symbol: 'VND');
    return formatter.format(amount);
  }

  Future<void> _handleCheckout() async {
    if (addressLine1.isEmpty) {
      Fluttertoast.showToast(
          msg: 'Vui lòng chọn địa chỉ giao hàng',
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.BOTTOM,
          backgroundColor: Colors.red,
          textColor: Colors.white,
          fontSize: 16.0);
      return;
    }

    String? accountId = await _sharedPreferencesService.getAccountID();
    AccountModel? account = await _sharedPreferencesService.getAccountInfo();

    if (accountId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Không tìm thấy thông tin tài khoản')),
      );
      return;
    }

    String date = DateFormat('dd-MM-yyyy').format(DateTime.now());
    final invoiceData = {
      'details': widget.cartItems.map((item) {
        return {
          'productId': item.productID,
          'quantity': item.quantity,
          'price': item.price,
          'address': addressLine1,
          'date': date,
        };
      }).toList(),
      'accountId': accountId,
    };

    final int cartTotal = widget.cartItems
        .fold(0, (sum, item) => sum + (item.price * item.quantity).toInt());

    _apiRepository.addNewInvoice(invoiceData).then((invoice) {
      if (invoice != null) {
        String proList = '';
        int totalQuan = 0;
        for (var d in invoice.details) {
          proList += '''
            <tr>
              <td>${d.product.nameProduct}</td>
              <td>${d.quantity} cái</td>
              <td>${d.price * d.quantity} VND</td>
            </tr>
          ''';
          totalQuan += d.quantity;
        }
        sendEmail(
          account!.email,
          _emailTemplate(account.name, addressLine1, date, invoice.nameInvoice,
              proList, totalQuan, cartTotal),
          'Đặt hàng thành công',
        );

        _databaseHelper.deleteProductAll();

        if (_selectedPaymentMethod == 'vietqr') {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => VietQRPaymentScreen(
                amount: cartTotal.toDouble(),
                invoiceName: invoice.nameInvoice,
                orderId: accountId,
              ),
            ),
          );
        } else {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const MainPageScreen()),
          );
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Đặt hàng thành công! Thanh toán khi nhận hàng.'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Không thể tạo đơn hàng, thử lại!')),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    int total = widget.cartItems
        .fold(0, (sum, item) => sum + (item.price * item.quantity).toInt());

    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA), // Đổi nền sang xám nhạt cao cấp
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          'Xác nhận đơn hàng',
          style: TextStyle(
              color: Colors.black, fontSize: 18, fontWeight: FontWeight.bold),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new,
              size: 18, color: Colors.black),
          onPressed: () => Navigator.push(
            context,
            MaterialPageRoute(
                builder: (_) =>
                    const MainPageScreen(currentScreen: CartPage())),
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Thẻ Địa chỉ giao hàng thiết kế lại bóng bẩy cực đẹp
            const Text('Giao đến',
                style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: Colors.black54)),
            const SizedBox(height: 8),
            GestureDetector(
              onTap:
                  _navigateToAddressScreen, // Bấm nguyên cái card để đổi địa chỉ luôn
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                        color: Colors.black.withOpacity(0.03),
                        blurRadius: 10,
                        offset: const Offset(0, 4))
                  ],
                  border: Border.all(color: Colors.grey.shade100),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.location_on,
                        color: Color(0xfff56789), size: 26),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            addressLine1.isEmpty
                                ? 'Bấm để chọn địa chỉ nhận hàng...'
                                : addressLine1,
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: addressLine1.isEmpty
                                  ? FontWeight.normal
                                  : FontWeight.w600,
                              color: addressLine1.isEmpty
                                  ? Colors.grey
                                  : Colors.black,
                            ),
                          ),
                          const SizedBox(height: 6),
                          const Text(
                            'Thời gian giao: Giao ngay lập tức (20-30 phút)',
                            style: TextStyle(
                                fontSize: 13,
                                color: Colors.green,
                                fontWeight: FontWeight.w500),
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.arrow_forward_ios,
                        size: 14, color: Colors.grey),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            // 2. Chi tiết tóm tắt đơn hàng & Món đi kèm dòng dưới
            const Text('Tóm tắt đơn hàng',
                style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: Colors.black54)),
            const SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                      color: Colors.black.withOpacity(0.03),
                      blurRadius: 10,
                      offset: const Offset(0, 4))
                ],
                border: Border.all(color: Colors.grey.shade100),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Column(
                  children: [
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: widget.cartItems.length,
                      itemBuilder: (context, index) {
                        final item = widget.cartItems[index];
                        final parsedData = _parseCartItemName(item.name);
                        final String mainProductName = parsedData['mainName'];
                        final bool hasExtras = parsedData['hasExtras'];
                        final List<String> extras = parsedData['extras'];

                        return Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16.0, vertical: 10.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Text(
                                      '$mainProductName x${item.quantity}',
                                      style: const TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.bold,
                                          color: Color(0xFF2D2D2D)),
                                    ),
                                  ),
                                  Text(
                                    formatCurrency(item.price * item.quantity),
                                    style: const TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w600),
                                  ),
                                ],
                              ),
                              if (hasExtras) ...[
                                const SizedBox(height: 6),
                                ...extras.map((extraName) => Padding(
                                      padding: const EdgeInsets.only(
                                          left: 16.0, top: 4.0),
                                      child: Row(
                                        children: [
                                          const Icon(
                                              Icons.subdirectory_arrow_right,
                                              size: 14,
                                              color: Colors.grey),
                                          const SizedBox(width: 6),
                                          Expanded(
                                            child: Text(
                                              '$extraName x${item.quantity}',
                                              style: TextStyle(
                                                  fontSize: 13,
                                                  color: Colors.grey[600],
                                                  fontStyle: FontStyle.italic),
                                            ),
                                          ),
                                        ],
                                      ),
                                    )),
                              ],
                              const SizedBox(height: 10),
                              const Divider(
                                  height: 1, color: Color(0xFFF5F5F5)),
                            ],
                          ),
                        );
                      },
                    ),
                    ListTile(
                      contentPadding:
                          const EdgeInsets.symmetric(horizontal: 16),
                      title: const Text('Tổng cộng tiền món',
                          style: TextStyle(
                              fontWeight: FontWeight.w500,
                              fontSize: 14,
                              color: Colors.grey)),
                      trailing: Text(
                        formatCurrency(total.toDouble()),
                        style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                            color: Color(0xfff56789)),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            // 3. Chọn phương thức thanh toán
            const Text('Phương thức thanh toán',
                style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: Colors.black54)),
            const SizedBox(height: 8),

            _paymentOption(
              value: 'vietqr',
              icon: Icons.qr_code_2,
              title: 'VietQR / Chuyển khoản nhanh',
              subtitle: 'Quét mã QR qua ứng dụng ngân hàng',
              color: const Color(0xFF0063B2),
            ),

            const SizedBox(height: 8),

            _paymentOption(
              value: 'cod',
              icon: Icons.payments_outlined,
              title: 'Tiền mặt (COD)',
              subtitle: 'Thanh toán tiền trực tiếp khi nhận hàng',
              color: Colors.orange,
            ),

            const SizedBox(height: 32),

            // 4. Khối nút Đặt hàng bự tràn viền mượt mà
            Center(
              child: SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _handleCheckout,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xfff56789),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                  ),
                  child: const Text(
                    'Xác nhận đặt hàng',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _paymentOption({
    required String value,
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
  }) {
    final isSelected = _selectedPaymentMethod == value;
    return GestureDetector(
      onTap: () => setState(() => _selectedPaymentMethod = value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isSelected ? color.withOpacity(0.04) : Colors.white,
          border: Border.all(
            color: isSelected ? color.withOpacity(0.7) : Colors.grey.shade200,
            width: isSelected ? 1.5 : 1,
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(0.01),
                blurRadius: 10,
                offset: const Offset(0, 2))
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          color: isSelected ? color : Colors.black87)),
                  const SizedBox(height: 2),
                  Text(subtitle,
                      style: const TextStyle(color: Colors.grey, fontSize: 12)),
                ],
              ),
            ),
            Radio<String>(
              value: value,
              groupValue: _selectedPaymentMethod,
              onChanged: (v) => setState(() => _selectedPaymentMethod = v!),
              activeColor: color,
            ),
          ],
        ),
      ),
    );
  }

  String _emailTemplate(
    String name,
    String address,
    String date,
    String nameInvoice,
    String proList,
    int totalQuan,
    int totalPrice,
  ) {

    String formatPrice(int price) {
      return price.toString().replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.');
    }

    return '''
<!DOCTYPE html>
<html lang="vi">
<head>
    <meta charset="UTF-8">
    <style>
        body { font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif; background-color: #f4f7f6; margin: 0; padding: 20px; }
        .wrapper { max-width: 600px; margin: 0 auto; background: #ffffff; border-radius: 16px; overflow: hidden; box-shadow: 0 4px 15px rgba(0,0,0,0.1); }
        .header { background: #ffb0b0; color: #ffffff; padding: 30px; text-align: center; }
        .header h1 { margin: 0; font-size: 24px; letter-spacing: 1px; }
        .content { padding: 30px; }
        .info-box { background: #f8f9fa; padding: 15px; border-radius: 10px; margin-bottom: 20px; font-size: 14px; color: #555; }
        .item-table { width: 100%; border-collapse: collapse; table-layout: fixed; margin-top: 10px; }
        .item-table th { background: #f1f1f1; padding: 12px; text-align: left; font-size: 13px; color: #333; }
        .item-table td { padding: 12px; border-bottom: 1px solid #eee; font-size: 14px; word-wrap: break-word; }
        .total-row { background: #fff5f5; font-weight: bold; }
        .footer { text-align: center; padding: 20px; font-size: 12px; color: #999; }
    </style>
</head>
<body>
    <div class="wrapper">
        <div class="header">
            <h1>XÁC NHẬN ĐƠN HÀNG</h1>
        </div>
        <div class="content">
            <p>Chào <strong>$name</strong>,</p>
            <p>Cảm ơn bạn đã đặt món tại <b>Yummy Deli Canteen</b>. Đơn hàng của bạn đã được xác nhận!</p>
            
            <div class="info-box">
                <p>📍 <b>Địa chỉ:</b> $address</p>
                <p>📅 <b>Ngày đặt:</b> $date</p>
                <p>🧾 <b>Mã đơn:</b> $nameInvoice</p>
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
                    $proList
                    <tr class="total-row">
                        <td>TỔNG CỘNG</td>
                        <td>$totalQuan món</td>
                        <td>${formatPrice(totalPrice)} đ</td>
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
</html>
''';
  }
}

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:food_store/screens/cart/order.succesful.dart';
import 'package:food_store/services/vietqr.service.dart';

class VietQRPaymentScreen extends StatefulWidget {
  final double amount;
  final String invoiceName;
  final String orderId;

  const VietQRPaymentScreen({
    super.key,
    required this.amount,
    required this.invoiceName,
    required this.orderId,
  });

  @override
  State<VietQRPaymentScreen> createState() => _VietQRPaymentScreenState();
}

class _VietQRPaymentScreenState extends State<VietQRPaymentScreen>
    with SingleTickerProviderStateMixin {
  bool _isLoading = true;
  VietQRResult? _qrResult;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  // Giả lập kiểm tra thanh toán (production cần webhook/polling)
  bool _paymentConfirmed = false;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..repeat(reverse: true);
    _pulseAnimation =
        Tween<double>(begin: 0.95, end: 1.05).animate(_pulseController);

    _generateQR();
  }

  Future<void> _generateQR() async {
    setState(() => _isLoading = true);
    final result = await VietQRService.generateQR(
      amount: widget.amount,
      description: '${widget.invoiceName} - ${widget.orderId}',
    );
    setState(() {
      _qrResult = result;
      _isLoading = false;
    });
  }

  void _confirmPayment() {
    setState(() => _paymentConfirmed = true);
    Future.delayed(const Duration(milliseconds: 800), () {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const OrderSuccessScreen()),
        (route) => false,
      );
    });
  }

  String _formatCurrency(double amount) {
    final formatted = amount.toInt().toString().replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (m) => '${m[1]}.',
        );
    return '$formatted VND';
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAF8FF),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Thanh toán VietQR',
          style: TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.w700,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
      ),
      body: _isLoading
          ? _buildLoading()
          : _qrResult?.success == true
              ? _buildQRContent()
              : _buildError(),
    );
  }

  Widget _buildLoading() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(color: Color(0xFFf56789)),
          SizedBox(height: 16),
          Text(
            'Đang tạo mã QR...',
            style: TextStyle(color: Colors.grey, fontSize: 15),
          ),
        ],
      ),
    );
  }

  Widget _buildError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.redAccent),
            const SizedBox(height: 16),
            Text(
              _qrResult?.error ?? 'Không thể tạo mã QR',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16, color: Colors.black54),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _generateQR,
              icon: const Icon(Icons.refresh),
              label: const Text('Thử lại'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFf56789),
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQRContent() {
    final qrBytes = base64Decode(
      _qrResult!.qrDataURL!.replaceFirst('data:image/png;base64,', ''),
    );

    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        child: Column(
          children: [
            // Thông tin đơn hàng
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.06),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Đơn hàng',
                          style: TextStyle(color: Colors.grey, fontSize: 14)),
                      Text(
                        widget.invoiceName,
                        style: const TextStyle(
                            fontWeight: FontWeight.w600, fontSize: 14),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Divider(height: 1),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Số tiền cần thanh toán',
                          style: TextStyle(color: Colors.grey, fontSize: 14)),
                      Text(
                        _formatCurrency(widget.amount),
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 16,
                          color: Color(0xFFf56789),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // QR Code card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: 20,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Column(
                children: [
                  // Logo VietQR
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        // decoration: BoxDecoration(
                        //   gradient: const LinearGradient(
                        //     colors: [Color(0xFF0063B2), Color(0xFF00A550)],
                        //   ),
                        //   borderRadius: BorderRadius.circular(8),
                        // ),
                        // child: const Text(
                        //   'VietQR',
                        //   style: TextStyle(
                        //     color: Colors.white,
                        //     fontWeight: FontWeight.w900,
                        //     fontSize: 16,
                        //     letterSpacing: 1,
                        //   ),
                        // ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  // QR Image
                  ScaleTransition(
                    scale: _pulseAnimation,
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: const Color(0xFFf56789).withOpacity(0.4),
                          width: 2,
                        ),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.memory(
                          qrBytes,
                          width: 240,
                          height: 240,
                          fit: BoxFit.contain,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Thông tin ngân hàng
                  _infoRow(
                      Icons.account_balance, 'Ngân hàng', 'Vietcombank (VCB)'),
                  const SizedBox(height: 8),
                  _infoRow(Icons.account_box_outlined, 'Tài khoản',
                      VietQRService.shopAccountNo),
                  const SizedBox(height: 8),
                  _infoRow(Icons.person_outline, 'Chủ tài khoản',
                      VietQRService.shopAccountName),
                  const SizedBox(height: 8),
                  _infoRow(Icons.notes_outlined, 'Nội dung',
                      '${widget.invoiceName} - ${widget.orderId}'),

                  const SizedBox(height: 16),

                  // Copy nội dung chuyển khoản
                  OutlinedButton.icon(
                    onPressed: () {
                      Clipboard.setData(ClipboardData(
                        text: '${widget.invoiceName} - ${widget.orderId}',
                      ));
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Đã sao chép nội dung chuyển khoản'),
                          duration: Duration(seconds: 2),
                        ),
                      );
                    },
                    icon: const Icon(Icons.copy, size: 16),
                    label: const Text('Sao chép nội dung'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFFf56789),
                      side: const BorderSide(color: Color(0xFFf56789)),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Hướng dẫn
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF3F5),
                borderRadius: BorderRadius.circular(12),
                border:
                    Border.all(color: const Color(0xFFf56789).withOpacity(0.3)),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('📱 Hướng dẫn thanh toán:',
                      style:
                          TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                  SizedBox(height: 8),
                  Text('1. Mở app ngân hàng của bạn',
                      style: TextStyle(fontSize: 13, color: Colors.black87)),
                  Text('2. Chọn "Quét QR" hoặc "Chuyển khoản QR"',
                      style: TextStyle(fontSize: 13, color: Colors.black87)),
                  Text('3. Quét mã QR bên trên',
                      style: TextStyle(fontSize: 13, color: Colors.black87)),
                  Text('4. Kiểm tra thông tin và xác nhận',
                      style: TextStyle(fontSize: 13, color: Colors.black87)),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Nút xác nhận
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _paymentConfirmed ? null : _confirmPayment,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFf56789),
                  disabledBackgroundColor: Colors.green,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                  elevation: 0,
                ),
                child: _paymentConfirmed
                    ? const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.check_circle, color: Colors.white),
                          SizedBox(width: 8),
                          Text('Đã xác nhận!',
                              style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white)),
                        ],
                      )
                    : const Text(
                        'Tôi đã chuyển khoản xong',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
              ),
            ),

            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget _infoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 18, color: Colors.grey),
        const SizedBox(width: 8),
        Text('$label: ',
            style: const TextStyle(color: Colors.grey, fontSize: 13)),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

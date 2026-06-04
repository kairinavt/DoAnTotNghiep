import 'dart:convert';
import 'package:http/http.dart' as http;

class VietQRService {
  static const String _baseUrl = 'https://api.vietqr.io/v2';


  static const String shopBankBin     = '970436';          // Vietcombank
  static const String shopAccountNo   = '1234567890';      // Số tài khoản
  static const String shopAccountName = 'CANTEEN YUMMY DELI';

  static const String _clientId = '33d31d80-8912-4c8e-8189-9a3efe84eaf7';
  static const String _apiKey   = '7d9a6842-4773-4644-864d-c2c5aa0e9eee';

  /// Tạo QR thanh toán, trả về base64 image string (data:image/png;base64,...)
  static Future<VietQRResult> generateQR({
    required double amount,
    required String description,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/generate'),
        headers: {
          'Content-Type': 'application/json',
          'x-client-id': _clientId,
          'x-api-key': _apiKey,
        },
        body: jsonEncode({
          'accountNo':   shopAccountNo,
          'accountName': shopAccountName,
          'acqId':       shopBankBin,
          'amount':      amount.toInt(),
          'addInfo':     description,
          'format':      'text',
          'template':    'compact2',
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['code'] == '00') {
          return VietQRResult(
            success: true,
            qrDataURL: data['data']['qrDataURL'] as String,
            qrCode:    data['data']['qrCode']    as String,
          );
        }
        return VietQRResult(
          success: false,
          error: data['desc'] ?? 'Không thể tạo mã QR',
        );
      }
      return VietQRResult(success: false, error: 'Lỗi kết nối: ${response.statusCode}');
    } catch (e) {
      return VietQRResult(success: false, error: e.toString());
    }
  }

  /// Lấy danh sách ngân hàng hỗ trợ VietQR
  static Future<List<BankInfo>> getBankList() async {
    try {
      final response = await http.get(Uri.parse('$_baseUrl/banks'));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return (data['data'] as List)
            .map((b) => BankInfo(
                  id:       b['id'].toString(),
                  bin:      b['bin'].toString(),
                  name:     b['name']      as String,
                  shortName: b['shortName'] as String,
                  logo:     b['logo']      as String,
                ))
            .toList();
      }
    } catch (_) {}
    return [];
  }
}

class VietQRResult {
  final bool success;
  final String? qrDataURL; // base64 PNG
  final String? qrCode;    // raw QR string
  final String? error;

  VietQRResult({required this.success, this.qrDataURL, this.qrCode, this.error});
}

class BankInfo {
  final String id;
  final String bin;
  final String name;
  final String shortName;
  final String logo;

  BankInfo({
    required this.id,
    required this.bin,
    required this.name,
    required this.shortName,
    required this.logo,
  });
}
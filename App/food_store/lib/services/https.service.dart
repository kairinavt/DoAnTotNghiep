import 'dart:io';
import 'package:food_store/models/base.model.dart';
import 'package:dio/dio.dart';

class HttpService {
  HttpService() {}

  // String headerUrl = 'http://10.0.2.2:3000/api/'; // Emulator
  String headerUrl = 'http://192.168.100.85:3000/api/'; // Physic device
  var dio = Dio();

  // ================= GET METHOD =================
  Future<TResultType> get<TModel extends IBaseModel, TResultType>(
      String path, IBaseModel model) async {
    try {
      // In ra chính xác URL đang được gọi để bạn debug lỗi 404
      print("🚀 [DIO GET] Đang gọi URL: $headerUrl$path");

      final response = await dio.get("$headerUrl$path");

      switch (response.statusCode) {
        case HttpStatus.ok:
          return _jsonBodyParser<TResultType>(model, response.data);
        default:
          throw response.data;
      }
    } on DioException catch (e) {
      _handleDioError(e, "$headerUrl$path");
      rethrow;
    }
  }

  // ================= POST METHOD =================
  Future<TResultType> post<TModel extends IBaseModel, TResultType>(
      String path, IBaseModel model,
      {IBaseModel? returnType}) async {
    try {
      // In ra chính xác URL đang được gọi và dữ liệu gửi đi để bạn debug
      print("🚀 [DIO POST] Đang gọi URL: $headerUrl$path");
      print("📦 [DIO DATA GỬI ĐI]: ${model.toJson()}");

      final response = await dio.post("$headerUrl$path", data: model.toJson());

      switch (response.statusCode) {
        case HttpStatus.ok:
          return _jsonBodyParser<TResultType>(model, response.data,
              returnType: returnType);
        default:
          throw response.data;
      }
    } on DioException catch (e) {
      _handleDioError(e, "$headerUrl$path");
      rethrow;
    }
  }

  // ================= PARSER JSON CHUẨN =================
  dynamic _jsonBodyParser<TResultType>(IBaseModel model, dynamic jsonBody,
      {IBaseModel? returnType}) {
    if (jsonBody is List) {
      if (jsonBody.isNotEmpty && jsonBody.first is Map) {
        return jsonBody
            .map((e) => returnType != null
                ? returnType.fromJson(
                    e is Map ? e.map((key, value) => MapEntry(key, value)) : e)
                : model.fromJson(
                    e is Map ? e.map((key, value) => MapEntry(key, value)) : e))
            .toList()
            .cast<TResultType>();
      }
    } else if (jsonBody is Map) {
      Map<String, Object> stringObjectMap = jsonBody.map(
        (key, value) {
          if (key is! String) {
            throw ArgumentError('All keys must be of type String');
          }
          if (value is! Object) {
            throw ArgumentError('All values must be of type Object');
          }
          return MapEntry(key, value);
        },
      );
      return returnType != null
          ? returnType.fromJson(stringObjectMap)
          : model.fromJson(stringObjectMap);
    } else {
      return jsonBody;
    }
  }

  // ================= HÀM IN LỖI CHI TIẾT =================
  void _handleDioError(DioException error, String fullUrl) {
    print("--------------------------------------------------");
    if (error.response != null) {
      print(" Server phản hồi lỗi!");
      print(" URL bị lỗi: $fullUrl");
      print(" Mã lỗi (Status Code): ${error.response?.statusCode}");
      print(" Nội dung lỗi từ Server: ${error.response?.data}");
    }
  }
}

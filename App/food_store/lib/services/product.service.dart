import 'package:food_store/models/product/product.model.dart';
import 'package:food_store/services/https.service.dart';

class ProductService {
  final HttpService _httpService = HttpService();

  Future<List<ProductModel>> getAll() async {
    try {
      final response = await _httpService.dio.post('${_httpService.headerUrl}Product/getall-product');
      if (response.statusCode == 200) {
        List<ProductModel> products = (response.data as List)
            .map((product) => ProductModel.empty().fromJson(product))
            .toList();
        return products;
      } else {
        throw Exception('Không thể tải sản phẩm');
      }
    } catch (e) {
      throw Exception('Không thể tải sản phẩm: $e');
    }
  }

  Future<List<ProductModel>> getProductFavorite() async {
    try {
      final response = await _httpService.dio.get('${_httpService.headerUrl}Product/get-favorite-products');
      if (response.statusCode == 200) {
        List<ProductModel> favoriteProducts = (response.data as List)
            .map((product) => ProductModel.empty().fromJson(product))
            .toList();
        return favoriteProducts;
      } else {
        throw Exception('Không thể tải sản phẩm yêu thích');
      }
    } catch (e) {
      throw Exception('Không thể tải sản phẩm yêu thích: $e');
    }
  }

 Future<void> toggleFavorite(String productId, bool isFavorite) async {
  try {
    final response = await _httpService.dio.post(
      '${_httpService.headerUrl}Product/toggle-favorite',
      // Gửi productId và trạng thái mong muốn lên Server để lưu vào Database
      data: {'id': productId, 'isFavorite': isFavorite},
    );

    if (response.statusCode != 200) {
      throw Exception('Không thể cập nhật trạng thái');
    }
    
    // TODO: Tại đây, bạn cần cập nhật lại State của Product trong ứng dụng
    // Ví dụ: product.isFavorite = isFavorite; 
    
  } catch (e) {
    throw Exception('Không thể cập nhật trạng thái: $e');
  }
}

  Future<List<ProductModel>> getProductsByCategory(String categoryId) async {
    final response = await _httpService.dio.get(
        '${_httpService.headerUrl}Product/get-products-by-category/$categoryId'
    );
    return (response.data as List)
        .map((product) => ProductModel.empty().fromJson(product))
        .toList();
 }

 Future<List<ProductModel>> searchProducts(String keyword) async {
    final response = await _httpService.dio.get(
      '${_httpService.headerUrl}Product/find-product',
      queryParameters: {'nameProduct': keyword},
    );
    return (response.data as List)
        .map((product) => ProductModel.empty().fromJson(product))
        .toList();
  }

  Future<List<ProductModel>> searchFavoriteProducts(String keyword) async {
    final response = await _httpService.dio.get(
      '${_httpService.headerUrl}Product/search-favorite-products',
      queryParameters: {'keyword': keyword},
    );
    return (response.data as List)
        .map((product) => ProductModel.empty().fromJson(product))
        .toList();
  }

  Future<List<ProductModel>> searchProductsByCategory(String categoryId, String keyword) async {
    final response = await _httpService.dio.get(
      '${_httpService.headerUrl}Product/search-products-by-category',
      queryParameters: {'categoryId': categoryId, 'keyword': keyword},
    );
    return (response.data as List)
        .map((product) => ProductModel.empty().fromJson(product))
        .toList();
  }

  Future<List<ProductModel>> getIncludeProductById(String id) async {
    try {
      final response = await _httpService.dio.get('${_httpService.headerUrl}Product/get-include-product-by-product-id/$id');
      if (response.statusCode == 200) {
        List<ProductModel> favoriteProducts = (response.data as List)
            .map((product) => ProductModel.empty().fromJson(product))
            .toList();
        return favoriteProducts;
      } else {
        throw Exception('Không thể tải sản phẩm bao gom');
      }
    } catch (e) {
      throw Exception('Không thể tải sản phẩm bao gom: $e');
    }
  }
}

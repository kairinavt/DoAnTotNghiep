import 'package:food_store/constants/colors.dart';
import 'package:food_store/models/cart.dart';
import 'package:food_store/models/product/product.model.dart';
import 'package:food_store/screens/cart/cart.screen.dart';
import 'package:food_store/screens/mainpage/mainpage.screen.dart';
import 'package:food_store/services/product.service.dart';
import 'package:food_store/services/sqlite.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class ProductDisplayScreen extends StatefulWidget {
  final ProductModel product;
  const ProductDisplayScreen({super.key, required this.product});

  @override
  State<ProductDisplayScreen> createState() => _ProductDisplayScreenState();
}

class _ProductDisplayScreenState extends State<ProductDisplayScreen> {
  final ProductService _productService = ProductService();
  final DatabaseHelper _databaseHelper = DatabaseHelper();

  // Hằng số giới hạn đơn hàng (3 triệu đồng)
  static const double maxOrderLimit = 3000000;

  late bool liked;
  late ProductModel product;
  late double originalPrice;
  int quantity = 1;
  List<ProductModel> includeProducts = [];

  // Biến lưu danh sách các món ăn kèm được chọn
  List<ProductModel> selectedExtras = [];

  @override
  void initState() {
    super.initState();
    product = widget.product;
    liked = widget.product.fav ?? false;
    originalPrice = product.price;

    if (includeProducts.isEmpty) _getIncludeProduct();
  }

  // Hàm bổ trợ tính tổng giá tiền của 1 sản phẩm + các món kèm (chưa nhân quantity)
  double _getSingleProductWithExtrasPrice() {
    double extrasTotalPrice = 0;
    for (var extra in selectedExtras) {
      extrasTotalPrice += extra.price;
    }
    return originalPrice + extrasTotalPrice;
  }

  void _calculateTotalPrice() {
    setState(() {
      product.price = _getSingleProductWithExtrasPrice();
    });
  }

  void toggleFavorite() async {
    setState(() {
      liked = !liked;
      product.fav = liked;
    });

    try {
      await _productService.toggleFavorite(product.id!, liked);
      _showSnackBar(liked
          ? 'Đã thêm ${product.nameProduct} vào danh sách yêu thích'
          : 'Đã xóa ${product.nameProduct} khỏi danh sách yêu thích');
    } catch (e) {
      setState(() {
        liked = !liked;
        product.fav = liked;
      });
      _showSnackBar('Có lỗi xảy ra: $e');
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  String getFormattedPrice(double price) {
    return NumberFormat('#,###').format(price);
  }

  Future<void> _addToCart() async {
    String finalName = product.nameProduct;
    if (selectedExtras.isNotEmpty) {
      finalName += " (${selectedExtras.map((e) => e.nameProduct).join(', ')})";
    }

    await _databaseHelper.insertProduct(Cart(
      productID: product.id!,
      name: finalName,
      price: product.price,
      img: product.img,
      address: 'Default Address',
      des: product.descrip ?? '',
      date: DateFormat('dd/MM/yyyy').format(DateTime.now()),
      quantity: quantity,
    ));
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const MainPageScreen(currentScreen: CartPage()),
      ),
    );
  }

  _getIncludeProduct() {
    if (product.id != null) {
      _productService.getIncludeProductById(product.id!).then((onValue) {
        if (onValue.isNotEmpty) {
          setState(() {
            includeProducts = onValue;
          });
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final double screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      body: CustomScrollView(
        slivers: [
          // 1. Ảnh sản phẩm Parallax
          SliverAppBar(
            expandedHeight: screenHeight * 0.4,
            elevation: 0,
            pinned: true,
            backgroundColor: softPink,
            leading: Padding(
              padding: const EdgeInsets.all(8.0),
              child: CircleAvatar(
                backgroundColor: Colors.white.withOpacity(0.9),
                child: IconButton(
                  icon: const Icon(Icons.arrow_back_ios_new,
                      size: 18, color: Colors.black),
                  onPressed: () => Navigator.pop(context, product),
                ),
              ),
            ),
            actions: [
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: CircleAvatar(
                  backgroundColor: Colors.white.withOpacity(0.9),
                  child: IconButton(
                    icon: Icon(liked ? Icons.favorite : Icons.favorite_border,
                        color: liked ? Colors.red : Colors.grey),
                    onPressed: toggleFavorite,
                  ),
                ),
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                color: softPink,
                padding:
                    const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
                child: Center(
                  child: Hero(
                    tag: 'product_image_${product.id}',
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(24),
                      child: product.img.contains('https://')
                          ? Image.network(product.img, fit: BoxFit.cover)
                          : Image.asset(product.img, fit: BoxFit.cover),
                    ),
                  ),
                ),
              ),
            ),
          ),

          // 2. Nội dung chi tiết
          SliverToBoxAdapter(
            child: Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
              ),
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Tên sản phẩm & Nút tăng giảm số lượng
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          product.nameProduct,
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF2D2D2D),
                          ),
                        ),
                      ),
                      _buildQuantitySelector(),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Phần mô tả sản phẩm
                  if (product.descrip != null) ...[
                    const Text(
                      'Mô tả món ăn',
                      style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF2D2D2D)),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${product.descrip}',
                      style: TextStyle(
                          fontSize: 15, color: Colors.grey[600], height: 1.5),
                    ),
                    const SizedBox(height: 24),
                  ],

                  // 2. Phần danh sách món ăn kèm CÓ THỂ BẤM CHỌN ĐƯỢC
                  if (includeProducts.isNotEmpty) ...[
                    const Text(
                      'Món ăn kèm (Tùy chọn)',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF2D2D2D),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Danh sách lựa chọn hiện đại giống App đặt đồ ăn lớn
                    Column(
                      children: includeProducts.map((item) {
                        final isSelected = selectedExtras.contains(item);

                        return InkWell(
                          onTap: () {
                            setState(() {
                              if (isSelected) {
                                selectedExtras.remove(item);
                                _calculateTotalPrice();
                              } else {
                                // Kiểm tra xem nếu thêm món kèm này thì tổng tiền (đã nhân quantity) có vượt 3 triệu không
                                double temporaryExtrasPrice = 0;
                                for (var extra in selectedExtras) {
                                  temporaryExtrasPrice += extra.price;
                                }
                                temporaryExtrasPrice +=
                                    item.price; // Thử cộng thêm món mới

                                double estimatedTotalPrice =
                                    (originalPrice + temporaryExtrasPrice) *
                                        quantity;

                                if (estimatedTotalPrice > maxOrderLimit) {
                                  _showSnackBar(
                                      'Tổng giá trị món hàng không được vượt quá 3,000,000 đ');
                                  return; // Chặn không cho chọn thêm
                                }

                                selectedExtras.add(item);
                                _calculateTotalPrice();
                              }
                            });
                          },
                          borderRadius: BorderRadius.circular(12),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                                vertical: 10.0, horizontal: 4.0),
                            child: Row(
                              children: [
                                Icon(
                                  isSelected
                                      ? Icons.check_circle
                                      : Icons.radio_button_unchecked,
                                  color: isSelected
                                      ? const Color(0xfff56789)
                                      : Colors.grey[400],
                                  size: 22,
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Text(
                                    item.nameProduct,
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: isSelected
                                          ? FontWeight.bold
                                          : FontWeight.w500,
                                      color: isSelected
                                          ? const Color(0xFF2D2D2D)
                                          : const Color(0xFF5A5A5A),
                                    ),
                                  ),
                                ),
                                Text(
                                  '+ ${getFormattedPrice(item.price)} đ',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                    color: isSelected
                                        ? const Color(0xfff56789)
                                        : Colors.grey[500],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ],

                  const SizedBox(height: 100),
                ],
              ),
            ),
          ),
        ],
      ),

      // 3. Thanh thanh toán dưới màn hình
      bottomNavigationBar: _buildBottomActionBar(),
    );
  }

  Widget _buildQuantitySelector() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF5F5F5),
        borderRadius: BorderRadius.circular(30),
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.remove, size: 18, color: Colors.black87),
            onPressed: () {
              if (quantity > 1) {
                setState(() {
                  quantity--;
                  _calculateTotalPrice();
                });
              }
            },
          ),
          Text(
            quantity.toString(),
            style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.black87),
          ),
          IconButton(
            icon: const Icon(Icons.add, size: 18, color: Colors.black87),
            onPressed: () {
              if (quantity < (product.quantity)) {
                // Kiểm tra trước xem nếu tăng số lượng thì tổng tiền có vượt quá 3 triệu không
                double nextTotalPrice =
                    _getSingleProductWithExtrasPrice() * (quantity + 1);

                if (nextTotalPrice > maxOrderLimit) {
                  _showSnackBar(
                      'Tổng giá trị món hàng không được vượt quá 3,000,000 đ');
                  return; // Chặn không cho tăng số lượng
                }

                setState(() {
                  quantity++;
                  _calculateTotalPrice();
                });
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildBottomActionBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Tổng thanh toán',
                    style: TextStyle(color: Colors.grey, fontSize: 14)),
                const SizedBox(height: 4),
                Text(
                  '${getFormattedPrice(product.price * quantity)} đ',
                  style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Color(0xfff56789)),
                ),
              ],
            ),
            const SizedBox(width: 24),
            Expanded(
              child: ElevatedButton(
                onPressed: _addToCart,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xfff56789),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                ),
                child: const Text(
                  'Thêm vào giỏ',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

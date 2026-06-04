import 'package:food_store/services/sqlite.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:food_store/screens/cart/checkout.screen.dart';
import 'package:food_store/screens/mainpage/mainpage.screen.dart';
import 'package:food_store/models/cart.dart';

class CartPage extends StatefulWidget {
  const CartPage({super.key});

  @override
  _CartPageState createState() => _CartPageState();
}

class _CartPageState extends State<CartPage> {
  final DatabaseHelper _databaseHelper = DatabaseHelper();
  List<Cart> items = [];
  bool isLoading = true;

  final Color _kPink = const Color(0xfff56789); 
  final Color _kTextDark = const Color(0xff2D2D2D);

  @override
  void initState() {
    super.initState();
    _loadCartItems();
  }

  Future<void> _loadCartItems() async {
    List<Cart> cartItems = await _databaseHelper.products();
    setState(() {
      items = cartItems;
      isLoading = false;
    });
  }

  void _incrementQuantity(Cart cartItem) async {
    await _databaseHelper.add(cartItem);
    _loadCartItems();
  }

  void _decrementQuantity(Cart cartItem) async {
    await _databaseHelper.minus(cartItem);
    _loadCartItems();
  }

  double _calculateTotal() {
    double total = 0;
    for (var item in items) {
      total += (item.price * item.quantity);
    }
    return total;
  }

  String formatCurrency(double amount) {
    final formatter = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ');
    return formatter.format(amount);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xffF7F7F7),
      body: SafeArea(
        child: isLoading
            ? const Center(child: CircularProgressIndicator())
            : Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(6, 12, 16, 12),
                    child: Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.black, size: 20),
                          onPressed: () {
                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const MainPageScreen(isBack: true),
                              ),
                            );
                          },
                        ),
                        Text(
                          'Giỏ hàng (${items.length})',
                          style: TextStyle(
                            color: _kTextDark,
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: items.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.shopping_bag_outlined, size: 80, color: Colors.grey.withOpacity(0.5)),
                                const SizedBox(height: 16),
                                const Text(
                                  'Giỏ hàng của bạn đang trống',
                                  style: TextStyle(color: Colors.grey, fontSize: 16, fontWeight: FontWeight.w500),
                                ),
                                const SizedBox(height: 20),
                                ElevatedButton(
                                  onPressed: () {
                                    Navigator.pushReplacement(
                                      context,
                                      MaterialPageRoute(builder: (context) => const MainPageScreen(isBack: true)),
                                    );
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: _kPink,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
                                  ),
                                  child: const Text('Mua ngay nào', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                                )
                              ],
                            ),
                          )
                        : ListView.builder(
                            physics: const BouncingScrollPhysics(),
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            itemCount: items.length,
                            itemBuilder: (context, index) {
                              final item = items[index];
                              return Container(
                                margin: const EdgeInsets.only(bottom: 12),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(16),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.02),
                                      blurRadius: 10,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.all(10.0),
                                  child: Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      ClipRRect(
                                        borderRadius: BorderRadius.circular(12),
                                        child: Image.network(
                                          item.img,
                                          width: 85,
                                          height: 85,
                                          fit: BoxFit.cover,
                                          errorBuilder: (_, __, ___) => Container(
                                            width: 85,
                                            height: 85,
                                            color: _kPink.withOpacity(0.1),
                                            child: Icon(Icons.restaurant, color: _kPink, size: 24),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: SizedBox(
                                          height: 85,
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                            children: [
                                              Text(
                                                item.name,
                                                style: TextStyle(
                                                  color: _kTextDark,
                                                  fontSize: 15,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                                maxLines: 2,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                              Row(
                                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                children: [
                                                  Text(
                                                    formatCurrency(item.price * item.quantity),
                                                    style: TextStyle(
                                                      color: _kPink,
                                                      fontSize: 15,
                                                      fontWeight: FontWeight.bold,
                                                    ),
                                                  ),
                                                  Container(
                                                    decoration: BoxDecoration(
                                                      border: Border.all(color: Colors.grey.withOpacity(0.3), width: 0.8),
                                                      borderRadius: BorderRadius.circular(6),
                                                    ),
                                                    child: Row(
                                                      children: [
                                                        GestureDetector(
                                                          onTap: () => _decrementQuantity(item),
                                                          child: const Padding(
                                                            padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                                            child: Icon(Icons.remove, size: 16, color: Colors.black87),
                                                          ),
                                                        ),
                                                        Padding(
                                                          padding: const EdgeInsets.symmetric(horizontal: 4),
                                                          child: Text(
                                                            item.quantity.toString(),
                                                            style: TextStyle(
                                                              fontSize: 14,
                                                              fontWeight: FontWeight.w700,
                                                              color: _kTextDark,
                                                            ),
                                                          ),
                                                        ),
                                                        GestureDetector(
                                                          onTap: () => _incrementQuantity(item),
                                                          child: Padding(
                                                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                                            child: Icon(Icons.add, size: 16, color: _kPink),
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                  ),
                  if (items.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 16,
                            offset: const Offset(0, -4),
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Tổng cộng',
                                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: Colors.grey),
                              ),
                              Text(
                                formatCurrency(_calculateTotal()),
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w800,
                                  color: _kPink,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (context) => CheckoutPage(cartItems: items),
                                  ),
                                );
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: _kPink,
                                elevation: 0,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                                padding: const EdgeInsets.symmetric(vertical: 14.0),
                              ),
                              child: const Text(
                                'Thanh toán ngay',
                                style: TextStyle(fontSize: 16, color: Colors.white, fontWeight: FontWeight.w700),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
      ),
    );
  }
}
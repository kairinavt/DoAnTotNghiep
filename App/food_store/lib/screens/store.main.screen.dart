import 'dart:async';
import 'package:food_store/models/product/product.model.dart';
import 'package:food_store/screens/favorite.screen.dart';
import 'package:food_store/screens/store_product_page/product_display.screen.dart';
import 'package:food_store/services/product.service.dart';
import 'package:food_store/shared/components/custom_drawer.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

// ─── Màu chủ đạo ─────────────────────────────────────────────────────────────
const Color kPink        = Color(0xFFf56789);
const Color kPinkLight   = Color(0xFFFFECF0);
const Color kPinkDark    = Color(0xFFD94F6E);
const Color kBg          = Color(0xFFFDF6F8);
const Color kCard        = Colors.white;
const Color kTextDark    = Color(0xFF1A1A2E);
const Color kTextGrey    = Color(0xFF9E9E9E);

class StoreMainScreen extends StatefulWidget {
  const StoreMainScreen({super.key});

  @override
  State<StoreMainScreen> createState() => _StoreMainScreenState();
}

class _StoreMainScreenState extends State<StoreMainScreen>
    with SingleTickerProviderStateMixin {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final ProductService _productService = ProductService();

  // ── Data ──────────────────────────────────────────────────────────────────
  List<ProductModel> _allProducts     = [];
  List<ProductModel> _favoriteProducts = [];
  List<ProductModel> _filteredProducts = [];

  bool _isLoading = true;

  // ── Category ─────────────────────────────────────────────────────────────
  final List<Map<String, String>> _categories = [
    {'label': 'Tất cả', 'icon': '🍽️'},
    {'label': 'Phở & Bún', 'icon': '🍜'},
    {'label': 'Cơm', 'icon': '🍚'},
    {'label': 'Bánh mì', 'icon': '🥖'},
    {'label': 'Lẩu', 'icon': '🍲'},
    {'label': 'Tráng miệng', 'icon': '🍰'},
    {'label': 'Đồ uống', 'icon': '🥤'},
  ];
  int _selectedCategoryIndex = 0;

  // ── Banner ────────────────────────────────────────────────────────────────
  final List<Map<String, dynamic>> _banners = [
    {
      'title': 'Món ngon\nmỗi ngày',
      'sub': 'Giảm 20% đơn đầu tiên',
      'color1': const Color(0xFFf56789),
      'color2': const Color(0xFFFF8FAB),
      'icon': '🍜',
    },
    {
      'title': 'Ưu đãi\ncuối tuần',
      'sub': 'Freeship cho mọi đơn hàng',
      'color1': const Color(0xFF9B59B6),
      'color2': const Color(0xFFBE8FD4),
      'icon': '🎉',
    },
    {
      'title': 'Combo\ntiết kiệm',
      'sub': 'Từ 2 món giảm ngay 15%',
      'color1': const Color(0xFFE67E22),
      'color2': const Color(0xFFF0A85A),
      'icon': '🍱',
    },
  ];
  int _currentBanner = 0;
  late PageController _bannerController;
  Timer? _bannerTimer;

  // ── Search ────────────────────────────────────────────────────────────────
  final TextEditingController _searchController = TextEditingController();
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    _bannerController = PageController();
    _loadAllData();
    _searchController.addListener(_onSearchChanged);
    _startBannerTimer();
  }

  void _startBannerTimer() {
    _bannerTimer?.cancel();
    _bannerTimer = Timer.periodic(const Duration(seconds: 3), (_) {
      if (!mounted || !_bannerController.hasClients) return;
      final next = (_currentBanner + 1) % _banners.length;
      _bannerController.animateToPage(
        next,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
      );
    });
  }

  Future<void> _loadAllData() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    try {
      final results = await Future.wait([
        _productService.getAll(),
        _productService.getProductFavorite(),
      ]);
      if (!mounted) return;
      setState(() {
        _allProducts      = results[0];
        _favoriteProducts = results[1];
        _filteredProducts = results[0];
        _isLoading        = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
    }
  }

  void _onSearchChanged() {
    final kw = _searchController.text.trim().toLowerCase();
    setState(() {
      _isSearching = kw.isNotEmpty;
      _filteredProducts = kw.isEmpty
          ? _allProducts
          : _allProducts
              .where((p) => p.nameProduct.toLowerCase().contains(kw))
              .toList();
    });
  }

  Future<void> _navigateToProduct(ProductModel product) async {
    final result = await Navigator.of(context).push(
      MaterialPageRoute(
          builder: (_) => ProductDisplayScreen(product: product)),
    );
    if (result != null && result is ProductModel) _loadAllData();
  }

  @override
  void dispose() {
    _bannerTimer?.cancel();
    _bannerController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  // ── Format ────────────────────────────────────────────────────────────────
  String _fmt(double price) =>
      NumberFormat.currency(locale: 'vi_VN', symbol: '₫').format(price);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: kBg,
      drawer: const CustomDrawer(),
      body: SafeArea(
        child: _isLoading
            ? _buildSkeleton()
            : RefreshIndicator(
                color: kPink,
                onRefresh: _loadAllData,
                child: CustomScrollView(
                  slivers: [
                    _buildHeader(),
                    _buildSearchBar(),
                    if (_isSearching)
                      _buildSearchResults()
                    else ...[
                      _buildBannerSliver(),
                      _buildCategoryBar(),
                      _buildSectionSliver(
                          '❤️ Đã thích', _favoriteProducts,
                          seeAll: true,
                          onSeeAll: () {
                            // Điều hướng dạng Push một trang độc lập hợp lý cho nút "Xem tất cả"
                            Navigator.push(context, MaterialPageRoute(
                              builder: (_) => const FavoriteScreen()
                            ));
                          }),
                      _buildSectionSliver(
                          '🔥 Bán nhiều nhất', _allProducts,
                          seeAll: true),
                      _buildSectionSliver(
                          '⭐ Đánh giá cao',
                          [..._allProducts]..sort((a, b) =>
                              (b.fav ?? false ? 1 : 0) - (a.fav ?? false ? 1 : 0)),
                          seeAll: true),
                      _buildSectionSliver(
                          '🆕 Món mới ra', _allProducts.reversed.toList(),
                          seeAll: true),
                      const SliverToBoxAdapter(child: SizedBox(height: 30)),
                    ],
                  ],
                ),
              ),
      ),
    );
  }

  // ── Header ────────────────────────────────────────────────────────────────
  Widget _buildHeader() {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
        child: Row(
          children: [
            GestureDetector(
              onTap: () => _scaffoldKey.currentState?.openDrawer(),
              child: Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: kCard,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                        color: Colors.black.withOpacity(0.07),
                        blurRadius: 8,
                        offset: const Offset(0, 2)),
                  ],
                ),
                child: const Icon(Icons.menu_rounded, color: kTextDark, size: 22),
              ),
            ),
            const SizedBox(width: 14),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Xin chào! 👋',
                      style: TextStyle(
                          color: kTextGrey,
                          fontSize: 13,
                          fontWeight: FontWeight.w500)),
                  Text('CANTEEN YUMMY DELI',
                      style: TextStyle(
                          color: kTextDark,
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.3)),
                ],
              ),
            ),
            // Cart badge (Đã được tối ưu - để xem thông báo hoặc lịch sử thay vì đẩy trùng lặp màn Cart)
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                    colors: [kPink, kPinkDark],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                      color: kPink.withOpacity(0.4),
                      blurRadius: 10,
                      offset: const Offset(0, 4)),
                ],
              ),
              child: const Icon(Icons.notifications_none_rounded,
                  color: Colors.white, size: 20),
            ),
          ],
        ),
      ),
    );
  }

  // ── Search Bar ────────────────────────────────────────────────────────────
  Widget _buildSearchBar() {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
        child: Container(
          height: 50,
          decoration: BoxDecoration(
            color: kCard,
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                  color: Colors.black.withOpacity(0.06),
                  blurRadius: 12,
                  offset: const Offset(0, 3)),
            ],
          ),
          child: TextField(
            controller: _searchController,
            style: const TextStyle(fontSize: 14, color: kTextDark),
            decoration: InputDecoration(
              hintText: 'Tìm món ăn yêu thích...',
              hintStyle: const TextStyle(color: kTextGrey, fontSize: 14),
              prefixIcon:
                  const Icon(Icons.search_rounded, color: kPink, size: 22),
              suffixIcon: _isSearching
                  ? IconButton(
                      icon: const Icon(Icons.close_rounded,
                          color: kTextGrey, size: 20),
                      onPressed: () {
                        _searchController.clear();
                        FocusScope.of(context).unfocus();
                      },
                    )
                  : null,
              border: InputBorder.none,
              contentPadding:
                  const EdgeInsets.symmetric(vertical: 15),
            ),
          ),
        ),
      ),
    );
  }

  // ── Banner ────────────────────────────────────────────────────────────────
  Widget _buildBannerSliver() {
    return SliverToBoxAdapter(
      child: Column(
        children: [
          const SizedBox(height: 20),
          SizedBox(
            height: 160,
            child: PageView.builder(
              controller: _bannerController,
              onPageChanged: (i) => setState(() => _currentBanner = i),
              itemCount: _banners.length,
              itemBuilder: (_, i) {
                final b = _banners[i];
                return Padding(
                  padding: EdgeInsets.only(
                      left: i == 0 ? 20 : 8,
                      right: i == _banners.length - 1 ? 20 : 8),
                  child: _buildBannerCard(b),
                );
              },
            ),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(_banners.length, (i) {
              final active = i == _currentBanner;
              return AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                margin: const EdgeInsets.symmetric(horizontal: 3),
                width: active ? 20 : 6,
                height: 6,
                decoration: BoxDecoration(
                  color: active ? kPink : kPink.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(3),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildBannerCard(Map<String, dynamic> b) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [b['color1'] as Color, b['color2'] as Color],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
              color: (b['color1'] as Color).withOpacity(0.35),
              blurRadius: 16,
              offset: const Offset(0, 6)),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: -20,
            top: -20,
            child: Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Positioned(
            right: 30,
            bottom: -30,
            child: Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.08),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(22),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        b['title'] as String,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                          height: 1.2,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.25),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          b['sub'] as String,
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w600),
                        ),
                      ),
                    ],
                  ),
                ),
                Text(b['icon'] as String,
                    style: const TextStyle(fontSize: 56)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Category Bar ──────────────────────────────────────────────────────────
  Widget _buildCategoryBar() {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.only(top: 20, bottom: 4),
        child: SizedBox(
          height: 80,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: _categories.length,
            itemBuilder: (_, i) {
              final active = i == _selectedCategoryIndex;
              return GestureDetector(
                onTap: () => setState(() => _selectedCategoryIndex = i),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  margin: const EdgeInsets.symmetric(horizontal: 5),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: active ? kPink : kCard,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                          color: active
                              ? kPink.withOpacity(0.3)
                              : Colors.black.withOpacity(0.05),
                          blurRadius: active ? 10 : 6,
                          offset: const Offset(0, 3)),
                    ],
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(_categories[i]['icon']!,
                          style: const TextStyle(fontSize: 22)),
                      const SizedBox(height: 4),
                      Text(
                        _categories[i]['label']!,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: active ? Colors.white : kTextDark,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  // ── Product Section ───────────────────────────────────────────────────────
  Widget _buildSectionSliver(String title, List<ProductModel> products,
      {bool seeAll = false, VoidCallback? onSeeAll}) {
    if (products.isEmpty) return const SliverToBoxAdapter(child: SizedBox());
    final displayList = products.take(6).toList();

    return SliverToBoxAdapter(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: kTextDark,
                    fontSize: 18, 
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.3,
                  ),
                ),
                if (seeAll && onSeeAll != null)
                  GestureDetector( 
                    onTap: onSeeAll,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                      decoration: BoxDecoration(
                        color: kPinkLight.withOpacity(0.4),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Xem tất cả',
                            style: TextStyle(
                              color: kPink,
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          SizedBox(width: 2),
                          Icon(Icons.chevron_right_rounded, color: kPink, size: 16),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
          
          SizedBox(
            height: 240, 
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(), 
              padding: const EdgeInsets.symmetric(horizontal: 14),
              itemCount: displayList.length,
              itemBuilder: (_, i) => _buildProductCard(displayList[i]), 
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProductCard(ProductModel product) { 
    return Container(
      width: 160,
      margin: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
      decoration: BoxDecoration(
        color: kCard, 
        borderRadius: BorderRadius.circular(24), 
        border: Border.all(color: Colors.grey.withOpacity(0.08), width: 1), 
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04), 
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: GestureDetector( 
        onTap: () => _navigateToProduct(product),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                Padding(
                  padding: const EdgeInsets.all(8.0), 
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Image.network(
                      product.img,
                      width: double.infinity,
                      height: 115,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        width: double.infinity,
                        height: 115,
                        color: kPinkLight,
                        child: const Icon(Icons.restaurant_rounded, color: kPink, size: 32),
                      ),
                    ),
                  ),
                ),
                if (product.fav ?? false)
                  Positioned(
                    top: 14,
                    right: 14,
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.9),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.08),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          )
                        ],
                      ),
                      child: const Icon(Icons.favorite_rounded, color: kPink, size: 14),
                    ),
                  ),
              ],
            ),
            
            Expanded( 
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 4, 12, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween, 
                  children: [
                    Text(
                      product.nameProduct,
                      style: const TextStyle(
                        color: kTextDark,
                        fontSize: 13.5,
                        fontWeight: FontWeight.w600, 
                        height: 1.3,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          _fmt(product.price),
                          style: const TextStyle(
                            color: kPink,
                            fontSize: 14.5,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        Container(
                          width: 30,
                          height: 30,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [kPink, kPinkDark],
                            ),
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: kPink.withOpacity(0.3),
                                blurRadius: 8,
                                offset: const Offset(0, 3),
                              )
                            ],
                          ),
                          child: const Icon(Icons.shopping_cart_rounded, color: Colors.white, size: 18),
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
  }

  // ── Search Results ────────────────────────────────────────────────────────
  Widget _buildSearchResults() {
    if (_filteredProducts.isEmpty) {
      return SliverFillRemaining(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('🔍', style: TextStyle(fontSize: 48)),
              const SizedBox(height: 12),
              Text('Không tìm thấy "${_searchController.text}"',
                  style: const TextStyle(
                      color: kTextGrey,
                      fontSize: 15,
                      fontWeight: FontWeight.w500)),
            ],
          ),
        ),
      );
    }

    return SliverPadding(
      padding: const EdgeInsets.all(16),
      sliver: SliverGrid(
        delegate: SliverChildBuilderDelegate(
          (_, i) => _buildProductCard(_filteredProducts[i]),
          childCount: _filteredProducts.length,
        ),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 155 / 220,
          crossAxisSpacing: 4,
          mainAxisSpacing: 4,
        ),
      ),
    );
  }

  // ── Skeleton loading ──────────────────────────────────────────────────────
  Widget _buildSkeleton() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 20),
          _shimmer(double.infinity, 50, radius: 14),
          const SizedBox(height: 20),
          _shimmer(double.infinity, 160, radius: 20),
          const SizedBox(height: 20),
          _shimmer(200, 20, radius: 8),
          const SizedBox(height: 12),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: List.generate(
                  3,
                  (_) => Padding(
                        padding: const EdgeInsets.only(right: 12),
                        child: _shimmer(155, 220, radius: 18),
                      )),
            ),
          ),
        ],
      ),
    );
  }

  Widget _shimmer(double w, double h, {double radius = 8}) {
    return Container(
      width: w,
      height: h,
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        borderRadius: BorderRadius.circular(radius),
      ),
    );
  }
}
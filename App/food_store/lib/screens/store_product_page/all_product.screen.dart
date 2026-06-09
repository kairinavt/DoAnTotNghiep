import 'package:food_store/models/product/product.model.dart';
import 'package:food_store/screens/store_product_page/product_display.screen.dart';
import 'package:food_store/services/product.service.dart';
import 'package:food_store/shared/components/custom_drawer.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

const Color kPink = Color(0xFFf56789);
const Color kPinkLight = Color(0xFFFFECF0);
const Color kPinkDark = Color(0xFFD94F6E);
const Color kBg = Color(0xFFFDF6F8);
const Color kTextDark = Color(0xFF1A1A2E);
const Color kTextGrey = Color(0xFF9E9E9E);

class AllProductScreen extends StatefulWidget {
  const AllProductScreen({super.key});
  @override
  State<AllProductScreen> createState() => _AllProductScreenState();
}

class _AllProductScreenState extends State<AllProductScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final ProductService _productService = ProductService();
  final TextEditingController _searchController = TextEditingController();

  List<ProductModel> _products = [];
  List<ProductModel> _display = [];
  bool _isLoading = true;
  String _sortOption = '';
  bool _isSearching = false;

  // Layout toggle
  bool _isGrid = true;

  final List<String> _sortOptions = [
    'A-Z',
    'Z-A',
    'Giá, thấp đến cao',
    'Giá, cao đến thấp'
  ];

  @override
  void initState() {
    super.initState();
    _fetchProducts();
    _searchController.addListener(_onSearch);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchProducts() async {
    setState(() => _isLoading = true);
    try {
      final list = await _productService.getAll();
      setState(() {
        _products = list;
        _display = list;
        _isLoading = false;
      });
    } catch (_) {
      setState(() => _isLoading = false);
    }
  }

  void _onSearch() {
    final kw = _searchController.text.trim().toLowerCase();
    setState(() {
      _isSearching = kw.isNotEmpty;
      _display = kw.isEmpty
          ? _products
          : _products
              .where((p) => p.nameProduct.toLowerCase().contains(kw))
              .toList();
    });
  }

  void _applySort(String opt) {
    setState(() {
      _sortOption = opt;
      if (opt == 'A-Z')
        _display.sort((a, b) => a.nameProduct.compareTo(b.nameProduct));
      else if (opt == 'Z-A')
        _display.sort((a, b) => b.nameProduct.compareTo(a.nameProduct));
      else if (opt == 'Giá, thấp đến cao')
        _display.sort((a, b) => a.price.compareTo(b.price));
      else if (opt == 'Giá, cao đến thấp')
        _display.sort((a, b) => b.price.compareTo(a.price));
    });
  }

  Future<void> _goToProduct(ProductModel p) async {
    final result = await Navigator.push(context,
        MaterialPageRoute(builder: (_) => ProductDisplayScreen(product: p)));
    if (result is ProductModel) _fetchProducts();
  }

  String _fmt(double price) =>
      NumberFormat.currency(locale: 'vi_VN', symbol: '₫').format(price);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: kBg,
      drawer: const CustomDrawer(),
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            _buildSearchAndFilter(),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator(color: kPink))
                  : _display.isEmpty
                      ? _buildEmpty()
                      : RefreshIndicator(
                          color: kPink,
                          onRefresh: _fetchProducts,
                          child: _isGrid ? _buildGrid() : _buildList(),
                        ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
      color: Colors.white,
      child: Row(
        children: [
          // GestureDetector(
          //   onTap: () => _scaffoldKey.currentState?.openDrawer(),
          //   child: _iconBtn(Icons.menu_rounded),
          // ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Khám phá',
                    style: TextStyle(color: kTextGrey, fontSize: 12)),
                const Text('Tất cả món ăn',
                    style: TextStyle(
                        color: kTextDark,
                        fontSize: 18,
                        fontWeight: FontWeight.w800)),
              ],
            ),
          ),
          Text('${_display.length} món',
              style: const TextStyle(color: kTextGrey, fontSize: 13)),
        ],
      ),
    );
  }

  Widget _buildSearchAndFilter() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
      child: Column(
        children: [
          // Search bar
          Container(
            height: 46,
            decoration: BoxDecoration(
              color: kBg,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: TextField(
              controller: _searchController,
              style: const TextStyle(fontSize: 14),
              decoration: InputDecoration(
                hintText: 'Tìm món ăn...',
                hintStyle: const TextStyle(color: kTextGrey, fontSize: 14),
                prefixIcon:
                    const Icon(Icons.search_rounded, color: kPink, size: 20),
                suffixIcon: _isSearching
                    ? IconButton(
                        icon: const Icon(Icons.close_rounded,
                            color: kTextGrey, size: 18),
                        onPressed: () => _searchController.clear())
                    : null,
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(vertical: 13),
              ),
            ),
          ),
          const SizedBox(height: 10),
          // Filter row
          Row(
            children: [
              // Sort dropdown
              Expanded(
                child: GestureDetector(
                  onTap: _showSortSheet,
                  child: Container(
                    height: 36,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: _sortOption.isNotEmpty ? kPinkLight : kBg,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                          color: _sortOption.isNotEmpty
                              ? kPink
                              : Colors.grey.shade200),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.sort_rounded,
                            size: 16,
                            color: _sortOption.isNotEmpty ? kPink : kTextGrey),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            _sortOption.isNotEmpty ? _sortOption : 'Sắp xếp',
                            style: TextStyle(
                                fontSize: 12,
                                color:
                                    _sortOption.isNotEmpty ? kPink : kTextGrey,
                                fontWeight: FontWeight.w600),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Icon(Icons.keyboard_arrow_down_rounded,
                            size: 16,
                            color: _sortOption.isNotEmpty ? kPink : kTextGrey),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              // Grid/List toggle
              GestureDetector(
                onTap: () => setState(() => _isGrid = !_isGrid),
                child: Container(
                  height: 36,
                  width: 36,
                  decoration: BoxDecoration(
                    color: kBg,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Icon(
                    _isGrid ? Icons.view_list_rounded : Icons.grid_view_rounded,
                    size: 18,
                    color: kTextDark,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showSortSheet() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 30),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(2))),
            ),
            const SizedBox(height: 16),
            const Text('Sắp xếp theo',
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: kTextDark)),
            const SizedBox(height: 12),
            ..._sortOptions.map((opt) => ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(
                      _sortOption == opt
                          ? Icons.radio_button_checked
                          : Icons.radio_button_unchecked,
                      color: _sortOption == opt ? kPink : kTextGrey,
                      size: 20),
                  title: Text(opt,
                      style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: _sortOption == opt ? kPink : kTextDark)),
                  onTap: () {
                    _applySort(opt);
                    Navigator.pop(context);
                  },
                )),
          ],
        ),
      ),
    );
  }

  Widget _buildGrid() {
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 155 / 230,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: _display.length,
      itemBuilder: (_, i) => _buildGridCard(_display[i]),
    );
  }

  Widget _buildList() {
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: _display.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (_, i) => _buildListCard(_display[i]),
    );
  }

  Widget _buildGridCard(ProductModel p) {
    return GestureDetector(
      onTap: () => _goToProduct(p),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(0.06),
                blurRadius: 12,
                offset: const Offset(0, 4))
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(children: [
              ClipRRect(
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(16)),
                child: Image.network(p.img,
                    width: double.infinity,
                    height: 120,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                        height: 120,
                        color: kPinkLight,
                        child: const Icon(Icons.restaurant,
                            color: kPink, size: 32))),
              ),
              if (p.fav ?? false)
                Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                            color: Colors.white, shape: BoxShape.circle),
                        child: const Icon(Icons.favorite,
                            color: kPink, size: 13))),
            ]),
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(p.nameProduct,
                        style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: kTextDark),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 6),
                    Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                              child: Text(_fmt(p.price),
                                  style: const TextStyle(
                                      color: kPink,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w800),
                                  overflow: TextOverflow.ellipsis)),
                          const SizedBox(width: 4),
                          Container(
                              width: 26,
                              height: 26,
                              decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                      colors: [kPink, kPinkDark]),
                                  borderRadius: BorderRadius.circular(7)),
                              child: const Icon(Icons.add,
                                  color: Colors.white, size: 15)),
                        ]),
                  ]),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildListCard(ProductModel p) {
    return GestureDetector(
      onTap: () => _goToProduct(p),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 3))
          ],
        ),
        child: Row(children: [
          ClipRRect(
            borderRadius:
                const BorderRadius.horizontal(left: Radius.circular(14)),
            child: Image.network(p.img,
                width: 100,
                height: 90,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                    width: 100,
                    height: 90,
                    color: kPinkLight,
                    child: const Icon(Icons.restaurant, color: kPink))),
          ),
          const SizedBox(width: 12),
          Expanded(
              child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(p.nameProduct,
                  style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: kTextDark),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis),
              const SizedBox(height: 6),
              Text(_fmt(p.price),
                  style: const TextStyle(
                      color: kPink, fontSize: 13, fontWeight: FontWeight.w800)),
            ]),
          )),
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                    gradient: const LinearGradient(colors: [kPink, kPinkDark]),
                    borderRadius: BorderRadius.circular(9)),
                child: const Icon(Icons.add, color: Colors.white, size: 18)),
          ),
        ]),
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(
        child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text('🍽️', style: TextStyle(fontSize: 52)),
        const SizedBox(height: 12),
        Text(_isSearching ? 'Không tìm thấy món nào' : 'Chưa có sản phẩm',
            style: const TextStyle(
                color: kTextGrey, fontSize: 15, fontWeight: FontWeight.w500)),
      ],
    ));
  }

  Widget _iconBtn(IconData icon) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
          color: kBg,
          borderRadius: BorderRadius.circular(11),
          border: Border.all(color: Colors.grey.shade200)),
      child: Icon(icon, color: kTextDark, size: 20),
    );
  }
}

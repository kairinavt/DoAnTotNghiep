class Product {
  final String name;
  double price;
  final String imageUrl;
  bool isFavorite;
  String? description;
  late int stock;
  late List<Product> includeProducts;

  Product({
    required this.name,
    required this.price,
    required this.imageUrl,
    required this.isFavorite,
    int? stock,
    this.description,
    List<Product>? includeProducts
  }) {
    this.stock = stock ?? 1;
    this.includeProducts = includeProducts ?? [];
  }

 static List<Product> products = [
  Product(
    name: 'Phở Bò Đặc Biệt',
    price: 65000,
    imageUrl:
        'https://images.unsplash.com/photo-1582878826629-29b7ad1cdc43?w=800',
    isFavorite: true,
    stock: 20,
    description:
        'Phở bò truyền thống với nước dùng đậm đà, thịt bò tươi ngon, ăn kèm rau thơm và chanh.',
    includeProducts: [
      Product(
        name: 'Chả Giò',
        price: 25000,
        imageUrl:
            'https://images.unsplash.com/photo-1604908176997-125f25cc6f3d?w=800',
        isFavorite: false,
      ),
      Product(
        name: 'Trà Đá',
        price: 5000,
        imageUrl:
            'https://images.unsplash.com/photo-1556679343-c7306c1976bc?w=800',
        isFavorite: false,
      ),
      Product(
        name: 'Bánh Flan',
        price: 15000,
        imageUrl:
            'https://images.unsplash.com/photo-1488477181946-6428a0291777?w=800',
        isFavorite: false,
      ),
      Product(
        name: 'Gỏi Cuốn',
        price: 30000,
        imageUrl:
            'https://images.unsplash.com/photo-1565299624946-b28f40a0ae38?w=800',
        isFavorite: false,
      ),
    ],
  ),
  Product(
    name: 'Cơm Tấm Sườn Bì Chả',
    price: 70000,
    imageUrl:
        'https://images.unsplash.com/photo-1512058564366-18510be2db19?w=800',
    isFavorite: true,
    stock: 15,
    description:
        'Cơm tấm thơm ngon ăn kèm sườn nướng, bì, chả trứng và nước mắm đặc trưng.',
  ),
  Product(
    name: 'Bún Bò Huế',
    price: 60000,
    imageUrl:
        'https://images.unsplash.com/photo-1559847844-5315695dadae?w=800',
    isFavorite: true,
    stock: 12,
    description:
        'Bún bò Huế cay nhẹ với thịt bò, giò heo và nước dùng đậm vị miền Trung.',
  ),
  Product(
    name: 'Bánh Mì Thịt Nướng',
    price: 35000,
    imageUrl:
        'https://images.unsplash.com/photo-1627308595229-7830a5c91f9f?w=800',
    isFavorite: true,
    stock: 25,
    description:
        'Bánh mì giòn rụm với thịt nướng thơm lừng, rau sống và nước sốt đặc biệt.',
  ),
  Product(
    name: 'Pizza Hải Sản',
    price: 180000,
    imageUrl:
        'https://images.unsplash.com/photo-1513104890138-7c749659a591?w=800',
    isFavorite: true,
    stock: 10,
    description:
        'Pizza đế mỏng phủ đầy tôm, mực, phô mai mozzarella béo ngậy.',
  ),
  Product(
    name: 'Burger Bò Phô Mai',
    price: 85000,
    imageUrl:
        'https://images.unsplash.com/photo-1568901346375-23c9450c58cd?w=800',
    isFavorite: true,
    stock: 18,
    description:
        'Burger bò nướng kết hợp phô mai cheddar và rau tươi.',
  ),
  Product(
    name: 'Gà Rán Giòn Cay',
    price: 95000,
    imageUrl:
        'https://images.unsplash.com/photo-1569058242253-92a9c755a0ec?q=80&w=870&auto=format&fit=crop&ixlib=rb-4.1.0&ixid=M3wxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8fA%3D%3D',
    isFavorite: true,
    stock: 14,
    description:
        'Gà rán lớp vỏ giòn tan, vị cay nhẹ hấp dẫn.',
  ),
  Product(
    name: 'Mì Ý Sốt Bò Bằm',
    price: 120000,
    imageUrl:
        'https://images.unsplash.com/photo-1621996346565-e3dbc646d9a9?w=800',
    isFavorite: true,
    stock: 11,
    description:
        'Mì Ý al dente kết hợp sốt bò bằm chuẩn vị Ý.',
  ),
  Product(
    name: 'Lẩu Thái Hải Sản',
    price: 280000,
    imageUrl:
        'https://images.unsplash.com/photo-1544025162-d76694265947?w=800',
    isFavorite: true,
    stock: 8,
    description:
        'Lẩu Thái chua cay với tôm, mực và nhiều loại rau tươi.',
  ),
];
}

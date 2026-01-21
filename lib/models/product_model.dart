class Product {
  final String id;
  final String name;
  final String barcode;
  final String category;
  final double price;
  final double cost;
  final double stock;
  final double gstRate;

  Product({
    required this.id,
    required this.name,
    required this.barcode,
    required this.category,
    required this.price,
    required this.cost,
    required this.stock,
    required this.gstRate,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['_id'],
      name: json['name'],
      barcode: json['barcode'] ?? '',
      category: json['category'] ?? 'General',
      price: (json['price'] ?? 0).toDouble(),
      cost: (json['cost'] ?? 0).toDouble(),
      stock: (json['stock'] ?? 0).toDouble(),
      gstRate: (json['gstRate'] ?? 0).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'name': name,
      'barcode': barcode,
      'category': category,
      'price': price,
      'cost': cost,
      'stock': stock,
      'gstRate': gstRate,
    };
  }
}

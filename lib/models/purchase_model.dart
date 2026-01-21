
class Purchase {
  final String? id;
  final String vendor;
  final String? vendorName;
  final List<PurchaseItem> items;
  final double subTotal;
  final double taxAmount;
  final double grandTotal;
  final String status;
  final String paymentStatus;
  final double paidAmount;
  final DateTime? createdAt;
  final String? invoiceNo;

   Purchase({
    this.id,
    required this.vendor,
    this.vendorName,
    required this.items,
    required this.subTotal,
    required this.taxAmount,
    required this.grandTotal,
    required this.status,
    required this.paymentStatus,
    required this.paidAmount,
    this.createdAt,
    this.invoiceNo,
  });

  factory Purchase.fromJson(Map<String, dynamic> json) {
    return Purchase(
      id: json['_id'],
      vendor: json['vendor'],
      vendorName: json['vendorName'],
      items: (json['items'] as List).map((i) => PurchaseItem.fromJson(i)).toList(),
      subTotal: (json['subTotal'] ?? 0).toDouble(),
      taxAmount: (json['taxAmount'] ?? 0).toDouble(),
      grandTotal: (json['grandTotal'] ?? 0).toDouble(),
      status: json['status'] ?? 'Draft',
      paymentStatus: json['paymentStatus'] ?? 'Unpaid',
      paidAmount: (json['paidAmount'] ?? 0).toDouble(),
      createdAt: json['createdAt'] != null ? DateTime.parse(json['createdAt']) : null,
      invoiceNo: json['invoiceNo'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'vendor': vendor,
      'items': items.map((i) => i.toJson()).toList(),
      'subTotal': subTotal,
      'taxAmount': taxAmount,
      'grandTotal': grandTotal,
      'status': status,
      'paymentStatus': paymentStatus,
      'paidAmount': paidAmount,
    };
  }
}

class PurchaseItem {
  final String product;
  final String name;
  final double quantity;
  final double purchasePrice;
  final double totalAmount;

  PurchaseItem({
    required this.product,
    required this.name,
    required this.quantity,
    required this.purchasePrice,
    required this.totalAmount,
  });

  factory PurchaseItem.fromJson(Map<String, dynamic> json) {
    return PurchaseItem(
      product: json['product'],
      name: json['name'] ?? '',
      quantity: (json['quantity'] ?? 0).toDouble(),
      purchasePrice: (json['purchasePrice'] ?? 0).toDouble(),
      totalAmount: (json['totalAmount'] ?? 0).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'product': product,
      'name': name,
      'quantity': quantity,
      'purchasePrice': purchasePrice,
      'totalAmount': totalAmount,
    };
  }
}

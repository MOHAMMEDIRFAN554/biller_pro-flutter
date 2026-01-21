class Bill {
  final String? id;
  final String? customer;
  final List<BillItem> items;
  final double subTotal;
  final double taxAmount;
  final double discountAmount; // Changed from totalDiscount
  final double grandTotal;
  final double roundOff;
  final List<Payment> payments;
  final DateTime? createdAt;
  final String? billNumber; // Changed from billNo to match backend

  Bill({
    this.id,
    this.customer,
    required this.items,
    required this.subTotal,
    required this.taxAmount,
    required this.discountAmount,
    required this.grandTotal,
    required this.roundOff,
    required this.payments,
    this.createdAt,
    this.billNumber,
  });

  double get paidTotal => payments.fold(0, (sum, p) => sum + p.amount);
  double get balanceAmount => (grandTotal - paidTotal).clamp(0, double.infinity);

  Map<String, dynamic> toJson() {
    return {
      'customer': customer,
      'items': items.map((i) => i.toJson()).toList(),
      'subTotal': subTotal,
      'taxAmount': taxAmount,
      'discountAmount': discountAmount,
      'grandTotal': grandTotal,
      'roundOff': roundOff,
      'payments': payments.map((p) => p.toJson()).toList(),
    };
  }

  factory Bill.fromJson(Map<String, dynamic> json) {
    return Bill(
      id: json['_id'],
      customer: json['customer'] != null ? (json['customer'] is Map ? json['customer']['_id'] : json['customer']) : null,
      items: (json['items'] as List).map((i) => BillItem.fromJson(i)).toList(),
      subTotal: (json['subTotal'] ?? 0).toDouble(),
      taxAmount: (json['taxAmount'] ?? 0).toDouble(),
      discountAmount: (json['discountAmount'] ?? 0).toDouble(),
      grandTotal: (json['grandTotal'] ?? 0).toDouble(),
      roundOff: (json['roundOff'] ?? 0).toDouble(),
      payments: (json['payments'] as List).map((p) => Payment.fromJson(p)).toList(),
      createdAt: json['createdAt'] != null ? DateTime.parse(json['createdAt']) : null,
      billNumber: json['billNumber'],
    );
  }
}

class BillItem {
  final String product;
  final String name;
  final double price;
  final double quantity;
  final double gstRate;
  final double discountAmount;
  final double totalAmount;

  BillItem({
    required this.product,
    required this.name,
    required this.price,
    required this.quantity,
    required this.gstRate,
    required this.discountAmount,
    required this.totalAmount,
  });

  Map<String, dynamic> toJson() {
    return {
      'product': product,
      'name': name,
      'price': price,
      'quantity': quantity,
      'gstRate': gstRate,
      'discountAmount': discountAmount,
      'totalAmount': totalAmount,
    };
  }

  factory BillItem.fromJson(Map<String, dynamic> json) {
    return BillItem(
      product: json['product'] ?? '',
      name: json['name'] ?? '',
      price: (json['price'] ?? 0).toDouble(),
      quantity: (json['quantity'] ?? 0).toDouble(),
      gstRate: (json['gstRate'] ?? 0).toDouble(),
      discountAmount: (json['discountAmount'] ?? 0).toDouble(),
      totalAmount: (json['totalAmount'] ?? 0).toDouble(),
    );
  }
}

class Payment {
  final String mode;
  final double amount;
  final String? reference;
  final bool showQr;

  Payment({
    required this.mode,
    required this.amount,
    this.reference,
    this.showQr = false,
  });

  Map<String, dynamic> toJson() {
    return {
      'mode': mode,
      'amount': amount,
      'reference': reference,
    };
  }

  factory Payment.fromJson(Map<String, dynamic> json) {
    return Payment(
      mode: json['mode'] ?? 'Cash',
      amount: (json['amount'] ?? 0).toDouble(),
      reference: json['reference'],
      showQr: json['showQr'] ?? false,
    );
  }
}

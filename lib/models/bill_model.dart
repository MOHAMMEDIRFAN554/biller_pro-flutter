class Bill {
  final String? id;
  final String? customer;
  final List<BillItem> items;
  final double subTotal;
  final double taxAmount;
  final double totalDiscount;
  final double grandTotal;
  final double roundOff;
  final List<Payment> payments;
  final DateTime? createdAt;
  final String? billNo;

  Bill({
    this.id,
    this.customer,
    required this.items,
    required this.subTotal,
    required this.taxAmount,
    required this.totalDiscount,
    required this.grandTotal,
    required this.roundOff,
    required this.payments,
    this.createdAt,
    this.billNo,
  });

  Map<String, dynamic> toJson() {
    return {
      'customer': customer,
      'items': items.map((i) => i.toJson()).toList(),
      'subTotal': subTotal,
      'taxAmount': taxAmount,
      'totalDiscount': totalDiscount,
      'grandTotal': grandTotal,
      'roundOff': roundOff,
      'payments': payments.map((p) => p.toJson()).toList(),
    };
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
}

class Payment {
  final String mode;
  final double amount;
  final String? reference;

  Payment({
    required this.mode,
    required this.amount,
    this.reference,
  });

  Map<String, dynamic> toJson() {
    return {
      'mode': mode,
      'amount': amount,
      'reference': reference,
    };
  }
}

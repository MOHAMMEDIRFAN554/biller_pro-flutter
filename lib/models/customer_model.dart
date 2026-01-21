class Customer {
  final String id;
  final String name;
  final String phone;
  final String? email;
  final String address;
  final double ledgerBalance;

  Customer({
    required this.id,
    required this.name,
    required this.phone,
    this.email,
    required this.address,
    required this.ledgerBalance,
  });

  factory Customer.fromJson(Map<String, dynamic> json) {
    return Customer(
      id: json['_id'],
      name: json['name'],
      phone: json['phone'] ?? '',
      email: json['email'],
      address: json['address'] ?? '',
      ledgerBalance: (json['ledgerBalance'] ?? 0).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'name': name,
      'phone': phone,
      'email': email,
      'address': address,
      'ledgerBalance': ledgerBalance,
    };
  }
}

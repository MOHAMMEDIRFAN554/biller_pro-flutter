import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/api_service.dart';
import '../models/product_model.dart';
import '../models/customer_model.dart';
import '../models/bill_model.dart';

class PosScreen extends StatefulWidget {
  const PosScreen({super.key});

  @override
  State<PosScreen> createState() => _PosScreenState();
}

class _PosScreenState extends State<PosScreen> {
  final List<BillItem> _cartItems = [];
  Customer? _selectedCustomer;
  List<Product> _products = [];
  bool _isLoading = false;
  String _search = '';

  double get subTotal => _cartItems.fold(0, (sum, item) => sum + item.totalAmount);
  double get totalTax => _cartItems.fold(0, (sum, item) => sum + (item.totalAmount * (item.gstRate / (100 + item.gstRate))));
  double get grandTotal => subTotal.roundToDouble();

  @override
  void initState() {
    super.initState();
    _fetchProducts();
  }

  Future<void> _fetchProducts() async {
    try {
      final api = Provider.of<ApiService>(context, listen: false);
      final data = await api.get('products?keyword=$_search&limit=20');
      setState(() {
        _products = (data['products'] as List).map((p) => Product.fromJson(p)).toList();
      });
    } catch (e) {
      debugPrint('Error fetching products: $e');
    }
  }

  void _addToCart(Product p) {
    setState(() {
      int idx = _cartItems.indexWhere((item) => item.product == p.id);
      if (idx >= 0) {
        _cartItems[idx] = BillItem(
          product: p.id,
          name: p.name,
          price: p.price,
          quantity: _cartItems[idx].quantity + 1,
          gstRate: p.gstRate,
          discountAmount: 0,
          totalAmount: (p.price * (_cartItems[idx].quantity + 1)),
        );
      } else {
        _cartItems.add(BillItem(
          product: p.id,
          name: p.name,
          price: p.price,
          quantity: 1,
          gstRate: p.gstRate,
          discountAmount: 0,
          totalAmount: p.price,
        ));
      }
    });
  }

  Future<void> _checkout() async {
    if (_cartItems.isEmpty) return;

    setState(() => _isLoading = true);
    try {
      final api = Provider.of<ApiService>(context, listen: false);
      final bill = Bill(
        customer: _selectedCustomer?.id,
        items: _cartItems,
        subTotal: subTotal - totalTax,
        taxAmount: totalTax,
        totalDiscount: 0,
        grandTotal: grandTotal,
        roundOff: grandTotal - subTotal,
        payments: [Payment(mode: 'Cash', amount: grandTotal)],
      );

      await api.post('bills', bill.toJson());
      
      setState(() {
        _cartItems.clear();
        _selectedCustomer = null;
        _isLoading = false;
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Sale Completed Successfully!')));
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Row(
        children: [
          // Products Side
          Expanded(
            flex: 3,
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: TextField(
                    decoration: InputDecoration(
                      hintText: 'Search products...',
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onChanged: (val) {
                      _search = val;
                      _fetchProducts();
                    },
                  ),
                ),
                Expanded(
                  child: GridView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      childAspectRatio: 1.1,
                      crossAxisSpacing: 10,
                      mainAxisSpacing: 10,
                    ),
                    itemCount: _products.length,
                    itemBuilder: (context, index) {
                      final p = _products[index];
                      return InkWell(
                        onTap: () => _addToCart(p),
                        child: Card(
                          elevation: 0,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: Colors.grey[200]!)),
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(p.name, style: const TextStyle(fontWeight: FontWeight.bold), maxLines: 2, overflow: TextOverflow.ellipsis),
                                const Spacer(),
                                Text('₹${p.price}', style: const TextStyle(color: Colors.blue, fontWeight: FontWeight.bold, fontSize: 18)),
                                Text('Stock: ${p.stock}', style: const TextStyle(fontSize: 10, color: Colors.grey)),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          
          // Cart Side
          Container(
            width: 320,
            decoration: BoxDecoration(
              color: Colors.grey[50],
              border: Border(left: BorderSide(color: Colors.grey[200]!)),
            ),
            child: Column(
              children: [
                const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Text('Current Cart', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                ),
                Expanded(
                  child: _cartItems.isEmpty
                    ? const Center(child: Text('Cart is empty', style: TextStyle(color: Colors.grey)))
                    : ListView.builder(
                        itemCount: _cartItems.length,
                        itemBuilder: (context, index) {
                          final item = _cartItems[index];
                          return ListTile(
                            title: Text(item.name, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                            subtitle: Text('qty: ${item.quantity.toInt()} x ${item.price}'),
                            trailing: Text('₹${item.totalAmount.toInt()}', style: const TextStyle(fontWeight: FontWeight.bold)),
                            onLongPress: () => setState(() => _cartItems.removeAt(index)),
                          );
                        },
                      ),
                ),
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Grand Total', style: TextStyle(fontSize: 16, color: Colors.grey)),
                          Text('₹$grandTotal', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.blue)),
                        ],
                      ),
                      const SizedBox(height: 20),
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _checkout,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          child: _isLoading 
                            ? const CircularProgressIndicator(color: Colors.white)
                            : const Text('Checkout', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

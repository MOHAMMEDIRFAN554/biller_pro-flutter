import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/api_service.dart';
import '../models/product_model.dart';
import '../models/customer_model.dart';
import '../models/bill_model.dart';
import '../services/pdf_service.dart';

class PosScreen extends StatefulWidget {
  const PosScreen({super.key});

  @override
  State<PosScreen> createState() => _PosScreenState();
}

class _PosScreenState extends State<PosScreen> {
  final List<BillItem> _cartItems = [];
  Customer? _selectedCustomer;
  List<Product> _products = [];
  List<Customer> _customers = [];
  bool _isLoading = false;
  String _search = '';
  String _customerSearch = '';
  String _paymentMode = 'Cash'; // Default payment mode

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
      if (mounted) {
        setState(() {
          _products = (data['products'] as List).map((p) => Product.fromJson(p)).toList();
        });
      }
    } catch (e) {
      debugPrint('Error fetching products: $e');
    }
  }

  Future<void> _fetchCustomers() async {
    if (_customerSearch.isEmpty) return;
    try {
      final api = Provider.of<ApiService>(context, listen: false);
      final data = await api.get('customers?keyword=$_customerSearch&limit=5');
      if (mounted) {
        setState(() {
          _customers = (data['customers'] as List).map((c) => Customer.fromJson(c)).toList();
        });
      }
    } catch (e) {
      debugPrint('Error fetching customers: $e');
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
        roundOff: 0,
        payments: [
          Payment(
            mode: _paymentMode, 
            amount: grandTotal,
            reference: _paymentMode == 'Credit' ? 'CREDIT_SALE' : null,
          )
        ],
      );

      final response = await api.post('bills', bill.toJson());
      
      // Auto-print bill
      try {
        final savedBill = Bill(
          billNo: response['billNo'],
          items: _cartItems,
          grandTotal: grandTotal,
          subTotal: subTotal,
          taxAmount: totalTax,
          totalDiscount: 0,
          roundOff: 0,
          payments: [],
        );
        await PdfService.generateAndPrintBill(savedBill);
      } catch (pe) {
        debugPrint('Print error: $pe');
      }
      
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
            width: 350,
            decoration: BoxDecoration(
              color: Colors.grey[50],
              border: Border(left: BorderSide(color: Colors.grey[200]!)),
            ),
            child: Column(
              children: [
                // Customer Selection
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Customer (Optional for Credit)', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey)),
                      const SizedBox(height: 8),
                      _selectedCustomer != null 
                        ? ListTile(
                            contentPadding: EdgeInsets.zero,
                            title: Text(_selectedCustomer!.name),
                            subtitle: Text(_selectedCustomer!.phone),
                            trailing: IconButton(icon: const Icon(Icons.close), onPressed: () => setState(() => _selectedCustomer = null)),
                          )
                        : TextField(
                            decoration: const InputDecoration(
                              hintText: 'Search customer...',
                              prefixIcon: Icon(Icons.person_search),
                              isDense: true,
                            ),
                            onChanged: (val) {
                              _customerSearch = val;
                              _fetchCustomers();
                            },
                          ),
                      if (_selectedCustomer == null && _customers.isNotEmpty && _customerSearch.isNotEmpty)
                        Container(
                          constraints: const BoxConstraints(maxHeight: 150),
                          child: ListView.builder(
                            shrinkWrap: true,
                            itemCount: _customers.length,
                            itemBuilder: (context, index) {
                              final c = _customers[index];
                              return ListTile(
                                title: Text(c.name),
                                subtitle: Text(c.phone),
                                onTap: () => setState(() {
                                  _selectedCustomer = c;
                                  _customers.clear();
                                  _customerSearch = '';
                                }),
                              );
                            },
                          ),
                        ),
                    ],
                  ),
                ),
                const Divider(),
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8.0),
                  child: Text('Current Cart', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
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
                      const SizedBox(height: 10),
                      // Payment Mode Selection
                      Row(
                        children: ['Cash', 'Bank', 'Credit'].map((mode) => Expanded(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 2.0),
                            child: ChoiceChip(
                              label: Text(mode, style: TextStyle(fontSize: 12, color: _paymentMode == mode ? Colors.white : Colors.black)),
                              selected: _paymentMode == mode,
                              selectedColor: Colors.blue,
                              onSelected: (selected) {
                                if (selected) setState(() => _paymentMode = mode);
                              },
                            ),
                          ),
                        )).toList(),
                      ),
                      const SizedBox(height: 20),
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          onPressed: (_isLoading || (_paymentMode == 'Credit' && _selectedCustomer == null)) ? null : _checkout,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          child: _isLoading 
                            ? const CircularProgressIndicator(color: Colors.white)
                            : Text('Checkout ($_paymentMode)', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
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

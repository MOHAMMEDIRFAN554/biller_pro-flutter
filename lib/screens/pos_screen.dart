import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/api_service.dart';
import '../models/product_model.dart';
import '../models/customer_model.dart';
import '../models/bill_model.dart';
import '../services/pdf_service.dart';
import 'package:barcode_widget/barcode_widget.dart';

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
  List<Payment> _payments = [Payment(mode: 'Cash', amount: 0)]; // Multi-payment support
  Map<String, dynamic>? _companyProfile;

  double get subTotal => _cartItems.fold(0, (sum, item) => sum + item.totalAmount);
  double get totalTax => _cartItems.fold(0, (sum, item) => sum + (item.totalAmount * (item.gstRate / (100 + item.gstRate))));
  double get grandTotal => subTotal.roundToDouble();

  @override
  void initState() {
    super.initState();
    _fetchProducts();
    _fetchCompanyProfile();
  }

  Future<void> _fetchCompanyProfile() async {
    try {
      final api = Provider.of<ApiService>(context, listen: false);
      final data = await api.get('settings/profile');
      if (mounted) {
        setState(() => _companyProfile = data);
      }
    } catch (e) {
      debugPrint('Error profile: $e');
    }
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
    if (p.stock <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Zero stock available!')));
      return;
    }

    setState(() {
      int idx = _cartItems.indexWhere((item) => item.product == p.id);
      if (idx >= 0) {
        if (_cartItems[idx].quantity + 1 > p.stock) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Insufficient stock!')));
          return;
        }
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
      _resetPayments();
    });
  }

  void _resetPayments() {
    _payments = [Payment(mode: 'Cash', amount: grandTotal)];
  }

  Future<void> _checkout() async {
    if (_cartItems.isEmpty) return;
    
    double paidTotal = _payments.fold(0, (sum, p) => sum + p.amount);
    if (paidTotal < grandTotal && _selectedCustomer == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Customer required for credit sales')));
      return;
    }

    setState(() => _isLoading = true);
    try {
      final api = Provider.of<ApiService>(context, listen: false);
      final bill = Bill(
        customer: _selectedCustomer?.id,
        items: _cartItems,
        subTotal: subTotal - totalTax,
        taxAmount: totalTax,
        discountAmount: 0,
        grandTotal: grandTotal,
        roundOff: 0,
        payments: _payments,
      );

      final response = await api.post('bills', bill.toJson());
      
      // Auto-print
      try {
        final savedBill = Bill.fromJson(response);
        await PdfService.generateAndPrintBill(savedBill, companyProfile: _companyProfile);
      } catch (pe) {
        debugPrint('Print error: $pe');
      }
      
      setState(() {
        _cartItems.clear();
        _selectedCustomer = null;
        _payments = [Payment(mode: 'Cash', amount: 0)];
        _isLoading = false;
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Sale Completed Successfully!')));
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  void _showSettlementSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => StatefulBuilder(
        builder: (context, setSheetState) {
          double paid = _payments.fold(0, (sum, p) => sum + p.amount);
          double balance = grandTotal - paid;

          return Padding(
            padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom, left: 16, right: 16, top: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Settlement', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    Text('Total: ₹$grandTotal', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blue)),
                  ],
                ),
                const Divider(),
                ..._payments.asMap().entries.map((entry) {
                  int idx = entry.key;
                  Payment p = entry.value;
                  return Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: DropdownButton<String>(
                              value: p.mode,
                              isExpanded: true,
                              items: ['Cash', 'UPI', 'Card', 'Credit'].map((m) => DropdownMenuItem(value: m, child: Text(m))).toList(),
                              onChanged: (val) {
                                if (val != null) {
                                  setSheetState(() => _payments[idx] = Payment(mode: val, amount: p.amount, reference: p.reference));
                                  setState(() {});
                                }
                              },
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: TextField(
                              decoration: const InputDecoration(isDense: true, prefixText: '₹'),
                              keyboardType: TextInputType.number,
                              controller: TextEditingController(text: p.amount.toString())..selection = TextSelection.collapsed(offset: p.amount.toString().length),
                              onChanged: (val) {
                                double amt = double.tryParse(val) ?? 0;
                                setSheetState(() => _payments[idx] = Payment(mode: p.mode, amount: amt, reference: p.reference));
                                setState(() {});
                              },
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.remove_circle_outline, color: Colors.red),
                            onPressed: _payments.length > 1 ? () {
                              setSheetState(() => _payments.removeAt(idx));
                              setState(() {});
                            } : null,
                          ),
                        ],
                      ),
                      if (p.mode == 'UPI' && _companyProfile != null && _companyProfile!['enableQrPayments'] == true && _companyProfile!['upiId'] != null)
                        Column(
                          children: [
                            Row(
                              children: [
                                Switch(
                                  value: p.showQr, 
                                  onChanged: (val) {
                                    setSheetState(() => _payments[idx] = Payment(mode: p.mode, amount: p.amount, reference: p.reference, showQr: val));
                                    setState(() {});
                                  }
                                ),
                                const Text('GENERATE QR CODE', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.blue)),
                              ],
                            ),
                            if (p.showQr)
                              Container(
                                margin: const EdgeInsets.only(bottom: 10),
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(border: Border.all(color: Colors.blue.shade100), borderRadius: BorderRadius.circular(12), color: Colors.blue.shade50),
                                child: Column(
                                  children: [
                                    Text('Scan to Pay ₹${p.amount}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                                    const SizedBox(height: 8),
                                    BarcodeWidget(
                                      barcode: Barcode.qrCode(),
                                      data: 'upi://pay?pa=${_companyProfile!['upiId']}&pn=${Uri.encodeComponent(_companyProfile!['upiName'] ?? _companyProfile!['name'])}&am=${p.amount.toStringAsFixed(2)}&cu=INR',
                                      width: 120,
                                      height: 120,
                                    ),
                                    const SizedBox(height: 4),
                                    Text(_companyProfile!['upiId'], style: const TextStyle(fontSize: 10, color: Colors.grey)),
                                  ],
                                ),
                              ),
                          ],
                        ),
                      if (p.mode == 'UPI' || p.mode == 'Card')
                        TextField(
                          decoration: const InputDecoration(hintText: 'Reference ID (optional)', isDense: true, hintStyle: TextStyle(fontSize: 12)),
                          onChanged: (val) {
                            setSheetState(() => _payments[idx] = Payment(mode: p.mode, amount: p.amount, reference: val));
                            setState(() {});
                          },
                        ),
                      const Divider(),
                    ],
                  );
                }),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    TextButton.icon(
                      onPressed: () {
                        setSheetState(() => _payments.add(Payment(mode: 'UPI', amount: balance > 0 ? balance : 0)));
                        setState(() {});
                      },
                      icon: const Icon(Icons.add),
                      label: const Text('Add Mode'),
                    ),
                    Text('Balance: ₹${balance.toStringAsFixed(2)}', style: TextStyle(color: balance > 0 ? Colors.red : Colors.green, fontWeight: FontWeight.bold)),
                  ],
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: (_isLoading || (balance > 0 && _selectedCustomer == null)) ? null : () {
                      Navigator.pop(context);
                      _checkout();
                    },
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.blue, foregroundColor: Colors.white),
                    child: const Text('Complete Sale', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          );
        },
      ),
    );
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
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          onPressed: (_isLoading || _cartItems.isEmpty) ? null : _showSettlementSheet,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          child: _isLoading 
                            ? const CircularProgressIndicator(color: Colors.white)
                            : const Text('Settlement & Pay', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
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

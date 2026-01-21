import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/api_service.dart';
import '../models/vendor_model.dart';
import '../models/product_model.dart';
import '../models/purchase_model.dart';

class NewPurchaseScreen extends StatefulWidget {
  const NewPurchaseScreen({super.key});

  @override
  State<NewPurchaseScreen> createState() => _NewPurchaseScreenState();
}

class _NewPurchaseScreenState extends State<NewPurchaseScreen> {
  Vendor? _selectedVendor;
  final List<PurchaseItem> _items = [];
  double _taxAmount = 0;
  double _paidAmount = 0;
  String _status = 'Ordered';
  String _paymentStatus = 'Unpaid';
  bool _isSaving = false;

  double get subTotal => _items.fold(0, (sum, item) => sum + item.totalAmount);
  double get grandTotal => subTotal + _taxAmount;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('New Purchase Entry')),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _buildVendorSelector(),
                const SizedBox(height: 24),
                _buildItemManager(),
                const SizedBox(height: 24),
                _buildSummary(),
              ],
            ),
          ),
          _buildBottomAction(),
        ],
      ),
    );
  }

  Widget _buildVendorSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Vendor*', style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        InkWell(
          onTap: _pickVendor,
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(border: Border.all(color: Colors.grey[300]!), borderRadius: BorderRadius.circular(8)),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(_selectedVendor?.name ?? 'Select Vendor'),
                const Icon(Icons.arrow_drop_down),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildItemManager() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Purchase Items*', style: TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
        const SizedBox(height: 8),
        ..._items.asMap().entries.map((entry) {
          int idx = entry.key;
          PurchaseItem item = entry.value;
          return Card(
            margin: const EdgeInsets.only(bottom: 8),
            child: ListTile(
              title: Text(item.name),
              subtitle: Text('Qty: ${item.quantity} | Unit: ₹${item.purchasePrice}'),
              trailing: IconButton(
                icon: const Icon(Icons.delete_outline, color: Colors.red),
                onPressed: () => setState(() => _items.removeAt(idx)),
              ),
            ),
          );
        }),
        const SizedBox(height: 8),
        OutlinedButton.icon(
          onPressed: _addItem,
          icon: const Icon(Icons.add),
          label: const Text('Add Product Item'),
        ),
      ],
    );
  }

  Widget _buildSummary() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(12)),
      child: Column(
        children: [
          _buildSummaryRow('Subtotal', '₹${subTotal.toStringAsFixed(2)}'),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Tax Amount'),
              SizedBox(
                width: 100,
                child: TextField(
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(isDense: true, prefixText: '₹'),
                  textAlign: TextAlign.right,
                  onChanged: (val) => setState(() => _taxAmount = double.tryParse(val) ?? 0),
                ),
              ),
            ],
          ),
          const Divider(height: 24),
          _buildSummaryRow('Grand Total', '₹${grandTotal.toStringAsFixed(2)}', isBold: true),
          const SizedBox(height: 16),
          _buildPaymentSection(),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value, {bool isBold = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(fontWeight: isBold ? FontWeight.bold : FontWeight.normal)),
        Text(value, style: TextStyle(fontWeight: isBold ? FontWeight.bold : FontWeight.normal, fontSize: isBold ? 18 : 14)),
      ],
    );
  }

  Widget _buildPaymentSection() {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Paid Amount'),
            SizedBox(
              width: 120,
              child: TextField(
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(isDense: true, prefixText: '₹'),
                textAlign: TextAlign.right,
                onChanged: (val) {
                  setState(() {
                    _paidAmount = double.tryParse(val) ?? 0;
                    if (_paidAmount >= grandTotal) {
                      _paymentStatus = 'Paid';
                    } else if (_paidAmount > 0) {
                      _paymentStatus = 'Partial';
                    } else {
                      _paymentStatus = 'Unpaid';
                    }
                  });
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        DropdownButtonFormField<String>(
          initialValue: _status,
          decoration: const InputDecoration(labelText: 'Status', isDense: true),
          items: ['Ordered', 'Received', 'Cancelled']
              .map((s) => DropdownMenuItem(value: s, child: Text(s)))
              .toList(),
          onChanged: (val) => setState(() => _status = val!),
        ),
      ],
    );
  }

  Widget _buildBottomAction() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(color: Colors.white, boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4)]),
      child: ElevatedButton(
        onPressed: _isSaving ? null : _savePurchase,
        style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 50), backgroundColor: Colors.indigo, foregroundColor: Colors.white),
        child: _isSaving ? const CircularProgressIndicator(color: Colors.white) : const Text('Save Purchase Voucher', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
    );
  }

  void _pickVendor() async {
    final Vendor? picked = await showSearch<Vendor?>(
      context: context,
      delegate: VendorSearchDelegate(),
    );
    if (picked != null) setState(() => _selectedVendor = picked);
  }

  void _addItem() async {
    final Product? picked = await showSearch<Product?>(
      context: context,
      delegate: ProductSearchDelegate(),
    );
    if (picked == null) return;

    final qtyController = TextEditingController();
    final priceController = TextEditingController(text: picked.purchasePrice.toString());

    if (!mounted) return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Add ${picked.name}'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: qtyController, decoration: const InputDecoration(labelText: 'Quantity'), keyboardType: TextInputType.number),
              TextField(controller: priceController, decoration: const InputDecoration(labelText: 'Purchase Price'), keyboardType: TextInputType.number),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              double qty = double.tryParse(qtyController.text) ?? 0;
              double price = double.tryParse(priceController.text) ?? 0;
              if (qty > 0 && price > 0) {
                setState(() {
                  _items.add(PurchaseItem(
                    product: picked.id,
                    name: picked.name,
                    quantity: qty,
                    purchasePrice: price,
                    totalAmount: qty * price,
                  ));
                });
                Navigator.pop(context);
              }
            },
            child: const Text('Add Item'),
          ),
        ],
      ),
    );
  }

  void _savePurchase() async {
    if (_selectedVendor == null || _items.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select vendor and add items')));
      return;
    }

    setState(() => _isSaving = true);
    try {
      final api = Provider.of<ApiService>(context, listen: false);
      final purchase = Purchase(
        vendor: _selectedVendor!.id,
        items: _items,
        subTotal: subTotal,
        taxAmount: _taxAmount,
        grandTotal: grandTotal,
        status: _status,
        paymentStatus: _paymentStatus,
        paidAmount: _paidAmount,
      );

      await api.post('purchases', purchase.toJson());
      if (mounted) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Purchase Entry Saved Successfully')));
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }
}

class VendorSearchDelegate extends SearchDelegate<Vendor?> {
  @override
  List<Widget>? buildActions(BuildContext context) => [IconButton(icon: const Icon(Icons.clear), onPressed: () => query = '')];
  @override
  Widget? buildLeading(BuildContext context) => IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => close(context, null));

  @override
  Widget buildResults(BuildContext context) => _buildList(context);
  @override
  Widget buildSuggestions(BuildContext context) => _buildList(context);

  Widget _buildList(BuildContext context) {
    if (query.isEmpty) return const Center(child: Text('Search Vendors...'));
    final api = Provider.of<ApiService>(context, listen: false);
    return FutureBuilder(
      future: api.get('vendors?keyword=$query'),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        final data = snapshot.data as Map<String, dynamic>;
        final vendors = (data['vendors'] as List).map((v) => Vendor.fromJson(v)).toList();
        return ListView.builder(
          itemCount: vendors.length,
          itemBuilder: (context, idx) {
            final v = vendors[idx];
            return ListTile(title: Text(v.name), subtitle: Text(v.phone), onTap: () => close(context, v));
          },
        );
      },
    );
  }
}

class ProductSearchDelegate extends SearchDelegate<Product?> {
  @override
  List<Widget>? buildActions(BuildContext context) => [IconButton(icon: const Icon(Icons.clear), onPressed: () => query = '')];
  @override
  Widget? buildLeading(BuildContext context) => IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => close(context, null));

  @override
  Widget buildResults(BuildContext context) => _buildList(context);
  @override
  Widget buildSuggestions(BuildContext context) => _buildList(context);

  Widget _buildList(BuildContext context) {
    if (query.isEmpty) return const Center(child: Text('Search Products...'));
    final api = Provider.of<ApiService>(context, listen: false);
    return FutureBuilder(
      future: api.get('products?keyword=$query'),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        final data = snapshot.data as Map<String, dynamic>;
        final products = (data['products'] as List).map((p) => Product.fromJson(p)).toList();
        return ListView.builder(
          itemCount: products.length,
          itemBuilder: (context, idx) {
            final p = products[idx];
            return ListTile(title: Text(p.name), subtitle: Text('Price: ₹${p.price}'), onTap: () => close(context, p));
          },
        );
      },
    );
  }
}

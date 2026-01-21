import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/api_service.dart';
import '../models/purchase_model.dart';

class PurchaseScreen extends StatefulWidget {
  const PurchaseScreen({super.key});

  @override
  State<PurchaseScreen> createState() => _PurchaseScreenState();
}

class _PurchaseScreenState extends State<PurchaseScreen> {
  List<Purchase> _purchases = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchPurchases();
  }

  Future<void> _fetchPurchases() async {
    setState(() => _isLoading = true);
    try {
      final api = Provider.of<ApiService>(context, listen: false);
      final data = await api.get('purchases');
      if (mounted) {
        setState(() {
          _purchases = (data['purchases'] as List).map((p) => Purchase.fromJson(p)).toList();
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator())
        : RefreshIndicator(
            onRefresh: _fetchPurchases,
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _purchases.length,
              itemBuilder: (context, index) {
                final p = _purchases[index];
                return Card(
                  elevation: 0,
                  margin: const EdgeInsets.only(bottom: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: Colors.grey[200]!)),
                  child: ListTile(
                    title: Text(p.vendorName ?? 'Unknown Vendor', style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text('Inv: ${p.invoiceNo ?? "N/A"} | ${p.createdAt.toString().split(' ')[0]}'),
                    trailing: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text('₹${p.grandTotal}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(color: p.paymentStatus == 'Paid' ? Colors.green : Colors.orange, borderRadius: BorderRadius.circular(4)),
                          child: Text(p.paymentStatus, style: const TextStyle(color: Colors.white, fontSize: 10)),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
      floatingActionButton: FloatingActionButton(
        onPressed: () { /* New Purchase Logic */ },
        backgroundColor: Colors.indigo,
        child: const Icon(Icons.add_shopping_cart, color: Colors.white),
      ),
    );
  }
}

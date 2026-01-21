import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/api_service.dart';
import '../models/bill_model.dart';
import '../services/pdf_service.dart';
import 'package:intl/intl.dart';

class BillHistoryScreen extends StatefulWidget {
  const BillHistoryScreen({super.key});

  @override
  State<BillHistoryScreen> createState() => _BillHistoryScreenState();
}

class _BillHistoryScreenState extends State<BillHistoryScreen> {
  List<dynamic> _bills = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchBills();
  }

  Future<void> _fetchBills() async {
    setState(() => _isLoading = true);
    try {
      final api = Provider.of<ApiService>(context, listen: false);
      final data = await api.get('bills');
      if (mounted) {
        setState(() {
          _bills = data['bills'] ?? [];
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
      appBar: AppBar(title: const Text('Sales History'), backgroundColor: Colors.white, foregroundColor: Colors.black, elevation: 0),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator())
        : RefreshIndicator(
            onRefresh: _fetchBills,
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _bills.length,
              itemBuilder: (context, index) {
                final b = _bills[index];
                return Card(
                  elevation: 0,
                  margin: const EdgeInsets.only(bottom: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: Colors.grey[200]!)),
                  child: ListTile(
                    title: Text(b['customerName'] ?? 'Walk-in Customer', style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text('Bill: ${b['billNumber'] ?? b['billNo'] ?? "N/A"} | ${DateFormat('dd-MM-yyyy').format(DateTime.parse(b['createdAt']))}'),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('₹${b['grandTotal']}', style: const TextStyle(fontWeight: FontWeight.bold)),
                        const SizedBox(width: 8),
                        IconButton(
                          icon: const Icon(Icons.print, color: Colors.blue),
                          onPressed: () => _printBill(b),
                        ),
                        IconButton(
                          icon: const Icon(Icons.assignment_return, color: Colors.orange),
                          onPressed: () => _showReturnDialog(b),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
    );
  }

  void _showReturnDialog(dynamic b) {
    List<Map<String, dynamic>> returnItems = [];
    final items = b['items'] as List;
    
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text('Return - ${b['billNumber'] ?? 'Bill'}'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () => _processReturn(b['_id'], returnItems),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.orange, foregroundColor: Colors.white),
              child: const Text('Process Return'),
            ),
          ],
          content: SizedBox(
            width: double.maxFinite,
            child: SingleChildScrollView(
              child: ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: items.length,
                itemBuilder: (context, idx) {
                  final item = items[idx];
                  final productId = item['product'] is Map ? item['product']['_id'] : item['product'];
                  int maxQty = (item['quantity'] as num).toInt() - ((item['returnedQuantity'] ?? 0) as num).toInt();
                  
                  return ListTile(
                    title: Text(item['name'] ?? 'Product'),
                    subtitle: Text('Max Returnable: $maxQty'),
                    trailing: SizedBox(
                      width: 60,
                      child: TextField(
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(isDense: true, hintText: '0'),
                        onChanged: (val) {
                          int qty = int.tryParse(val) ?? 0;
                          if (qty > maxQty) {
                            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Cannot return more than purchased')));
                            return;
                          }
                          returnItems.removeWhere((ri) => ri['productId'] == productId);
                          if (qty > 0) {
                            returnItems.add({'productId': productId, 'quantity': qty});
                          }
                        },
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _processReturn(String billId, List<Map<String, dynamic>> items) async {
    if (items.isEmpty) return;
    try {
      final api = Provider.of<ApiService>(context, listen: false);
      await api.post('returns/sales', {
        'billId': billId,
        'items': items,
        'reason': 'Customer Return (Mobile App)',
        'refundMode': 'Ledger'
      });
      if (mounted) {
        Navigator.pop(context);
        _fetchBills();
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Return processed successfully')));
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  Future<void> _printBill(dynamic b) async {
    try {
        final savedBill = Bill.fromJson(b);
        await PdfService.generateAndPrintBill(savedBill);
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Print Error: $e')));
    }
  }
}

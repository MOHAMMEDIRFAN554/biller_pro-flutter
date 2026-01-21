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
                    subtitle: Text('Bill: ${b['billNo']} | ${DateFormat('dd-MM-yyyy').format(DateTime.parse(b['createdAt']))}'),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('₹${b['grandTotal']}', style: const TextStyle(fontWeight: FontWeight.bold)),
                        const SizedBox(width: 8),
                        IconButton(
                          icon: const Icon(Icons.print, color: Colors.blue),
                          onPressed: () => _printBill(b),
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

  Future<void> _printBill(dynamic b) async {
    try {
       // Map dynamic to Bill model
       final bill = Bill(
         billNo: b['billNo'],
         items: (b['items'] as List).map((i) => BillItem(
           product: i['product'] ?? '',
           name: i['name'] ?? '',
           quantity: (i['quantity'] ?? 0).toDouble(),
           price: (i['price'] ?? 0).toDouble(),
           gstRate: (i['gstRate'] ?? 0).toDouble(),
           discountAmount: (i['discountAmount'] ?? 0).toDouble(),
           totalAmount: (i['totalAmount'] ?? 0).toDouble(),
         )).toList().cast<BillItem>(),
         grandTotal: (b['grandTotal'] ?? 0).toDouble(),
         subTotal: (b['subTotal'] ?? 0).toDouble(),
         taxAmount: (b['taxAmount'] ?? 0).toDouble(),
         totalDiscount: (b['totalDiscount'] ?? 0).toDouble(),
         roundOff: (b['roundOff'] ?? 0).toDouble(),
         payments: [],
       );
       await PdfService.generateAndPrintBill(bill);
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Print Error: $e')));
    }
  }
}

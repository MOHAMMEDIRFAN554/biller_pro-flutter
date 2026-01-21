import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/api_service.dart';

class PnlScreen extends StatefulWidget {
  const PnlScreen({super.key});

  @override
  State<PnlScreen> createState() => _PnlScreenState();
}

class _PnlScreenState extends State<PnlScreen> {
  Map<String, dynamic> _pnlData = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchPnl();
  }

  Future<void> _fetchPnl() async {
    try {
      final api = Provider.of<ApiService>(context, listen: false);
      final data = await api.get('reports/pnl'); // Assuming this endpoint exists
      if (mounted) {
        setState(() {
          _pnlData = data;
          _isLoading = false;
        });
      }
    } catch (e) {
      // If P&L endpoint doesn't exist, calculate from summary
      try {
        if (!mounted) return;
        final api = Provider.of<ApiService>(context, listen: false);
        final summary = await api.get('analytics/dashboard');
        if (mounted) {
           setState(() {
            _pnlData = {
              'revenue': summary['totalSales'] ?? 0,
              'expenses': summary['totalExpenses'] ?? 0,
              'netProfit': (summary['totalSales'] ?? 0) - (summary['totalExpenses'] ?? 0),
            };
            _isLoading = false;
          });
        }
      } catch (e2) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e2')));
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator())
        : RefreshIndicator(
            onRefresh: _fetchPnl,
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _buildFinanceNode('Total Revenue', '₹${_pnlData['revenue'] ?? 0}', Colors.green),
                const SizedBox(height: 12),
                _buildFinanceNode('Total Expenses', '₹${_pnlData['expenses'] ?? 0}', Colors.red),
                const Divider(height: 40),
                _buildFinanceNode(
                  'Net Profit', 
                  '₹${_pnlData['netProfit'] ?? 0}', 
                  (_pnlData['netProfit'] ?? 0) >= 0 ? Colors.blue : Colors.red,
                  isLarge: true
                ),
              ],
            ),
          ),
    );
  }

  Widget _buildFinanceNode(String title, String value, Color color, {bool isLarge = false}) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: TextStyle(fontSize: isLarge ? 18 : 14, fontWeight: isLarge ? FontWeight.bold : FontWeight.normal)),
          Text(value, style: TextStyle(fontSize: isLarge ? 24 : 18, fontWeight: FontWeight.bold, color: color)),
        ],
      ),
    );
  }
}

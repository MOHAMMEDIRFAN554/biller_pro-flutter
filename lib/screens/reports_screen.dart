import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import '../services/api_service.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  Map<String, dynamic> _stats = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchStats();
  }

  Future<void> _fetchStats() async {
    try {
      setState(() => _isLoading = true);
      final api = Provider.of<ApiService>(context, listen: false);
      final data = await api.get('analytics/dashboard');
      setState(() {
        _stats = data;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error fetching stats: $e');
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Dashboard Summary', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        actions: [
          IconButton(onPressed: _fetchStats, icon: const Icon(Icons.refresh)),
        ],
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator())
        : RefreshIndicator(
            onRefresh: _fetchStats,
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Top Stats Row
                Row(
                  children: [
                    Expanded(child: _buildMiniCard('Sales', '₹${_stats['totalSales'] ?? 0}', Colors.blue)),
                    const SizedBox(width: 12),
                    Expanded(child: _buildMiniCard('Bills', '${_stats['totalOrders'] ?? 0}', Colors.green)),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(child: _buildMiniCard('Clients', '${_stats['customerCount'] ?? 0}', Colors.orange)),
                    const SizedBox(width: 12),
                    Expanded(child: _buildMiniCard('Stock', '${_stats['productCount'] ?? 0}', Colors.red)),
                  ],
                ),
                
                const SizedBox(height: 24),
                _buildSectionTitle('Sales Analytics (Last 7 Days)'),
                const SizedBox(height: 12),
                _buildSalesGraph(),

                const SizedBox(height: 24),
                _buildSectionTitle('Low Stock Alerts'),
                const SizedBox(height: 12),
                _buildLowStockList(),

                const SizedBox(height: 24),
                _buildSectionTitle('Recent Billings'),
                const SizedBox(height: 12),
                _buildRecentBillsList(),
              ],
            ),
          ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.blueGrey));
  }

  Widget _buildMiniCard(String title, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(color: Colors.grey, fontSize: 12)),
          const SizedBox(height: 4),
          Text(value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color)),
        ],
      ),
    );
  }

  Widget _buildSalesGraph() {
    List<dynamic> dailySales = _stats['dailySales'] ?? [];
    if (dailySales.isEmpty) {
      return Container(
        height: 200,
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
        child: const Center(child: Text('No data for graph')),
      );
    }

    return Container(
      height: 220,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: LineChart(
        LineChartData(
          gridData: const FlGridData(show: false),
          titlesData: const FlTitlesData(show: false),
          borderData: FlBorderData(show: false),
          lineBarsData: [
            LineChartBarData(
              spots: List.generate(dailySales.length, (i) {
                return FlSpot(i.toDouble(), (dailySales[i]['amount'] as num).toDouble());
              }),
              isCurved: true,
              color: Colors.blue,
              barWidth: 4,
              dotData: const FlDotData(show: false),
              belowBarData: BarAreaData(show: true, color: Colors.blue.withValues(alpha: 0.1)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLowStockList() {
    List<dynamic> products = _stats['lowStockProducts'] ?? [];
    if (products.isEmpty) return const Text('All products are well stocked', style: TextStyle(color: Colors.grey, fontSize: 12));

    return Column(
      children: products.map((p) => Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(color: Colors.red[50], borderRadius: BorderRadius.circular(12)),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(p['name'], style: const TextStyle(fontWeight: FontWeight.bold)),
            Text('Only ${p['stock']} left', style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 12)),
          ],
        ),
      )).toList(),
    );
  }

  Widget _buildRecentBillsList() {
    List<dynamic> bills = _stats['recentBills'] ?? [];
    if (bills.isEmpty) return const Text('No recent bills', style: TextStyle(color: Colors.grey, fontSize: 12));

    return Column(
      children: bills.map((b) => Card(
        elevation: 0,
        margin: const EdgeInsets.only(bottom: 8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: Colors.grey[200]!)),
        child: ListTile(
          title: Text(b['customer']?['name'] ?? 'Walk-in Customer', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
          subtitle: Text('ID: ${b['billNumber']}', style: const TextStyle(fontSize: 10)),
          trailing: Text('₹${b['grandTotal']}', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blue)),
        ),
      )).toList(),
    );
  }
}

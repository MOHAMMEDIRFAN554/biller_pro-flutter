import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../services/api_service.dart';

class PnlScreen extends StatefulWidget {
  const PnlScreen({super.key});

  @override
  State<PnlScreen> createState() => _PnlScreenState();
}

class _PnlScreenState extends State<PnlScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  Map<String, dynamic> _pnlData = {};
  Map<String, dynamic> _collectionData = {};
  bool _isLoading = true;
  DateTime _startDate = DateTime.now().subtract(const Duration(days: 30));
  DateTime _endDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _fetchData();
  }

  Future<void> _fetchData() async {
    setState(() => _isLoading = true);
    final api = Provider.of<ApiService>(context, listen: false);
    final String startStr = DateFormat('yyyy-MM-dd').format(_startDate);
    final String endStr = DateFormat('yyyy-MM-dd').format(_endDate);

    try {
      final pnl = await api.get('reports/pnl?startDate=$startStr&endDate=$endStr');
      final coll = await api.get('reports/collection?startDate=$startStr&endDate=$endStr');
      if (mounted) {
        setState(() {
          _pnlData = pnl;
          _collectionData = coll;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Financial Reports', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(100),
          child: Column(
            children: [
              _buildDateFilter(),
              TabBar(
                controller: _tabController,
                indicatorColor: Colors.blue,
                labelColor: Colors.blue,
                unselectedLabelColor: Colors.grey,
                tabs: const [Tab(text: 'Profit & Loss'), Tab(text: 'Collections')],
              ),
            ],
          ),
        ),
      ),
      body: _isLoading 
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [_buildPnlTab(), _buildCollectionTab()],
            ),
    );
  }

  Widget _buildDateFilter() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: InkWell(
              onTap: () => _selectDateRange(context),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(8)),
                child: Row(
                  children: [
                    const Icon(Icons.calendar_month, size: 18, color: Colors.blue),
                    const SizedBox(width: 8),
                    Text('${DateFormat('dd MMM').format(_startDate)} - ${DateFormat('dd MMM').format(_endDate)}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          IconButton(onPressed: _fetchData, icon: const Icon(Icons.refresh, color: Colors.blue)),
        ],
      ),
    );
  }

  Future<void> _selectDateRange(BuildContext context) async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: DateTimeRange(start: _startDate, end: _endDate),
    );
    if (picked != null) {
      setState(() {
        _startDate = picked.start;
        _endDate = picked.end;
      });
      _fetchData();
    }
  }

  Widget _buildPnlTab() {
    final revenue = _pnlData['revenue'] ?? {};
    final expenses = _pnlData['expenses'] ?? {};
    final profit = _pnlData['profit'] ?? {};

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildSectionTitle('Revenue'),
        _buildReportRow('Gross Sales', '₹${revenue['totalSales'] ?? 0}'),
        _buildReportRow('Sales Returns', '-₹${revenue['totalSalesReturns'] ?? 0}', color: Colors.red),
        _buildReportRow('Net Revenue', '₹${revenue['netRevenue'] ?? 0}', isBold: true),
        const SizedBox(height: 24),
        _buildSectionTitle('Operating Expenses'),
        _buildReportRow('Total Expenses', '₹${expenses['totalExpenses'] ?? 0}', color: Colors.red),
        const SizedBox(height: 24),
        _buildSectionTitle('Summary'),
        _buildReportRow('Gross Profit', '₹${profit['grossProfit'] ?? 0}', isBold: true, color: Colors.green),
        _buildReportRow('Net Profit', '₹${profit['netProfit'] ?? 0}', isBold: true, color: Colors.blue, isLarge: true),
      ],
    );
  }

  Widget _buildCollectionTab() {
    final summary = _collectionData['summary'] ?? {};
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildSectionTitle('Collection Breakdown'),
        _buildReportRow('Cash Collection', '₹${summary['totalCash'] ?? 0}'),
        _buildReportRow('UPI Collection', '₹${summary['totalUPI'] ?? 0}'),
        _buildReportRow('Card Collection', '₹${summary['totalCard'] ?? 0}'),
        const Divider(height: 32),
        _buildReportRow('Total Net Collection', '₹${summary['netCollection'] ?? 0}', isBold: true, color: Colors.blue),
        const SizedBox(height: 24),
        _buildSectionTitle('Outstanding'),
        _buildReportRow('Credit Sales (Pending)', '₹${summary['totalCredit'] ?? 0}', color: Colors.orange),
      ],
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(title.toUpperCase(), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey, letterSpacing: 0.5)),
    );
  }

  Widget _buildReportRow(String label, String value, {bool isBold = false, Color? color, bool isLarge = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontSize: isLarge ? 16 : 14, fontWeight: isBold ? FontWeight.bold : FontWeight.normal)),
          Text(value, style: TextStyle(fontSize: isLarge ? 20 : 16, fontWeight: FontWeight.bold, color: color ?? Colors.black87)),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/api_service.dart';
import 'inventory_screen.dart';
import 'pos_screen.dart';
import 'customer_screen.dart';
import 'reports_screen.dart';
import 'vendor_screen.dart';
import 'purchase_screen.dart';
import 'warehouse_screen.dart';
import 'expense_screen.dart';
import 'pnl_screen.dart';
import 'bill_history_screen.dart';
import 'settings_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _selectedIndex = 0;

  final List<Widget> _pages = [
    const ReportsScreen(),    // 0: Analytics
    const PosScreen(),        // 1: POS
    const InventoryScreen(),  // 2: Products
    const WarehouseScreen(),  // 3: Stock
    const PurchaseScreen(),   // 4: Purchases
    const CustomerScreen(),   // 5: Customers
    const VendorScreen(),     // 6: Vendors
    const ExpenseScreen(),    // 7: Expenses
    const PnlScreen(),        // 8: P&L
    const BillHistoryScreen(), // 9: History
    const SettingsScreen(),    // 10: Settings
  ];

  @override
  Widget build(BuildContext context) {
    final apiService = Provider.of<ApiService>(context);
    final user = apiService.userInfo;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Biller Pro', style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout_rounded),
            onPressed: () => apiService.logout(),
          ),
        ],
      ),
      drawer: Drawer(
        child: Column(
          children: [
            UserAccountsDrawerHeader(
              currentAccountPicture: CircleAvatar(
                backgroundColor: Colors.white,
                child: Text(
                  (user?['name'] as String?)?[0].toUpperCase() ?? 'U',
                  style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.blue),
                ),
              ),
              accountName: Text(user?['name'] ?? 'User', style: const TextStyle(fontWeight: FontWeight.bold)),
              accountEmail: Text(user?['email'] ?? 'user@billerpro.com'),
              decoration: const BoxDecoration(color: Colors.blue),
            ),
            Expanded(
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  _buildDrawerItem(0, Icons.dashboard_outlined, 'Dashboard Summary'),
                  _buildDrawerItem(1, Icons.point_of_sale_outlined, 'Sales / POS'),
                  const Divider(),
                  _buildDrawerItem(2, Icons.inventory_2_outlined, 'Products'),
                  _buildDrawerItem(3, Icons.warehouse_outlined, 'Warehouse / Stock'),
                  _buildDrawerItem(4, Icons.shopping_cart_outlined, 'Purchases'),
                  const Divider(),
                  _buildDrawerItem(5, Icons.people_outline, 'Customers'),
                  _buildDrawerItem(6, Icons.business_outlined, 'Vendors'),
                  const Divider(),
                  _buildDrawerItem(7, Icons.outbox_outlined, 'Expenses'),
                  _buildDrawerItem(8, Icons.analytics_outlined, 'Profit & Loss (P&L)'),
                  const Divider(),
                  _buildDrawerItem(9, Icons.history_edu_outlined, 'Sales History'),
                  _buildDrawerItem(10, Icons.settings_outlined, 'Settings'),
                ],
              ),
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.logout, color: Colors.red),
              title: const Text('Logout', style: TextStyle(color: Colors.red)),
              onTap: () => apiService.logout(),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
      body: _pages[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex > 3 ? 0 : _selectedIndex,
        onTap: (index) => setState(() => _selectedIndex = index),
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.analytics_outlined), label: 'Reports'),
          BottomNavigationBarItem(icon: Icon(Icons.add_shopping_cart), label: 'POS'),
          BottomNavigationBarItem(icon: Icon(Icons.inventory_2_outlined), label: 'Inventory'),
          BottomNavigationBarItem(icon: Icon(Icons.people_outline), label: 'Users'),
        ],
      ),
    );
  }

  Widget _buildDrawerItem(int index, IconData icon, String title) {
    return ListTile(
      leading: Icon(icon, color: _selectedIndex == index ? Colors.blue : Colors.grey[700]),
      title: Text(title, style: TextStyle(color: _selectedIndex == index ? Colors.blue : Colors.black, fontWeight: _selectedIndex == index ? FontWeight.bold : FontWeight.normal)),
      selected: _selectedIndex == index,
      selectedTileColor: Colors.blue.withValues(alpha: 0.1),
      onTap: () {
        setState(() => _selectedIndex = index);
        Navigator.pop(context);
      },
    );
  }
}

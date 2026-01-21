import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/api_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  Map<String, dynamic> _settings = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchSettings();
  }

  Future<void> _fetchSettings() async {
    try {
      final api = Provider.of<ApiService>(context, listen: false);
      final data = await api.get('settings');
      if (mounted) {
        setState(() {
          _settings = data['settings'] ?? {};
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(title: const Text('Settings'), backgroundColor: Colors.white, foregroundColor: Colors.black, elevation: 0),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator())
        : ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _buildSection('Business Details', [
                _buildTile(Icons.store, 'Business Name', _settings['businessName'] ?? 'Biller Pro'),
                _buildTile(Icons.email_outlined, 'Email', _settings['email'] ?? 'N/A'),
                _buildTile(Icons.phone_outlined, 'Phone', _settings['phone'] ?? 'N/A'),
                _buildTile(Icons.location_on_outlined, 'Address', _settings['address'] ?? 'N/A'),
              ]),
              const SizedBox(height: 24),
              _buildSection('Financial Info', [
                _buildTile(Icons.receipt_long, 'GSTIN', _settings['gstin'] ?? 'N/A'),
                _buildTile(Icons.account_balance, 'Bank Name', _settings['bankName'] ?? 'N/A'),
              ]),
              const SizedBox(height: 24),
              _buildSection('Payment & QR Settings', [
                _buildTile(Icons.qr_code, 'UPI ID', _settings['upiId'] ?? 'Not Set'),
                _buildTile(Icons.person_pin, 'UPI Name', _settings['upiName'] ?? 'Not Set'),
                ListTile(
                  leading: const Icon(Icons.qr_code_scanner, color: Colors.blue, size: 20),
                  title: const Text('Dynamic QR Payments', style: TextStyle(fontSize: 12, color: Colors.grey)),
                  subtitle: Text(_settings['enableQrPayments'] == true ? 'Enabled' : 'Disabled', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black)),
                ),
              ]),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () {},
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Edit Business Profile'),
              ),
            ],
          ),
    );
  }

  Widget _buildSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.grey)),
        ),
        Container(
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
          child: Column(children: children),
        ),
      ],
    );
  }

  Widget _buildTile(IconData icon, String title, String value) {
    return ListTile(
      leading: Icon(icon, color: Colors.blue, size: 20),
      title: Text(title, style: const TextStyle(fontSize: 12, color: Colors.grey)),
      subtitle: Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black)),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/api_service.dart';

class ExpenseScreen extends StatefulWidget {
  const ExpenseScreen({super.key});

  @override
  State<ExpenseScreen> createState() => _ExpenseScreenState();
}

class _ExpenseScreenState extends State<ExpenseScreen> {
  List<dynamic> _expenses = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchExpenses();
  }

  Future<void> _fetchExpenses() async {
    setState(() => _isLoading = true);
    try {
      final api = Provider.of<ApiService>(context, listen: false);
      final data = await api.get('expenses');
      if (mounted) {
        setState(() {
          _expenses = data['expenses'] ?? [];
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
            onRefresh: _fetchExpenses,
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _expenses.length,
              itemBuilder: (context, index) {
                final ex = _expenses[index];
                return Card(
                  elevation: 0,
                  margin: const EdgeInsets.only(bottom: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: Colors.grey[200]!)),
                  child: ListTile(
                    leading: CircleAvatar(backgroundColor: Colors.red.withValues(alpha: 0.1), child: const Icon(Icons.outbox, color: Colors.red)),
                    title: Text(ex['description'] ?? 'No Description', style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text(ex['category'] ?? 'General'),
                    trailing: Text('₹${ex['amount']}', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.red, fontSize: 16)),
                  ),
                );
              },
            ),
          ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddExpenseDialog,
        backgroundColor: Colors.redAccent,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  void _showAddExpenseDialog() {
    final amountController = TextEditingController();
    final descController = TextEditingController();
    String category = 'General';

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Add New Expense'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(controller: amountController, decoration: const InputDecoration(labelText: 'Amount*', prefixText: '₹'), keyboardType: TextInputType.number),
                TextField(controller: descController, decoration: const InputDecoration(labelText: 'Description*')),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  initialValue: category,
                  decoration: const InputDecoration(labelText: 'Category'),
                  items: ['General', 'Rent', 'Electricity', 'Salary', 'Transport', 'Other']
                      .map((cat) => DropdownMenuItem(value: cat, child: Text(cat)))
                      .toList(),
                  onChanged: (val) => setDialogState(() => category = val!),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () {
                if (amountController.text.isNotEmpty && descController.text.isNotEmpty) {
                  _addExpense(double.tryParse(amountController.text) ?? 0, descController.text, category);
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent, foregroundColor: Colors.white),
              child: const Text('Save Expense'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _addExpense(double amount, String description, String category) async {
    try {
      final api = Provider.of<ApiService>(context, listen: false);
      await api.post('expenses', {
        'amount': amount,
        'description': description,
        'category': category,
        'date': DateTime.now().toIso8601String(),
      });
      if (mounted) {
        Navigator.pop(context);
        _fetchExpenses();
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Expense recorded successfully')));
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }
}

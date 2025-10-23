import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';

// Supabase client
final supabase = Supabase.instance.client;

class AddPaymentScreen extends StatefulWidget {
  const AddPaymentScreen({super.key});

  @override
  State<AddPaymentScreen> createState() => _AddPaymentScreenState();
}

class _AddPaymentScreenState extends State<AddPaymentScreen> {
  String? _selectedPaymentType;
  int? _selectedCustomerId;
  int? _selectedUnitId;
  String _amount = '';
  DateTime _selectedDate = DateTime.now();
  String _description = '';

  final List<String> _paymentTypes = ['Rent', 'Maintenance', 'Deposit'];
  List<Map<String, dynamic>> _customers = [];
  List<Map<String, dynamic>> _units = [];
  bool _isLoading = true;

  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _fetchRequiredData();
  }

  Future<void> _fetchRequiredData() async {
    try {
      final customersData = await supabase.from('customers').select('id, name');
      final unitsData = await supabase.from('uints').select('id, unit_number, rent_amount');

      setState(() {
        _customers = List<Map<String, dynamic>>.from(customersData);
        _units = List<Map<String, dynamic>>.from(unitsData);
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error fetching data: $e')),
        );
      }
      setState(() => _isLoading = false);
    }
  }

  Future<void> _savePayment() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedPaymentType == null || _selectedCustomerId == null || _selectedUnitId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill all required fields.')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final newPayment = {
        'customer_id': _selectedCustomerId,
        'uint_id': _selectedUnitId,
        'payment_type': _selectedPaymentType,
        'amount': double.tryParse(_amount),
        'date': _selectedDate.toIso8601String().substring(0, 10),
        'description': _description,
      };

      await supabase.from('payments').insert(newPayment);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Payment added successfully! 🎉')),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving payment: $e')),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() => _selectedDate = picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Add New Payment')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Add New Payment'), centerTitle: true),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Payment Type
              const Text('Payment Type', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: _selectedPaymentType,
                hint: const Text('Select payment type...'),
                decoration: const InputDecoration(border: OutlineInputBorder(), contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 10)),
                items: _paymentTypes.map((type) => DropdownMenuItem<String>(value: type, child: Text(type))).toList(),
                onChanged: (value) => setState(() => _selectedPaymentType = value),
                validator: (value) => value == null ? 'Required field' : null,
              ),

              const SizedBox(height: 20),

              // Customer
              const Text('Customer', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              DropdownButtonFormField<int>(
                value: _selectedCustomerId,
                hint: const Text('Select customer...'),
                decoration: const InputDecoration(border: OutlineInputBorder(), contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 10)),
                items: _customers.map((customer) {
                  return DropdownMenuItem<int>(
                    value: customer['id'] as int,
                    child: Text(customer['name'].toString()),
                  );
                }).toList(),
                onChanged: (value) => setState(() => _selectedCustomerId = value),
                validator: (value) => value == null ? 'Required field' : null,
              ),

              const SizedBox(height: 20),

              // Unit
              const Text('Unit', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              DropdownButtonFormField<int>(
                value: _selectedUnitId,
                hint: const Text('Select unit...'),
                decoration: const InputDecoration(border: OutlineInputBorder(), contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 10)),
                items: _units.map((unit) {
                  return DropdownMenuItem<int>(
                    value: unit['id'] as int,
                    child: Text(unit['unit_number'].toString()),
                  );
                }).toList(),
                onChanged: (value) => setState(() => _selectedUnitId = value),
                validator: (value) => value == null ? 'Required field' : null,
              ),

              const SizedBox(height: 20),

              // Amount
              const Text('Amount (\$)', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              TextFormField(
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(border: OutlineInputBorder(), hintText: 'Enter amount', contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 10)),
                onChanged: (value) => _amount = value,
                validator: (value) {
                  if (value == null || value.isEmpty) return 'Required field';
                  if (double.tryParse(value) == null) return 'Must be a valid number';
                  return null;
                },
              ),

              const SizedBox(height: 20),

              // Payment Date
              const Text('Payment Date', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              GestureDetector(
                onTap: () => _selectDate(context),
                child: AbsorbPointer(
                  child: TextFormField(
                    controller: TextEditingController(text: DateFormat('MM/dd/yyyy').format(_selectedDate)),
                    decoration: InputDecoration(
                      border: const OutlineInputBorder(),
                      suffixIcon: IconButton(icon: const Icon(Icons.calendar_today), onPressed: () => _selectDate(context)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                    ),
                    validator: (value) => value!.isEmpty ? 'Required field' : null,
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // Description
              const Text('Description', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              TextFormField(
                maxLines: 2,
                decoration: const InputDecoration(border: OutlineInputBorder(), hintText: 'Enter payment description (optional)', contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 10)),
                onChanged: (value) => _description = value,
              ),

              const SizedBox(height: 30),

              // Save button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _isLoading ? null : _savePayment,
                  icon: _isLoading
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                      : const Icon(Icons.check),
                  label: Text(_isLoading ? 'Saving...' : 'Add Payment'),
                  style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 15), textStyle: const TextStyle(fontSize: 18)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

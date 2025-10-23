// lib/screens/add_new_contract_screen.dart

import 'dart:ui' as fw;
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

// ✅ نوع العقد
enum ContractPeriod { monthly, threeMonths, yearly }

extension ContractPeriodExtension on ContractPeriod {
  String toDisplayString() {
    switch (this) {
      case ContractPeriod.monthly:
        return 'Monthly';
      case ContractPeriod.threeMonths:
        return '3 Months';
      case ContractPeriod.yearly:
        return 'Yearly';
    }
  }

  int toMonths() {
    switch (this) {
      case ContractPeriod.monthly:
        return 1;
      case ContractPeriod.threeMonths:
        return 3;
      case ContractPeriod.yearly:
        return 12;
    }
  }
}

// ✅ موديلات البيانات
class Unit {
  final int id;
  final String unitNumber;
  final String propertyName;

  Unit({
    required this.id,
    required this.unitNumber,
    required this.propertyName,
  });

  factory Unit.fromJson(Map<String, dynamic> json) {
    return Unit(
      id: json['id'],
      unitNumber: json['unit_number']?.toString() ?? '',
      propertyName: json['properties']?['name']?.toString() ?? 'N/A',
    );
  }

  @override
  String toString() => '$unitNumber - $propertyName';
}

class Customer {
  final int id;
  final String name;

  Customer({required this.id, required this.name});

  factory Customer.fromJson(Map<String, dynamic> json) {
    return Customer(id: json['id'], name: json['name'] ?? '');
  }

  @override
  String toString() => name;
}

class AddNewContractScreen extends StatefulWidget {
  const AddNewContractScreen({super.key});

  @override
  State<AddNewContractScreen> createState() => _AddNewContractScreenState();
}

class _AddNewContractScreenState extends State<AddNewContractScreen> {
  final supabase = Supabase.instance.client;

  // ✅ البيانات المختارة
  Unit? _selectedUnit;
  Customer? _selectedCustomer;
  bool _createNewCustomer = false;
  ContractPeriod _selectedContractType = ContractPeriod.monthly;

  // ✅ الخانات الجديدة
  bool _isContractActive = true;
  String _paymentStatus = 'Unpaid';

  // ✅ Controllers
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _newCustomerNameController =
      TextEditingController();
  final TextEditingController _newCustomerPhoneController =
      TextEditingController();
  final TextEditingController _newCustomerNationalityController =
      TextEditingController();
  final TextEditingController _totalContractAmountController =
      TextEditingController();

  final TextEditingController _startDateController = TextEditingController();
  final TextEditingController _endDateController = TextEditingController();

  DateTime? _startDate;
  DateTime? _endDate;

  late Future<List<Unit>> _unitsFuture;
  late Future<List<Customer>> _customersFuture;

  final DateFormat _displayDateFormat = DateFormat('MM/dd/yyyy');

  @override
  void initState() {
    super.initState();
    _unitsFuture = _fetchUnits();
    _customersFuture = _fetchCustomers();
  }

  // =========================
  // جلب البيانات من Supabase
  // =========================
  Future<List<Unit>> _fetchUnits() async {
    try {
      final response = await supabase
          .from('uints')
          .select('id, unit_number, properties(name)');
      return (response as List).map((json) => Unit.fromJson(json)).toList();
    } catch (e) {
      debugPrint('Error fetching units: $e');
      return [];
    }
  }

  Future<List<Customer>> _fetchCustomers() async {
    try {
      final response = await supabase.from('customers').select('id, name');
      return (response as List).map((json) => Customer.fromJson(json)).toList();
    } catch (e) {
      debugPrint('Error fetching customers: $e');
      return [];
    }
  }

  // =========================
  // إضافة عقد جديد
  // =========================
  Future<void> _addContract() async {
    if (_selectedUnit == null ||
        (_selectedCustomer == null && !_createNewCustomer) ||
        _totalContractAmountController.text.isEmpty ||
        _startDateController.text.isEmpty ||
        _endDateController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('⚠️ Please fill all required fields')),
      );
      return;
    }

    try {
      int? customerId = _selectedCustomer?.id;

      // إنشاء عميل جديد إذا مطلوب
      if (_createNewCustomer &&
          _newCustomerNameController.text.trim().isNotEmpty) {
        final response = await supabase
            .from('customers')
            .insert({
              'name': _newCustomerNameController.text.trim(),
              'phone': _newCustomerPhoneController.text.trim(),
              'nationality': _newCustomerNationalityController.text.trim(),
              'created_at': DateTime.now().toIso8601String(),
            })
            .select()
            .single();

        if (response != null && response['id'] != null) {
          customerId = response['id'];
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('❌ Failed to create customer')),
          );
          return;
        }
      }

      // تحويل النص لتاريخ
      _startDate = _displayDateFormat.parse(_startDateController.text.trim());
      _endDate = _displayDateFormat.parse(_endDateController.text.trim());

      // حساب totalAmount
      final totalAmount =
          double.tryParse(_totalContractAmountController.text.trim()) ?? 0.0;

      // توليد UUID
      final uuid = const Uuid().v4();

      // إدخال العقد
      final contractResponse = await supabase.from('contract').insert({
        'uuid': uuid,
        'unit_id': _selectedUnit!.id,
        'customer_id': customerId,
        'contract_type': _selectedContractType.toDisplayString(),
        'start_date': _startDate!.toIso8601String(),
        'end_date': _endDate!.toIso8601String(),
        'annul_rent': totalAmount,
        'description':
            '${_descriptionController.text.trim()} ${_isContractActive ? " العقد ساري" : "غير ساري"}',
        'created_at': DateTime.now().toIso8601String(),
      }).select();

      // تحديث payment_status في جدول rent
      await supabase
          .from('rent')
          .update({'payment_status': _paymentStatus})
          .eq('unit_id', _selectedUnit!.id)
          .eq('customer_id', customerId as Object);

      if (contractResponse != null && contractResponse.isNotEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('✅ Contract added successfully!')),
        );
        Navigator.pop(context, true);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('❌ Failed to add contract')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('❌ Error: $e')));
    }
  }

  // =========================
  // واجهة المستخدم
  // =========================
  Widget _buildUnitDropdown() {
    return FutureBuilder<List<Unit>>(
      future: _unitsFuture,
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const LinearProgressIndicator();
        final units = snapshot.data!;
        return DropdownButtonFormField<Unit>(
          value: _selectedUnit,
          items: units
              .map(
                (unit) =>
                    DropdownMenuItem(value: unit, child: Text(unit.toString())),
              )
              .toList(),
          onChanged: (val) => setState(() => _selectedUnit = val),
          decoration: const InputDecoration(
            labelText: 'Select Unit',
            border: OutlineInputBorder(),
          ),
        );
      },
    );
  }

  Widget _buildCustomerSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CheckboxListTile(
          title: const Text('Create New Customer'),
          value: _createNewCustomer,
          onChanged: (val) => setState(() => _createNewCustomer = val!),
        ),
        if (_createNewCustomer) ...[
          TextFormField(
            controller: _newCustomerNameController,
            decoration: const InputDecoration(
              labelText: 'Customer Name',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 10),
          TextFormField(
            controller: _newCustomerPhoneController,
            keyboardType: TextInputType.phone,
            decoration: const InputDecoration(
              labelText: 'Phone',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 10),
          TextFormField(
            controller: _newCustomerNationalityController,
            decoration: const InputDecoration(
              labelText: 'Nationality',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 10),
          TextFormField(
            controller: _totalContractAmountController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Total Contract Amount',
              border: OutlineInputBorder(),
            ),
          ),
        ] else
          FutureBuilder<List<Customer>>(
            future: _customersFuture,
            builder: (context, snapshot) {
              if (!snapshot.hasData) return const LinearProgressIndicator();
              final customers = snapshot.data!;
              return DropdownButtonFormField<Customer>(
                value: _selectedCustomer,
                items: customers
                    .map((c) => DropdownMenuItem(value: c, child: Text(c.name)))
                    .toList(),
                onChanged: (val) => setState(() => _selectedCustomer = val),
                decoration: const InputDecoration(
                  labelText: 'Select Existing Customer',
                  border: OutlineInputBorder(),
                ),
              );
            },
          ),
      ],
    );
  }

  Widget _buildDateTextField(String label, TextEditingController controller) {
    return TextFormField(
      controller: controller,
      keyboardType: TextInputType.datetime,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
        suffixIcon: IconButton(
          icon: const Icon(Icons.calendar_today_outlined),
          onPressed: () async {
            final picked = await showDatePicker(
              context: context,
              initialDate: DateTime.now(),
              firstDate: DateTime(2020),
              lastDate: DateTime(2050),
            );
            if (picked != null) {
              setState(() {
                controller.text = _displayDateFormat.format(picked);
              });
            }
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: fw.TextDirection.ltr,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Add New Contract'),
          centerTitle: true,
        ),
        body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: ListView(
            children: [
              _buildUnitDropdown(),
              const SizedBox(height: 16),
              _buildCustomerSection(),
              const SizedBox(height: 16),
              DropdownButtonFormField<ContractPeriod>(
                value: _selectedContractType,
                items: ContractPeriod.values
                    .map(
                      (e) => DropdownMenuItem(
                        value: e,
                        child: Text(e.toDisplayString()),
                      ),
                    )
                    .toList(),
                onChanged: (val) =>
                    setState(() => _selectedContractType = val!),
                decoration: const InputDecoration(
                  labelText: 'Contract Type',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              _buildDateTextField(
                'Start Date (MM/dd/yyyy)',
                _startDateController,
              ),
              const SizedBox(height: 16),
              _buildDateTextField('End Date (MM/dd/yyyy)', _endDateController),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descriptionController,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Description',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              CheckboxListTile(
                title: const Text('Contract Active'),
                value: _isContractActive,
                onChanged: (val) => setState(() => _isContractActive = val!),
              ),
              const SizedBox(height: 10),
              DropdownButtonFormField<String>(
                value: _paymentStatus,
                items: ['Paid', 'Unpaid']
                    .map(
                      (status) =>
                          DropdownMenuItem(value: status, child: Text(status)),
                    )
                    .toList(),
                onChanged: (val) => setState(() => _paymentStatus = val!),
                decoration: const InputDecoration(
                  labelText: 'Payment Status',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _addContract,
                child: const Text('Add Contract'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/contracts_manage_model.dart';

class EditContractScreen extends StatefulWidget {
  final ContractModel contract;

  const EditContractScreen({Key? key, required this.contract}) : super(key: key);

  @override
  State<EditContractScreen> createState() => _EditContractScreenState();
}

class _EditContractScreenState extends State<EditContractScreen> {
  final _formKey = GlobalKey<FormState>();
  final SupabaseClient supabase = Supabase.instance.client;

  int? selectedUnitId;
  int? selectedCustomerId;

  TextEditingController startDateController = TextEditingController();
  TextEditingController endDateController = TextEditingController();
  TextEditingController annualRentController = TextEditingController();

  List<Map<String, dynamic>> units = [];
  List<Map<String, dynamic>> customers = [];

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    try {
      // ✅ تحميل البيانات من الجداول الصحيحة
      final unitResponse = await supabase
          .from('uints')
          .select('id, unit_number, properties(name)');
      final customerResponse =
          await supabase.from('customers').select('id, name');

      setState(() {
        units = List<Map<String, dynamic>>.from(unitResponse);
        customers = List<Map<String, dynamic>>.from(customerResponse);

        selectedUnitId = widget.contract.unitId;
        selectedCustomerId = widget.contract.customerId;
        startDateController.text = widget.contract.startDate;
        endDateController.text = widget.contract.endDate;
        annualRentController.text = widget.contract.annualRent.toString();
      });

      debugPrint("✅ Contract data loaded successfully");
    } catch (e, stack) {
      debugPrint("❌ Error loading data: $e");
      debugPrint(stack.toString());
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading data: $e')),
      );
    }
  }

  Future<void> _updateContract() async {
    if (!_formKey.currentState!.validate()) return;

    if (selectedUnitId == null || selectedCustomerId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a valid unit and customer')),
      );
      return;
    }

    try {
      // ✅ استخدام أسماء الأعمدة والجداول الحقيقية من Supabase
      final response = await supabase
          .from('contract')
          .update({
            'unit_id': selectedUnitId,
            'customer_id': selectedCustomerId,
            'start_date': startDateController.text,
            'end_date': endDateController.text,
            'annul_rent': double.tryParse(annualRentController.text) ?? 0,
          })
          .eq('id', widget.contract.id);

      debugPrint("✅ Update response: $response");

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Contract updated successfully')),
      );
      Navigator.pop(context, true);
    } catch (e, stack) {
      debugPrint("❌ Failed to update contract: $e");
      debugPrint(stack.toString());
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update contract: $e')),
      );
    }
  }

  Future<void> _pickDate(TextEditingController controller) async {
    try {
      final DateTime? date = await showDatePicker(
        context: context,
        initialDate: DateTime.tryParse(controller.text) ?? DateTime.now(),
        firstDate: DateTime(2000),
        lastDate: DateTime(2100),
      );
      if (date != null) {
        controller.text = DateFormat('yyyy-MM-dd').format(date);
        debugPrint("📅 Selected date: ${controller.text}");
      }
    } catch (e) {
      debugPrint("❌ Error selecting date: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Edit Contract')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: units.isEmpty || customers.isEmpty
            ? const Center(child: CircularProgressIndicator())
            : Form(
                key: _formKey,
                child: ListView(
                  children: [
                    // 🏢 اختيار الوحدة
                    DropdownButtonFormField<int>(
                      value: units.any((u) => u['id'] == selectedUnitId)
                          ? selectedUnitId
                          : null,
                      decoration: const InputDecoration(labelText: 'Unit'),
                      items: units.map<DropdownMenuItem<int>>((unit) {
                        final propertyName = unit['properties']?['name'] ?? 'N/A';
                        return DropdownMenuItem<int>(
                          value: unit['id'] as int,
                          child: Text('$propertyName - ${unit['unit_number']}'),
                        );
                      }).toList(),
                      onChanged: (value) => setState(() => selectedUnitId = value),
                      validator: (value) =>
                          value == null ? 'Please select a unit' : null,
                    ),
                    const SizedBox(height: 16),

                    // 👤 اختيار العميل
                    DropdownButtonFormField<int>(
                      value: customers.any((c) => c['id'] == selectedCustomerId)
                          ? selectedCustomerId
                          : null,
                      decoration: const InputDecoration(labelText: 'Customer'),
                      items: customers.map<DropdownMenuItem<int>>((customer) {
                        return DropdownMenuItem<int>(
                          value: customer['id'] as int,
                          child: Text(customer['name']),
                        );
                      }).toList(),
                      onChanged: (value) =>
                          setState(() => selectedCustomerId = value),
                      validator: (value) =>
                          value == null ? 'Please select a customer' : null,
                    ),
                    const SizedBox(height: 16),

                    // 📅 تاريخ البداية
                    TextFormField(
                      controller: startDateController,
                      decoration: InputDecoration(
                        labelText: 'Start Date',
                        suffixIcon: IconButton(
                          icon: const Icon(Icons.calendar_today),
                          onPressed: () => _pickDate(startDateController),
                        ),
                      ),
                      readOnly: true,
                      validator: (value) =>
                          value == null || value.isEmpty ? 'Enter start date' : null,
                    ),
                    const SizedBox(height: 16),

                    // 📅 تاريخ النهاية
                    TextFormField(
                      controller: endDateController,
                      decoration: InputDecoration(
                        labelText: 'End Date',
                        suffixIcon: IconButton(
                          icon: const Icon(Icons.calendar_today),
                          onPressed: () => _pickDate(endDateController),
                        ),
                      ),
                      readOnly: true,
                      validator: (value) =>
                          value == null || value.isEmpty ? 'Enter end date' : null,
                    ),
                    const SizedBox(height: 16),

                    // 💰 الإيجار السنوي
                    TextFormField(
                      controller: annualRentController,
                      decoration: const InputDecoration(labelText: 'Annual Rent'),
                      keyboardType: TextInputType.number,
                      validator: (value) =>
                          value == null || value.isEmpty ? 'Enter annual rent' : null,
                    ),
                    const SizedBox(height: 24),

                    // الأزرار
                    Row(
                      children: [
                        ElevatedButton(
                          onPressed: _updateContract,
                          child: const Text('Update Contract'),
                        ),
                        const SizedBox(width: 16),
                        OutlinedButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('Cancel'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}

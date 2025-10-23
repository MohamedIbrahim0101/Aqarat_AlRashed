import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart'; // استيراد مكتبة UUID

// تهيئة مولد UUID
const uuidGenerator = Uuid();

// تهيئة Supabase (افتراضياً)
// تأكد من تهيئة Supabase في main()
final supabase = Supabase.instance.client;

// ==========================
// 1. نماذج البيانات (Models) (تم إضافة حقل uuid)
// ==========================

// نموذج عقد الإيجار للقراءة من الجدول الرئيسي
class RentItem {
  final int id;
  final String uuid; // تم إضافة حقل UUID
  final double rentAmount;
  final String status;
  final String unitNumber;
  final String customerName;
  final DateTime startDate;
  final DateTime endDate;
  final int unitId;
  final int customerId;

  RentItem({
    required this.id,
    required this.uuid,
    required this.rentAmount,
    required this.status,
    required this.unitNumber,
    required this.customerName,
    required this.startDate,
    required this.endDate,
    required this.unitId,
    required this.customerId,
  });

  factory RentItem.fromJson(Map<String, dynamic> json) {
    double rentAmount = 0.0;
    final rentValue = json['rent'];
    if (rentValue is num) {
      rentAmount = rentValue.toDouble();
    } else if (rentValue is String) {
      rentAmount = double.tryParse(rentValue) ?? 0.0;
    }

    String status = json['payment_status']?.toString() ?? 'Unknown';

    DateTime safeParseDate(dynamic value) {
      if (value == null) return DateTime.now();
      try {
        return DateTime.parse(value.toString());
      } catch (_) {
        return DateTime.now();
      }
    }

    return RentItem(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      uuid: json['uuid']?.toString() ?? '', // قراءة حقل uuid
      rentAmount: rentAmount,
      status: status,
      unitNumber: json['uints']?['unit_number']?.toString() ?? 'N/A',
      customerName: json['customers']?['name']?.toString() ?? 'N/A',
      startDate: safeParseDate(json['start_date']),
      endDate: safeParseDate(json['end_date']),
      unitId: json['unit_id'] is int ? json['unit_id'] : int.tryParse(json['unit_id']?.toString() ?? '0') ?? 0, 
      customerId: json['customer_id'] is int ? json['customer_id'] : int.tryParse(json['customer_id']?.toString() ?? '0') ?? 0,
    );
  }
}

// نموذج العقار (PropertyModel)
class PropertyModel {
  final int id;
  final String name;
  PropertyModel({required this.id, required this.name});
  factory PropertyModel.fromJson(Map<String, dynamic> json) => 
      PropertyModel(
        id: json['id'] is int ? json['id'] : int.tryParse(json['id']?.toString() ?? '0') ?? 0,
        name: json['name']?.toString() ?? 'N/A'
      );
}

// نموذج الوحدة (UnitModel)
class UnitModel {
  final int id;
  final String unitNumber;
  final int propId;
  final double rentAmount;
  UnitModel({required this.id, required this.unitNumber, required this.propId, required this.rentAmount});
  
  factory UnitModel.fromJson(Map<String, dynamic> json) => 
      UnitModel(
          id: json['id'] is int ? json['id'] : int.tryParse(json['id']?.toString() ?? '0') ?? 0,
          unitNumber: json['unit_number']?.toString() ?? 'N/A',
          propId: json['prop_id'] is int ? json['prop_id'] : int.tryParse(json['prop_id']?.toString() ?? '0') ?? 0,
          rentAmount: (json['rent_amount'] is num) ? (json['rent_amount'] as num).toDouble() : double.tryParse(json['rent_amount']?.toString() ?? '0') ?? 0.0,
      );
}

// نموذج العميل (CustomerModel)
class CustomerModel {
  final int id;
  final String name;
  CustomerModel({required this.id, required this.name});
  factory CustomerModel.fromJson(Map<String, dynamic> json) => 
      CustomerModel(
        id: json['id'] is int ? json['id'] : int.tryParse(json['id']?.toString() ?? '0') ?? 0,
        name: json['name']?.toString() ?? 'N/A'
      );
}

// ==========================
// 2. شاشة إضافة عقد إيجار (AddRentScreen)
// (تم تعديل منطق الحفظ لإضافة UUID)
// ==========================

class AddRentScreen extends StatefulWidget {
  const AddRentScreen({super.key});

  @override
  State<AddRentScreen> createState() => _AddRentScreenState();
}

class _AddRentScreenState extends State<AddRentScreen> {
  final _formKey = GlobalKey<FormState>();
  
  int? _selectedPropertyId;
  int? _selectedUnitId;
  int? _selectedCustomerId;
  
  DateTime? _startDate;
  DateTime? _endDate;
  final TextEditingController _rentAmountController = TextEditingController();
  final String _paymentStatus = 'pending'; 

  List<PropertyModel> _properties = [];
  List<UnitModel> _units = [];
  List<CustomerModel> _customers = [];

  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchDropdownData();
    _startDate = DateTime.now();
    _endDate = DateTime.now().add(const Duration(days: 365));
  }

  @override
  void dispose() {
    _rentAmountController.dispose();
    super.dispose();
  }

  Future<void> _fetchDropdownData() async {
    try {
      final propertiesResponse = await supabase.from('properties').select('id, name');
      final unitsResponse = await supabase.from('uints').select('id, unit_number, prop_id, rent_amount');
      final customersResponse = await supabase.from('customers').select('id, name');

      setState(() {
        _properties = (propertiesResponse as List).map((e) => PropertyModel.fromJson(e)).toList();
        _units = (unitsResponse as List).map((e) => UnitModel.fromJson(e)).toList();
        _customers = (customersResponse as List).map((e) => CustomerModel.fromJson(e)).toList();
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error fetching dropdown data: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('فشل تحميل البيانات المطلوبة: $e'), backgroundColor: Colors.red),
        );
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _onUnitSelected(int? unitId) {
    setState(() {
      _selectedUnitId = unitId;
      if (unitId != null) {
        final selectedUnit = _units.firstWhere((unit) => unit.id == unitId);
        _rentAmountController.text = selectedUnit.rentAmount.toStringAsFixed(2);
      } else {
        _rentAmountController.clear();
      }
    });
  }

  List<UnitModel> get _filteredUnits {
    if (_selectedPropertyId == null) {
      return [];
    }
    return _units.where((unit) => unit.propId == _selectedPropertyId).toList();
  }

  Future<void> _saveRentContract() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    
    if (_selectedUnitId == null || _selectedCustomerId == null || _startDate == null || _endDate == null) {
      if(mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('الرجاء اختيار الوحدة والعميل وتحديد التواريخ.'), backgroundColor: Colors.orange),
        );
      }
      return;
    }

    try {
      // **توليد UUID جديد**
      final newUuid = uuidGenerator.v4(); 

      final newRentData = {
        'unit_id': _selectedUnitId,
        'customer_id': _selectedCustomerId,
        'start_date': _startDate!.toIso8601String().substring(0, 10), 
        'end_date': _endDate!.toIso8601String().substring(0, 10),
        'rent': double.tryParse(_rentAmountController.text),
        'payment_status': _paymentStatus,
        'uuid': newUuid, // إضافة UUID للبيانات
      };

      await supabase.from('rent').insert(newRentData);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تم حفظ عقد الإيجار بنجاح!'), backgroundColor: Colors.green),
        );
        Navigator.pop(context, true); 
      }
    } catch (e) {
      debugPrint('Error saving rent contract: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('فشل حفظ العقد: ${e.toString()}'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: PreferredSize(
          preferredSize: const Size.fromHeight(kToolbarHeight),
          child: AppBar(title: const Text('Add New Rent Contract'), backgroundColor: const Color(0xFF42A5F5)),
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add New Rent Contract'),
        backgroundColor: const Color(0xFF42A5F5),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Property Dropdown
              const Text('Property:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              DropdownButtonFormField<int>(
                decoration: const InputDecoration(hintText: 'Select Property'),
                value: _selectedPropertyId,
                items: _properties.map((prop) => DropdownMenuItem(
                  value: prop.id,
                  child: Text(prop.name),
                )).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedPropertyId = value;
                    _onUnitSelected(null);
                  });
                },
                validator: (value) => value == null ? 'Please select a Property' : null,
              ),
              const SizedBox(height: 16),

              // Unit Dropdown
              const Text('Unit:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              DropdownButtonFormField<int>(
                decoration: const InputDecoration(hintText: 'Select Unit'),
                value: _selectedUnitId,
                items: _filteredUnits.map((unit) => DropdownMenuItem(
                  value: unit.id,
                  child: Text('Unit ${unit.unitNumber}'),
                )).toList(),
                onChanged: _onUnitSelected,
                hint: Text(_selectedPropertyId == null && _properties.isNotEmpty ? 'Select Property first' : 'Select Unit'),
                validator: (value) => value == null ? 'Please select a Unit' : null,
              ),
              const SizedBox(height: 16),

              // Customer Dropdown
              const Text('Customer:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              DropdownButtonFormField<int>(
                decoration: const InputDecoration(hintText: 'Select Customer'),
                value: _selectedCustomerId,
                items: _customers.map((customer) => DropdownMenuItem(
                  value: customer.id,
                  child: Text(customer.name),
                )).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedCustomerId = value;
                  });
                },
                validator: (value) => value == null ? 'Please select a Customer' : null,
              ),
              const SizedBox(height: 16),
              
              // Contract Dropdown (Placeholder)
              const Text('Contract (Optional):', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(hintText: 'Select Contract'),
                items: const [
                  DropdownMenuItem(value: 'Standard', child: Text('Standard Contract')),
                  DropdownMenuItem(value: 'LongTerm', child: Text('Long Term Contract')),
                ], 
                onChanged: (value) {},
              ),
              const SizedBox(height: 16),

              // Rent Amount
              const Text('Rent Amount:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              TextFormField(
                controller: _rentAmountController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(hintText: 'Enter Rent Amount (e.g., 1692.31)'),
                validator: (value) {
                  if (value == null || value.isEmpty) return 'Please enter rent amount';
                  if (double.tryParse(value) == null) return 'Invalid number format';
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Start Date
              const Text('Start Date:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              _buildDatePicker(context, 'mm/dd/yyyy', _startDate, (date) => setState(() => _startDate = date), 'Start Date is required'),
              const SizedBox(height: 16),

              // End Date
              const Text('End Date:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              _buildDatePicker(context, 'mm/dd/yyyy', _endDate, (date) => setState(() => _endDate = date), 'End Date is required'),
              const SizedBox(height: 30),

              Center(
                child: ElevatedButton(
                  onPressed: _saveRentContract,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1A237E),
                    padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 15),
                  ),
                  child: const Text('Save Rent Contract', style: TextStyle(color: Colors.white, fontSize: 18)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDatePicker(BuildContext context, String hint, DateTime? selectedDate, Function(DateTime?) onDateSelected, String validationMessage) {
    final displayDate = selectedDate == null ? hint : DateFormat('MM/dd/yyyy').format(selectedDate);
    
    return InkWell(
      onTap: () async {
        final date = await showDatePicker(
          context: context,
          initialDate: selectedDate ?? DateTime.now(),
          firstDate: DateTime(2000),
          lastDate: DateTime(2050),
        );
        onDateSelected(date);
        _formKey.currentState!.validate();
      },
      child: InputDecorator(
        decoration: InputDecoration(
          hintText: hint,
          errorText: selectedDate == null && _formKey.currentState?.validate() == false ? validationMessage : null,
          suffixIcon: const Icon(Icons.calendar_today, size: 20),
          border: const OutlineInputBorder(),
        ),
        child: Text(displayDate, style: TextStyle(color: selectedDate == null ? Colors.grey : Colors.black)),
      ),
    );
  }
}

// ==========================
// 3. شاشة تعديل عقد إيجار (EditRentScreen)
// (تم تعديل منطق الحفظ لإضافة UUID)
// ==========================

class EditRentScreen extends StatefulWidget {
  final RentItem item;
  const EditRentScreen({super.key, required this.item});

  @override
  State<EditRentScreen> createState() => _EditRentScreenState();
}

class _EditRentScreenState extends State<EditRentScreen> {
  final _formKey = GlobalKey<FormState>();

  late int? _selectedUnitId;
  late int? _selectedCustomerId;
  late DateTime? _startDate;
  late DateTime? _endDate;
  late final TextEditingController _rentAmountController;
  late String _paymentStatus;

  List<UnitModel> _units = [];
  List<CustomerModel> _customers = [];

  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _selectedUnitId = widget.item.unitId;
    _selectedCustomerId = widget.item.customerId;
    _startDate = widget.item.startDate;
    _endDate = widget.item.endDate;
    _rentAmountController = TextEditingController(text: widget.item.rentAmount.toStringAsFixed(2));
    _paymentStatus = widget.item.status.toLowerCase();
    
    _fetchDropdownData();
  }

  @override
  void dispose() {
    _rentAmountController.dispose();
    super.dispose();
  }

  Future<void> _fetchDropdownData() async {
    try {
      final unitsResponse = await supabase.from('uints').select('id, unit_number, prop_id, rent_amount');
      final customersResponse = await supabase.from('customers').select('id, name');

      setState(() {
        _units = (unitsResponse as List).map((e) => UnitModel.fromJson(e)).toList();
        _customers = (customersResponse as List).map((e) => CustomerModel.fromJson(e)).toList();
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error fetching dropdown data for Edit: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('فشل تحميل البيانات المطلوبة: $e'), backgroundColor: Colors.red),
        );
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _updateRentContract() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    
    if (_selectedUnitId == null || _selectedCustomerId == null || _startDate == null || _endDate == null) {
      if(mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('الرجاء اختيار الوحدة والعميل وتحديد التواريخ.'), backgroundColor: Colors.orange),
        );
      }
      return;
    }

    try {
      final updatedRentData = {
        'unit_id': _selectedUnitId,
        'customer_id': _selectedCustomerId,
        'start_date': _startDate!.toIso8601String().substring(0, 10), 
        'end_date': _endDate!.toIso8601String().substring(0, 10),
        'rent': double.tryParse(_rentAmountController.text),
        'payment_status': _paymentStatus,
        'uuid': widget.item.uuid, // إرسال UUID الحالي
      };

      await supabase
        .from('rent')
        .update(updatedRentData)
        .eq('id', widget.item.id);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تم تحديث عقد الإيجار بنجاح!'), backgroundColor: Colors.green),
        );
        Navigator.pop(context, true); 
      }
    } catch (e) {
      debugPrint('Error updating rent contract: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('فشل تحديث العقد: ${e.toString()}'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: PreferredSize(
          preferredSize: const Size.fromHeight(kToolbarHeight),
          child: AppBar(title: const Text('Edit Rent Contract'), backgroundColor: Colors.blueGrey),
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }
    
    return Scaffold(
      appBar: AppBar(
        title: Text('Edit Rent Contract (ID: ${widget.item.id})'),
        backgroundColor: Colors.blueGrey,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Unit Dropdown
              const Text('Unit:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              DropdownButtonFormField<int>(
                decoration: const InputDecoration(hintText: 'Select Unit'),
                value: _selectedUnitId,
                items: _units.map((unit) => DropdownMenuItem(
                  value: unit.id,
                  child: Text('Unit ${unit.unitNumber}'),
                )).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedUnitId = value;
                  });
                },
                validator: (value) => value == null ? 'Please select a Unit' : null,
              ),
              const SizedBox(height: 16),

              // Customer Dropdown
              const Text('Customer:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              DropdownButtonFormField<int>(
                decoration: const InputDecoration(hintText: 'Select Customer'),
                value: _selectedCustomerId,
                items: _customers.map((customer) => DropdownMenuItem(
                  value: customer.id,
                  child: Text(customer.name),
                )).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedCustomerId = value;
                  });
                },
                validator: (value) => value == null ? 'Please select a Customer' : null,
              ),
              const SizedBox(height: 16),

              // Rent Amount
              const Text('Rent Amount:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              TextFormField(
                controller: _rentAmountController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(hintText: 'Enter Rent Amount'),
                validator: (value) {
                  if (value == null || value.isEmpty) return 'Please enter rent amount';
                  if (double.tryParse(value) == null) return 'Invalid number format';
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Start Date
              const Text('Start Date:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              _buildDatePicker(context, 'mm/dd/yyyy', _startDate, (date) => setState(() => _startDate = date), 'Start Date is required'),
              const SizedBox(height: 16),

              // End Date
              const Text('End Date:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              _buildDatePicker(context, 'mm/dd/yyyy', _endDate, (date) => setState(() => _endDate = date), 'End Date is required'),
              const SizedBox(height: 16),

              // Payment Status
              const Text('Payment Status:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              DropdownButtonFormField<String>(
                value: _paymentStatus, 
                items: const [
                  DropdownMenuItem(value: 'paid', child: Text('Paid')),
                  DropdownMenuItem(value: 'unpaid', child: Text('Unpaid')),
                  DropdownMenuItem(value: 'pending', child: Text('Pending')),
                ],
                onChanged: (value) {
                  setState(() {
                    _paymentStatus = value!;
                  });
                },
                validator: (value) => value == null ? 'Please select a status' : null,
              ),

              const SizedBox(height: 30),

              Center(
                child: ElevatedButton(
                  onPressed: _updateRentContract, 
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1A237E),
                    padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 15),
                  ),
                  child: const Text('Save Changes', style: TextStyle(color: Colors.white, fontSize: 18)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDatePicker(BuildContext context, String hint, DateTime? selectedDate, Function(DateTime?) onDateSelected, String validationMessage) {
    final displayDate = selectedDate == null ? hint : DateFormat('MM/dd/yyyy').format(selectedDate);
    
    return InkWell(
      onTap: () async {
        final date = await showDatePicker(
          context: context,
          initialDate: selectedDate ?? DateTime.now(),
          firstDate: DateTime(2000),
          lastDate: DateTime(2050),
        );
        onDateSelected(date);
        _formKey.currentState!.validate();
      },
      child: InputDecorator(
        decoration: InputDecoration(
          hintText: hint,
          errorText: selectedDate == null && _formKey.currentState?.validate() == false ? validationMessage : null,
          suffixIcon: const Icon(Icons.calendar_today, size: 20),
          border: const OutlineInputBorder(),
        ),
        child: Text(displayDate, style: TextStyle(color: selectedDate == null ? Colors.grey : Colors.black)),
      ),
    );
  }
}

// ==========================
// 4. شاشة إدارة الإيجارات (RentManagementScreen)
// ==========================

class RentManagementScreen extends StatefulWidget {
  const RentManagementScreen({super.key});

  @override
  State<RentManagementScreen> createState() => _RentManagementScreenState();
}

class _RentManagementScreenState extends State<RentManagementScreen> {
  late Future<List<RentItem>> _rentItemsFuture;
  
  @override
  void initState() {
    super.initState();
    _rentItemsFuture = _fetchRentData();
  }

  Future<List<RentItem>> _fetchRentData() async {
    try {
      // الاستعلام يجلب كل الحقول '*' بما في ذلك uuid, unit_id, customer_id
      final response = await supabase
          .from('rent')
          .select('*, uints!inner(unit_number), customers!inner(name)') 
          .order('start_date', ascending: false);

      final List<RentItem> items = (response as List)
          .map((map) => RentItem.fromJson(map as Map<String, dynamic>))
          .toList();

      return items;
    } catch (e) {
      debugPrint('Error fetching rent data: $e');
      return Future.error('Error fetching rent data: $e');
    }
  }

  void _navigateToAddRent() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const AddRentScreen()),
    );
    if (result == true) {
      setState(() {
        _rentItemsFuture = _fetchRentData();
      });
    }
  }

  void _navigateToEditRent(RentItem item) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => EditRentScreen(item: item)),
    );
    if (result == true) {
      setState(() {
        _rentItemsFuture = _fetchRentData();
      });
    }
  }

  Future<void> _deleteRentItem(int id) async {
    try {
      await supabase.from('rent').delete().eq('id', id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('تم حذف سجل الإيجار بنجاح.'),
            backgroundColor: Colors.green,
          ),
        );
      }
      setState(() {
        _rentItemsFuture = _fetchRentData();
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('فشل حذف سجل الإيجار: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Widget _buildStatusChip(String status) {
    final statusLower = status.toLowerCase();
    Color color;
    Color textColor;

    if (statusLower == 'paid') {
      color = Colors.lightGreen.shade100;
      textColor = Colors.green.shade700;
    } else if (statusLower == 'unpaid' || statusLower == 'late' || statusLower == 'pending') {
      color = Colors.red.shade100;
      textColor = Colors.red.shade700;
    } else {
      color = Colors.grey.shade100;
      textColor = Colors.grey.shade700;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(5),
      ),
      child: Text(
        status.toUpperCase(),
        style: TextStyle(color: textColor, fontWeight: FontWeight.bold, fontSize: 12),
      ),
    );
  }

  Widget _buildOperationsButtons(RentItem item) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          icon: const Icon(Icons.edit, color: Colors.blueGrey, size: 20),
          onPressed: () => _navigateToEditRent(item),
        ),
        IconButton(
          icon: const Icon(Icons.delete, color: Colors.red, size: 20),
          onPressed: () => _deleteRentItem(item.id),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Rent Management Dashboard'),
        backgroundColor: const Color(0xFF1A237E),
        titleTextStyle: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                ElevatedButton.icon(
                  onPressed: _navigateToAddRent,
                  icon: const Icon(Icons.add, color: Colors.white),
                  label: const Text('Add Rent', style: TextStyle(color: Colors.white)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF42A5F5),
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: FutureBuilder<List<RentItem>>(
                future: _rentItemsFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                      child: Padding(
                        padding: EdgeInsets.all(50.0),
                        child: CircularProgressIndicator(),
                      ),
                    );
                  }

                  if (snapshot.hasError) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(50.0),
                        child: Text('Error loading data: ${snapshot.error}'),
                      ),
                    );
                  }

                  final items = snapshot.data ?? [];
                  if (items.isEmpty) {
                    return const Center(
                      child: Padding(
                        padding: EdgeInsets.all(50.0),
                        child: Text('No rent records found.'),
                      ),
                    );
                  }

                  return DataTable(
                    columnSpacing: 10,
                    horizontalMargin: 10,
                    dataRowMinHeight: 50,
                    dataRowMaxHeight: 50,
                    headingRowColor: MaterialStateProperty.resolveWith(
                        (states) => const Color(0xFF1A237E)),
                    columns: const [
                      DataColumn(label: Text('Unit Number', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white))),
                      DataColumn(label: Text('Customer Name', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white))),
                      DataColumn(label: Text('Rent', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white))),
                      DataColumn(label: Text('Start Date', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white))),
                      DataColumn(label: Text('End Date', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white))),
                      DataColumn(label: Text('Status', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white))),
                      DataColumn(label: Text('Operations', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white))),
                    ],
                    rows: items.map((item) {
                      return DataRow(cells: [
                        DataCell(Text(item.unitNumber, overflow: TextOverflow.ellipsis)),
                        DataCell(Text(item.customerName, overflow: TextOverflow.ellipsis)),
                        DataCell(Text(item.rentAmount.toStringAsFixed(2))),
                        DataCell(Text(DateFormat('dd/MM/yyyy').format(item.startDate))),
                        DataCell(Text(DateFormat('dd/MM/yyyy').format(item.endDate))),
                        DataCell(_buildStatusChip(item.status)),
                        DataCell(_buildOperationsButtons(item)),
                      ]);
                    }).toList(),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
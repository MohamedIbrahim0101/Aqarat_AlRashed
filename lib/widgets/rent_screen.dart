// lib/screens/rent_screen.dart
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// ------------------- Supabase Client -------------------
final supabase = Supabase.instance.client;

// ------------------- Unit Service -------------------
class UnitService {
  Future<List<Map<String, dynamic>>> fetchUnits() async {
    try {
      final response = await supabase.from('uints').select();
      return (response as List)
          .map((e) => Map<String, dynamic>.from(e))
          .toList();
    } catch (e) {
      print("Error fetching units: $e");
      return [];
    }
  }
}

// ------------------- Property Service -------------------
class PropertyService {
  Future<List<Map<String, dynamic>>> fetchProperties() async {
    try {
      final response = await supabase.from('properties').select();
      return (response as List)
          .map((e) => Map<String, dynamic>.from(e))
          .toList();
    } catch (e) {
      print("Error fetching properties: $e");
      return [];
    }
  }
}

// ------------------- Customer Service -------------------
class CustomerService {
  Future<List<Map<String, dynamic>>> fetchCustomers() async {
    try {
      final response = await supabase.from('customers').select();
      return (response as List)
          .map((e) => Map<String, dynamic>.from(e))
          .toList();
    } catch (e) {
      print("Error fetching customers: $e");
      return [];
    }
  }
}

// ------------------- Rent Service -------------------
class RentService {
  Future<List<Map<String, dynamic>>> fetchRents() async {
    try {
      final response = await supabase.from('rent').select();
      return (response as List)
          .map((e) => Map<String, dynamic>.from(e))
          .toList();
    } catch (e) {
      print("Error fetching rents: $e");
      return [];
    }
  }
}

// ------------------- Rent Screen -------------------
class RentScreen extends StatefulWidget {
  const RentScreen({super.key});

  @override
  State<RentScreen> createState() => _RentScreenState();
}

class _RentScreenState extends State<RentScreen> {
  bool _isLoading = true;
  String? _error;

  List<Map<String, dynamic>> _rents = [];
  List<Map<String, dynamic>> _units = [];
  List<Map<String, dynamic>> _customers = [];
  List<Map<String, dynamic>> _properties = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      _units = await UnitService().fetchUnits();
      _customers = await CustomerService().fetchCustomers();
      _properties = await PropertyService().fetchProperties();
      _rents = await RentService().fetchRents();

      // تعديل البيانات لإظهار الأعمدة المطلوبة
      _rents = _rents.map((rent) {
        final unit = _units.firstWhere(
          (u) => u['id'] == rent['unit_id'],
          orElse: () => <String, dynamic>{},
        );
        final property = _properties.firstWhere(
          (p) => p['id'] == unit?['prop_id'],
          orElse: () => <String, dynamic>{},
        );

        return {
          ...rent,
          'Unit Name': unit?['unit_number'] ?? 'N/A',
          'Property Name': property?['name'] ?? 'N/A',
          'Payment Status': rent['payment_status'] ?? 'غير محدد',
          'Paid Amount': (rent['payment_status'] == 'unpaid' || rent['payment_status'] == 'late')
              ? '0'
              : rent['rent']?.toString() ?? '0',
          'Rent Amount': rent['rent']?.toString() ?? '0',
          'Contract Total Amount': unit?['rent_amount']?.toString() ?? '0',
          'Rent Description': ('N/A'),
          'From': rent['start_date']?.toString()?? '0',
          'To': rent['end_date']?.toString()?? '0',
        };
      }).toList();

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (_error != null) {
      return Scaffold(body: Center(child: Text('Error: $_error')));
    }
    if (_rents.isEmpty) {
      return const Scaffold(body: Center(child: Text('No rent data found.')));
    }

    final visibleColumns = [
      'Number',
      'Unit Name',
      'Property Name',
      'From',
      'To',
      'Payment Status',
      'Paid Amount',
      'Rent Amount',
      'Contract Total Amount',
      'Rent Description',
    ];

    return Scaffold(
      appBar: AppBar(title: const Text('Rent Report')),
      body: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: ConstrainedBox(
          constraints: BoxConstraints(minWidth: visibleColumns.length * 180),
          child: SingleChildScrollView(
            scrollDirection: Axis.vertical,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Container(
                  color: Colors.blue.shade900,
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: visibleColumns.map((col) {
                      return ConstrainedBox(
                        constraints: const BoxConstraints(minWidth: 180),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          child: Text(
                            col,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
                // Rows
                ..._rents.asMap().entries.map((entry) {
                  final index = entry.key + 1;
                  final rent = entry.value;
                  return Container(
                    padding: const EdgeInsets.all(12),
                    decoration: const BoxDecoration(
                      border: Border(
                        bottom: BorderSide(color: Colors.grey, width: 0.5),
                      ),
                    ),
                    child: Row(
                      children: visibleColumns.map((col) {
                        String value = '';
                        if (col == 'Number') {
                          value = index.toString();
                        } else {
                          value = rent[col]?.toString() ?? '';
                        }
                        return ConstrainedBox(
                          constraints: const BoxConstraints(minWidth: 180),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 4),
                            child: Text(value, overflow: TextOverflow.ellipsis),
                          ),
                        );
                      }).toList(),
                    ),
                  );
                }).toList(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

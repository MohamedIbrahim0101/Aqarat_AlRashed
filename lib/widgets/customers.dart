import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// --- تأكد من أنك عملت init لـ Supabase قبل استخدامه ---
final supabase = Supabase.instance.client;

// =======================
// === Data Models =======
// =======================
class Customer {
  final int id;
  final String name;
  final String phone;
  final String nationality;

  Customer({
    required this.id,
    required this.name,
    required this.phone,
    required this.nationality,
  });
}

class CustomerRentInfo {
  final Customer customer;
  final double rentAmount;

  CustomerRentInfo({
    required this.customer,
    required this.rentAmount,
  });
}

// =======================
// === Data Fetching =====
// =======================
Future<List<CustomerRentInfo>> fetchCustomerRentList({String? search}) async {
  try {
    // جلب العملاء مع العقود والوحدات في طلب واحد
    final query = supabase.from('customers').select(
      '''
      id,
      name,
      phone,
      nationality,
      contract (
        unit_id (
          rent_amount
        )
      )
      '''
    );

    // لو فيه بحث نضيف فلتر
    if (search != null && search.isNotEmpty) {
      query.or(
        'name.ilike.%$search%,phone.ilike.%$search%,nationality.ilike.%$search%',
      );
    }

    final response = await query;

    if (response == null) return [];

    List<CustomerRentInfo> customerRentList = [];

    for (var c in response) {
      final customer = Customer(
        id: c['id'],
        name: c['name'] ?? '',
        phone: c['phone'] ?? '',
        nationality: c['nationality'] ?? '',
      );

      double totalRent = 0.0;

      if (c['contract'] != null) {
        for (var contract in c['contract']) {
          final unit = contract['unit_id'];
          if (unit != null && unit['rent_amount'] != null) {
            totalRent += (unit['rent_amount'] as num).toDouble();
          }
        }
      }

      customerRentList.add(CustomerRentInfo(
        customer: customer,
        rentAmount: totalRent,
      ));
    }

    return customerRentList;
  } catch (e) {
    debugPrint('Error fetching customer rent list: $e');
    return [];
  }
}

// =======================
// === UI Screen =========
// =======================
class CustomerListPage extends StatefulWidget {
  const CustomerListPage({super.key});

  @override
  State<CustomerListPage> createState() => _CustomerListPageState();
}

class _CustomerListPageState extends State<CustomerListPage> {
  Future<List<CustomerRentInfo>>? _customerRentData;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _loadData({String? search}) {
    setState(() {
      _customerRentData = fetchCustomerRentList(search: search);
    });
  }

  @override
  Widget build(BuildContext context) {
    const primaryColor = Color(0xFF3B82F6);
    const headerColor = Color(0xFF283593);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Customer/Rent Management'),
        backgroundColor: Colors.white,
        elevation: 1,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Search + Refresh Button
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    decoration: const InputDecoration(
                      hintText: 'Search by name, phone, or nationality...',
                      border: OutlineInputBorder(),
                      contentPadding:
                          EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    ),
                    onChanged: (value) {
                      _loadData(search: value);
                    },
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton.icon(
                  onPressed: () {
                    _searchController.clear();
                    _loadData();
                  },
                  icon: const Icon(Icons.refresh, size: 20),
                  label: const Text('Refresh'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(4)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Data Table
            Expanded(
              child: _customerRentData == null
                  ? const Center(child: CircularProgressIndicator())
                  : FutureBuilder<List<CustomerRentInfo>>(
                      future: _customerRentData,
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const Center(
                              child: CircularProgressIndicator());
                        } else if (snapshot.hasError) {
                          return Center(
                              child: Text(
                                  'Error fetching data: ${snapshot.error}'));
                        } else if (!snapshot.hasData ||
                            snapshot.data!.isEmpty) {
                          return const Center(child: Text('No data available'));
                        }

                        final data = snapshot.data!;

                        return SingleChildScrollView(
                          scrollDirection: Axis.vertical,
                          child: DataTable(
                            columnSpacing: 24,
                            showCheckboxColumn: false,
                            headingRowColor:
                                MaterialStateProperty.all(headerColor),
                            headingTextStyle: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                            columns: const [
                              DataColumn(label: Text('Name')),
                              DataColumn(label: Text('Phone')),
                              DataColumn(label: Text('Nationality')),
                              DataColumn(
                                  label: Text('Rent Amount'), numeric: true),
                            ],
                            rows: data.map((item) {
                              return DataRow(
                                cells: [
                                  DataCell(Text(item.customer.name)),
                                  DataCell(Text(item.customer.phone)),
                                  DataCell(Text(item.customer.nationality)),
                                  DataCell(
                                      Text(item.rentAmount.toStringAsFixed(2))),
                                ],
                              );
                            }).toList(),
                          ),
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

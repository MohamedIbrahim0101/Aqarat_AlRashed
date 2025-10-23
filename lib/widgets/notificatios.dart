import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// تأكد من init Supabase قبل الاستخدام
final supabase = Supabase.instance.client;

// =======================
// === Data Model =======
// =======================
class ContractItem {
  final int id;
  final int customerId;
  final int unitId;
  final DateTime startDate;
  final DateTime endDate;
  final double annulRent;
  final String customerName;
  final String unitNumber;
  final String propertyName;

  ContractItem({
    required this.id,
    required this.customerId,
    required this.unitId,
    required this.startDate,
    required this.endDate,
    required this.annulRent,
    required this.customerName,
    required this.unitNumber,
    required this.propertyName,
  });

  factory ContractItem.fromMap(Map<String, dynamic> map) {
    // التعامل مع customers
    dynamic customersData = map['customers'];
    List<dynamic> customersList =
        (customersData is Map) ? [customersData] : (customersData as List<dynamic>? ?? []);
    final customer = (customersList.isNotEmpty) ? customersList[0] as Map<String, dynamic> : null;

    // التعامل مع uints
    dynamic uintsData = map['uints'];
    List<dynamic> uintsList =
        (uintsData is Map) ? [uintsData] : (uintsData as List<dynamic>? ?? []);
    final unit = (uintsList.isNotEmpty) ? uintsList[0] as Map<String, dynamic> : null;

    // التعامل مع property داخل unit
    String propertyName = '';
    if (unit != null && unit['properties'] != null) {
      final prop = unit['properties'];
      if (prop is Map) propertyName = prop['name']?.toString() ?? '';
      else if (prop is List && prop.isNotEmpty) propertyName = prop[0]['name']?.toString() ?? '';
    }

    return ContractItem(
      id: map['id'] is int ? map['id'] : int.tryParse(map['id'].toString()) ?? 0,
      customerId: map['customer_id'] is int
          ? map['customer_id']
          : int.tryParse(map['customer_id']?.toString() ?? '0') ?? 0,
      unitId: map['unit_id'] is int
          ? map['unit_id']
          : int.tryParse(map['unit_id']?.toString() ?? '0') ?? 0,
      startDate: DateTime.parse(map['start_date'].toString()),
      endDate: DateTime.parse(map['end_date'].toString()),
      annulRent: (map['annul_rent'] ?? 0).toDouble(),
      customerName: customer?['name']?.toString() ?? 'غير محدد',
      unitNumber: unit?['unit_number']?.toString() ?? 'N/A',
      propertyName: propertyName,
    );
  }
}

// =======================
// === Contracts Page =======
// =======================
class ContractsNotificationPage extends StatefulWidget {
  const ContractsNotificationPage({super.key});

  @override
  State<ContractsNotificationPage> createState() =>
      _ContractsNotificationPageState();
}

class _ContractsNotificationPageState extends State<ContractsNotificationPage> {
  List<ContractItem> contracts = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadContracts();
    _subscribeRealtime();
  }

  // =======================
  // جلب العقود اللي قربت تنتهي (خلال 30 يوم)
  Future<void> _loadContracts() async {
    setState(() => isLoading = true);
    try {
      final now = DateTime.now();
      final thirtyDaysLater = now.add(const Duration(days: 30));
      final String todayStr = now.toIso8601String().split('T')[0];
      final String futureStr = thirtyDaysLater.toIso8601String().split('T')[0];

      final data = await supabase
          .from('contract')
          .select('*, customers!inner(id,name), uints!inner(id,unit_number,properties!left(name))')
          .lt('end_date', futureStr)
          .gt('end_date', todayStr)
          .order('end_date', ascending: true);

      final list = (data as List)
          .map((e) => ContractItem.fromMap(e as Map<String, dynamic>))
          .toList();

      setState(() {
        contracts = list;
      });
    } catch (e) {
      debugPrint('Error loading contracts: $e');
    } finally {
      setState(() => isLoading = false);
    }
  }

  // =======================
  // الاشتراك في التحديثات الفورية
  void _subscribeRealtime() {
    supabase
        .from('contract')
        .stream(primaryKey: ['id'])
        .listen((List<Map<String, dynamic>> newData) {
      final now = DateTime.now();
      final thirtyDaysLater = now.add(const Duration(days: 30));

      final filtered = newData.where((map) {
        final endDate = DateTime.parse(map['end_date']);
        return endDate.isAfter(now) && endDate.isBefore(thirtyDaysLater);
      }).toList();

      final list = filtered.map((e) => ContractItem.fromMap(e)).toList();

      setState(() {
        contracts = list;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Contracts Expiring Soon'),
        actions: [
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Center(
              child: Text(
                '${contracts.length}',
                style: const TextStyle(
                    fontWeight: FontWeight.bold, color: Colors.white),
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadContracts,
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : contracts.isEmpty
              ? const Center(child: Text('No contracts expiring soon'))
              : ListView.builder(
                  itemCount: contracts.length,
                  itemBuilder: (context, index) {
                    final c = contracts[index];
                    return Card(
                      color: Colors.orange[50],
                      margin: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      child: ListTile(
                        title: Text('Unit ${c.unitNumber}'),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Customer: ${c.customerName}'),
                            Text('Property: ${c.propertyName}'),
                            Text(
                                'End Date: ${c.endDate.toLocal().toIso8601String().split("T")[0]}'),
                            Text('Annual Rent: ${c.annulRent}'),
                          ],
                        ),
                        trailing: IconButton(
                          icon: const Icon(Icons.check_circle_outline),
                          onPressed: () {
                            // إمكانية تعليم العقد كمقروء أو متابعة
                          },
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}

import 'dart:ui' as fw show TextDirection;
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:my_app/widgets/customer_details.dart';
import 'package:my_app/widgets/info_screen.dart' show UnitInfoScreen;
import 'package:supabase_flutter/supabase_flutter.dart';

// ----------------------------------------------------------------------
// 1. Data model
// ----------------------------------------------------------------------
class PaymentRecord {
  final int id;
  final int customerId;
  final int unitId;
  final String paymentType;
  final String customerName;
  final String ownerName;
  final String propertyName;
  final String unitNumber;
  final double paymentAmount;
  final DateTime date;

  PaymentRecord({
    required this.id,
    required this.customerId,
    required this.unitId,
    required this.paymentType,
    required this.customerName,
    required this.ownerName,
    required this.propertyName,
    required this.unitNumber,
    required this.paymentAmount,
    required this.date,
  });

  factory PaymentRecord.fromJson(Map<String, dynamic> json) {
    try {
      final customer = json['customers'] ?? {};
      final unit = json['uints'] ?? {};
      final property = unit['properties'] ?? {};
      final owner = property['owners'] ?? {};

      return PaymentRecord(
        id: json['id'] ?? 0,
        customerId: customer['id'] ?? 0,
        unitId: unit['id'] ?? 0,
        paymentType: (json['payment_type'] ?? 'Unknown').toString(),
        customerName: (customer['name'] ?? '').toString(),
        ownerName: (owner['name'] ?? '').toString(),
        propertyName: (property['name'] ?? '').toString(),
        unitNumber: (unit['unit_number'] ?? '').toString(),
        paymentAmount:
            double.tryParse(unit['rent_amount']?.toString() ?? '0') ?? 0,
        date:
            DateTime.tryParse(json['date']?.toString() ?? '') ?? DateTime.now(),
      );
    } catch (e) {
      return PaymentRecord(
        id: 0,
        customerId: 0,
        unitId: 0,
        paymentType: 'Unknown',
        customerName: '',
        ownerName: '',
        propertyName: '',
        unitNumber: '',
        paymentAmount: 0,
        date: DateTime.now(),
      );
    }
  }
}

// ----------------------------------------------------------------------
// 2. Supabase setup
// ----------------------------------------------------------------------
const String supabaseUrl =
    '[https://yvdaupqwzxaoqygkxlii.supabase.co](https://yvdaupqwzxaoqygkxlii.supabase.co)';
const String supabaseAnonKey =
    'YOUR_ANON_KEY_HERE'; // Replace with your own key

// ----------------------------------------------------------------------
// 3. Main function
// ----------------------------------------------------------------------
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Supabase.initialize(url: supabaseUrl, anonKey: supabaseAnonKey);
  Intl.defaultLocale = 'en';
  runApp(const PaymentHistoryApp());
}

// ----------------------------------------------------------------------
// 4. Main app
// ----------------------------------------------------------------------
class PaymentHistoryApp extends StatelessWidget {
  const PaymentHistoryApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Payment History',
      builder: (context, child) =>
          Directionality(textDirection: fw.TextDirection.rtl, child: child!),
      theme: ThemeData(primarySwatch: Colors.blue, fontFamily: 'Roboto'),
      home: const PaymentHistoryScreen(),
    );
  }
}

// ----------------------------------------------------------------------
// 5. Payment history screen with working filter
// ----------------------------------------------------------------------
class PaymentHistoryScreen extends StatefulWidget {
  const PaymentHistoryScreen({super.key});

  @override
  State<PaymentHistoryScreen> createState() => _PaymentHistoryScreenState();
}

class _PaymentHistoryScreenState extends State<PaymentHistoryScreen> {
  String selectedYear = DateTime.now().year.toString();
  String selectedMonth = DateFormat('MMMM').format(DateTime.now());
  late Future<List<PaymentRecord>> _futurePayments;

  @override
  void initState() {
    super.initState();
    _futurePayments = fetchPayments();
  }

  Future<List<PaymentRecord>> fetchPayments() async {
    try {
      final data = await Supabase.instance.client
          .from('payments')
          .select('''
id,
payment_type,
date,
customers!inner(id,name),
uints!inner(
id,
unit_number,
rent_amount,
properties!inner(id,name, owners!inner(id,name))
)
''')
          .order('date', ascending: false);

      final List<dynamic> listData = data as List<dynamic>;
      return listData.map((json) => PaymentRecord.fromJson(json)).toList();
    } catch (e) {
      return [];
    }
  }

  void _applyFilter(String year, String month) {
    setState(() {
      selectedYear = year;
      selectedMonth = month;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Payment History',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF333333),
                ),
              ),
              const SizedBox(height: 10),
              Container(width: 150, height: 2, color: Colors.orange.shade600),
              const SizedBox(height: 16),

              FilterAndExportRow(
                selectedYear: selectedYear,
                selectedMonth: selectedMonth,
                onFilterChanged: _applyFilter,
              ),
              const SizedBox(height: 16),

              Expanded(
                child: FutureBuilder<List<PaymentRecord>>(
                  future: _futurePayments,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    } else if (snapshot.hasError) {
                      return Center(
                        child: Text('Error fetching data: ${snapshot.error}'),
                      );
                    } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                      return const Center(child: Text('No data to display'));
                    } else {
                      final filtered = snapshot.data!.where((p) {
                        final date = p.date;
                        final matchesYear =
                            date.year.toString() == selectedYear;
                        final matchesMonth =
                            DateFormat('MMMM').format(date) == selectedMonth;
                        return matchesYear && matchesMonth;
                      }).toList();

                      if (filtered.isEmpty) {
                        return const Center(
                          child: Text('No data for this period'),
                        );
                      }

                      return PaymentDataTable(payments: filtered);
                    }
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ----------------------------------------------------------------------
// 6. Filter row with callback
// ----------------------------------------------------------------------
class FilterAndExportRow extends StatefulWidget {
  final String selectedYear;
  final String selectedMonth;
  final Function(String, String) onFilterChanged;

  const FilterAndExportRow({
    super.key,
    required this.selectedYear,
    required this.selectedMonth,
    required this.onFilterChanged,
  });

  @override
  State<FilterAndExportRow> createState() => _FilterAndExportRowState();
}

class _FilterAndExportRowState extends State<FilterAndExportRow> {
  late String year;
  late String month;

  final List<String> years = ['2025', '2024', '2023'];
  final List<String> months = [
    'January',
    'February',
    'March',
    'April',
    'May',
    'June',
    'July',
    'August',
    'September',
    'October',
    'November',
    'December',
  ];

  @override
  void initState() {
    super.initState();
    year = widget.selectedYear;
    month = widget.selectedMonth;
  }

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 17,
      runSpacing: 17,
      children: [
        _buildDropdown(year, years, (v) {
          setState(() => year = v!);
          widget.onFilterChanged(year, month);
        }),
        _buildDropdown(month, months, (v) {
          setState(() => month = v!);
          widget.onFilterChanged(year, month);
        }),
        ElevatedButton(
          onPressed: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Simulated CSV export')),
            );
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF3B82F6),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          child: const Text(
            'Export to CSV',
            style: TextStyle(fontWeight: FontWeight.w500),
          ),
        ),
      ],
    );
  }

  Widget _buildDropdown(
  String value,
  List<String> items,
  ValueChanged<String?> onChanged,
) {
  return Flexible( // ✅ استخدم Flexible بدلاً من SizedBox
    child: DropdownButtonFormField<String>(
      value: value,
      decoration: InputDecoration(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 4,
        ),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        filled: true,
        fillColor: Colors.white,
      ),
      icon: const Icon(Icons.keyboard_arrow_down, color: Colors.grey),
      onChanged: onChanged,
      items: items
          .map(
            (e) => DropdownMenuItem(
              value: e,
              child: Text(
                e,
                textAlign: TextAlign.right,
                overflow: TextOverflow.ellipsis, // ✅ يمنع النص الطويل من كسر التصميم
              ),
            ),
          )
          .toList(),
    ),
  );
}

}

// ----------------------------------------------------------------------
// 7. Payment Data Table (unchanged design)
// ----------------------------------------------------------------------
class PaymentDataTable extends StatelessWidget {
  final List<PaymentRecord> payments;
  const PaymentDataTable({super.key, required this.payments});

  @override
  Widget build(BuildContext context) {
    return Scrollbar(
      thumbVisibility: true,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: ConstrainedBox(
          constraints: BoxConstraints(
            minWidth: MediaQuery.of(context).size.width,
          ),
          child: Scrollbar(
            thumbVisibility: true,
            child: SingleChildScrollView(
              scrollDirection: Axis.vertical,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.1),
                      spreadRadius: 1,
                      blurRadius: 5,
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    _buildHeaderRow(),
                    ...payments.map((r) => _buildDataRow(r, context)).toList(),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderRow() {
    const headerStyle = TextStyle(
      color: Colors.white,
      fontWeight: FontWeight.bold,
      fontSize: 14,
    );
    const headers = [
      'ID',
      'Payment Type',
      'Customer',
      'Owner',
      'Property',
      'Unit',
      'Amount',
      'Date',
    ];
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: const BoxDecoration(
        color: Color(0xFF1E3A8A),
        borderRadius: BorderRadius.only(
          topRight: Radius.circular(8),
          topLeft: Radius.circular(8),
        ),
      ),
      child: Row(
        children: headers.map((title) {
          double width = (title == 'ID')
              ? 60
              : ((title == 'Amount' || title == 'Date') ? 120 : 180);
          return Container(
            width: width,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(title, style: headerStyle, textAlign: TextAlign.right),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildDataRow(PaymentRecord r, BuildContext context) {
    final formattedAmount = r.paymentAmount.toStringAsFixed(2);
    final formattedDate = DateFormat('yyyy-MM-dd').format(r.date);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
      ),
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Row(
        children: [
          _buildCell(Text(r.id.toString()), 60),
          _buildCell(
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: r.paymentType == 'Rent'
                    ? const Color(0xFFDBEAFE)
                    : const Color(0xFFFEE2E2),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                r.paymentType,
                style: TextStyle(
                  color: r.paymentType == 'Rent'
                      ? const Color(0xFF2563EB)
                      : const Color(0xFFDC2626),
                  fontSize: 13,
                ),
              ),
            ),
            180,
            alignment: Alignment.centerRight,
          ),
          _buildCell(
            InkWell(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) =>
                        CustomerDetailsPage(customerId: r.customerId),
                  ),
                );
              },
              child: Text(
                r.customerName,
                style: const TextStyle(
                  color: Colors.blue,
                  decoration: TextDecoration.underline,
                ),
              ),
            ),
            180,
          ),
          _buildCell(Text(r.ownerName), 180),
          _buildCell(Text(r.propertyName), 180),
          _buildCell(
            InkWell(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => UnitInfoScreen(unitId: r.unitId),
                  ),
                );
              },
              child: Text(
                r.unitNumber,
                style: const TextStyle(
                  color: Color(0xFF3B82F6),
                  decoration: TextDecoration.underline,
                ),
              ),
            ),
            180,
          ),
          _buildCell(
            Text(
              formattedAmount,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
            120,
          ),
          _buildCell(Text(formattedDate), 120),
        ],
      ),
    );
  }

  Widget _buildCell(
    Widget child,
    double width, {
    Alignment alignment = Alignment.centerRight,
  }) {
    return Container(
      width: width,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      alignment: alignment,
      child: child,
    );
  }
}

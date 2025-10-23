import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// **ملاحظة:** تم افتراض وجود هذه الصفحة لضمان عمل الكود. يجب أن تكون في ملف 'package:my_app/widgets/customer_details.dart'
class CustomerDetailsPage extends StatelessWidget {
final int customerId;
const CustomerDetailsPage({super.key, required this.customerId});

@override
Widget build(BuildContext context) {
return Scaffold(
appBar: AppBar(title: Text('Customer Details for ID: $customerId')),
body: Center(child: Text('Displaying details for Customer ID: $customerId')),
);
}
}

// --- START: Supabase Configuration ---

const String SUPABASE_URL = 'https://yvdaupqwzxaoqygkxlii.supabase.co';
const String SUPABASE_ANON_KEY =
'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Inl2ZGF1cHF3enhhb3F5Z2t4bGlpIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc0NjI1NTE0MCwiZXhwIjoyMDYxODMxMTQwfQ.DnOlJSlggeD7DLqW-2SMN4svISCjzUbJFax17grxq3A';

// --- END: Supabase Configuration ---

// --- START: Supabase Data Structures ---

class ContractReportItem {
final int id;
final int? customerId;
final String? propertyName;
final String? unitNumber;
final String? customerName;
final DateTime? startDate;
final DateTime? endDate;
final double? rentAmount;
final double? annulRent;
final String? nationality;
final String? phone;
final String? contractType;
final String? contractDescription;

ContractReportItem({
required this.id,
this.customerId,
this.unitNumber,
this.propertyName,
this.customerName,
this.startDate,
this.endDate,
this.rentAmount,
this.annulRent,
this.nationality,
this.phone,
this.contractType,
this.contractDescription,
});

factory ContractReportItem.fromSupabase(Map<String, dynamic> data) {
final contract = data;
final units = data['uints'] as Map<String, dynamic>?;
final properties = units?['properties'] as Map<String, dynamic>?;
final customer = data['customers'] as Map<String, dynamic>?;

return ContractReportItem(
  id: contract['id'] as int,
  customerId: customer?['id'] as int?,
  unitNumber: units?['unit_number']?.toString(),
  propertyName: properties?['name']?.toString(),
  customerName: customer?['name']?.toString(),
  startDate: contract['start_date'] != null
      ? DateTime.tryParse(contract['start_date'])
      : null,
  endDate: contract['end_date'] != null
      ? DateTime.tryParse(contract['end_date'])
      : null,
  rentAmount: (units?['rent_amount'] as num?)?.toDouble(),
  annulRent: (contract['annul_rent'] as num?)?.toDouble(),
  nationality: customer?['nationality']?.toString(),
  phone: customer?['phone']?.toString(),
  contractType: contract['contract_type']?.toString(),
  contractDescription: contract['description']?.toString(),
);

}
}

// --- END: Supabase Data Structures ---

class SupabaseService {
final SupabaseClient db;
SupabaseService(this.db);

Future<List<ContractReportItem>> fetchContractsReportData() async {
try {
final response = await db.from('contract').select('''
id,
start_date,
end_date,
annul_rent,
contract_type,
description,
customers!left(id, name, nationality, phone),
uints!left(id, unit_number, rent_amount, properties!left(id, name))
''');

  if (response is List) {
    return response
        .map((item) => ContractReportItem.fromSupabase(item))
        .toList();
  }
  return [];
} catch (e) {
  print("Error fetching contracts report data: $e");
  throw 'فشل في تحميل بيانات العقود: تأكد من صحة المفاتيح ووجود الأعمدة في قاعدة البيانات.';
}

}
}

// --- START: Flutter UI Implementation ---

class ContractsReportPage extends StatefulWidget {
const ContractsReportPage({super.key});

@override
State<ContractsReportPage> createState() => _ContractsReportPageState();
}

class _ContractsReportPageState extends State<ContractsReportPage> {
late SupabaseService _supabaseService;
late Future<List<ContractReportItem>> _contractsFuture;

List<ContractReportItem> _allContracts = [];
List<ContractReportItem> _filteredContracts = [];
String _selectedYear = 'All Years';
String _selectedMonth = 'All Months';

final List<String> _years = [
'All Years',
'2025',
'2024',
'2023',
'2022',
'2021',
'2020'
];
final List<String> _months = [
'All Months',
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
'December'
];

final List<String> _selectedColumns = [
'num',
'Property Name',
'Unit Name',
'Customer Name',
'Nationality',
'Phone',
'Contract Type',
'Total Contract',
'Rent Amount',
'Start Contract Date',
'End Contract Date',
'Contract Description'
];

@override
void initState() {
super.initState();
final supabase = SupabaseClient(SUPABASE_URL, SUPABASE_ANON_KEY);
_supabaseService = SupabaseService(supabase);

_contractsFuture = _supabaseService.fetchContractsReportData().then((contracts) {
  _allContracts = contracts;
  _filterContracts();
  return contracts;
});

}

void _filterContracts() {
setState(() {
_filteredContracts = _allContracts.where((contract) {
final startDate = contract.startDate;
if (startDate == null) return false;

    final yearFilter = _selectedYear == 'All Years' ||
        startDate.year.toString() == _selectedYear;

    final monthFilter = _selectedMonth == 'All Months' ||
        DateFormat('MMMM').format(startDate) == _selectedMonth;

    return yearFilter && monthFilter;
  }).toList();
});

}

List<String> get _tableHeaders =>
_selectedColumns.where((col) => col != 'num').toList();

Widget _buildDropdown({
required String value,
required List<String> items,
required String hint,
required ValueChanged<String?> onChanged,
}) {
return Container(
padding: const EdgeInsets.symmetric(horizontal: 10.0),
decoration: BoxDecoration(
border: Border.all(color: Colors.grey.shade300),
borderRadius: BorderRadius.circular(4.0),
),
child: DropdownButtonHideUnderline(
child: DropdownButton<String>(
value: value,
hint: Text(hint),
items: items.map((String item) {
return DropdownMenuItem<String>(
value: item,
child: Text(item),
);
}).toList(),
onChanged: onChanged,
),
),
);
}

Widget _buildActionButton({required String text, required Color color}) {
return ElevatedButton(
onPressed: () {
ScaffoldMessenger.of(context)
.showSnackBar(SnackBar(content: Text('تم تنفيذ الإجراء: $text')));
},
style: ElevatedButton.styleFrom(
backgroundColor: color,
foregroundColor: Colors.white,
padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
textStyle: const TextStyle(fontSize: 14),
),
child: Text(text),
);
}

Widget _buildControls() {
return Column(
crossAxisAlignment: CrossAxisAlignment.start,
children: [
Row(
children: [
_buildDropdown(
value: _selectedYear,
items: _years,
hint: 'Select Year',
onChanged: (String? newValue) {
setState(() {
_selectedYear = newValue!;
_filterContracts();
});
},
),
const SizedBox(width: 8),
_buildDropdown(
value: _selectedMonth,
items: _months,
hint: 'Select Month',
onChanged: (String? newValue) {
setState(() {
_selectedMonth = newValue!;
_filterContracts();
});
},
),
],
),
const SizedBox(height: 16),
Wrap(
spacing: 8.0,
runSpacing: 8.0,
children: [
_buildActionButton(text: 'Export Selected', color: Colors.blue),
_buildActionButton(text: 'Export This Year', color: Colors.blue),
_buildActionButton(text: 'Export All', color: Colors.blue),
_buildActionButton(text: 'Print Selected', color: Colors.green),
_buildActionButton(text: 'Print This Year', color: Colors.green),
_buildActionButton(text: 'Print All', color: Colors.green),
],
),
const SizedBox(height: 16),
],
);
}

Widget _buildTable(List<ContractReportItem> contracts) {
return SingleChildScrollView(
scrollDirection: Axis.horizontal,
child: DataTable(
headingRowColor:
MaterialStateProperty.resolveWith((states) => Colors.blue.shade900),
headingTextStyle:
const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
dataRowMinHeight: 40,
dataRowMaxHeight: 60,
columns: [
const DataColumn(label: Text('num')),
..._tableHeaders.map((header) => DataColumn(label: Text(header))),
],
rows: contracts.asMap().entries.map((entry) {
final index = entry.key;
final contract = entry.value;

      String formatDate(DateTime? date) =>
          date != null ? DateFormat('yyyy-MM-dd').format(date) : 'N/A';
      String formatCurrency(double? amount) =>
          amount != null ? '\$${amount.toStringAsFixed(2)}' : 'N/A';
      String formatString(String? text) => text ?? 'N/A';

      return DataRow(
        cells: [
          DataCell(Text((index + 1).toString())),
          DataCell(Text(formatString(contract.propertyName))),
          DataCell(Text(formatString(contract.unitNumber))),
          DataCell(
            InkWell(
              onTap: () {
                if (contract.customerId != null) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => CustomerDetailsPage(
                        customerId: contract.customerId!,
                      ),
                    ),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content:
                            Text('لا يمكن عرض التفاصيل. معرف العميل غير موجود.')),
                  );
                }
              },
              child: Text(
                formatString(contract.customerName),
                style: const TextStyle(
                  color: Colors.blue,
                  decoration: TextDecoration.underline,
                ),
              ),
            ),
          ),
          DataCell(Text(formatString(contract.nationality))),
          DataCell(Text(formatString(contract.phone))),
          DataCell(Text(formatString(contract.contractType))),
          DataCell(Text(formatCurrency(contract.annulRent))),
          DataCell(Text(formatCurrency(contract.rentAmount))),
          DataCell(Text(formatDate(contract.startDate))),
          DataCell(Text(formatDate(contract.endDate))),
          DataCell(Text(formatString(contract.contractDescription))),
        ],
      );
    }).toList(),
  ),
);

}

@override
Widget build(BuildContext context) {
return Scaffold(
appBar: AppBar(
title: const Text('Contracts Report'),
backgroundColor: Colors.blue.shade900,
foregroundColor: Colors.white,
),
body: SingleChildScrollView(
padding: const EdgeInsets.all(24.0),
child: Column(
crossAxisAlignment: CrossAxisAlignment.start,
children: [
const Text(
'Properties Report',
style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
),
const Divider(),
_buildControls(),
const SizedBox(height: 24),
FutureBuilder<List<ContractReportItem>>(
future: _contractsFuture,
builder: (context, snapshot) {
if (snapshot.connectionState == ConnectionState.waiting) {
return const Center(
child: Text("جاري تحميل البيانات...",
style: TextStyle(color: Colors.grey)));
} else if (snapshot.hasError) {
return Center(
child: Padding(
padding: const EdgeInsets.all(16.0),
child: Text(
"خطأ في جلب البيانات: ${snapshot.error}",
textAlign: TextAlign.center,
style: TextStyle(
color: Colors.red.shade700,
fontWeight: FontWeight.bold),
),
),
);
} else if (!snapshot.hasData) {
return const Center(
child: Text("لا توجد بيانات متاحة لعرضها.",
style: TextStyle(color: Colors.grey)));
}

            if (_filteredContracts.isEmpty && snapshot.data!.isNotEmpty) {
              return const Center(
                  child: Text("لا توجد نتائج مطابقة لمعايير الفلترة المحددة.",
                      style: TextStyle(color: Colors.orange)));
            }

            return _buildTable(_filteredContracts);
          },
        ),
      ],
    ),
  ),
);

}
}

// unit_info_screen.dart

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart' as intl;

// 🛑 Required packages (ensure they are added in pubspec.yaml)
import 'package:csv/csv.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'dart:async';

// -----------------------------------------------------------------------------
// 0. Constants and Colors
// -----------------------------------------------------------------------------
const Color primaryDarkBlue = Color(0xFF142B49);
const Color backgroundColor = Color(0xFFF7F7F7);

// -----------------------------------------------------------------------------
// 1. Data Models
// -----------------------------------------------------------------------------

class UnitDetails {
  final UnitData unit;
  final PropertyData property;
  final ContractData? contract;
  final List<RentHistory> rents;
  final List<PaymentHistory> payments;

  UnitDetails({
    required this.unit,
    required this.property,
    this.contract,
    required this.rents,
    required this.payments,
  });
}

class UnitData {
  final int id;
  final String unitNumber;
  final double rentAmount;
  final String createdAt;

  UnitData({
    required this.id,
    required this.unitNumber,
    required this.rentAmount,
    required this.createdAt,
  });

  factory UnitData.fromJson(Map<String, dynamic> json) {
    return UnitData(
      id: json['id'] as int,
      unitNumber: (json['unit_number'] ?? '').toString(),
      rentAmount: _parseNumber(json['rent_amount']),
      createdAt: (json['created_at'] ?? '').toString(),
    );
  }
}

class PropertyData {
  final int id;
  final String name;
  final String address;
  final String ownerName;

  PropertyData({
    required this.id,
    required this.name,
    required this.address,
    required this.ownerName,
  });

  // ✅ التعديل الأول: تصحيح قراءة اسم المالك من الكائن المتداخل 'owners'
  factory PropertyData.fromJson(Map<String, dynamic> json) {
    // 1. الوصول إلى كائن 'owners' الناتج عن عملية الـ JOIN في Supabase
    final dynamic ownerData = json['owners'];

    // 2. التحقق من وجود الكائن وقراءة حقل 'name' بداخله
    final String ownerNameValue =
        (ownerData is Map<String, dynamic> && ownerData['name'] != null)
        ? ownerData['name'].toString()
        : 'Owner Not Found (Check DB Join)';

    return PropertyData(
      id: json['id'] as int,
      name: (json['name'] ?? '').toString(),
      address: (json['address'] ?? '').toString(),
      // 3. استخدام اسم المالك المصحح
      ownerName: ownerNameValue,
    );
  }
}

class ContractData {
  final int id;
  final String customerName;
  final String startDate;
  final String endDate;
  final double annualRent;
  final String description;

  ContractData({
    required this.id,
    required this.customerName,
    required this.startDate,
    required this.endDate,
    required this.annualRent,
    required this.description,
  });

  // Helper function for CSV
  List<String> toCsvList() => [
    id.toString(),
    customerName,
    startDate,
    endDate,
    annualRent.toStringAsFixed(2),
    description,
  ];
}

class RentHistory {
  final int num;
  final String customerName;
  final String startDate;
  final String endDate;
  final double rent;
  final String rentStatus; // Will be 'Paid' or 'Unpaid'
  final String paymentDate;
  final String notes;

  RentHistory({
    required this.num,
    required this.customerName,
    required this.startDate,
    required this.endDate,
    required this.rent,
    required this.rentStatus,
    required this.paymentDate,
    required this.notes,
  });

  // Helper function for CSV
  List<String> toCsvList() => [
    num.toString(),
    customerName,
    startDate,
    endDate,
    rent.toStringAsFixed(2),
    rentStatus,
    paymentDate,
    notes,
  ];
}

class PaymentHistory {
  final int num;
  final String customerName;
  final String date;
  final double amount;
  final String paymentType;
  final String description;

  PaymentHistory({
    required this.num,
    required this.customerName,
    required this.date,
    required this.amount,
    required this.paymentType,
    required this.description,
  });

  // Helper function for CSV
  List<String> toCsvList() => [
    num.toString(),
    customerName,
    date,
    amount.toStringAsFixed(2),
    paymentType,
    description,
  ];
}

// Helper function to handle number conversion which may come as text or number
double _parseNumber(dynamic value) {
  if (value == null) return 0.0;
  if (value is num) return value.toDouble();
  if (value is String) return double.tryParse(value) ?? 0.0;
  return 0.0;
}

// -----------------------------------------------------------------------------
// 2. Supabase Data Fetching Service
// -----------------------------------------------------------------------------

class UnitDetailsService {
  final SupabaseClient _supabase = Supabase.instance.client;

  // lowerCamelCase is used to satisfy the analyzer warning
  static const String unitsTable = 'uints';
  static const String propertiesTable = 'properties';
  static const String contractsTable = 'contract';
  static const String rentsTable = 'rent';
  static const String paymentsTable = 'payments';
  static const String customersTable = 'customers';

  // ❌ تم حذف الثابت ownerName هنا
  // static const String ownerName = 'Mishal Ibrahim Khalid Alrashed';

  Future<UnitDetails> getUnitDetails(int unitId) async {
    try {
      // 1. Fetch Unit and Property Data
      // ✅ التعديل الثاني: إضافة owners(name) داخل select الخاص بـ properties:prop_id
      // هذا يفترض أن جدول properties مرتبط بجدول owners عبر FK
      final unitResult = await _supabase
          .from(unitsTable)
          .select('*, ${propertiesTable}:prop_id(*, owners(name))')
          .eq('id', unitId)
          .single();

      final unit = UnitData.fromJson(unitResult);

      // استدعاء دالة PropertyData.fromJson مع بيانات الخاصية المستخرجة
      final property = PropertyData.fromJson(
        unitResult[propertiesTable] as Map<String, dynamic>,
      );

      // 2. Fetch Latest Contract
      final contractResult = await _supabase
          .from(contractsTable)
          .select('*, customer_id(name)')
          .eq('unit_id', unitId)
          .order('end_date', ascending: false)
          .limit(1)
          .maybeSingle();

      ContractData? contract;
      if (contractResult != null) {
        final customerNameMap =
            contractResult['customer_id'] as Map<String, dynamic>;
        final customerName = (customerNameMap['name'] ?? '').toString();

        contract = ContractData(
          id: contractResult['id'] as int,
          customerName: customerName,
          startDate: (contractResult['start_date'] ?? '').toString(),
          endDate: (contractResult['end_date'] ?? '').toString(),
          annualRent: _parseNumber(contractResult['annul_rent']),
          description: 'Contract is active',
        );
      }

      // 3. Fetch Rent History
      final rentsResult = await _supabase
          .from(rentsTable)
          .select('*, ${customersTable}:customer_id(name)')
          .eq('unit_id', unitId)
          .order('start_date', ascending: false);

      final rents = rentsResult.asMap().entries.map<RentHistory>((entry) {
        final rentData = entry.value;

        // Extract tenant name from the join
        final customerName =
            (rentData[customersTable] as Map<String, dynamic>?)?['name']
                .toString() ??
            'N/A';

        // 👈 Logic to map rent_status to 'Paid' or 'Unpaid' (English)
        // We assume the DB column might be 'payment_status' or 'rent_status'.
        // Based on the previous context, we look for 'paid' in any case.
        final String fetchedStatus =
            (rentData['rent_status'] ?? rentData['payment_status'] ?? '')
                .toString()
                .toLowerCase();

        // Map any status containing 'paid' (and not 'unpaid') to 'Paid', otherwise 'Unpaid'.
        final String mappedStatus =
            fetchedStatus.contains('paid') && !fetchedStatus.contains('unpaid')
            ? 'Paid'
            : 'Unpaid';

        return RentHistory(
          num: entry.key + 1,
          customerName: customerName,
          startDate: (rentData['start_date'] ?? '').toString(),
          endDate: (rentData['end_date'] ?? '').toString(),
          rent: _parseNumber(rentData['rent']),
          rentStatus:
              mappedStatus, // Use the mapped English status: Paid or Unpaid
          paymentDate: (rentData['payment_date'] ?? 'N/A').toString(),
          notes: (rentData['notes'] ?? 'N/A').toString(),
        );
      }).toList();

      // 4. Fetch Payments History
      final paymentsResult = await _supabase
          .from(paymentsTable)
          .select('*, customer_id!inner(name)')
          .eq('uint_id', unitId)
          .order('date', ascending: false);

      final payments = paymentsResult.asMap().entries.map<PaymentHistory>((
        entry,
      ) {
        final paymentData = entry.value;

        final customerName =
            (paymentData['customer_id'] as Map<String, dynamic>?)?['name']
                .toString() ??
            'N/A';

        return PaymentHistory(
          num: entry.key + 1,
          customerName: customerName,
          date: (paymentData['date'] ?? '').toString(),
          amount: _parseNumber(paymentData['amount']),
          paymentType: (paymentData['type'] ?? 'Rent').toString(),
          description: (paymentData['description'] ?? 'N/A').toString(),
        );
      }).toList();

      return UnitDetails(
        unit: unit,
        property: property,
        contract: contract,
        rents: rents,
        payments: payments,
      );
    } on PostgrestException catch (e) {
      debugPrint('🚨 SUPABASE ERROR for Unit ID $unitId: ${e.message}');
      debugPrint('Database Query Error Stack: ${e.toString()}');

      throw Exception('Database error while fetching details. ${e.message}');
    } catch (e, stackTrace) {
      debugPrint('❌ GENERAL ERROR for Unit ID $unitId: ${e.toString()}');
      debugPrint('Stack Trace: $stackTrace');

      throw Exception('Failed to fetch unit details. ${e.toString()}');
    }
  }
}
// -----------------------------------------------------------------------------
// 3. UI Screen
// -----------------------------------------------------------------------------

class UnitInfoScreen extends StatefulWidget {
  final int unitId;

  const UnitInfoScreen({super.key, required this.unitId});

  @override
  State<UnitInfoScreen> createState() => _UnitInfoScreenState();
}

class _UnitInfoScreenState extends State<UnitInfoScreen> {
  late Future<UnitDetails> _unitDetailsFuture;
  final UnitDetailsService _service = UnitDetailsService();
  UnitDetails? _details;

  @override
  void initState() {
    super.initState();
    _unitDetailsFuture = _service.getUnitDetails(widget.unitId).then((details) {
      _details = details;
      return details;
    });
  }

  // ====== Export Functions (No changes needed here) ======

  Future<void> _exportDataToCSV({
    required String fileName,
    required List<List<dynamic>> data,
    required BuildContext context,
  }) async {
    if (data.isEmpty || data.length == 1) {
      // Check if only headers exist
      _showSnackBar(
        context,
        'No data records to export in $fileName.',
        Colors.orange,
      );
      return;
    }

    try {
      // 1. Convert data to CSV format
      final csvData = const ListToCsvConverter().convert(data);

      // 2. Get the temporary storage path
      final directory = await getTemporaryDirectory();
      final filePath = '${directory.path}/$fileName.csv';
      final file = File(filePath);

      // 3. Write the file
      await file.writeAsString(csvData);

      // 4. Show success message
      _showSnackBar(
        context,
        'Data exported successfully to $fileName.csv.',
        Colors.green,
      );
    } catch (e) {
      debugPrint('Export Error: $e');
      _showSnackBar(
        context,
        'Export failed: Check device permissions. Error: ${e.toString()}',
        Colors.red,
      );
    }
  }

  void _handleExportButtonPress(String type) async {
    if (_details == null) {
      _showSnackBar(context, 'Data is loading or unavailable.', Colors.orange);
      return;
    }

    // Setup data for export
    List<List<dynamic>> data = [];
    String fileName = 'Unit_${widget.unitId}_';
    String title = '';
    bool hasData = false;

    if (type == 'Contracts') {
      final headers = [
        'ID',
        'Customer Name',
        'Start Date',
        'End Date',
        'Annual Rent',
        'Description',
      ];
      data.add(headers);
      if (_details!.contract != null) {
        data.addAll([_details!.contract!.toCsvList()]);
        hasData = true;
      }
      title = 'Contracts';
    } else if (type == 'Rents') {
      final headers = [
        'Num',
        'Customer Name',
        'Start Date',
        'End Date',
        'Rent Amount',
        'Rent Status',
        'Payment Date',
        'Notes',
      ];
      data.add(headers);
      data.addAll(_details!.rents.map((r) => r.toCsvList()));
      if (_details!.rents.isNotEmpty) hasData = true;
      title = 'Rents';
    } else if (type == 'Payments') {
      final headers = [
        'Num',
        'Customer Name',
        'Date',
        'Amount',
        'Payment Type',
        'Description',
      ];
      data.add(headers);
      data.addAll(_details!.payments.map((p) => p.toCsvList()));
      if (_details!.payments.isNotEmpty) hasData = true;
      title = 'Payments';
    } else if (type == 'All') {
      // Combine all data into one file
      data = [];
      fileName = 'Unit_${widget.unitId}_All_Data';

      // Contracts
      data.add(['--- Contracts ---']);
      data.add([
        'ID',
        'Customer Name',
        'Start Date',
        'End Date',
        'Annual Rent',
        'Description',
      ]);
      if (_details!.contract != null) {
        data.addAll([_details!.contract!.toCsvList()]);
        hasData = true;
      } else {
        data.add(['No contract data available']);
      }
      data.add([]); // Separator

      // Rents
      data.add(['--- Rents History ---']);
      data.add([
        'Num',
        'Customer Name',
        'Start Date',
        'End Date',
        'Rent Amount',
        'Rent Status',
        'Payment Date',
        'Notes',
      ]);
      data.addAll(_details!.rents.map((r) => r.toCsvList()));
      if (_details!.rents.isNotEmpty) hasData = true;
      data.add([]); // Separator

      // Payments
      data.add(['--- Payments History ---']);
      data.add([
        'Num',
        'Customer Name',
        'Date',
        'Amount',
        'Payment Type',
        'Description',
      ]);
      data.addAll(_details!.payments.map((p) => p.toCsvList()));
      if (_details!.payments.isNotEmpty) hasData = true;
      title = 'All Data';
    }

    fileName += title;

    // Condition to ensure there is data beyond just the headers to export
    if (hasData || type == 'All') {
      await _exportDataToCSV(
        fileName: fileName.replaceAll(' ', '_'),
        data: data,
        context: context,
      );
    } else {
      _showSnackBar(
        context,
        'No data records to export in the $title section.',
        Colors.orange,
      );
    }
  }

  void _showSnackBar(BuildContext context, String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, textDirection: TextDirection.rtl),
        backgroundColor: color,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  // ====== End Export Functions ======

  // ====== Helper Functions (No significant changes needed here) ======

  String _formatCurrency(double amount) {
    // Using the dollar sign '$'
    // Using standard international format
    return intl.NumberFormat.currency(
      symbol: '\$',
      decimalDigits: 2,
      locale: 'en_US',
    ).format(amount);
  }

  Widget _buildActionButtons(BuildContext context) {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      alignment: WrapAlignment.start,
      children: [
        ElevatedButton.icon(
          onPressed: () => Navigator.pop(context),
          style: ElevatedButton.styleFrom(
            foregroundColor: Colors.white,
            backgroundColor: Colors.blue.shade600,
          ),
          icon: const Icon(Icons.arrow_back, size: 20),
          label: const Text(
            'Back to Units',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
            textDirection: TextDirection.ltr,
          ),
        ),
        _exportButton(context, 'Export Contracts', Icons.download, 'Contracts'),
        _exportButton(context, 'Export Rents', Icons.download, 'Rents'),
        _exportButton(context, 'Export Payments', Icons.download, 'Payments'),
        _exportButton(context, 'Export All', Icons.download, 'All'),
      ],
    );
  }

  Widget _exportButton(
    BuildContext context,
    String label,
    IconData icon,
    String type,
  ) {
    return ElevatedButton.icon(
      onPressed: () => _handleExportButtonPress(type),
      style: ElevatedButton.styleFrom(
        foregroundColor: Colors.white,
        backgroundColor: Colors.blue.shade600,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        elevation: 2,
      ),
      icon: Icon(icon, size: 20),
      label: Text(
        label,
        style: const TextStyle(fontSize: 14),
        textDirection: TextDirection.ltr,
      ),
    );
  }

  Widget _buildInfoCard({
    required String title,
    required List<Widget> children,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 15.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 8.0),
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.bold,
                color: primaryDarkBlue,
              ),
              textDirection: TextDirection.rtl,
            ),
          ),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.15),
                  spreadRadius: 2,
                  blurRadius: 5,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: children,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    // ✅ NEW: تنسيق التاريخ إذا كان هو الحقل "Created At"
    String displayValue = value;
    if (label == 'Created At') {
      try {
        // إذا كان التنسيق ISO 8601 (مثل 2025-06-18T...)
        // نأخذ أول 10 أحرف فقط للحصول على التاريخ (YYYY-MM-DD)
        displayValue = value.substring(0, 10);
      } catch (e) {
        // في حالة وجود خطأ في تنسيق السلسلة (قيمة غير متوقعة)، نعرض القيمة الأصلية.
        debugPrint('Error formatting date: $e');
        displayValue = value; 
      }
    }

 return Padding(
padding: const EdgeInsets.symmetric(vertical: 6.0),
child: Row(
 mainAxisAlignment: MainAxisAlignment.spaceBetween,
 children: [
 Text(
  '$label:',
  style: TextStyle(
  fontWeight: FontWeight.w600,
  color: primaryDarkBlue.withOpacity(0.8),
   fontSize: 16,
  ),
  textDirection: TextDirection.rtl,
 ),
 // ⬅️ تم استبدال 'value' بـ 'displayValue' هنا
 Text(
 displayValue, // استخدم القيمة المنسقة/المقصورة
 style: const TextStyle(
  fontWeight: FontWeight.bold,
  color: primaryDarkBlue,
 fontSize: 16,
 ),
 // Name/Address fields are RTL, Numbers/Dates are LTR
 textDirection:
(label.contains('Name') ||
 label.contains('Address') ||
 label.contains('Owner'))
? TextDirection.rtl
: TextDirection.ltr,
),
 ],
 ),
 );
 }
  // ====== Table-Specific Functions (No changes needed here) ======

  Widget _buildContractsHistoryTable(List<ContractData> contracts) {
    return _buildTableSection(
      title: 'Contracts History',
      headers: const [
        'Num',
        'Customer Name',
        'Start Date',
        'End Date',
        'Annual Rent',
        'Description',
      ],
      dataRows: contracts.asMap().entries.map((entry) {
        final contract = entry.value;
        return [
          (entry.key + 1).toString(),
          contract.customerName,
          contract.startDate,
          contract.endDate,
          _formatCurrency(contract.annualRent),
          contract.description,
        ];
      }).toList(),
      sectionTitle: 'Contracts History',
    );
  }

  Widget _buildRentsHistoryTable(List<RentHistory> rents) {
    return _buildTableSection(
      title: 'Rents History',
      headers: const [
        'Num',
        'Customer Name',
        'Start Date',
        'End Date',
        'Rent Amount',
        'Rent Status',
        'Payment Date',
        'Notes',
      ],
      dataRows: rents.asMap().entries.map((entry) {
        final rent = entry.value;
        return [
          rent.num.toString(),
          rent.customerName,
          rent.startDate,
          rent.endDate,
          _formatCurrency(rent.rent),
          rent.rentStatus,
          rent.paymentDate,
          rent.notes,
        ];
      }).toList(),
      sectionTitle: 'Rents History',
    );
  }

  Widget _buildPaymentsHistoryTable(List<PaymentHistory> payments) {
    return _buildTableSection(
      title: 'Payments History',
      headers: const [
        'Num',
        'Customer Name',
        'Date',
        'Amount',
        'Payment Type',
        'Description',
      ],
      dataRows: payments.asMap().entries.map((entry) {
        final payment = entry.value;
        return [
          payment.num.toString(),
          payment.customerName,
          payment.date,
          _formatCurrency(payment.amount),
          payment.paymentType,
          payment.description,
        ];
      }).toList(),
      sectionTitle: 'Payments History',
    );
  }

  // Generic table building function (with conditional formatting retained)
  Widget _buildTableSection({
    required String title,
    required List<String> headers,
    required List<List<dynamic>> dataRows,
    required String sectionTitle,
  }) {
    // ⬅️ Determine Rent Status column index for conditional formatting
    final statusColumnIndex = (sectionTitle == 'Rents History')
        ? headers.indexOf('Rent Status')
        : -1;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 8.0),
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: primaryDarkBlue,
              ),
              textDirection: TextDirection.rtl,
            ),
          ),

          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.15),
                  spreadRadius: 2,
                  blurRadius: 5,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: DataTable(
                  headingRowColor: WidgetStateProperty.all(primaryDarkBlue),
                  dataRowHeight: 50,
                  columnSpacing: 15,
                  columns: headers.map((header) {
                    return DataColumn(
                      label: Text(
                        header,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                        textAlign: TextAlign.center,
                        textDirection: TextDirection.ltr,
                      ),
                    );
                  }).toList(),
                  rows: dataRows.asMap().entries.map((entry) {
                    final rowIndex = entry.key;
                    final row = entry.value;

                    final Color? rowColor = rowIndex % 2 == 1
                        ? Colors.blue.shade50.withOpacity(0.5)
                        : Colors.white;

                    return DataRow(
                      color: WidgetStateProperty.all(rowColor),
                      cells: row.asMap().entries.map((cellEntry) {
                        final cellIndex = cellEntry.key;
                        final value = cellEntry.value.toString();

                        // Determine cell direction: Name is RTL, others are LTR (since they are numbers/dates/English statuses)
                        final TextDirection direction =
                            (headers[cellIndex] == 'Customer Name')
                            ? TextDirection.rtl
                            : TextDirection.ltr;

                        // ✅ Apply conditional formatting to the Rent Status column in the Rents History table only
                        if (sectionTitle == 'Rents History' &&
                            cellIndex == statusColumnIndex) {
                          final normalizedValue = value.toLowerCase().trim();

                          // Define the two main states: Paid or Unpaid
                          final isRed = normalizedValue == 'unpaid';
                          final isGreen = normalizedValue == 'paid';

                          // Coloring logic
                          final color = isGreen
                              ? Colors.green.shade600
                              : isRed
                              ? Colors.red.shade600
                              : Colors
                                    .grey
                                    .shade600; // Grey for other statuses (e.g. N/A or empty)

                          final bgColor = isGreen
                              ? Colors.green.shade50
                              : isRed
                              ? Colors.red.shade50
                              : Colors.grey.shade100; // Light grey background

                          return DataCell(
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: bgColor,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: color.withOpacity(0.5),
                                  width: 1,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: color.withOpacity(0.2),
                                    blurRadius: 3,
                                    offset: const Offset(0, 1),
                                  ),
                                ],
                              ),
                              child: Center(
                                child: Text(
                                  value,
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: color,
                                  ),
                                  textDirection: TextDirection
                                      .ltr, // Keep LTR for Paid/Unpaid status text
                                ),
                              ),
                            ),
                          );
                        }

                        // For normal cells
                        return DataCell(
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                            child: Text(
                              value,
                              style: const TextStyle(fontSize: 14),
                              textDirection: direction,
                            ),
                          ),
                        );
                      }).toList(),
                    );
                  }).toList(),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ✅ The build function (No changes needed here)
  @override
  Widget build(BuildContext context) {
    // ⬅️ Retained RTL direction as requested
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: backgroundColor,
        appBar: AppBar(
          title: const Text(
            'Unit Details',
            style: TextStyle(
              color: primaryDarkBlue,
              fontWeight: FontWeight.bold,
            ),
            textDirection: TextDirection.ltr,
          ),
          centerTitle: true,
          backgroundColor: Colors.white,
          elevation: 0,
          iconTheme: const IconThemeData(color: primaryDarkBlue),
        ),
        body: FutureBuilder<UnitDetails>(
          future: _unitDetailsFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: CircularProgressIndicator(color: primaryDarkBlue),
              );
            } else if (snapshot.hasError) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(
                    'Error: ${snapshot.error.toString()}',
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.red),
                    textDirection: TextDirection.ltr,
                  ),
                ),
              );
            } else if (snapshot.hasData) {
              final details = snapshot.data!;
              return SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildActionButtons(context),
                    const SizedBox(height: 20),

                    // Unit Information
                    _buildInfoCard(
                      title: 'Unit Information',
                      children: [
                        _buildInfoRow('Unit ID', details.unit.id.toString()),
                        _buildInfoRow('Unit Number', details.unit.unitNumber),
                        _buildInfoRow(
                          'Reported Rent Amount',
                          _formatCurrency(details.unit.rentAmount),
                        ),
                        _buildInfoRow('Created At', details.unit.createdAt),
                      ],
                    ),

                    // Property Information
                    _buildInfoCard(
                      title: 'Property Information',
                      children: [
                        _buildInfoRow(
                          'Property ID',
                          details.property.id.toString(),
                        ),
                        _buildInfoRow('Property Name', details.property.name),
                        _buildInfoRow('Address', details.property.address),
                        // يعرض اسم المالك الذي تم جلبه ديناميكياً
                        _buildInfoRow('Owner', details.property.ownerName),
                      ],
                    ),
                    _buildContractsHistoryTable(
                      details.contract != null ? [details.contract!] : [],
                    ),
                    _buildRentsHistoryTable(details.rents),
                    _buildPaymentsHistoryTable(details.payments),
                    const SizedBox(height: 50),
                  ],
                ),
              );
            } else {
              return const Center(
                child: Text(
                  'No unit details found.',
                  style: TextStyle(fontSize: 18, color: primaryDarkBlue),
                  textDirection: TextDirection.rtl,
                ),
              );
            }
          },
        ),
      ),
    );
  }
}

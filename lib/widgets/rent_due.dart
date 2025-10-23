import 'dart:ui' as fw;

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';

// تهيئة Supabase (افتراضياً)
final supabase = Supabase.instance.client;

// ==========================
// 2. نموذج البيانات (Model)
// ==========================

class ExpiredRentReportItem {
  final int rentId;
  final String unitNumber;
  final String propertyName;
  final String propertyAddress; // افتراضاً أنه موجود في جدول properties
  final String customerName;
  final String customerPhone;   // افتراضاً أنه موجود في جدول customers
  final DateTime endDate;
  final String paymentStatus;

  ExpiredRentReportItem({
    required this.rentId,
    required this.unitNumber,
    required this.propertyName,
    required this.propertyAddress,
    required this.customerName,
    required this.customerPhone,
    required this.endDate,
    required this.paymentStatus,
  });

  factory ExpiredRentReportItem.fromJson(Map<String, dynamic> json) {
    // استخراج بيانات الوحدة والعقار
    final uints = json['uints'] as Map<String, dynamic>?;
    final properties = uints?['properties'] as Map<String, dynamic>?;

    // استخراج بيانات العميل
    final customers = json['customers'] as Map<String, dynamic>?;

    DateTime safeParseDate(dynamic value) {
      if (value == null) return DateTime.now();
      try {
        return DateTime.parse(value.toString());
      } catch (_) {
        return DateTime.now();
      }
    }
    
    return ExpiredRentReportItem(
      rentId: json['id'] is int ? json['id'] : int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      unitNumber: uints?['unit_number']?.toString() ?? 'N/A',
      propertyName: properties?['name']?.toString() ?? 'N/A',
      propertyAddress: properties?['address']?.toString() ?? 'N/A', // افتراض وجود عمود address في properties
      customerName: customers?['name']?.toString() ?? 'N/A',
      customerPhone: customers?['phone']?.toString() ?? 'N/A', // افتراض وجود عمود phone في customers
      endDate: safeParseDate(json['end_date']),
      paymentStatus: json['payment_status']?.toString().toUpperCase() ?? 'N/A',
    );
  }
}

// ==========================
// 3. شاشة التقرير (ExpiredRentsReportScreen)
// ==========================

class ExpiredRentsReportScreen extends StatefulWidget {
  const ExpiredRentsReportScreen({super.key});

  @override
  State<ExpiredRentsReportScreen> createState() => _ExpiredRentsReportScreenState();
}

class _ExpiredRentsReportScreenState extends State<ExpiredRentsReportScreen> {
  late Future<List<ExpiredRentReportItem>> _reportItemsFuture;

  @override
  void initState() {
    super.initState();
    _reportItemsFuture = _fetchExpiredUnpaidRents();
  }

  // دالة لجلب البيانات من Supabase مع الفلترة والربط
  Future<List<ExpiredRentReportItem>> _fetchExpiredUnpaidRents() async {
    // تاريخ اليوم بصيغة YYYY-MM-DD
    final today = DateFormat('yyyy-MM-dd').format(DateTime.now());

    try {
      final response = await supabase
          .from('rent')
          .select('''
            id,
            end_date,
            payment_status,
            uints!inner (
              unit_number,
              properties!inner (
                name,
                address
              )
            ),
            customers!inner (
              name,
              phone
            )
          ''')
          // الشرط الأول: تاريخ الانتهاء أقل من تاريخ اليوم (منتهي الصلاحية)
          .lt('end_date', today)
          // الشرط الثاني: حالة الدفع غير مدفوع
          .eq('payment_status', 'unpaid') 
          .order('end_date', ascending: true);

      final List<ExpiredRentReportItem> items = (response as List)
          .map((map) => ExpiredRentReportItem.fromJson(map as Map<String, dynamic>))
          .toList();

      return items;
    } on PostgrestException catch (e) {
      debugPrint('Postgrest Error fetching report data: ${e.message}');
      throw Exception('فشل جلب البيانات من قاعدة البيانات: ${e.message}');
    } catch (e) {
      debugPrint('General Error fetching report data: $e');
      throw Exception('حدث خطأ عام أثناء جلب البيانات: $e');
    }
  }

  // دالة لعرض شريحة حالة الدفع
  Widget _buildStatusChip(String status) {
    final statusLower = status.toLowerCase();
    Color color;
    Color textColor;

    if (statusLower == 'unpaid' || statusLower == 'pending') {
      color = const Color(0xFFFFFBE6); // لون خلفية أصفر فاتح
      textColor = const Color(0xFF8A6D3B); // لون نص بني غامق
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


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Expired Rents Report'),
        backgroundColor: const Color(0xFF1A237E), // نفس لون الشريط العلوي
        titleTextStyle: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Expired Rents Report',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 15),
            
            // زر Export All بنفس تصميم الصورة
            ElevatedButton(
              onPressed: () {
                // TODO: تنفيذ وظيفة التصدير (مثلاً إلى ملف CSV/Excel)
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Exporting data... (Functionality not implemented)')),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF42A5F5), // لون أزرق
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
              ),
              child: const Text('Export All', style: TextStyle(fontSize: 16)),
            ),
            
            const SizedBox(height: 25),
            
            // عرض جدول البيانات
            FutureBuilder<List<ExpiredRentReportItem>>(
              future: _reportItemsFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: Padding(
                    padding: EdgeInsets.all(50.0),
                    child: CircularProgressIndicator(),
                  ));
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(50.0),
                      child: Text('Error loading data: ${snapshot.error}', style: const TextStyle(color: Colors.red)),
                    ),
                  );
                }

                final items = snapshot.data ?? [];
                if (items.isEmpty) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(50.0),
                      child: Text('No expired and unpaid rent records found.'),
                    ),
                  );
                }
                
                // استخدام SingleChildScrollView لوضع DataTable بداخله للسماح بالتمرير الأفقي
                return SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: DataTable(
                    columnSpacing: 10,
                    horizontalMargin: 10,
                    dataRowMinHeight: 50,
                    dataRowMaxHeight: 50,
                    headingRowColor: MaterialStateProperty.resolveWith(
                        (states) => const Color(0xFF1A237E)), // لون أزرق داكن لرأس الجدول
                    columns: const [
                      DataColumn(label: Text('Rent ID', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white))),
                      DataColumn(label: Text('Unit Number', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white))),
                      DataColumn(label: Text('Property Name', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white))),
                      DataColumn(label: Text('Property Address', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white))),
                      DataColumn(label: Text('Customer Name', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white))),
                      DataColumn(label: Text('Phone', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white))),
                      DataColumn(label: Text('End Date', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white))),
                      DataColumn(label: Text('Payment Status', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white))),
                    ],
                    rows: items.map((item) {
                      return DataRow(cells: [
                        DataCell(Text(item.rentId.toString())),
                        DataCell(Text(item.unitNumber, overflow: TextOverflow.ellipsis)),
                        DataCell(Text(item.propertyName, overflow: TextOverflow.ellipsis)),
                        DataCell(Text(item.propertyAddress, overflow: TextOverflow.ellipsis)),
                        DataCell(Text(item.customerName, overflow: TextOverflow.ellipsis, textDirection:fw. TextDirection.rtl)),
                        DataCell(Text(item.customerPhone)),
                        DataCell(Text(DateFormat('M/d/yyyy').format(item.endDate))), // نفس تنسيق التاريخ في الصورة
                        DataCell(_buildStatusChip(item.paymentStatus)),
                      ]);
                    }).toList(),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
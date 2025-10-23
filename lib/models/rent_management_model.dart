// rent_model.dart
import 'package:intl/intl.dart';

class RentItem {
  final int id;
  final String unitNumber; // من جدول uints
  final String customerName; // من جدول customers
  final double rentAmount; // من جدول rent
  final DateTime startDate; // من جدول rent أو contract (سنفترض من rent لتحديد فترة الدفع)
  final DateTime endDate; // من جدول rent أو contract
  final String status; // من جدول rent

  RentItem({
    required this.id,
    required this.unitNumber,
    required this.customerName,
    required this.rentAmount,
    required this.startDate,
    required this.endDate,
    required this.status,
  });

  // Factory constructor لتحويل بيانات Supabase المعقدة إلى كائن RentItem
  factory RentItem.fromJson(Map<String, dynamic> json) {
    // Supabase يرجع البيانات المرتبطة في شكل nested objects
    final customerData = json['customer_id'];
    final unitData = json['uint_id'];
    
    // ملاحظة: نفترض هنا أن أعمدة تاريخ البداية والنهاية موجودة في جدول rent 
    // لتمثيل فترة الإيجار الشهري، على الرغم من أنها غير مذكورة في التصميم الأصلي لجدول rent.
    // إذا لم تكن موجودة في جدول rent، يجب تعديل قاعدة البيانات أو جلبها من جدول contract.

    // لتحقيق شكل الشاشة المرسلة، سنضيف عمودين (start_date, end_date) لجدول rent في Supabase.

    return RentItem(
      id: json['id'] as int,
      unitNumber: (unitData?['unit_number'] as String?) ?? 'N/A',
      customerName: (customerData?['name'] as String?) ?? 'N/A',
      rentAmount: (json['rent'] as num).toDouble(),
      startDate: DateTime.parse(json['start_date'] as String),
      endDate: DateTime.parse(json['end_date'] as String),
      status: json['payment_status'] as String,
    );
  }
}
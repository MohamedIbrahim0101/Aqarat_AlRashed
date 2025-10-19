// lib/models/UnitDetails.dart

// **********************************************
// موديل الوحدة المفصل (UnitDetails)
// يستخدم في شاشة عرض الوحدات (UnitsScreen).
// **********************************************
class UnitDetails {
  final int id;
  final String unitNumber; // تم تغييرها لـ String لاحتمال وجود أحرف (A-101)
  final double rentAmount;
  final String status; // حالة الوحدة (Occupied, Vacant, Maintenance)

  UnitDetails({
    required this.id,
    required this.unitNumber,
    required this.rentAmount,
    required this.status,
  });

  factory UnitDetails.fromJson(Map<String, dynamic> json) {
    // 1. استخراج الـ ID بشكل آمن
    final int id = json['id'] is int ? json['id'] as int : int.tryParse(json['id']?.toString() ?? '0') ?? 0;
    
    // 2. استخراج رقم الوحدة (String)
    final String unitNumber = json['unit_number']?.toString() ?? 'N/A';
    
    // 3. استخراج قيمة الإيجار (Double)
    final double rentAmount = (json['rent_amount'] is num)
        ? json['rent_amount'].toDouble()
        : double.tryParse(json['rent_amount']?.toString() ?? '0') ?? 0.0;
        
    // 4. استخراج حالة الوحدة (String)
    final String status = json['status']?.toString() ?? 'غير معروف';

    return UnitDetails(
      id: id,
      unitNumber: unitNumber, 
      rentAmount: rentAmount,
      status: status,
    );
  }
}
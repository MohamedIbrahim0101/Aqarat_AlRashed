class UnitDetails {
  final int id;
  final String unitNumber;
  final String propertyName;
  final double rentAmount;
  final String status;
  final int propertyId; // 🆕 معرف العقار

  UnitDetails({
    required this.id,
    required this.unitNumber,
    required this.propertyName,
    required this.rentAmount,
    required this.status,
    required this.propertyId, // 🆕 التأكد من التهيئة
  });

  factory UnitDetails.fromJson(Map<String, dynamic> json) {
    final int id = json['id'] is int
        ? json['id'] as int
        : int.tryParse(json['id']?.toString() ?? '0') ?? 0;

    final String unitNumber = json['unit_number']?.toString() ?? 'N/A';

    final dynamic propertyData = json['prop_id'];
    String propertyName = 'Unknown Property';
    int propertyId = 0; // 🆕 default

    if (propertyData is Map<String, dynamic>) {
      propertyName = propertyData['name']?.toString() ?? 'Unknown Property';
      propertyId = propertyData['id'] as int? ?? 0; // 🆕 قراءة الـ ID
    } else {
      propertyName = json['property_name']?.toString() ?? 'Unknown Property';
      propertyId = json['property_id'] as int? ?? 0; // 🆕 fallback
    }

    final double rentAmount = (json['rent_amount'] is num)
        ? (json['rent_amount'] as num).toDouble()
        : double.tryParse(json['rent_amount']?.toString() ?? '0') ?? 0.0;

    final String status = json['status']?.toString() ?? 'N/A';

    return UnitDetails(
      id: id,
      unitNumber: unitNumber,
      propertyName: propertyName,
      rentAmount: rentAmount,
      status: status,
      propertyId: propertyId, // 🆕 تمريره للموديل
    );
  }
}

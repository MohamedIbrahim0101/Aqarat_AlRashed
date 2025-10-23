const String unitsTableName = 'uints';

class Unit {
  final int id;
  String unitNumber;
  int propId;
  String propertyName;
  double rentAmount;

  Unit({
    required this.id,
    required this.unitNumber,
    required this.propId,
    required this.propertyName,
    required this.rentAmount,
  });

  factory Unit.fromJson(Map<String, dynamic> json) {
    String propName;
    if (json.containsKey('properties') && json['properties'] is Map) {
      propName = (json['properties'] as Map<String, dynamic>)['name'] ?? 'N/A';
    } else {
      propName = json['property_name'] ?? 'N/A';
    }

    return Unit(
      id: json['id'] as int,
      unitNumber: json['unit_number']?.toString() ?? 'N/A',
      propId: json['prop_id'] as int,
      rentAmount: _parseDouble(json['rent_amount']),
      propertyName: propName,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'unit_number': unitNumber.trim(),
      'prop_id': propId,
      'rent_amount': rentAmount,
    };
  }

  static double _parseDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }
}

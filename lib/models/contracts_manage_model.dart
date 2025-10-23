class ContractModel {
  final int id;
  final int unitId; // 🆕 added
  final String unitNumber;
  final String propertyName;
  final String customerName;
  final int customerId;
  final String startDate;
  final String endDate;
  final num annualRent;
  final String createdAt;
  final String description;
  final String contractType;

  ContractModel({
    required this.id,
    required this.unitId, // 🆕 added
    required this.unitNumber,
    required this.propertyName,
    required this.customerName,
    required this.customerId,
    required this.startDate,
    required this.endDate,
    required this.annualRent,
    required this.createdAt,
    required this.description,
    required this.contractType,
  });

  factory ContractModel.fromJson(Map<String, dynamic> json) {
    final unitData = json['uints'] as Map<String, dynamic>?;
    final customerData = json['customers'] as Map<String, dynamic>?;

    Map<String, dynamic>? propertyData;
    if (unitData != null && unitData['properties'] != null) {
      final propertiesField = unitData['properties'];
      if (propertiesField is List && propertiesField.isNotEmpty) {
        propertyData = propertiesField.first as Map<String, dynamic>;
      } else if (propertiesField is Map<String, dynamic>) {
        propertyData = propertiesField;
      }
    }

    return ContractModel(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id'].toString()) ?? 0,
      unitId: unitData?['id'] is int
          ? unitData!['id']
          : int.tryParse(unitData?['id']?.toString() ?? '0') ?? 0, // 🆕
      unitNumber: unitData?['unit_number']?.toString() ?? 'N/A',
      propertyName: propertyData?['name']?.toString() ?? 'N/A',
      customerName: customerData?['name']?.toString() ?? 'N/A',
      customerId: customerData?['id'] is int
          ? customerData!['id']
          : int.tryParse(customerData?['id']?.toString() ?? '0') ?? 0,
      startDate: json['start_date']?.toString() ?? 'N/A',
      endDate: json['end_date']?.toString() ?? 'N/A',
      annualRent: (json['annul_rent'] is num)
          ? json['annul_rent']
          : num.tryParse(json['annual_rent']?.toString() ?? '0') ?? 0,
      createdAt: json['created_at']?.toString() ?? 'N/A',
      description: json['description']?.toString() ?? '',
      contractType: json['contract_type']?.toString() ?? 'N/A',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'unit_id': unitId, // 🆕 added
      'start_date': startDate,
      'end_date': endDate,
      'annul_rent': annualRent,
      'created_at': createdAt,
      'description': description,
      'contract_type': contractType,
      'customer_id': customerId,
    };
  }
}

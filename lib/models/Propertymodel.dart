// **********************************************
// موديل العقار الأساسي (PropertyItem)
// **********************************************
class PropertyItem {
  final int id;
  final String name;

  PropertyItem({
    required this.id,
    required this.name,
  });

  factory PropertyItem.fromJson(Map<String, dynamic> json) {
    return PropertyItem(
      id: json['id'] as int,
      name: json['name'] as String,
    );
  }
}

// **********************************************
// موديل العقار المفصل (PropertyDetails)
// **********************************************
class PropertyDetails extends PropertyItem {
  final String ownerName;
  final String address;
  final double totalValue;
  final int unitsCount;

  PropertyDetails({
    required super.id,
    required super.name,
    required this.ownerName,
    required this.address,
    required this.totalValue,
    required this.unitsCount,
  });

  factory PropertyDetails.fromJson(Map<String, dynamic> json) {
    final dynamic ownerData = json['owners'];
    String ownerName = 'غير محدد';

    if (ownerData is List && ownerData.isNotEmpty) {
      ownerName = ownerData.first['name']?.toString() ?? 'غير محدد';
    } else if (ownerData is Map<String, dynamic>) {
      ownerName = ownerData['name']?.toString() ?? 'غير محدد';
    }

    final List<dynamic> unitsList = (json['units'] as List?) ?? [];
    final double value =
        double.tryParse(json['total_value']?.toString() ?? '0') ?? 0.0;
    final String address = json['address']?.toString() ?? 'لا يوجد عنوان';

    return PropertyDetails(
      id: json['id'] as int,
      name: json['name']?.toString() ?? 'غير معروف',
      ownerName: ownerName,
      address: address,
      totalValue: value,
      unitsCount: unitsList.length,
    );
  }
}

// lib/models/Propertymodel.dart

import 'package:my_app/services/dashboard_service.dart';

class PropertyDetails extends PropertyItem {
  final String ownerName;
  final String address;
  final double totalValue;
  final int unitsCount;
  final int ownerId; // 🆕 حقل جديد

  PropertyDetails({
    required super.id,
    required super.name,
    required this.ownerName,
    required this.address,
    required this.totalValue,
    required this.unitsCount,
    required this.ownerId,
  });

  factory PropertyDetails.fromJson(Map<String, dynamic> json) {
    // قراءة بيانات المالك
    final dynamic ownerData = json['owners'];
    String ownerName = 'غير محدد';
    if (ownerData is List && ownerData.isNotEmpty) {
      ownerName = ownerData.first['name']?.toString() ?? 'غير محدد';
    } else if (ownerData is Map<String, dynamic>) {
      ownerName = ownerData['name']?.toString() ?? 'غير محدد';
    }

    // قراءة عدد الوحدات
    final List<dynamic>? unitsCountData = json['uints'] as List<dynamic>?;
    final int unitsCount = unitsCountData != null && unitsCountData.isNotEmpty
        ? (unitsCountData.first['count'] as num?)?.toInt() ?? 0
        : 0;

    // قراءة القيمة الإجمالية
    final double totalValue = (json['total_value'] is num)
        ? json['total_value'].toDouble()
        : double.tryParse(json['total_value']?.toString() ?? '0') ?? 0.0;

    // قراءة العنوان
    final String address = json['address']?.toString() ?? 'لا يوجد عنوان';

    // 🆕 قراءة owner_id بأمان
    final int ownerId = (json['owner_id'] is int)
        ? json['owner_id']
        : int.tryParse(json['owner_id']?.toString() ?? '0') ?? 0;

    return PropertyDetails(
      id: json['id'] as int,
      name: json['name']?.toString() ?? 'غير معروف',
      ownerName: ownerName,
      address: address,
      totalValue: totalValue,
      unitsCount: unitsCount,
      ownerId: ownerId,
    );
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'ownerName': ownerName,
      'address': address,
      'totalValue': totalValue,
      'unitsCount': unitsCount,
      'ownerId': ownerId, // 🆕 إضافته للـ JSON
    };
  }
}

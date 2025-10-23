import 'dart:async';
import 'package:supabase_flutter/supabase_flutter.dart';

/// **********************************************
/// نماذج البيانات (Models)
/// **********************************************

class DashboardStats {
  final int propertiesCount;
  final int unitsCount;
  final int ownersCount;
  final int customersCount;
  final double cashInflows;
  final double cashOutflows;
  final double netIncome;
  final int dueRentsCount;

  DashboardStats({
    required this.propertiesCount,
    required this.unitsCount,
    required this.ownersCount,
    required this.customersCount,
    required this.cashInflows,
    required this.cashOutflows,
    required this.netIncome,
    required this.dueRentsCount,
  });
}

class PropertyItem {
  final int id;
  final String name;

  PropertyItem({required this.id, required this.name});

  factory PropertyItem.fromJson(Map<String, dynamic> json) {
    return PropertyItem(id: json['id'] as int, name: json['name'] as String);
  }
}

/// **********************************************
/// الخدمة الرئيسية DashboardService
/// **********************************************

class DashboardService {
  late final SupabaseClient client;

  DashboardService() {
    try {
      client = Supabase.instance.client;
    } catch (e) {
      // نكتفي برمي استثناء عام عند فشل التهيئة
      throw Exception('Supabase Client not initialized.');
    }
  }

  /// **********************************************
  /// دالة لحساب عدد السجلات في جدول معين
  /// **********************************************
  Future<int> _fetchCount(String tableName) async {
    try {
      final int count = await client.from(tableName).count();
      return count;
    } catch (e) {
      return 0; // نرجع صفر عند أي خطأ في الجلب
    }
  }

  /// **********************************************
  /// دالة لجمع القيم المالية (مثل الإيرادات والمصروفات)
  /// **********************************************
  Future<double> _fetchFinancialSum(
    String tableName, {
    String? matchType,
  }) async {
    try {
      var query = client.from(tableName).select('amount.sum');

      if (matchType != null) {
        query = query.eq('type', matchType);
      }

      final response = await query.single();
      final double total = (response['amount'] as num?)?.toDouble() ?? 0.0;
      return total;
    } catch (e) {
      return 0.0; // نرجع صفر عند أي خطأ في الجلب
    }
  }

  /// **********************************************
  /// دالة لجلب قائمة العقارات
  /// **********************************************
  Future<List<PropertyItem>> fetchPropertiesList() async {
    try {
      final List<Map<String, dynamic>> response = await client
          .from('properties')
          .select('id, name')
          .order('name', ascending: true);

      return response.map((item) => PropertyItem.fromJson(item)).toList();
    } catch (e) {
      return []; // نرجع قائمة فارغة عند أي خطأ
    }
  }

  /// **********************************************
  /// الدالة الرئيسية لجلب جميع إحصائيات لوحة القيادة
  /// **********************************************
  Future<DashboardStats> fetchDashboardStats() async {
    final propertiesFuture = _fetchCount('properties');
    final unitsFuture = _fetchCount('uints'); // جدول الوحدات
    final ownersFuture = _fetchCount('owners');
    final customersFuture = _fetchCount('customers');
    final inflowsFuture = _fetchFinancialSum(
      'incomes_and_outcomes',
      matchType: 'income',
    );
    final outflowsFuture = _fetchFinancialSum(
      'incomes_and_outcomes',
      matchType: 'outcome',
    );
    final dueRentsFuture = _fetchCount('rent'); // جدول الإيجارات/الديون

    final results = await Future.wait([
      propertiesFuture,
      unitsFuture,
      ownersFuture,
      customersFuture,
      inflowsFuture,
      outflowsFuture,
      dueRentsFuture,
    ]);

    final cashInflows = results[4] as double;
    final cashOutflows = results[5] as double;
    final netIncome = cashInflows - cashOutflows;

    return DashboardStats(
      propertiesCount: results[0] as int,
      unitsCount: results[1] as int,
      ownersCount: results[2] as int,
      customersCount: results[3] as int,
      cashInflows: cashInflows,
      cashOutflows: cashOutflows,
      netIncome: netIncome,
      dueRentsCount: results[6] as int,
    );
  }
}

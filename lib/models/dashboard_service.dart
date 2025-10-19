import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

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

/// **********************************************
/// الخدمة الرئيسية DashboardService (تتعامل مع Supabase)
/// **********************************************

class DashboardService {
  late final SupabaseClient client;

  DashboardService() {
    // قراءة القيم من ملف .env
    final supabaseUrl = dotenv.env['NEXT_PUBLIC_SUPABASE_URL'];
    final supabaseAnonKey = dotenv.env['NEXT_PUBLIC_SUPABASE_ANON_KEY'];

    if (supabaseUrl == null || supabaseAnonKey == null) {
      throw Exception(
        '❌ تأكد من وجود مفاتيح NEXT_PUBLIC_SUPABASE_URL و NEXT_PUBLIC_SUPABASE_ANON_KEY في ملف .env',
      );
    }

    client = SupabaseClient(supabaseUrl, supabaseAnonKey);
  }

  /// **********************************************
  /// دالة لحساب عدد السجلات في جدول معين
  /// **********************************************
  Future<int> _fetchCount(String tableName) async {
    try {
      final response = await client.from(tableName).select('id');
      return response.length;
    } on PostgrestException catch (e) {
      if (kDebugMode) {
        print('⚠️ Supabase Error fetching count for $tableName: ${e.message}');
      }
      return 0;
    } catch (e) {
      if (kDebugMode) {
        print('⚠️ General Error fetching count for $tableName: $e');
      }
      return 0;
    }
  }

  /// **********************************************
  /// دالة لجمع القيم المالية (مثل الإيرادات والمصروفات)
  /// **********************************************
  Future<double> _fetchFinancialSum(String tableName, {String? matchType}) async {
    try {
      var query = client.from(tableName).select('amount');
      if (matchType != null) {
        query = query.eq('type', matchType);
      }

      final List<Map<String, dynamic>> response = await query;
      double total = 0.0;

      for (final item in response) {
        total += (item['amount'] as num?)?.toDouble() ?? 0.0;
      }

      return total;
    } on PostgrestException catch (e) {
      if (kDebugMode) {
        print('⚠️ Supabase Error fetching financial sum for $tableName: ${e.message}');
      }
      return 0.0;
    } catch (e) {
      if (kDebugMode) {
        print('⚠️ General Error fetching financial sum for $tableName: $e');
      }
      return 0.0;
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
    } on PostgrestException catch (e) {
      if (kDebugMode) {
        print('⚠️ Supabase Error fetching properties list: ${e.message}');
      }
      return [];
    } catch (e) {
      if (kDebugMode) {
        print('⚠️ General Error fetching properties list: $e');
      }
      return [];
    }
  }

  /// **********************************************
  /// الدالة الرئيسية لجلب جميع إحصائيات لوحة القيادة
  /// **********************************************
  Future<DashboardStats> fetchDashboardStats() async {
    final propertiesFuture = _fetchCount('properties');
    final unitsFuture = _fetchCount('units');
    final ownersFuture = _fetchCount('owners');
    final customersFuture = _fetchCount('customers');
    final inflowsFuture =
        _fetchFinancialSum('incomes_and_outcomes', matchType: 'income');
    final outflowsFuture =
        _fetchFinancialSum('incomes_and_outcomes', matchType: 'outcome');
    final dueRentsFuture = _fetchCount('rent');

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

// lib/services/contracts_manage_service.dart

import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:my_app/models/contracts_manage_model.dart';
import 'package:flutter/foundation.dart'; // لاستخدام debugPrint

/// خدمة إدارة العقود: CRUD + حساب إجمالي الإيجارات السنوية
class ContractService {
  final SupabaseClient _client;
  static const String _tableName = 'contract'; // الاسم الصحيح للجدول

  ContractService({SupabaseClient? client})
      : _client = client ?? Supabase.instance.client;

  /// ===============================
  /// [القراءة - Read]
  /// جلب جميع العقود مع بيانات الوحدات والعقارات والعملاء المرتبطة
  /// ===============================
  Future<List<ContractModel>> fetchAllContracts() async {
    try {
      final response = await _client
          .from(_tableName)
          .select(
              '*, uints!inner(unit_number, properties!inner(name)), customers!inner(name)')
          .order('created_at', ascending: false);

      if (response is List) {
        return response
            .map((data) => ContractModel.fromJson(data as Map<String, dynamic>))
            .toList();
      }

      return [];
    } catch (e) {
      debugPrint('❌ Supabase fetchAllContracts error: $e');
      rethrow;
    }
  }

  /// ===============================
  /// [إجمالي الإيجارات السنوية - Annual Rent Sum]
  /// تجمع كل قيم annual_rent من جدول العقود
  /// ===============================
  Future<num> getAnnualRentSum() async {
    try {
      final response = await _client.from(_tableName).select('id, annul_rent');

      debugPrint('📦 Response من Supabase: $response');

      if (response == null || response.isEmpty) {
        debugPrint('⚠️ لا توجد عقود في قاعدة البيانات.');
        return 0;
      }

      num total = 0;
      for (final row in response) {
        final rentValue = row['annul_rent'];

        // طباعة كل قيمة للتأكد
        debugPrint('🔹 قيمة annul_rent: $rentValue (${rentValue.runtimeType})');

        if (rentValue is num) {
          total += rentValue;
        } else if (rentValue is String) {
          total += num.tryParse(rentValue) ?? 0;
        }
      }

      debugPrint('✅ إجمالي الإيجارات السنوية المحسوبة: $total');
      return total;
    } catch (e, stack) {
      debugPrint('❌ Supabase getAnnualRentSum error: $e');
      debugPrint('Stack: $stack');
      return 0;
    }
  }

  /// ===============================
  /// [الإنشاء - Create]
  /// إضافة عقد جديد إلى قاعدة البيانات
  /// ===============================
  Future<void> createContract(Map<String, dynamic> data) async {
    try {
      await _client.from(_tableName).insert(data);
      debugPrint('✅ Contract created successfully.');
    } catch (e) {
      debugPrint('❌ Supabase createContract error: $e');
      rethrow;
    }
  }

  /// ===============================
  /// [التحديث - Update]
  /// تحديث بيانات عقد موجود بناءً على معرّف العقد (id)
  /// ===============================
  Future<void> updateContract(int id, Map<String, dynamic> data) async {
    try {
      await _client.from(_tableName).update(data).eq('id', id);
      debugPrint('✅ Contract ID $id updated successfully.');
    } catch (e) {
      debugPrint('❌ Supabase updateContract error: $e');
      rethrow;
    }
  }

  /// ===============================
  /// [الحذف - Delete]
  /// حذف عقد من قاعدة البيانات باستخدام المعرّف
  /// ===============================
  Future<void> deleteContract(int id) async {
    try {
      await _client.from(_tableName).delete().eq('id', id);
      debugPrint('✅ Contract ID $id deleted successfully.');
    } catch (e) {
      debugPrint('❌ Supabase deleteContract error: $e');
      rethrow;
    }
  }
}

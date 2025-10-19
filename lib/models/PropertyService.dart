import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:my_app/models/Propertymodel.dart';
import 'package:my_app/models/UnitDetails.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class PropertyService {
  late final SupabaseClient supabase;

  // 1. تهيئة عميل Supabase وقراءة مفاتيح .env
  PropertyService() {
    final url = dotenv.env['NEXT_PUBLIC_SUPABASE_URL'];
    final key = dotenv.env['NEXT_PUBLIC_SUPABASE_ANON_KEY'];

    if (url == null || key == null) {
      throw Exception(
        '❌ القيم غير موجودة في ملف .env. تأكد من تحميله بشكل صحيح.',
      );
    }
    // تهيئة Supabase Client
    supabase = SupabaseClient(url, key);
  }

  // ------------------------------------------------------------------
  // 2. دالة جلب العقارات (fetchAllProperties)
  Future<List<PropertyDetails>> fetchAllProperties() async {
    try {
      final propertiesResponse = await supabase
          // 💡 افتراض أن اسم الجدول هو 'properties' أو 'Properties'
          .from('properties')
          .select('*');

      List<PropertyDetails> properties = propertiesResponse.map((prop) {
        // ⚠️ سنضع عدد الوحدات = 0 مؤقتاً لتجنب خطأ الـ PostgREST
        const int unitsCount = 0;

        // ✅ تحسين قراءة حقل اسم المالك: محاولة قراءة 'owner_name' ثم 'ownerName'
        final String ownerName =
            prop['owner_name']?.toString() ??
            prop['ownerName']?.toString() ?? // محاولة قراءة camelCase
            'N/A';

        // ✅ تحسين قراءة حقل القيمة الإجمالية
        final double totalValue = (prop['total_value'] is num)
            ? prop['total_value'].toDouble()
            : double.tryParse(prop['total_value']?.toString() ?? '0') ?? 0.0;

        return PropertyDetails(
          id: prop['id'],
          name: prop['name'] ?? '',
          ownerName: ownerName, // استخدام القيمة المحسنة
          address: prop['address'] ?? '',
          totalValue: totalValue,
          unitsCount: unitsCount, // قيمة مؤقتة
        );
      }).toList();

      return properties;
    } on PostgrestException catch (e) {
      print('❌ خطأ PostgREST أثناء تحميل العقارات: ${e.message}');
      throw Exception(
        'PostgrestException(message: ${e.message}, code: ${e.code})',
      );
    } catch (e) {
      print('❌ خطأ غير متوقع أثناء تحميل العقارات: $e');
      rethrow;
    }
  }

  // ------------------------------------------------------------------
  // 3. دالة جلب الوحدات المرتبطة بعقار معين (fetchUnitsByPropertyId)
  Future<List<UnitDetails>> fetchUnitsByPropertyId(int propertyId) async {
    try {
      final List<Map<String, dynamic>> unitsResponse = await supabase
          // 💡 مهم: إذا كان اسم الجدول في Supabase هو Units أو unit، قم بتغييره هنا.
          // نستخدم 'units' كاسم قياسي، لكن يجب التأكد من Supabase.
          .from('units')
          .select('*')
          .eq(
            'property_id', // افتراض أن العمود هو 'property_id'
            propertyId,
          );

      return unitsResponse.map((unit) {
        // UnitDetails.fromJson سيقوم بتحويل البيانات بأمان
        return UnitDetails.fromJson(unit);
      }).toList();
    } on PostgrestException catch (e) {
      print('❌ خطأ PostgREST أثناء تحميل الوحدات: ${e.message}');
      // هنا يظهر خطأ "relation units does not exist" إذا كان الاسم غير مطابق
      throw Exception(
        'PostgrestException(message: ${e.message}, code: ${e.code})',
      );
    } catch (e) {
      print('❌ خطأ غير متوقع أثناء تحميل الوحدات: $e');
      rethrow;
    }
  }
}

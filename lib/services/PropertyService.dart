// lib/models/PropertyService.dart

import 'package:my_app/models/Propertymodel.dart';
import 'package:my_app/models/UnitDetails.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class PropertyService {
  late final SupabaseClient supabase;

  PropertyService() {
    try {
      supabase = Supabase.instance.client;
    } catch (e) {
      throw Exception('Supabase Client not initialized.');
    }
  }

  // ------------------------------------------------------------------
  // إضافة عقار جديد بدون total_value
  Future<void> addProperty({
    required String name,
    required String address,
    required int ownerId,
  }) async {
    try {
      await supabase.from('properties').insert({
        'name': name,
        'address': address,
        'owner_id': ownerId,
      });
    } on PostgrestException catch (e) {
      throw Exception('Database error: ${e.message}');
    } catch (e) {
      throw Exception('Unexpected error: $e');
    }
  }

  // ------------------------------------------------------------------
  // تحديث عقار موجود بدون total_value
  Future<void> updateProperty({
    required int propertyId,
    required String name,
    required String address,
    required int ownerId,
  }) async {
    try {
      final updates = {
        'name': name,
        'address': address,
        'owner_id': ownerId,
      };
      await supabase.from('properties').update(updates).eq('id', propertyId);
    } on PostgrestException catch (e) {
      throw Exception('Error updating property: ${e.message}');
    } catch (e) {
      throw Exception('Error updating property: $e');
    }
  }

  // ------------------------------------------------------------------
  // بقية الدوال تبقى كما هي
  Future<List<PropertyDetails>> fetchAllProperties() async {
    try {
      final response = await supabase
          .from('properties')
          .select('*, owners!inner(name), uints(count)');

      return (response as List).map<PropertyDetails>((prop) {
        return PropertyDetails.fromJson(prop);
      }).toList();
    } on PostgrestException catch (e) {
      throw Exception('Error fetching all properties: ${e.message}');
    } catch (e) {
      throw Exception('Error fetching all properties: $e');
    }
  }

  Future<List<UnitDetails>> fetchUnitsByPropertyId(int propertyId) async {
    try {
      final response = await supabase
          .from('uints')
          .select('*, prop_id(name)')
          .eq('prop_id', propertyId);

      return (response as List).map<UnitDetails>((unit) {
        return UnitDetails.fromJson(unit);
      }).toList();
    } on PostgrestException catch (e) {
      throw Exception('Error fetching units: ${e.message}');
    } catch (e) {
      throw Exception('Error fetching units: $e');
    }
  }

  Future<List<UnitDetails>> fetchAllUnits() async {
    try {
      final response = await supabase
          .from('uints')
          .select('*, prop_id(name)')
          .order('unit_number', ascending: true);

      return (response as List).map<UnitDetails>((unit) {
        return UnitDetails.fromJson(unit);
      }).toList();
    } on PostgrestException catch (e) {
      throw Exception('Error fetching all units: ${e.message}');
    } catch (e) {
      throw Exception('Error fetching all units: $e');
    }
  }

  Future<void> deleteProperty(int propertyId) async {
    try {
      await supabase.from('properties').delete().eq('id', propertyId);
    } on PostgrestException catch (e) {
      throw Exception('Error deleting property: ${e.message}');
    } catch (e) {
      throw Exception('Error deleting property: $e');
    }
  }
}

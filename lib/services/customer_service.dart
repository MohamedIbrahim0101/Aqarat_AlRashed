// lib/services/customer_service.dart

import 'package:flutter/foundation.dart';
import 'package:my_app/models/customer_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class CustomerService {
  /// Supabase client instance
  final SupabaseClient supabase = Supabase.instance.client;

  /// Fetch full customer details by customer ID (preferred)
  Future<CustomerDetailsModel?> fetchCustomerDetailsById(int customerId) async {
    try {
      // =========================
      // 🔹 1. Fetch customer basic info
      // =========================
      final customerResponse = await supabase
          .from('customers')
          .select()
          .eq('id', customerId)
          .maybeSingle(); // returns null if no match

      if (customerResponse == null) {
        debugPrint('⚠️ No customer found with ID: $customerId');
        return null;
      }

      // =========================
      // 🔹 2. Fetch related rents
      // Join uints → properties to get unit_number & property_name
      // =========================
      final rentResponse = await supabase
          .from('rent')
          .select('''
            id,
            rent,
            payment_status,
            start_date,
            end_date,
            description,
            created_at,
            uints!left(
              id,
              unit_number,
              prop_id,
              properties!left(name)
            )
          ''')
          .eq('customer_id', customerId)
          .order('created_at', ascending: false);

      // =========================
      // 🔹 3. Fetch related payments
      // Join uints → properties
      // =========================
      final paymentsResponse = await supabase
          .from('payments')
          .select('''
            id,
            amount,
            payment_type,
            created_at,
            uints!left(
              id,
              unit_number,
              prop_id,
              properties!left(name)
            )
          ''')
          .eq('customer_id', customerId)
          .order('created_at', ascending: false);

      // =========================
      // 🔹 4. Convert to CustomerDetailsModel
      // =========================
      return CustomerDetailsModel.fromSupabase(
        customer: customerResponse,
        rents: rentResponse,
        payments: paymentsResponse,
      );
    } catch (e, stack) {
      debugPrint('❌ fetchCustomerDetailsById error: $e');
      debugPrint(stack.toString());
      return null;
    }
  }

  /// Fetch customer details by name (handles multiple customers with same name)
  Future<List<CustomerDetailsModel>> fetchCustomerDetailsByName(String customerName) async {
    try {
      // =========================
      // 🔹 1. Search all customers with the given name
      // =========================
      final customerList = await supabase
          .from('customers')
          .select()
          .eq('name', customerName);

      if (customerList.isEmpty) {
        debugPrint('⚠️ No customer found with name: $customerName');
        return [];
      }

      // =========================
      // 🔹 2. Fetch details for each customer by ID
      // =========================
      final List<CustomerDetailsModel> results = [];
      for (final customer in customerList) {
        final customerId = customer['id'] as int;
        final details = await fetchCustomerDetailsById(customerId);
        if (details != null) results.add(details);
      }

      return results;
    } catch (e, stack) {
      debugPrint('❌ fetchCustomerDetailsByName error: $e');
      debugPrint(stack.toString());
      return [];
    }
  }
}

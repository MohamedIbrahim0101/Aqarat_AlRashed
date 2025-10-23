/// Represents the full customer details including rents and payments.
class CustomerDetailsModel {
  /// Basic customer info
  final Map<String, dynamic> customer;

  /// Customer ID extracted from customer map
  final int customerId; // ✅ أضف هذا الحقل

  /// List of rents associated with the customer
  final List<Map<String, dynamic>> rents;

  /// List of payments associated with the customer
  final List<Map<String, dynamic>> payments;

  CustomerDetailsModel({
    required this.customer,
    required this.customerId, // ✅ أضف في الكونستركتور
    required this.rents,
    required this.payments,
  });

  /// Factory constructor to build a CustomerDetailsModel from Supabase query results
  factory CustomerDetailsModel.fromSupabase({
    required Map<String, dynamic> customer,
    required List rents,
    required List payments,
  }) {
    return CustomerDetailsModel(
      customer: Map<String, dynamic>.from(customer),

      // ✅ استخراج customerId من customer map
      customerId: customer['id'] ?? 0,

      // ========================
      // 🟧 RENTS SECTION
      // ========================
      rents: rents.map<Map<String, dynamic>>((item) {
        final rent = Map<String, dynamic>.from(item);

        // Flatten nested unit & property data
        rent['unit_number'] = rent['uints']?['unit_number'] ?? 'N/A';
        rent['property_name'] = rent['uints']?['properties']?['name'] ?? 'N/A';

        // Parse amounts and status safely
        rent['rent_amount'] = _parseDouble(
            rent['rent'] ?? rent['annul_rent'] ?? rent['rent_amount']);
        rent['payment_status'] = rent['payment_status'] ?? 'Unknown';

        // ✅ Handle dates safely
        rent['created_at'] = rent['created_at']?.toString().split('T').first ?? '-';
        rent['start_date'] = rent['start_date']?.toString().split('T').first ?? '-';
        rent['end_date'] = rent['end_date']?.toString().split('T').first ?? '-';

        // Optional description
        rent['description'] = rent['description'] ?? '-';

        return rent;
      }).toList(),

      // ========================
      // 🟩 PAYMENTS SECTION
      // ========================
      payments: payments.map<Map<String, dynamic>>((item) {
        final payment = Map<String, dynamic>.from(item);

        // Flatten nested unit & property data
        payment['unit_number'] = payment['uints']?['unit_number'] ?? 'N/A';
        payment['property_name'] = payment['uints']?['properties']?['name'] ?? 'N/A';

        // Parse amount safely
        payment['amount'] = _parseDouble(payment['amount']);
        payment['payment_type'] = payment['payment_type'] ?? '-';

        // Dates
        payment['created_at'] = payment['created_at']?.toString().split('T').first ?? '-';

        return payment;
      }).toList(),
    );
  }

  /// Helper method to parse dynamic values to double safely
  static double _parseDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }
}

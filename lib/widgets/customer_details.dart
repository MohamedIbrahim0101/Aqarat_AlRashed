// lib/widgets/customer_details_page.dart

import 'package:flutter/material.dart';
import 'package:my_app/models/customer_model.dart';
import 'package:my_app/services/customer_service.dart';
import 'dart:ui' as fw;

class CustomerDetailsPage extends StatefulWidget {
  final int customerId;

  const CustomerDetailsPage({super.key, required this.customerId});

  @override
  State<CustomerDetailsPage> createState() => _CustomerDetailsPageState();
}

class _CustomerDetailsPageState extends State<CustomerDetailsPage> {
  late Future<CustomerDetailsModel?> _customerFuture;

  @override
  void initState() {
    super.initState();
    _customerFuture = CustomerService().fetchCustomerDetailsById(
      widget.customerId,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: fw.TextDirection.ltr,
      child: Scaffold(
        appBar: AppBar(
          title: const Text(
            'Customer Details',
            style: TextStyle(color: Colors.white),
          ),
          backgroundColor: const Color(0xFF142B49),
        ),
        body: FutureBuilder<CustomerDetailsModel?>(
          future: _customerFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            } else if (snapshot.hasError) {
              return _buildError(snapshot.error.toString());
            } else if (!snapshot.hasData || snapshot.data == null) {
              return const Center(child: Text('No customer data found.'));
            }

            final customer = snapshot.data!;
            return SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildCustomerCard(customer.customer),
                  const SizedBox(height: 30),
                  _buildRentTable(customer.rents),
                  const SizedBox(height: 30),
                  _buildPaymentTable(customer.payments),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildError(String error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, color: Colors.red, size: 50),
          const SizedBox(height: 10),
          Text('Error: $error', textAlign: TextAlign.center),
          const SizedBox(height: 10),
          ElevatedButton(
            onPressed: () {
              setState(() {
                _customerFuture = CustomerService().fetchCustomerDetailsById(
                  widget.customerId,
                );
              });
            },
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildCustomerCard(Map<String, dynamic> data) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Customer Information',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            _buildRow('ID', data['id'].toString()),
            _buildRow('Name', data['name'] ?? 'N/A'),
            _buildRow('Nationality', data['nationality'] ?? 'N/A'),
            _buildRow('Address', data['address'] ?? 'N/A'),
            _buildRow('Phone', data['phone'] ?? 'N/A'),
            _buildRow(
              'Created At',
              data['created_at']?.toString().split('T').first ?? '-',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(child: Text(value, textAlign: TextAlign.left)),
        ],
      ),
    );
  }

  // ✅ Rent table (without description column)
  Widget _buildRentTable(List<Map<String, dynamic>> rents) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Rent Details',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 10),
        Card(
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              headingRowColor: MaterialStateProperty.all(
                const Color(0xFF142B49),
              ),
              headingTextStyle: const TextStyle(color: Colors.white),
              columns: const [
                DataColumn(label: Text('ID')),
                DataColumn(label: Text('Amount')),
                DataColumn(label: Text('Status')),
                DataColumn(label: Text('Start Date')),
                DataColumn(label: Text('End Date')),
                DataColumn(label: Text('Unit')),
                DataColumn(label: Text('Property')),
                DataColumn(label: Text('Created At')),
              ],
              rows: rents.map((rent) {
                return DataRow(
                  cells: [
                    DataCell(Text(rent['id']?.toString() ?? '-')),
                    DataCell(Text(rent['rent_amount']?.toString() ?? '-')),
                    DataCell(Text(rent['payment_status']?.toString() ?? '-')),
                    DataCell(Text(rent['start_date']?.toString() ?? '-')),
                    DataCell(Text(rent['end_date']?.toString() ?? '-')),
                    DataCell(Text(rent['unit_number']?.toString() ?? '-')),
                    DataCell(Text(rent['property_name']?.toString() ?? '-')),
                    DataCell(Text(rent['created_at']?.toString() ?? '-')),
                  ],
                );
              }).toList(),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPaymentTable(List<Map<String, dynamic>> payments) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Payment History',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 10),
        Card(
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              headingRowColor: MaterialStateProperty.all(
                const Color(0xFF142B49),
              ),
              headingTextStyle: const TextStyle(color: Colors.white),
              columns: const [
                DataColumn(label: Text('ID')),
                DataColumn(label: Text('Amount')),
                DataColumn(label: Text('Payment Type')),
                DataColumn(label: Text('Unit')),
                DataColumn(label: Text('Property')),
                DataColumn(label: Text('Created At')),
              ],
              rows: payments.map((p) {
                return DataRow(
                  cells: [
                    DataCell(Text(p['id']?.toString() ?? '-')),
                    DataCell(Text(p['amount']?.toString() ?? '-')),
                    DataCell(Text(p['payment_type']?.toString() ?? '-')),
                    DataCell(Text(p['unit_number']?.toString() ?? '-')),
                    DataCell(Text(p['property_name']?.toString() ?? '-')),
                    DataCell(Text(p['created_at']?.toString() ?? '-')),
                  ],
                );
              }).toList(),
            ),
          ),
        ),
      ],
    );
  }
}

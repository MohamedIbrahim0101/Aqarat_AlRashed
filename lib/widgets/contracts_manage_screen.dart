// lib/widgets/ContractsManageScreen.dart

import 'dart:ui' as fw;
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

// ✅ استيراد النموذج والخدمة
import 'package:my_app/models/contracts_manage_model.dart';
import 'package:my_app/services/contracts_manage_service.dart';
import 'package:my_app/widgets/contract_edit_screen.dart';

// 💡 الألوان والثوابت
import 'package:my_app/widgets/dashboardScreen.dart'
    show primaryBlue, backgroundColor, maxContentWidth;

// ✅ استيراد شاشة التعديل

class ContractsManageScreen extends StatefulWidget {
  final ContractService service;

  const ContractsManageScreen({required this.service, super.key});

  @override
  State<ContractsManageScreen> createState() => _ContractsManageScreenState();
}

class _ContractsManageScreenState extends State<ContractsManageScreen> {
  List<ContractModel> _allContracts = [];
  List<ContractModel> _filteredContracts = [];
  bool _isLoading = true;
  String? _errorMessage;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchContracts();
    _searchController.addListener(_filterContracts);
  }

  @override
  void dispose() {
    _searchController.removeListener(_filterContracts);
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchContracts() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final data = await widget.service.fetchAllContracts();
      setState(() {
        _allContracts = data;
        _filteredContracts = data;
        _isLoading = false;
        _filterContracts();
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'فشل في تحميل العقود: ${e.toString()}';
        _isLoading = false;
      });
      debugPrint('Error fetching contracts: $_errorMessage');
    }
  }

  void _filterContracts() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      if (query.isEmpty) {
        _filteredContracts = _allContracts;
      } else {
        _filteredContracts = _allContracts.where((contract) {
          return contract.unitNumber.toLowerCase().contains(query) ||
              contract.propertyName.toLowerCase().contains(query) ||
              contract.customerName.toLowerCase().contains(query) ||
              contract.description.toLowerCase().contains(query) ||
              contract.contractType.toLowerCase().contains(query);
        }).toList();
      }
    });
  }

  void _showMessage(String title, String content) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(content, textDirection: fw.TextDirection.rtl)),
    );
  }

  Future<void> _deleteContractLogic(ContractModel contract) async {
    setState(() => _isLoading = true);
    try {
      await widget.service.deleteContract(contract.id);
      _showMessage('نجاح', 'تم حذف العقد ID:${contract.id} بنجاح.');
      await _fetchContracts();
    } catch (e) {
      _showMessage('خطأ', 'فشل في حذف العقد: ${e.toString()}');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _confirmDelete(ContractModel contract) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Directionality(
          textDirection: fw.TextDirection.rtl,
          child: AlertDialog(
            title: const Text('تأكيد الحذف'),
            content: Text(
              'هل أنت متأكد من حذف العقد رقم ${contract.id} للوحدة ${contract.unitNumber}؟',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('إلغاء'),
              ),
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  _deleteContractLogic(contract);
                },
                child: const Text(
                  'حذف نهائي',
                  style: TextStyle(color: Colors.red),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _navigateToAddContract() {
    _showMessage('إضافة عقد', 'سيتم فتح شاشة إضافة عقد.');
  }

  // ✅ التعديل الصحيح هنا
  void _navigateToEditContract(ContractModel contract) async {
    final updated = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditContractScreen(contract: contract),
      ),
    );

    if (updated == true) {
      await _fetchContracts();
    }
  }

  // ----------------------------
  // بناء صف الجدول
  // ----------------------------
  DataRow _buildContractRow(ContractModel contract) {
    final currencyFormatter = NumberFormat.currency(
      locale: 'ar',
      symbol: '',
      decimalDigits: 0,
    );

    String formatDate(String dateString) {
      try {
        final date = DateTime.parse(dateString);
        return DateFormat('dd/MM/yyyy').format(date);
      } catch (_) {
        return dateString;
      }
    }

    return DataRow(
      color: MaterialStateProperty.resolveWith<Color?>(
        (states) => contract.id.isEven ? Colors.grey.shade50 : Colors.white,
      ),
      cells: [
        DataCell(Text(contract.id.toString())),
        DataCell(
          Text(
            contract.unitNumber,
            style: const TextStyle(color: primaryBlue, fontWeight: FontWeight.bold),
          ),
        ),
        DataCell(Text(contract.propertyName)),

        // عند الضغط على العميل → يفتح شاشة customer_details
        DataCell(
          InkWell(
            onTap: () {
              Navigator.pushNamed(
                context,
                '/customer_details',
                arguments: contract.customerName,
              );
            },
            child: Text(
              contract.customerName,
              style: const TextStyle(
                color: Colors.blue,
                decoration: TextDecoration.underline,
              ),
            ),
          ),
        ),

        DataCell(Text(formatDate(contract.startDate))),
        DataCell(Text(formatDate(contract.endDate))),
        DataCell(Text(currencyFormatter.format(contract.annualRent))),
        DataCell(Text(formatDate(contract.createdAt.substring(0, 10)))),
        DataCell(Text(contract.description)),
        DataCell(Text(contract.contractType)),

        // ----------------------------
        // أزرار التعديل والحذف فقط
        // ----------------------------
        DataCell(
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: const Icon(Icons.edit, color: primaryBlue),
                onPressed: () => _navigateToEditContract(contract),
                tooltip: 'تعديل العقد',
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline, color: Colors.red),
                onPressed: () => _confirmDelete(contract),
                tooltip: 'حذف العقد',
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ----------------------------
  // واجهة المستخدم
  // ----------------------------
  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: fw.TextDirection.rtl,
      child: Scaffold(
        backgroundColor: backgroundColor,
        appBar: AppBar(
          title: const Text(
            'إدارة العقود',
            style: TextStyle(color: Colors.white),
          ),
          backgroundColor: primaryBlue,
          iconTheme: const IconThemeData(color: Colors.white),
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: maxContentWidth),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildSearchAndActionRow(context),
                  const SizedBox(height: 20),
                  if (_isLoading)
                    const LinearProgressIndicator(color: primaryBlue),
                  if (_errorMessage != null && !_isLoading) _buildErrorWidget(),
                  _buildContractsTable(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSearchAndActionRow(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText:
                  'البحث حسب الوحدة، العقار، العميل، الوصف، أو نوع العقد...',
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide.none,
              ),
              filled: true,
              fillColor: Colors.white,
              contentPadding: const EdgeInsets.symmetric(
                vertical: 0,
                horizontal: 10,
              ),
            ),
            textDirection: fw.TextDirection.rtl,
          ),
        ),
        const SizedBox(width: 10),
        ElevatedButton.icon(
          onPressed: _fetchContracts,
          icon: const Icon(Icons.refresh, color: Colors.white),
          label: const Text('Refresh', style: TextStyle(color: Colors.white)),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blue.shade600,
          ),
        ),
        const SizedBox(width: 10),
        ElevatedButton.icon(
          onPressed: _navigateToAddContract,
          icon: const Icon(Icons.add, color: Colors.white),
          label: const Text(
            'Add Contract',
            style: TextStyle(color: Colors.white),
          ),
          style: ElevatedButton.styleFrom(backgroundColor: primaryBlue),
        ),
      ],
    );
  }

  Widget _buildErrorWidget() {
    return Padding(
      padding: const EdgeInsets.all(15.0),
      child: Text(
        _errorMessage!,
        textAlign: TextAlign.center,
        style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildContractsTable() {
    if (!_isLoading && _filteredContracts.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(20),
        child: Center(
          child: Text(
            'لا توجد عقود متاحة تطابق معايير البحث.',
            style: TextStyle(fontSize: 16, color: Colors.grey),
          ),
        ),
      );
    }

    return Card(
      elevation: 4.0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      clipBehavior: Clip.antiAlias,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: ConstrainedBox(
          constraints: BoxConstraints(
            minWidth: MediaQuery.of(context).size.width - 40,
          ),
          child: DataTable(
            columnSpacing: 25,
            horizontalMargin: 15,
            dataRowMinHeight: 55,
            dataRowMaxHeight: 55,
            headingRowColor: MaterialStateProperty.all(primaryBlue),
            columns: [
              _buildHeader('ID', width: 40),
              _buildHeader('Unit', width: 70),
              _buildHeader('Property', width: 120),
              _buildHeader('Customer', width: 180),
              _buildHeader('Start Date', width: 90),
              _buildHeader('End Date', width: 90),
              _buildHeader('Annual Rent', width: 100),
              _buildHeader('Created At', width: 90),
              _buildHeader('Description', width: 100),
              _buildHeader('Contract Type', width: 100),
              _buildHeader('Operations', width: 120),
            ],
            rows: _filteredContracts
                .map((contract) => _buildContractRow(contract))
                .toList(),
          ),
        ),
      ),
    );
  }

  DataColumn _buildHeader(String title, {double width = 120}) {
    return DataColumn(
      label: SizedBox(
        width: width,
        child: Text(
          title,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
          textAlign: TextAlign.right,
        ),
      ),
    );
  }
}

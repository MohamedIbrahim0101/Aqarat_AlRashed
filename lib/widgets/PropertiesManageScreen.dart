import 'dart:ui' as fw;
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
// افترض أنك وضعت ملف UnitsScreen.dart في نفس المجلد
import 'package:my_app/widgets/unitsScreen.dart'; // ⚠️ يجب إنشاء هذا الملف
import 'package:my_app/dashboardScreen.dart' show primaryBlue, backgroundColor;
import 'package:my_app/models/PropertyService.dart';
import 'package:my_app/models/Propertymodel.dart';

class PropertiesManageScreen extends StatefulWidget {
  final PropertyService service;
  static const double maxContentWidth = 1200.0;

  const PropertiesManageScreen({required this.service, super.key});

  @override
  State<PropertiesManageScreen> createState() => _PropertiesManageScreenState();
}

class _PropertiesManageScreenState extends State<PropertiesManageScreen> {
  List<PropertyDetails> _properties = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchProperties();
  }

  Future<void> _fetchProperties() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final data = await widget.service.fetchAllProperties();
      setState(() {
        _properties = data;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'فشل في تحميل العقارات: ${e.toString()}';
        _isLoading = false;
      });
      print(_errorMessage);
    }
  }

  void _showMessage(String title, String content) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(title, textDirection: fw.TextDirection.rtl),
          content: Text(content, textDirection: fw.TextDirection.rtl),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('حسناً', textDirection: fw.TextDirection.rtl),
            ),
          ],
        );
      },
    );
  }
  
  // 🆕 دالة لمعالجة النقر على عدد الوحدات والانتقال للشاشة الجديدة
  void _onUnitsSelected(PropertyDetails property) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => UnitsScreen(
          property: property,
          service: widget.service,
        ),
      ),
    );
  }

  DataColumn _buildHeader(String title) {
    return DataColumn(
      label: Container(
        padding: const EdgeInsets.symmetric(vertical: 16.0),
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

  DataRow _buildPropertyRow(PropertyDetails property) {
    final currencyFormatter = NumberFormat.currency(
      locale: 'ar',
      symbol: ' د.ك',
      decimalDigits: 3,
    );

    return DataRow(
      color: MaterialStateProperty.resolveWith<Color?>(
        (Set<MaterialState> states) =>
            property.id.isEven ? Colors.grey.shade50 : Colors.white,
      ),
      cells: [
        DataCell(
          Text(
            property.id.toString(),
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
        DataCell(Text(property.name, textDirection: fw.TextDirection.rtl)),
        DataCell(Text(property.ownerName, textDirection: fw.TextDirection.rtl)),
        DataCell(Text(property.address, textDirection: fw.TextDirection.rtl)),
        DataCell(Text(currencyFormatter.format(property.totalValue))),
        // 🆕 تم تعديل خانة الوحدات لتكون قابلة للنقر
        DataCell(
          InkWell(
            onTap: () => _onUnitsSelected(property),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    property.unitsCount.toString(),
                    style: TextStyle(color: primaryBlue, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(width: 4),
                  const Icon(Icons.arrow_forward_ios, size: 14, color: primaryBlue),
                ],
              ),
            ),
          ),
        ),
        DataCell(
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: const Icon(Icons.security, color: primaryBlue),
                onPressed: () {
                  _showMessage('عرض/تعديل', 'تعديل العقار ID: ${property.id}');
                },
                tooltip: 'عرض/تعديل العقار',
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline, color: Colors.red),
                onPressed: () {
                  _showMessage(
                    'حذف',
                    'هل أنت متأكد من حذف العقار ${property.name}؟',
                  );
                },
                tooltip: 'حذف العقار',
              ),
            ],
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: fw.TextDirection.rtl,
      child: Scaffold(
        backgroundColor: backgroundColor,
        appBar: AppBar(
          title: const Text(
            'إدارة العقارات',
            style: TextStyle(color: Colors.white),
          ),
          backgroundColor: primaryBlue,
          iconTheme: const IconThemeData(color: Colors.white),
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                maxWidth: PropertiesManageScreen.maxContentWidth,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // ... (Row of buttons: تحديث, إضافة عقار)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      ElevatedButton.icon(
                        onPressed: _fetchProperties,
                        icon: const Icon(
                          Icons.refresh,
                          color: Colors.white,
                          size: 20,
                        ),
                        label: const Text(
                          'تحديث',
                          style: TextStyle(color: Colors.white),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue.shade600,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 15,
                            vertical: 10,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      ElevatedButton.icon(
                        onPressed: () {
                          _showMessage(
                            'إضافة عقار',
                            'سيتم الانتقال إلى صفحة إضافة عقار جديدة.',
                          );
                        },
                        icon: const Icon(
                          Icons.add,
                          color: Colors.white,
                          size: 20,
                        ),
                        label: const Text(
                          'إضافة عقار',
                          style: TextStyle(color: Colors.white),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryBlue,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 15,
                            vertical: 10,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  // ... (Data Table Card)
                  Card(
                    elevation: 4.0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        if (_isLoading)
                          const LinearProgressIndicator(color: primaryBlue),
                        if (_errorMessage != null && !_isLoading)
                          Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Text(
                              _errorMessage!,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                color: Colors.red,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        if (!_isLoading && _properties.isEmpty)
                          const Padding(
                            padding: EdgeInsets.all(20),
                            child: Center(
                              child: Text(
                                'لا توجد بيانات متاحة حالياً.',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.grey,
                                ),
                              ),
                            ),
                          ),
                        if (_properties.isNotEmpty)
                          SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: ConstrainedBox(
                              constraints: BoxConstraints(
                                minWidth:
                                    MediaQuery.of(context).size.width - 40,
                              ),
                              child: DataTable(
                                columnSpacing: 25,
                                horizontalMargin: 15,
                                dataRowMinHeight: 55,
                                dataRowMaxHeight: 55,
                                headingRowColor: MaterialStateProperty.all(
                                  primaryBlue,
                                ),
                                columns: [
                                  _buildHeader('ID'),
                                  _buildHeader('Name'),
                                  _buildHeader('Owner Name'),
                                  _buildHeader('Address'),
                                  _buildHeader('Total Value'),
                                  _buildHeader('Units'),
                                  _buildHeader('Operations'),
                                ],
                                rows: _properties
                                    .map(
                                      (property) => _buildPropertyRow(property),
                                    )
                                    .toList(),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
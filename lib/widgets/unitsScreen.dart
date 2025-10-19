import 'dart:ui' as fw;
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
// يجب إخفاء UnitDetails من PropertyService لتجنب Ambiguous Import إذا كانت موجودة فيه
import 'package:my_app/models/PropertyService.dart' hide UnitDetails;
import 'package:my_app/models/Propertymodel.dart' show PropertyDetails;
import 'package:my_app/models/UnitDetails.dart'; // ✅ المصدر الوحيد لكلاس UnitDetails
// نستورد الثوابت
import 'package:my_app/dashboardScreen.dart' show primaryBlue, backgroundColor;
import 'package:my_app/widgets/PropertiesManageScreen.dart'
    show PropertiesManageScreen; // لاستخدام maxContentWidth

class UnitsScreen extends StatefulWidget {
  final PropertyDetails property;
  final PropertyService service;

  const UnitsScreen({required this.property, required this.service, super.key});

  @override
  State<UnitsScreen> createState() => _UnitsScreenState();
}

class _UnitsScreenState extends State<UnitsScreen> {
  List<UnitDetails> _units = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchUnits();
  }

  // 🆕 دالة جلب الوحدات
  Future<void> _fetchUnits() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final List<UnitDetails> data = await widget.service
          .fetchUnitsByPropertyId(widget.property.id);

      setState(() {
        _units = data;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'فشل في تحميل الوحدات: ${e.toString()}';
        _isLoading = false;
      });
      print('UnitsScreen Error: $_errorMessage');
    }
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

  DataRow _buildUnitRow(UnitDetails unit) {
    // 💡 تصحيح: استخدام 'KWD' كرمز عملة قياسي
    final currencyFormatter = NumberFormat.currency(
      locale: 'ar',
      symbol: 'د.ك', // عرض رمز العملة بعد التنسيق
      decimalDigits: 3,
    );

    // لإظهار الرمز المائل الأزرق الذي يشير إلى العمليات
    Widget buildActionIcon() {
      return Container(
        height: 24,
        width: 24,
        decoration: BoxDecoration(
          border: Border.all(color: primaryBlue, width: 2.5),
          borderRadius: BorderRadius.circular(4),
        ),
      );
    }

    return DataRow(
      color: MaterialStateProperty.resolveWith<Color?>(
        (Set<MaterialState> states) =>
            unit.id.isEven ? Colors.grey.shade50 : Colors.white,
      ),
      cells: [
        DataCell(Text(unit.id.toString())),
        DataCell(Text(unit.unitNumber)),
        DataCell(Text(currencyFormatter.format(unit.rentAmount))),
        // 🆕 إضافة عرض حقل الحالة
        DataCell(Text(unit.status)),
        DataCell(
          IconButton(
            icon: buildActionIcon(),
            onPressed: () {
              print('Edit unit: ${unit.id}');
              // يمكن إضافة Navigator.push هنا لفتح شاشة تعديل
            },
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
          title: Text(
            'وحدات العقار: ${widget.property.name}',
            textDirection: fw.TextDirection.rtl,
            style: const TextStyle(color: Colors.white),
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
              child: Card(
                elevation: 4.0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                clipBehavior: Clip.antiAlias,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // شريط عنوان الوحدات
                    Container(
                      padding: const EdgeInsets.all(12.0),
                      color: primaryBlue.withOpacity(0.1),
                      child: Text(
                        'الوحدات في ${widget.property.name}',
                        textDirection: fw.TextDirection.rtl,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: primaryBlue,
                        ),
                      ),
                    ),
                    if (_isLoading)
                      const LinearProgressIndicator(color: primaryBlue),
                    if (_errorMessage != null && !_isLoading)
                      Padding(
                        padding: const EdgeInsets.all(15.0),
                        child: Text(
                          _errorMessage!,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Colors.red,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    if (!_isLoading && _units.isEmpty)
                      const Padding(
                        padding: EdgeInsets.all(20),
                        child: Center(
                          child: Text(
                            'لا توجد وحدات مرتبطة بهذا العقار.',
                            style: TextStyle(fontSize: 16, color: Colors.grey),
                          ),
                        ),
                      ),
                    if (_units.isNotEmpty)
                      SingleChildScrollView(
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
                            headingRowColor: MaterialStateProperty.all(
                              primaryBlue,
                            ),
                            columns: [
                              _buildHeader('Unit ID'),
                              _buildHeader('Unit Number'),
                              _buildHeader('Rent Amount (د.ك)'),
                              // 🆕 إضافة عمود الحالة
                              _buildHeader('Status'),
                              _buildHeader('Actions'),
                            ],
                            rows: _units
                                .map((unit) => _buildUnitRow(unit))
                                .toList(),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
        // 🆕 إضافة زر لإضافة وحدة جديدة (اختياري)
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () {
            print('Add new unit for property: ${widget.property.name}');
            // هنا يمكن إضافة منطق فتح شاشة إضافة وحدة جديدة
          },
          label: const Text('Add Unit', style: TextStyle(color: Colors.white)),
          icon: const Icon(Icons.add, color: Colors.white),
          backgroundColor: primaryBlue,
        ),
      ),
    );
  }
}

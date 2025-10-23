// lib/screens/PropertiesManageScreen.dart

import 'dart:ui' as fw;
import 'dart:developer'; 
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
// ⚠️ تأكد من أن مسارات الاستيراد التالية صحيحة في مشروعك:
import 'package:my_app/widgets/AddPropertyScreen.dart' hide backgroundColor, primaryBlue;
import 'package:my_app/widgets/Edit_prperties_screen.dart';
// 👈🏻 هذا الملف يوفّر UnitController
import 'package:my_app/widgets/unit_manage_screen.dart' hide primaryBlue, backgroundColor; 
import 'package:my_app/widgets/unitsScreen.dart'; 
// 💡 افتراض: الألوان مُعرّفة هنا
import 'package:my_app/widgets/dashboardScreen.dart' show primaryBlue, backgroundColor; 
import 'package:my_app/services/PropertyService.dart'; 
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
      log('Error fetching properties: $_errorMessage', name: 'PropertiesManage');
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
  
  // دالة لمعالجة النقر على الصف والانتقال للشاشة الجديدة
  void _onUnitsSelected(PropertyDetails property) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => UnitsScreen(
          // ✅ تم حل مشكلة تضارب الأنواع: UnitController الآن مستورد من unit_manage_screen.dart
          controller: UnitController(), 
          propertyIdFilter: property.id, // 💡 يفضل تمرير فلترة لمعرّف العقار
        ),
      ),
    );
  }
  
  // دالة لمعالجة النقر على زر إضافة عقار
  void _navigateToAddProperty() async { // استخدام async
    final result = await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => AddPropertyScreen(service: widget.service), 
      ),
    );
    // تحديث القائمة بعد إضافة عقار جديد
    if (result == true) { 
      _fetchProperties();
    }
  }

  // 🆕 دالة لمعالجة النقر على زر تعديل عقار والانتقال
  void _navigateToEditProperty(PropertyDetails property) async {
    final result = await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => EditPropertiesScreen( 
          property: property, // تمرير بيانات العقار المراد تعديله
        ),
      ),
    );

    // تحديث القائمة عند العودة من شاشة التعديل إذا تم التعديل بنجاح
    if (result == true) { 
      _fetchProperties();
    }
  }

  // 🆕 دالة تنفيذ عملية الحذف الفعلية
  Future<void> _deletePropertyLogic(int propertyId, String propertyName) async {
    try {
      await widget.service.deleteProperty(propertyId); 
      _showMessage('نجاح', 'تم حذف العقار "$propertyName" بنجاح.');
      // تحديث القائمة بعد الحذف
      _fetchProperties(); 
    } catch (e) {
      _showMessage('خطأ', 'فشل في حذف العقار "$propertyName": ${e.toString()}');
      log('Error deleting property: ${e.toString()}', name: 'PropertiesManage');
    }
  }

  // 🆕 دالة عرض مربع حوار تأكيد الحذف
  void _confirmDelete(PropertyDetails property) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('تأكيد الحذف', textDirection: fw.TextDirection.rtl),
          content: Text('هل أنت متأكد من حذف العقار "${property.name}" نهائياً؟ ستُحذف جميع بياناته من Supabase.', textDirection: fw.TextDirection.rtl),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('إلغاء', textDirection: fw.TextDirection.rtl),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // إغلاق مربع الحوار
                _deletePropertyLogic(property.id, property.name); // بدء عملية الحذف
              },
              child: const Text('حذف نهائي', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold), textDirection: fw.TextDirection.rtl),
            ),
          ],
        );
      },
    );
  }

  DataColumn _buildHeader(String title) {
    return DataColumn(
      label: Text(
        title,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: 14,
        ),
        textDirection: fw.TextDirection.rtl, 
      ),
    );
  }

  // 🔄 الدالة المُعدّلة: إضافة onSelectChanged لجعل الصف كاملاً قابلاً للنقر
  DataRow _buildPropertyRow(PropertyDetails property) {
    final currencyFormatter = NumberFormat.currency(
      locale: 'ar',
      symbol: ' د.ك',
      decimalDigits: 3,
    );

    return DataRow(
      // ✅ تفعيل النقر على الصف للانتقال لشاشة الوحدات
      onSelectChanged: (isSelected) {
        if (isSelected == true) { 
          _onUnitsSelected(property);
        }
      },
      selected: false, 
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
        // ❌ تم إزالة InkWell من حول عدد الوحدات
        DataCell(
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: Text(
              property.unitsCount.toString(),
              style: TextStyle(color: primaryBlue, fontWeight: FontWeight.bold),
              textDirection: fw.TextDirection.rtl,
            ),
          ),
        ),
        DataCell(
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: const Icon(Icons.edit, color: primaryBlue),
                onPressed: () {
                  _navigateToEditProperty(property);
                },
                tooltip: 'عرض/تعديل العقار',
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline, color: Colors.red),
                onPressed: () {
                  _confirmDelete(property);
                },
                tooltip: 'حذف العقار',
              ),
            ],
          ),
          // ✅ منع النقر على خلية العمليات من تفعيل onSelectChanged للصف
          onTap: () {}, 
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
                        onPressed: _navigateToAddProperty, 
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
                                  _buildHeader('الاسم'),
                                  _buildHeader('اسم المالك'),
                                  _buildHeader('العنوان'),
                                  _buildHeader('القيمة الإجمالية'),
                                  _buildHeader('الوحدات'),
                                  _buildHeader('العمليات'),
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
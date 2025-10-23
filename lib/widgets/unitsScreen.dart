// lib/widgets/unitsScreen.dart

import 'dart:ui' as fw;
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:my_app/models/unit_model.dart' show Unit;
import 'package:my_app/widgets/edit_units_screen.dart';
import 'package:my_app/widgets/unit_manage_screen.dart' show UnitController;
import 'package:my_app/widgets/units_add.dart' show AddUnitScreen;
import 'package:my_app/widgets/dashboardScreen.dart'
    show primaryBlue, backgroundColor, maxContentWidth;

class UnitsScreen extends StatefulWidget {
  final UnitController controller;
  final int? propertyIdFilter; // فلترة حسب معرّف العقار

  const UnitsScreen({
    super.key,
    required this.controller,
    this.propertyIdFilter,
  });

  @override
  State<UnitsScreen> createState() => _UnitsScreenState();
}

class _UnitsScreenState extends State<UnitsScreen> {
  Map<String, List<Unit>> _groupedUnits = {};
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchAndGroupUnits();
  }

  Future<void> _fetchAndGroupUnits() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _groupedUnits = {};
    });

    try {
      await widget.controller.fetchUnits(context);
      final allUnits = widget.controller.units;

      // تطبيق الفلترة حسب propertyId إذا موجود
      final unitsToGroup = widget.propertyIdFilter == null
          ? allUnits
          : allUnits
              .where((unit) => unit.propId  == widget.propertyIdFilter)
              .toList();

      // تجميع الوحدات حسب اسم العقار
      final grouped = <String, List<Unit>>{};
      for (var unit in unitsToGroup) {
        grouped.putIfAbsent(unit.propertyName, () => []).add(unit);
      }

      setState(() {
        _groupedUnits = grouped;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'فشل في تحميل الوحدات: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  // رأس الجدول
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

  // أيقونة العمليات
  Widget buildActionIcon() {
    return Container(
      height: 28,
      width: 28,
      decoration: BoxDecoration(
        border: Border.all(color: primaryBlue, width: 1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: const Center(
        child: Icon(Icons.edit, size: 16, color: primaryBlue),
      ),
    );
  }

  // صف الوحدة
  DataRow _buildUnitRow(Unit unit) {
    final currencyFormatter = NumberFormat.currency(
      locale: 'ar',
      symbol: '',
      decimalDigits: 2,
    );

    return DataRow(
      color: MaterialStateProperty.resolveWith<Color?>(
        (states) => unit.id.isEven ? Colors.grey.shade50 : Colors.white,
      ),
      cells: [
        DataCell(Text(unit.id.toString())),
        DataCell(Text(
          unit.unitNumber,
          style: const TextStyle(fontWeight: FontWeight.w600, color: primaryBlue),
        )),
        DataCell(Text(currencyFormatter.format(unit.rentAmount),
            style: const TextStyle(color: Colors.black87))),
        DataCell(
          IconButton(
            icon: buildActionIcon(),
            onPressed: () async {
              final result = await Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) =>
                      EditUnitScreen(controller: widget.controller, unit: unit),
                ),
              );
              if (result == true) _fetchAndGroupUnits();
            },
          ),
        ),
      ],
    );
  }

  // جدول الوحدات
  Widget _buildUnitsDataTable(List<Unit> units) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          minWidth: MediaQuery.of(context).size.width - 60,
        ),
        child: DataTable(
          columnSpacing: 35,
          horizontalMargin: 15,
          dataRowMinHeight: 55,
          dataRowMaxHeight: 55,
          headingRowColor: MaterialStateProperty.all(primaryBlue),
          columns: [
            _buildHeader('ID'),
            _buildHeader('رقم الوحدة'),
            _buildHeader('الإيجار'),
            _buildHeader('العمليات'),
          ],
          rows: units.map((unit) => _buildUnitRow(unit)).toList(),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isFilteredView = widget.propertyIdFilter != null;

    return Directionality(
      textDirection: fw.TextDirection.rtl,
      child: Scaffold(
        backgroundColor: backgroundColor,
        appBar: AppBar(
          title: Text(
            isFilteredView
                ? 'وحدات العقار المحدد'
                : 'جميع الوحدات المجمعة حسب العقار',
            style: const TextStyle(color: Colors.white),
          ),
          backgroundColor: primaryBlue,
          iconTheme: const IconThemeData(color: Colors.white),
        ),
        body: RefreshIndicator(
          onRefresh: _fetchAndGroupUnits,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20.0),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: maxContentWidth),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (_isLoading)
                      const LinearProgressIndicator(color: primaryBlue),
                    if (_errorMessage != null && !_isLoading)
                      Padding(
                        padding: const EdgeInsets.all(15.0),
                        child: Text(
                          _errorMessage!,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                              color: Colors.red, fontWeight: FontWeight.bold),
                        ),
                      ),
                    if (!_isLoading && _groupedUnits.isEmpty)
                      const Padding(
                        padding: EdgeInsets.all(20),
                        child: Center(
                          child: Text(
                            'لا توجد وحدات متاحة.',
                            style: TextStyle(fontSize: 16, color: Colors.grey),
                          ),
                        ),
                      ),
                    if (_groupedUnits.isNotEmpty)
                      ..._groupedUnits.entries.map((entry) {
                        final propertyName = entry.key;
                        final units = entry.value;

                        if (isFilteredView) {
                          return _buildUnitsDataTable(units);
                        }

                        return Card(
                          margin: const EdgeInsets.only(bottom: 16),
                          elevation: 2,
                          child: ExpansionTile(
                            title: Text(
                              'العقار: $propertyName (${units.length} وحدة)',
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold, color: primaryBlue),
                            ),
                            childrenPadding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 0),
                            children: [_buildUnitsDataTable(units)],
                          ),
                        );
                      }).toList(),
                  ],
                ),
              ),
            ),
          ),
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () async {
            final result = await Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => AddUnitScreen(controller: widget.controller),
              ),
            );
            if (result == true) _fetchAndGroupUnits();
          },
          label: const Text('إضافة وحدة', style: TextStyle(color: Colors.white)),
          icon: const Icon(Icons.add, color: Colors.white),
          backgroundColor: primaryBlue,
        ),
      ),
    );
  }
}

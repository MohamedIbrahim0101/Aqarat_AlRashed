// File: units_manage_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
// يجب التأكد من صحة استيراد هذه الملفات (widgets)
import 'package:my_app/widgets/edit_units_screen.dart';
import 'package:my_app/widgets/info_screen.dart'; // ✅ هنا تم استيراد UnitInfoScreen
import 'package:my_app/widgets/units_add.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// 💡 الاستيراد الصحيح لنموذج الوحدة (Unit Model)
import 'package:my_app/models/unit_model.dart';

// --- الثوابت والألوان ---
const String unitsTableName = 'uints'; // افتراض اسم جدول الوحدات
const Color primaryBlue = Color(0xFF142B49);
const Color backgroundColor = Color(0xFFF7F7F7);
const Color accentOrange = Color(0xFFFFA500);

final String supabaseUrl =
    dotenv.env['NEXT_PUBLIC_SUPABASE_URL'] ?? 'SUPABASE_URL';
final String supabaseAnonKey =
    dotenv.env['NEXT_PUBLIC_SUPABASE_ANON_KEY'] ?? 'SUPABASE_ANON_KEY';

// --- 3. المتحكم (Controller) لإدارة منطق الشاشة ---
class UnitController extends ChangeNotifier {
  final SupabaseClient supabase = Supabase.instance.client;
  static const String tableName = unitsTableName;

  // الحالة
  List<Unit> _units = [];
  bool _isLoading = true;
  String _searchQuery = '';
  List<Map<String, dynamic>> _properties = [];

  List<Unit> get units => _units;
  bool get isLoading => _isLoading;
  List<Map<String, dynamic>> get availableProperties => _properties;

  // الوحدات المصفاة بناءً على البحث
  List<Unit> get filteredUnits {
    if (_searchQuery.isEmpty) {
      return _units;
    } else {
      final query = _searchQuery.toLowerCase();
      return _units.where((unit) {
        return unit.unitNumber.toLowerCase().contains(query) ||
            unit.propertyName.toLowerCase().contains(query);
      }).toList();
    }
  }

  void updateSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  void _showSnackbar(
    BuildContext context,
    String title,
    String message,
    Color color,
  ) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('$title: $message', textAlign: TextAlign.right),
          backgroundColor: color,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  // دالة جلب قائمة العقارات
  Future<void> fetchProperties(BuildContext context) async {
    try {
      final response = await supabase
          .from('properties')
          .select('id, name')
          .order('name', ascending: true);

      _properties = (response as List<dynamic>)
          .map((e) => {'id': e['id'] as int, 'name': e['name'] as String})
          .toList();
    } on PostgrestException catch (e) {
      debugPrint('Supabase Error fetching properties: ${e.message}');
    } catch (error) {
      debugPrint('General Error fetching properties: $error');
    }
    notifyListeners();
  }

  // دالة جلب الوحدات من Supabase
  Future<void> fetchUnits(BuildContext context) async {
    _isLoading = true;
    _searchQuery = '';
    notifyListeners();

    try {
      final response = await supabase
          .from(tableName)
          .select(
            // ✅ الاستعلام الصحيح لربط اسم العقار
            'id, unit_number, prop_id, rent_amount, properties!uints_prop_id_fkey(name)',
          )
          .order('id', ascending: true);

      final List<dynamic> responseList = (response is List) ? response : [];

      final fetchedUnits = responseList.map((map) {
        final Map<String, dynamic> unitData = map as Map<String, dynamic>;

        String propertyName = 'N/A';
        if (unitData.containsKey('properties') &&
            unitData['properties'] is Map) {
          propertyName =
              (unitData['properties'] as Map<String, dynamic>)['name'] ?? 'N/A';
        }

        final Map<String, dynamic> fullUnitJson = {
          ...unitData,
          'property_name': propertyName,
        };

        // يتم استخدام Unit.fromJson من ملف unit_model.dart
        return Unit.fromJson(fullUnitJson);
      }).toList();

      _units = fetchedUnits;
    } on PostgrestException catch (e) {
      debugPrint('Supabase Error fetching units: ${e.message}');
      _showSnackbar(
        context,
        'خطأ في قاعدة البيانات',
        'فشل الجلب: ${e.message}',
        Colors.red.shade400,
      );
      _units = [];
    } catch (error) {
      debugPrint('General Error fetching units: $error');
      _showSnackbar(
        context,
        'خطأ عام',
        'حدث خطأ أثناء جلب البيانات.',
        Colors.red.shade400,
      );
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // دالة إضافة وحدة جديدة
  Future<void> addUnit(BuildContext context, Unit newUnit) async {
    try {
      // نستخدم دالة toJson() المعرفة في ملف unit_model.dart
      final payload = newUnit.toJson();

      final response = await supabase
          .from(tableName)
          .insert(payload)
          .select(
            'id, unit_number, prop_id, rent_amount, properties!uints_prop_id_fkey(name)',
          )
          .single();

      // تحديث القائمة المحلية
      final Map<String, dynamic> responseMap = response as Map<String, dynamic>;
      String propertyName =
          (responseMap['properties'] as Map<String, dynamic>)['name'] ?? 'N/A';
      final Map<String, dynamic> fullUnitJson = {
        ...responseMap,
        'property_name': propertyName,
      };

      _units.add(Unit.fromJson(fullUnitJson));
      notifyListeners();

      if (context.mounted) Navigator.of(context).pop();

      _showSnackbar(
        context,
        'نجاح',
        'تمت إضافة الوحدة بنجاح.',
        Colors.green.shade400,
      );
    } on PostgrestException catch (e) {
      _showSnackbar(
        context,
        'خطأ في الإضافة',
        'فشل الإضافة: ${e.message}',
        Colors.red.shade400,
      );
    }
  }

  // دالة تعديل وحدة موجودة
  Future<void> updateUnit(BuildContext context, Unit updatedUnit) async {
    try {
      // نستخدم دالة toJson() المعرفة في ملف unit_model.dart
      final payload = updatedUnit.toJson();

      await supabase.from(tableName).update(payload).eq('id', updatedUnit.id);

      // تحديث الوحدة في القائمة المحلية
      final index = _units.indexWhere((u) => u.id == updatedUnit.id);
      if (index != -1) {
        // استخدام قائمة الخصائص المجلوبة (أو الاسم القديم في حال عدم العثور)
        final newPropName = _properties.firstWhere(
          (p) => p['id'] == updatedUnit.propId,
          orElse: () => {'name': updatedUnit.propertyName},
        )['name'];

        _units[index] = Unit(
          id: updatedUnit.id,
          unitNumber: updatedUnit.unitNumber,
          propId: updatedUnit.propId,
          propertyName: newPropName as String,
          rentAmount: updatedUnit.rentAmount,
        );
      }
      notifyListeners();

      _showSnackbar(
        context,
        'نجاح',
        'تم تحديث الوحدة بنجاح.',
        Colors.green.shade400,
      );
    } on PostgrestException catch (e) {
      _showSnackbar(
        context,
        'خطأ في التحديث',
        'فشل التحديث: ${e.message}',
        Colors.red.shade400,
      );
    }
  }

  // دالة حذف وحدة
  Future<void> deleteUnit(BuildContext context, int id) async {
    try {
      await supabase.from(tableName).delete().eq('id', id);

      _units.removeWhere((unit) => unit.id == id);
      notifyListeners();
      _showSnackbar(context, 'حذف', 'تم حذف الوحدة.', Colors.red.shade400);
    } on PostgrestException catch (e) {
      _showSnackbar(
        context,
        'خطأ في الحذف',
        'فشل الحذف: ${e.message}',
        Colors.red.shade400,
      );
    }
  }
}

// --- 4. شاشة إدارة الوحدات الرئيسية ---
class UnitsManageScreen extends StatefulWidget {
  const UnitsManageScreen({super.key});

  @override
  State<UnitsManageScreen> createState() => _UnitsManageScreenState();
}

class _UnitsManageScreenState extends State<UnitsManageScreen> {
  late final UnitController controller;

  @override
  void initState() {
    super.initState();
    controller = UnitController();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      controller.fetchUnits(context);
      // جلب قائمة العقارات عند تهيئة الشاشة
      controller.fetchProperties(context);
    });
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  // الدالة الجديدة للتنقل إلى شاشة الإضافة (Add Navigation)
  void _navigateToAddUnit(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        // يجب أن يتم استيراد AddUnitScreen وتمرير المتحكم إليه
        builder: (context) => AddUnitScreen(controller: controller),
      ),
    );
  }

  // الدالة الجديدة للتنقل إلى شاشة التعديل (Edit Navigation)
  void _navigateToEditUnit(BuildContext context, Unit unit) {
    Navigator.of(context).push(
      MaterialPageRoute(
        // الاستدعاء الفعلي لشاشة التعديل الخارجية وتمرير الوحدة والمتحكم
        builder: (context) =>
            EditUnitScreen(unit: unit, controller: controller),
      ),
    );
  }

  // ✅ الدالة التي تستدعي شاشة UnitInfoScreen
  void _navigateToInfoUnit(BuildContext context, Unit unit) {
    Navigator.of(context).push(
      MaterialPageRoute(
        // تم تمرير unitId: unit.id بدلاً من كائن الوحدة بالكامل (unit: unit)
        builder: (context) => UnitInfoScreen(unitId: unit.id),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: backgroundColor,
        appBar: AppBar(
          title: const Text(
            'إدارة الوحدات',
            style: TextStyle(color: primaryBlue, fontWeight: FontWeight.bold),
          ),
          centerTitle: true,
          backgroundColor: Colors.white,
          elevation: 0,
          iconTheme: const IconThemeData(color: primaryBlue),
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 8.0),
                child: Text(
                  'لوحة تحكم الوحدات العقارية',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: primaryBlue,
                  ),
                ),
              ),
              Container(
                width: 150,
                height: 3,
                color: accentOrange,
                margin: const EdgeInsets.only(bottom: 20),
              ),
              _buildActionButtons(context),
              const SizedBox(height: 15),
              _buildSearchBar(),
              const SizedBox(height: 20),
              AnimatedBuilder(
                animation: controller,
                builder: (context, child) {
                  return _buildUnitsTable(context, controller);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  // بناء صف أزرار الإجراءات
  Widget _buildActionButtons(BuildContext context) {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      alignment: WrapAlignment.start,
      children: [
        // زر التحديث
        _buildActionButton(
          label: 'تحديث',
          icon: Icons.refresh_rounded,
          color: primaryBlue.withOpacity(0.9),
          onPressed: () {
            controller.fetchUnits(context);
            controller.fetchProperties(context);
          },
          isOutline: true,
        ),
        // زر إضافة وحدة
        _buildActionButton(
          label: 'إضافة وحدة',
          icon: Icons.add_circle_outline,
          color: primaryBlue,
          // تم التغيير لاستخدام شاشة التنقل الجديدة
          onPressed: () => _navigateToAddUnit(context),
        ),
        // زر تصدير الوحدات
        _buildActionButton(
          label: 'تصدير الوحدات',
          icon: Icons.cloud_download_outlined,
          color: primaryBlue.withOpacity(0.9),
          onPressed: () => controller._showSnackbar(
            context,
            'تصدير',
            'تم تصدير البيانات.',
            Colors.amber.shade400,
          ),
          isOutline: true,
        ),
      ],
    );
  }

  // مكون زر الإجراءات المخصص
  Widget _buildActionButton({
    required String label,
    required IconData icon,
    required Color color,
    required VoidCallback onPressed,
    bool isOutline = false,
  }) {
    final style = ElevatedButton.styleFrom(
      foregroundColor: isOutline ? color : Colors.white,
      backgroundColor: isOutline ? Colors.blue.shade50 : color,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: isOutline ? BorderSide(color: color, width: 1) : BorderSide.none,
      ),
      elevation: isOutline ? 0 : 4,
    );

    return ElevatedButton.icon(
      onPressed: onPressed,
      style: style,
      icon: Icon(icon, size: 20),
      label: Text(label, style: const TextStyle(fontSize: 14)),
    );
  }

  // بناء حقل البحث
  Widget _buildSearchBar() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 5,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: TextField(
        textAlign: TextAlign.right,
        onChanged: (value) => controller.updateSearchQuery(value),
        decoration: InputDecoration(
          hintText: 'البحث برقم الوحدة أو اسم العقار...',
          hintStyle: TextStyle(color: Colors.grey.shade500),
          prefixIcon: const Icon(Icons.search, color: primaryBlue),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 10,
            vertical: 15,
          ),
        ),
      ),
    );
  }

  // بناء جدول عرض الوحدات
  Widget _buildUnitsTable(BuildContext context, UnitController controller) {
    if (controller.isLoading) {
      return const Center(
        heightFactor: 5,
        child: CircularProgressIndicator(color: primaryBlue),
      );
    }

    final units = controller.filteredUnits;

    if (units.isEmpty) {
      return Center(
        heightFactor: 5,
        child: Text(
          controller._searchQuery.isEmpty
              ? 'لا توجد وحدات لعرضها.'
              : 'لا توجد نتائج للبحث.',
          style: const TextStyle(fontSize: 18, color: Colors.grey),
          textAlign: TextAlign.center,
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 2,
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      // Scrollable horizontally to prevent overflow
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        // استخدام ConstrainedBox لضمان أن الجدول يملأ عرض الشاشة
        child: ConstrainedBox(
          constraints: BoxConstraints(
            minWidth:
                MediaQuery.of(context).size.width -
                32, // عرض الشاشة - الـ Padding
          ),
          child: DataTable(
            headingRowColor: WidgetStateProperty.resolveWith(
              (states) => primaryBlue,
            ),
            headingTextStyle: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 13,
            ),
            dataRowHeight: 60,
            columns: const [
              DataColumn(label: Text('رقم الوحدة')),
              DataColumn(label: Text('اسم العقار')),
              DataColumn(label: Text('مبلغ الإيجار')),
              DataColumn(label: Text('العمليات')),
            ],
            rows: units.map((unit) {
              return DataRow(
                color: WidgetStateProperty.resolveWith(
                  (index) => units.indexOf(unit) % 2 == 0
                      ? Colors.white
                      : Colors.blue.shade50.withOpacity(0.3),
                ),
                cells: [
                  DataCell(
                    Text(
                      unit.unitNumber,
                      style: const TextStyle(
                        color: primaryBlue,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  DataCell(Text(unit.propertyName)),
                  DataCell(Text('${unit.rentAmount.toStringAsFixed(2)} ')),
                  DataCell(_buildOperationIcons(context, unit)),
                ],
              );
            }).toList(),
          ),
        ),
      ),
    );
  }

  // بناء أيقونات العمليات
  Widget _buildOperationIcons(BuildContext context, Unit unit) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // ✅ أيقونة المعلومات (Info Icon)
        _buildIcon(
          icon: Icons.info_outline,
          color: Colors.blue.shade800,
          onTap: () =>
              _navigateToInfoUnit(context, unit), // استدعاء شاشة UnitInfoScreen
        ),
        const SizedBox(width: 8),
        // أيقونة التعديل
        _buildIcon(
          icon: Icons.edit_outlined,
          color: Colors.blue.shade600,
          // استخدام دالة التنقل المصححة
          onTap: () => _navigateToEditUnit(context, unit),
        ),
        const SizedBox(width: 8),
        // أيقونة الحذف
        _buildIcon(
          icon: Icons.delete_outline,
          color: Colors.red.shade600,
          onTap: () => _showDeleteConfirmation(context, unit),
        ),
      ],
    );
  }

  // بناء أيقونة العملية
  Widget _buildIcon({
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: color, size: 20),
      ),
    );
  }

  // إظهار نموذج تأكيد الحذف
  void _showDeleteConfirmation(BuildContext context, Unit unit) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: AlertDialog(
            title: const Text(
              'تأكيد الحذف',
              style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
            ),
            content: Text(
              'هل أنت متأكد من أنك تريد حذف الوحدة رقم ${unit.unitNumber}؟ لا يمكن التراجع عن هذا الإجراء.',
              style: const TextStyle(fontSize: 16),
            ),
            actions: [
              OutlinedButton(
                onPressed: () => Navigator.of(dialogContext).pop(),
                style: OutlinedButton.styleFrom(
                  foregroundColor: primaryBlue,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 10,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text('إلغاء'),
              ),
              ElevatedButton(
                onPressed: () {
                  // استدعاء دالة الحذف التي تتصل بـ Supabase
                  controller.deleteUnit(context, unit.id);
                  Navigator.of(dialogContext).pop();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 10,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text('حذف', style: TextStyle(color: Colors.white)),
              ),
            ],
            actionsPadding: const EdgeInsets.all(20),
          ),
        );
      },
    );
  }
}
// تم حذف _inputDecoration لأنه لم يعد يستخدم مباشرة في هذا الـ Widget
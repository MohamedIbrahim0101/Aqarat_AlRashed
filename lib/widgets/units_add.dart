import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:my_app/models/unit_model.dart';
import 'package:my_app/widgets/unit_manage_screen.dart'; // يحتوي على UnitController

// 🎨 ألوان التطبيق
const Color primaryBlue = Color(0xFF142B49);
const Color backgroundColor = Color(0xFFF7F7F7);
const Color accentOrange = Color(0xFFFFA500);

// 🧩 دالة مساعدة لعرض التنبيهات
void showAppSnackbar(
BuildContext context,
String title,
String message,
Color color,
) {
if (!context.mounted) return;
ScaffoldMessenger.of(context).showSnackBar(
SnackBar(
backgroundColor: color,
behavior: SnackBarBehavior.floating,
duration: const Duration(seconds: 3),
content: Directionality(
textDirection: TextDirection.rtl,
child: Column(
crossAxisAlignment: CrossAxisAlignment.start,
mainAxisSize: MainAxisSize.min,
children: [
Text(
title,
style: const TextStyle(
fontWeight: FontWeight.bold,
fontSize: 16,
color: Colors.white,
),
),
Text(message, style: const TextStyle(color: Colors.white)),
],
),
),
),
);
}

class AddUnitScreen extends StatefulWidget {
final UnitController controller;
const AddUnitScreen({super.key, required this.controller});

@override
State<AddUnitScreen> createState() => _AddUnitScreenState();
}

class _AddUnitScreenState extends State<AddUnitScreen> {
final _formKey = GlobalKey<FormState>();

String _unitNumber = '';
double _rentAmount = 0.0;
int? _selectedPropId;
bool _isSaving = false;

@override
void initState() {
super.initState();
try {
if (widget.controller.availableProperties.isEmpty) {
widget.controller.fetchProperties(context);
}
} catch (e) {
debugPrint('❌ Error fetching properties: $e');
}
}

InputDecoration _inputDecoration(String label) {
return InputDecoration(
labelText: label,
labelStyle: TextStyle(color: primaryBlue.withOpacity(0.8)),
contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
border: OutlineInputBorder(
borderRadius: BorderRadius.circular(10),
borderSide: BorderSide(color: Colors.grey.shade300),
),
focusedBorder: const OutlineInputBorder(
borderRadius: BorderRadius.all(Radius.circular(10)),
borderSide: BorderSide(color: primaryBlue, width: 2),
),
);
}

Future<void> _submitForm() async {
if (!_formKey.currentState!.validate() || _isSaving) return;

_formKey.currentState!.save();

if (_selectedPropId == null || _selectedPropId == 0) {
  showAppSnackbar(
    context,
    'خطأ في الإدخال',
    'الرجاء اختيار عقار.',
    Colors.red,
  );
  return;
}

setState(() => _isSaving = true);

try {
  // ✅ البحث الآمن داخل قائمة العقارات
  final property = widget.controller.availableProperties.firstWhere(
    (p) => p['id'] == _selectedPropId,
    orElse: () => <String, Object>{},
  );

  if (property.isEmpty) {
    showAppSnackbar(context, 'خطأ', 'العقار المحدد غير موجود.', Colors.red);
    setState(() => _isSaving = false);
    return;
  }

  // ✅ إنشاء كائن الوحدة الجديدة مطابق لهيكل جدول uints
  final newUnit = Unit(
    id: 0,
    unitNumber: _unitNumber,
    propId: _selectedPropId!,
    propertyName: property['name'] ?? 'غير معروف',
    rentAmount: _rentAmount,
  );

  // ✅ حفظ في Supabase
  await widget.controller.addUnit(context, newUnit);

  showAppSnackbar(
    context,
    'تم بنجاح',
    'تمت إضافة الوحدة بنجاح.',
    Colors.green,
  );

if (context.mounted) {
  // ✅ بعد الإضافة الناجحة، تحديث البيانات والانتقال إلى شاشة الوحدات
  await widget.controller.fetchUnits(context);
  Navigator.of(context).pushReplacement(
    MaterialPageRoute(
      builder: (_) => UnitsManageScreen(),
    ),
  );
}
} catch (e, s) {
  debugPrint('❌ General error in _submitForm: $e\n$s');
  showAppSnackbar(context, 'خطأ', 'حدث خطأ أثناء التنفيذ: $e', Colors.red);
} finally {
  if (mounted) setState(() => _isSaving = false);
}

}

@override
Widget build(BuildContext context) {
return Directionality(
textDirection: TextDirection.rtl,
child: Scaffold(
backgroundColor: backgroundColor,
appBar: AppBar(
title: const Text(
'إضافة وحدة جديدة',
style: TextStyle(color: primaryBlue, fontWeight: FontWeight.bold),
),
backgroundColor: Colors.white,
centerTitle: true,
iconTheme: const IconThemeData(color: primaryBlue),
),
body: Padding(
padding: const EdgeInsets.all(16.0),
child: SingleChildScrollView(
child: Form(
key: _formKey,
child: Column(
crossAxisAlignment: CrossAxisAlignment.start,
children: [
const SizedBox(height: 20),

              // 🏢 رقم الوحدة
              TextFormField(
                textDirection: TextDirection.rtl,
                textAlign: TextAlign.right,
                decoration: _inputDecoration('رقم الوحدة *'),
                onSaved: (val) => _unitNumber = val!.trim(),
                validator: (val) =>
                    val!.trim().isEmpty ? 'الرجاء إدخال رقم الوحدة' : null,
              ),
              const SizedBox(height: 15),

              // 🏠 اختيار العقار
              ListenableBuilder(
                listenable: widget.controller,
                builder: (context, child) {
                  final props =
                      widget.controller.availableProperties.cast<Map<String, dynamic>>();
                  return DropdownButtonFormField<int>(
                    value: _selectedPropId,
                    decoration: _inputDecoration('اسم العقار *'),
                    hint: const Text('اختر العقار'),
                    items: props
                        .map<DropdownMenuItem<int>>(
                          (p) => DropdownMenuItem<int>(
                            value: p['id'] as int,
                            child: Text(p['name'] as String),
                          ),
                        )
                        .toList(),
                    onChanged: (val) => setState(() {
                      _selectedPropId = val;
                    }),
                    validator: (val) =>
                        val == null || val == 0 ? 'اختر العقار' : null,
                  );
                },
              ),
              const SizedBox(height: 15),

              // 💰 مبلغ الإيجار الشهري (rent_amount)
              TextFormField(
                textDirection: TextDirection.rtl,
                textAlign: TextAlign.right,
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.allow(
                    RegExp(r'^\d+\.?\d{0,2}'),
                  ),
                ],
                decoration: _inputDecoration('مبلغ الإيجار الشهري *'),
                onSaved: (val) =>
                    _rentAmount = double.tryParse(val!.trim()) ?? 0.0,
                validator: (val) {
                  if (val!.trim().isEmpty) {
                    return 'الرجاء إدخال مبلغ الإيجار';
                  }
                  final parsed = double.tryParse(val.trim());
                  if (parsed == null || parsed <= 0) {
                    return 'الرجاء إدخال قيمة صحيحة موجبة';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 30),

              _buildActionButtons(context),
            ],
          ),
        ),
      ),
    ),
  ),
);

}

// 🎯 أزرار الإجراءات (إلغاء / حفظ)
Widget _buildActionButtons(BuildContext context) {
return Row(
children: [
Expanded(
child: OutlinedButton(
onPressed: _isSaving ? null : () => Navigator.pop(context),
style: OutlinedButton.styleFrom(
foregroundColor: primaryBlue,
padding: const EdgeInsets.symmetric(vertical: 15),
shape: RoundedRectangleBorder(
borderRadius: BorderRadius.circular(10),
),
side: const BorderSide(color: primaryBlue),
),
child: const Text('إلغاء'),
),
),
const SizedBox(width: 15),
Expanded(
child: ElevatedButton(
onPressed: _isSaving ? null : _submitForm,
style: ElevatedButton.styleFrom(
backgroundColor: primaryBlue,
padding: const EdgeInsets.symmetric(vertical: 15),
shape: RoundedRectangleBorder(
borderRadius: BorderRadius.circular(10),
),
),
child: _isSaving
? const SizedBox(
width: 24,
height: 24,
child: CircularProgressIndicator(
color: Colors.white,
strokeWidth: 3,
),
)
: const Text(
'إضافة الوحدة',
style: TextStyle(color: Colors.white, fontSize: 16),
),
),
),
],
);
}
}

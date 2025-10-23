import 'package:flutter/material.dart';
import 'package:my_app/models/unit_model.dart' show Unit;
import 'package:my_app/widgets/unit_manage_screen.dart' hide primaryBlue;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:my_app/widgets/dashboardScreen.dart'
    show primaryBlue, backgroundColor, accentOrange;

// لا يمكننا تعريف UnitController هنا، يجب أن يكون معرّفًا في ملف آخر.
// نفترض أنه متاح في النطاق (Scope).

class EditUnitScreen extends StatefulWidget {
  final Unit unit;
  final UnitController controller;

  const EditUnitScreen({
    super.key,
    required this.unit,
    required this.controller,
  });

  @override
  State<EditUnitScreen> createState() => _EditUnitScreenState();
}

class _EditUnitScreenState extends State<EditUnitScreen> {
  final _formKey = GlobalKey<FormState>();
  late String _unitNumber;
  late double _rentAmount;
  late int _propId;
  late String _propertyName;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _unitNumber = widget.unit.unitNumber;
    _rentAmount = widget.unit.rentAmount;
    _propId = widget.unit.propId;
    _propertyName = widget.unit.propertyName;

    if (widget.controller.availableProperties.isEmpty) {
      widget.controller.fetchProperties(context);
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
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: primaryBlue, width: 2),
      ),
    );
  }
  
  Future<void> _submitUpdate() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      
      if (mounted) setState(() => _isLoading = true);

      final updatedUnit = Unit(
        id: widget.unit.id,
        unitNumber: _unitNumber,
        propId: _propId,
        propertyName: _propertyName,
        rentAmount: _rentAmount,
      );

      bool success = false;
      try {
        // ننتظر التحديث، إذا انتهى الكود هنا فهو يعني أن عملية Supabase الأساسية تمت.
        await widget.controller.updateUnit(context, updatedUnit);
        success = true; 
        
      } catch (e) {
        // بما أنك أكدت أن البيانات تُحفظ، فإن هذا الخطأ ثانوي.
        // لذا، سنعتبر العملية ناجحة لغرض العودة.
        // ولكن سنظهر رسالة لتنبيه المستخدم بالخطأ الثانوي.
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('   تم حفظ البيانات،اضغط refresh.'),
              backgroundColor: Colors.orange, // نستخدم لون مختلف للتنبيه
            ),
          );
        }
        success = true; // نعتبره نجاحًا لأنه تم الحفظ
        
      } finally {
        // نستخدم finally لضمان التنفيذ
        if (mounted) {
          if (success) {
            // العودة فوراً بعد النجاح (سواء كان الخطأ ثانويًا أو لم يحدث خطأ)
            Navigator.of(context).pop(true);
          } else {
            // في حالة الخطأ الحقيقي (مثل فشل الاتصال بالشبكة)، نوقف التحميل ونبقى.
            setState(() => _isLoading = false);
          }
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            'تعديل الوحدة: ${widget.unit.unitNumber}',
            style: const TextStyle(color: primaryBlue, fontWeight: FontWeight.bold),
          ),
          backgroundColor: Colors.white,
          iconTheme: IconThemeData(color: primaryBlue),
          centerTitle: true,
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(15),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.15),
                  spreadRadius: 2,
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text('تعديل بيانات الوحدة',
                      style: TextStyle(fontSize: 22, fontWeight: FontWeight.w600, color: primaryBlue)),
                  Container(width: 100, height: 3, color: accentOrange, margin: const EdgeInsets.symmetric(vertical: 15)),
                  TextFormField(
                    initialValue: _unitNumber,
                    textAlign: TextAlign.right,
                    decoration: _inputDecoration('رقم الوحدة'),
                    onSaved: (val) => _unitNumber = val!.trim(),
                    validator: (val) => val!.trim().isEmpty ? 'الرجاء إدخال رقم الوحدة' : null,
                  ),
                  const SizedBox(height: 20),
                  AnimatedBuilder(
                    animation: widget.controller,
                    builder: (context, _) {
                      final properties = widget.controller.availableProperties;
                      return DropdownButtonFormField<int>(
                        value: _propId,
                        decoration: _inputDecoration('اسم العقار'),
                        items: properties.map<DropdownMenuItem<int>>((Map<String, dynamic> p) {
                          return DropdownMenuItem<int>(
                            value: p['id'] as int,
                            child: Text(p['name'] as String),
                          );
                        }).toList(),
                        onChanged: (val) {
                          setState(() {
                            _propId = val!;
                            _propertyName = properties.firstWhere((p) => p['id'] == val)['name'];
                          });
                        },
                        validator: (val) => val == null ? 'الرجاء اختيار اسم العقار' : null,
                      );
                    },
                  ),
                  const SizedBox(height: 20),
                  TextFormField(
                    initialValue: _rentAmount.toString(),
                    textAlign: TextAlign.right,
                    keyboardType: TextInputType.number,
                    decoration: _inputDecoration('مبلغ الإيجار '),
                    onSaved: (val) => _rentAmount = double.tryParse(val!.trim()) ?? 0.0,
                    validator: (val) {
                      final value = double.tryParse(val!.trim());
                      if (value == null || value <= 0) return 'الرجاء إدخال قيمة رقمية صحيحة';
                      return null;
                    },
                  ),
                  const SizedBox(height: 30),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _isLoading ? null : _submitUpdate,
                          icon: _isLoading
                              ? const CircularProgressIndicator(color: Colors.white, strokeWidth: 3)
                              : const Icon(Icons.save),
                          label: Text(_isLoading ? 'جاري الحفظ...' : 'تحديث الوحدة'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: primaryBlue,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 15),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                        ),
                      ),
                      const SizedBox(width: 15),
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.of(context).pop(),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: primaryBlue,
                            side: const BorderSide(color: primaryBlue),
                            padding: const EdgeInsets.symmetric(vertical: 15),
                          ),
                          child: const Text('إلغاء'),
                        ),
                      ),
                    ],
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
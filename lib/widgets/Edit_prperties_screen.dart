import 'dart:ui' as fw;
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:my_app/models/Propertymodel.dart';
import 'package:my_app/widgets/dashboardScreen.dart' show primaryBlue, backgroundColor;

class EditPropertiesScreen extends StatefulWidget {
  final PropertyDetails property;

  const EditPropertiesScreen({required this.property, super.key});

  @override
  State<EditPropertiesScreen> createState() => _EditPropertiesScreenState();
}

class _EditPropertiesScreenState extends State<EditPropertiesScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _addressController;
  late TextEditingController _ownerIdController;
  bool _isSaving = false;

  final SupabaseClient supabase = Supabase.instance.client;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.property.name);
    _addressController = TextEditingController(text: widget.property.address);
    _ownerIdController = TextEditingController(text: widget.property.ownerId.toString());
  }

  @override
  void dispose() {
    _nameController.dispose();
    _addressController.dispose();
    _ownerIdController.dispose();
    super.dispose();
  }

  Future<void> _updateProperty() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    final propertyId = widget.property.id;
    final newName = _nameController.text.trim();
    final newAddress = _addressController.text.trim();
    final newOwnerId = int.tryParse(_ownerIdController.text.trim());

    if (newOwnerId == null) {
      _showSnackBar('خطأ: معرّف المالك يجب أن يكون رقماً صحيحاً.');
      setState(() => _isSaving = false);
      return;
    }

    try {
      // النسخة الحديثة: update بدون execute()
      final response = await supabase
          .from('properties')
          .update({
            'name': newName,
            'address': newAddress,
            'owner_id': newOwnerId,
          })
          .eq('id', propertyId)
          .select() // 👈 للحصول على البيانات بعد التحديث
          .maybeSingle(); // 👈 تعطيك object واحد أو null

      print('Response: $response');

      if (response == null) {
        _showSnackBar('لم يتم العثور على العقار للتحديث.');
        setState(() => _isSaving = false);
        return;
      }

      _showSnackBar('تم تحديث العقار بنجاح! 🎉');
      Navigator.of(context).pop(true);

    } on PostgrestException catch (e) {
      print('PostgrestException: ${e.message}');
      _showSnackBar('فشل التحديث: ${e.message}');
      setState(() => _isSaving = false);

    } catch (e) {
      print('Exception: $e');
      _showSnackBar('حدث خطأ غير متوقع: $e');
      setState(() => _isSaving = false);
    }
  }

  void _showSnackBar(String message) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message, textDirection: fw.TextDirection.rtl),
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: fw.TextDirection.rtl,
      child: Scaffold(
        backgroundColor: backgroundColor,
        appBar: AppBar(
          title: Text('تعديل العقار: ${widget.property.name}', style: const TextStyle(color: Colors.white)),
          backgroundColor: primaryBlue,
          iconTheme: const IconThemeData(color: Colors.white),
        ),
        body: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 600),
              child: Card(
                elevation: 4.0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text(
                          'تعديل خصائص العقار',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: primaryBlue),
                        ),
                        const Divider(height: 30, color: Colors.orange),
                        _buildTextFormField(controller: _nameController, label: 'اسم العقار:', validatorMessage: 'الرجاء إدخال اسم العقار'),
                        const SizedBox(height: 15),
                        _buildTextFormField(controller: _addressController, label: 'العنوان:', validatorMessage: 'الرجاء إدخال العنوان'),
                        const SizedBox(height: 15),
                        _buildTextFormField(
                          controller: _ownerIdController,
                          label: 'معرّف المالك (Owner ID):',
                          keyboardType: TextInputType.number,
                          validatorMessage: 'الرجاء إدخال معرّف المالك (رقم)',
                          isNumber: true,
                        ),
                        const SizedBox(height: 30),
                        Row(
                          children: [
                            Expanded(
                              child: ElevatedButton(
                                onPressed: _isSaving ? null : _updateProperty,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: primaryBlue,
                                  padding: const EdgeInsets.symmetric(vertical: 15),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                ),
                                child: _isSaving
                                    ? const SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3),
                                      )
                                    : const Text('تحديث العقار', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: TextButton(
                                onPressed: () => Navigator.of(context).pop(),
                                style: TextButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 15)),
                                child: const Text('إلغاء', style: TextStyle(fontSize: 16, color: Colors.black54)),
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
          ),
        ),
      ),
    );
  }

  Widget _buildTextFormField({
    required TextEditingController controller,
    required String label,
    required String validatorMessage,
    TextInputType keyboardType = TextInputType.text,
    bool isNumber = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(padding: const EdgeInsets.only(bottom: 8.0), child: Text(label, style: const TextStyle(fontWeight: FontWeight.bold), textDirection: fw.TextDirection.rtl)),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          textDirection: fw.TextDirection.rtl,
          textAlign: TextAlign.right,
          decoration: InputDecoration(border: const OutlineInputBorder(), contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10), filled: true, fillColor: Colors.grey.shade50),
          validator: (value) {
            if (value == null || value.isEmpty) return validatorMessage;
            if (isNumber && int.tryParse(value) == null) return 'الرجاء إدخال قيمة رقمية صحيحة.';
            return null;
          },
        ),
      ],
    );
  }
}

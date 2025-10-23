import 'package:flutter/material.dart';
import 'dart:ui' as ui;
import 'package:my_app/services/PropertyService.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

const Color primaryBlue = Color.fromARGB(255, 12, 7, 100);
const Color backgroundColor = Color(0xFFF5F5F5);

class AddPropertyScreen extends StatefulWidget {
  final PropertyService service;

  const AddPropertyScreen({required this.service, super.key});

  @override
  State<AddPropertyScreen> createState() => _AddPropertyScreenState();
}

class _AddPropertyScreenState extends State<AddPropertyScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  int? _selectedOwnerId;
  bool _isSaving = false;
  bool _isLoadingOwners = true;
  List<Map<String, dynamic>> _owners = [];

  @override
  void initState() {
    super.initState();
    _fetchOwners();
  }

  Future<void> _fetchOwners() async {
    try {
      final ownersData = await Supabase.instance.client
          .from('owners')
          .select('id, name');

      setState(() {
        _owners = List<Map<String, dynamic>>.from(ownersData);
        _isLoadingOwners = false;
      });
    } catch (e) {
      debugPrint('Error fetching owners: $e');
      _showSnackBar('خطأ في جلب قائمة المالكين: $e');
      setState(() => _isLoadingOwners = false);
    }
  }

  Future<void> _addProperty() async {
    if (!_formKey.currentState!.validate() || _selectedOwnerId == null) {
      _showSnackBar('الرجاء تعبئة جميع الحقول واختيار المالك');
      return;
    }

    setState(() => _isSaving = true);

    try {
      await widget.service.addProperty(
        name: _nameController.text.trim(),
        address: _addressController.text.trim(),
        ownerId: _selectedOwnerId!,
      );

      _showSnackBar('تم إضافة العقار بنجاح! 🎉');
      Navigator.of(context).pop(true);
    } 
    on PostgrestException catch (e) {
      debugPrint('PostgrestException: ${e.message}');
      _showSnackBar('خطأ في قاعدة البيانات: ${e.message}');
    } 
    catch (e, stackTrace) {
      debugPrint('Unexpected error: $e');
      debugPrintStack(stackTrace: stackTrace);
      _showSnackBar('حدث خطأ غير متوقع: $e');
    } 
    finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _showSnackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message, textDirection: ui.TextDirection.rtl),
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoadingOwners) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Directionality(
      textDirection: ui.TextDirection.rtl,
      child: Scaffold(
        backgroundColor: backgroundColor,
        appBar: AppBar(
          title: const Text('إضافة عقار جديد', style: TextStyle(color: Colors.white)),
          backgroundColor: primaryBlue,
          iconTheme: const IconThemeData(color: Colors.white),
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 600),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildTextField(controller: _nameController, label: 'اسم العقار:'),
                    const SizedBox(height: 20),
                    _buildTextField(controller: _addressController, label: 'العنوان:'),
                    const SizedBox(height: 20),
                    const Text('المالك:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<int>(
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        hintText: 'اختر المالك',
                        contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                      ),
                      items: _owners.map((owner) {
                        return DropdownMenuItem<int>(
                          value: owner['id'] as int,
                          child: Text(owner['name'].toString()),
                        );
                      }).toList(),
                      value: _selectedOwnerId,
                      onChanged: (value) => setState(() => _selectedOwnerId = value),
                      validator: (value) => value == null ? 'الرجاء اختيار المالك' : null,
                    ),
                    const SizedBox(height: 40),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(),
                          style: TextButton.styleFrom(
                              foregroundColor: Colors.grey.shade700,
                              padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 15)),
                          child: const Text('إلغاء'),
                        ),
                        const SizedBox(width: 15),
                        ElevatedButton(
                          onPressed: _isSaving ? null : _addProperty,
                          style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.black,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15)),
                          child: _isSaving
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3),
                                )
                              : const Text('إضافة العقار'),
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
    );
  }

  Widget _buildTextField({required TextEditingController controller, required String label}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          decoration: InputDecoration(
            border: const OutlineInputBorder(),
            contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
            hintText: label.replaceAll(':', ''),
          ),
          textDirection: ui.TextDirection.rtl,
          validator: (value) => value == null || value.isEmpty ? 'الرجاء تعبئة الحقل' : null,
        ),
      ],
    );
  }
}

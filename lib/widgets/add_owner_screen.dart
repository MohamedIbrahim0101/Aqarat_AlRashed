// lib/screens/AddOwnerScreen.dart

import 'package:flutter/material.dart';
import 'dart:ui' as ui;

// افترض أن هذه الألوان مُعرّفة في مكان مركزي
const Color primaryBlue = Color.fromARGB(255, 16, 9, 112);
const Color backgroundColor = Color(0xFFF5F5F5);

class AddOwnerScreen extends StatelessWidget {
  const AddOwnerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: ui.TextDirection.rtl,
      child: Scaffold(
        backgroundColor: backgroundColor,
        appBar: AppBar(
          title: const Text(
            'إضافة مالك جديد',
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
                maxWidth: 600,
              ), // أقصى عرض للنموذج
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'Add Owner', // العنوان من الصورة
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const Divider(
                    color: Colors.orange,
                    thickness: 2,
                  ), // الخط البرتقالي
                  const SizedBox(height: 30),

                  // حقل اسم المالك (Owner Name)
                  _buildTextField(label: 'Owner Name:'),
                  const SizedBox(height: 20),

                  // حقل الحساب البنكي (Bank Account)
                  _buildTextField(label: 'Bank Account:'),
                  const SizedBox(height: 40),

                  // أزرار الإضافة والإلغاء
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.grey.shade700,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 30,
                            vertical: 15,
                          ),
                        ),
                        child: const Text('Cancel'),
                      ),
                      const SizedBox(width: 15),
                      ElevatedButton(
                        onPressed: () {
                          // 💡 منطق حفظ المالك الجديد
                          print('Add Owner button pressed!');
                          // يمكن إضافة Navigator.of(context).pop() هنا للعودة
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.black, // لون الزر Add Owner
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 30,
                            vertical: 15,
                          ),
                        ),
                        child: const Text('Add Owner'),
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

  Widget _buildTextField({required String label}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        const SizedBox(height: 8),
        TextField(
          decoration: InputDecoration(
            border: const OutlineInputBorder(),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 10,
              vertical: 10,
            ),
            hintText: label.replaceAll(':', ''),
          ),
          textDirection: ui.TextDirection.rtl,
        ),
      ],
    );
  }
}

// File: lib/widgets/login_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:my_app/widgets/dashboardScreen.dart';
import 'package:my_app/services/dashboard_service.dart';
import 'package:my_app/services/PropertyService.dart';
import 'package:my_app/services/contracts_manage_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  bool isLoading = false;

  late final String supabaseUrl = dotenv.env['NEXT_PUBLIC_SUPABASE_URL']!;
  late final String supabaseAnonKey = dotenv.env['NEXT_PUBLIC_SUPABASE_ANON_KEY']!;

  @override
  void initState() {
    super.initState();
    _checkLoggedIn();
  }

  Future<void> _checkLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    final isLoggedIn = prefs.getBool('isLoggedIn') ?? false;
    if (isLoggedIn) {
      _goToDashboard();
    }
  }

  Future<void> login() async {
    final email = emailController.text.trim();
    final password = passwordController.text;

    if (email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('الرجاء إدخال البريد وكلمة المرور')),
      );
      return;
    }

    setState(() => isLoading = true);

    final url = Uri.parse('$supabaseUrl/auth/v1/token?grant_type=password');

    try {
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'apikey': supabaseAnonKey,
        },
        body: jsonEncode({'email': email, 'password': password}),
      );

      final data = jsonDecode(response.body);
      setState(() => isLoading = false);

      if (response.statusCode == 200 && data['access_token'] != null) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('isLoggedIn', true); // حفظ حالة تسجيل الدخول

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تم تسجيل الدخول بنجاح')),
        );

        _goToDashboard();
      } else {
        final errorMsg = data['error_description'] ?? data['error'] ?? 'خطأ في تسجيل الدخول';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(errorMsg)),
        );
      }
    } catch (e) {
      setState(() => isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('حدث خطأ: $e')),
      );
    }
  }

  void _goToDashboard() {
    final dashboardService = DashboardService();
    final propertyService = PropertyService();
    final contractService = ContractService();

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => Dashboardscreen(
          dashboardService: dashboardService,
          propertyService: propertyService,
          contractService: contractService,
        ),
      ),
    );
  }

  Widget _buildInputField({
    required String labelText,
    required String hintText,
    bool isPassword = false,
    TextEditingController? controller,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 8.0),
          child: Text(
            labelText,
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
            textDirection: TextDirection.rtl,
          ),
        ),
        TextField(
          controller: controller,
          obscureText: isPassword,
          textAlign: TextAlign.right,
          decoration: InputDecoration(
            hintText: hintText,
            hintStyle: TextStyle(color: Colors.grey.shade500),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8.0),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8.0),
              borderSide: BorderSide(color: Colors.blue.shade700, width: 2.0),
            ),
            contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
            hintTextDirection: TextDirection.ltr,
          ),
          keyboardType: isPassword ? TextInputType.text : TextInputType.emailAddress,
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFE0F7FA), Color(0xFFFFFFFF)],
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  color: const Color(0xFF1B263B),
                  child: const Center(
                    child: Text(
                      'عقارات مشعل الراشد',
                      style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                      textDirection: TextDirection.rtl,
                    ),
                  ),
                ),
                const SizedBox(height: 30),
                Container(
                  width: 350,
                  padding: const EdgeInsets.all(30),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: [BoxShadow(color: Colors.grey, blurRadius: 10, spreadRadius: 2)],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      const Icon(Icons.apartment, size: 60, color: Color(0xFFC0996B)),
                      const SizedBox(height: 20),
                      const Text('تسجيل الدخول',
                          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                          textDirection: TextDirection.rtl),
                      const SizedBox(height: 20),
                      _buildInputField(labelText: 'البريد الإلكتروني', hintText: 'admin@example.com', controller: emailController),
                      const SizedBox(height: 15),
                      _buildInputField(labelText: 'كلمة المرور', hintText: '*********', isPassword: true, controller: passwordController),
                      const SizedBox(height: 30),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: isLoading ? null : login,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF1B263B),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 15),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                          child: isLoading ? const CircularProgressIndicator(color: Colors.white) : const Text('تسجيل الدخول', textDirection: TextDirection.rtl),
                        ),
                      ),
                      const SizedBox(height: 20),
                      const Text('عقارات مشعل الراشد. جميع الحقوق محفوظة 2025 ©',
                          style: TextStyle(fontSize: 12, color: Colors.grey), textDirection: TextDirection.rtl),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

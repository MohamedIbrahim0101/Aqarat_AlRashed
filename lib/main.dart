// File: lib/main.dart

import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

// الخدمات
import 'package:my_app/services/contracts_manage_service.dart' as contracts_service;
import 'package:my_app/services/dashboard_service.dart' as dashboard_service;
import 'package:my_app/services/PropertyService.dart' as property_service;
import 'package:my_app/services/customer_service.dart' as customer_service;

// الواجهات
import 'package:my_app/widgets/login_screen.dart';
import 'package:my_app/widgets/dashboardScreen.dart' show Dashboardscreen;
import 'package:my_app/widgets/unit_manage_screen.dart';
import 'package:my_app/widgets/customer_details.dart';

// ------------------------------------------------------------------
// 1. متغيرات عامة
// ------------------------------------------------------------------
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

late final SupabaseClient supabaseClient;
late final dashboard_service.DashboardService dashboardService;
late final property_service.PropertyService propertyService;
late final contracts_service.ContractService contractService;
late final customer_service.CustomerService customerService;

// ------------------------------------------------------------------
// 2. نقطة البداية main()
// ------------------------------------------------------------------
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");

  final supabaseUrl = dotenv.env['NEXT_PUBLIC_SUPABASE_URL'];
  final supabaseAnonKey = dotenv.env['NEXT_PUBLIC_SUPABASE_ANON_KEY'];

  if (supabaseUrl == null || supabaseAnonKey == null) {
    throw Exception('Supabase keys not configured.');
  }

  await Supabase.initialize(url: supabaseUrl, anonKey: supabaseAnonKey);

  // إنشاء الخدمات
  supabaseClient = Supabase.instance.client;
  dashboardService = dashboard_service.DashboardService();
  propertyService = property_service.PropertyService();
  contractService = contracts_service.ContractService();
  customerService = customer_service.CustomerService();

  // التحقق من حالة تسجيل الدخول
  final prefs = await SharedPreferences.getInstance();
  final bool isLoggedIn = prefs.getBool('isLoggedIn') ?? false;

  runApp(MyApp(isLoggedIn: isLoggedIn));
}

// ------------------------------------------------------------------
// 3. MyApp
// ------------------------------------------------------------------
class MyApp extends StatelessWidget {
  final bool isLoggedIn;
  const MyApp({super.key, required this.isLoggedIn});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navigatorKey,
      debugShowCheckedModeBanner: false,
      title: 'Real Estate App',
      theme: ThemeData(useMaterial3: true, fontFamily: 'Cairo'),
      initialRoute: isLoggedIn ? '/dashboard' : '/login',
      routes: {
        '/login': (context) => const LoginScreen(),
        '/dashboard': (context) => Dashboardscreen(
              dashboardService: dashboardService,
              propertyService: propertyService,
              contractService: contractService,
            ),
        '/units-manage': (context) => const UnitsManageScreen(),
        '/customer_details': (context) => FutureBuilder<int?>(
              future: _getCustomerIdFromArguments(context),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Scaffold(
                      body: Center(child: CircularProgressIndicator()));
                } else if (!snapshot.hasData || snapshot.data == null) {
                  return const Scaffold(
                      body: Center(child: Text('Customer not found.')));
                } else {
                  return CustomerDetailsPage(customerId: snapshot.data!);
                }
              },
            ),
      },
    );
  }

  /// تحويل اسم العميل إلى ID باستخدام خدمة العملاء
  Future<int?> _getCustomerIdFromArguments(BuildContext context) async {
    final customerName =
        ModalRoute.of(context)?.settings.arguments as String? ?? 'N/A';
    final customerList =
        await customerService.fetchCustomerDetailsByName(customerName);

    if (customerList.isEmpty) return null;

    return customerList.first.customer['id'] as int?;
  }
}

// ------------------------------------------------------------------
// 4. مساعدة تسجيل الدخول والخروج
// ------------------------------------------------------------------

// حفظ حالة تسجيل الدخول عند تسجيل الدخول الناجح
Future<void> saveLoginStatus() async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setBool('isLoggedIn', true);
}

// مسح حالة تسجيل الدخول عند تسجيل الخروج
Future<void> clearLoginStatus() async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.remove('isLoggedIn');
  await Supabase.instance.client.auth.signOut();

  // العودة لشاشة Login مع مسح كل الشاشة السابقة
  navigatorKey.currentState!.pushNamedAndRemoveUntil('/login', (route) => false);
}

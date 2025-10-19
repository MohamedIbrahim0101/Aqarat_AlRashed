import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:my_app/models/dashboard_service.dart';
import 'dashboardScreen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // تحميل متغيرات البيئة
  await dotenv.load(fileName: ".env");

  // تهيئة Supabase باستخدام مفاتيح البيئة
  await Supabase.initialize(
    url: dotenv.env['NEXT_PUBLIC_SUPABASE_URL'] ?? '',
    anonKey: dotenv.env['NEXT_PUBLIC_SUPABASE_ANON_KEY'] ?? '',
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final DashboardService service = DashboardService();

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Real Estate Dashboard',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        fontFamily: 'Cairo',
        useMaterial3: true,
      ),
      home: DashboardScreen(service: service),
    );
  }
}

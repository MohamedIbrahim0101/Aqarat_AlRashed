import 'package:supabase_flutter/supabase_flutter.dart';

// ✅ رابط مشروع Supabase
const String supabaseUrl = 'https://yvdaupqwzxaoqygkxlii.supabase.co';

// ✅ المفتاح العام (anon key)
const String supabaseAnonKey =
    'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Inl2ZGF1cHF3enhhb3F5Z2t4bGlpIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc0NjI1NTE0MCwiZXhwIjoyMDYxODMxMTQwfQ.DnOlJSlggeD7DLqW-2SMN4svISCjzUbFax17grxq3A';

// ✅ دالة التهيئة (يُفضل استدعاؤها في main قبل runApp)
Future<void> initializeSupabase() async {
  await Supabase.initialize(
    url: supabaseUrl,
    anonKey: supabaseAnonKey,
  );
}

// ✅ عميل Supabase بعد التهيئة
final SupabaseClient supabase = Supabase.instance.client;

import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseConfig {
  static const String SUPABASE_URL = 'https://npmtlpurofsfuwqsbgwy.supabase.co';
  static const String SUPABASE_ANON_KEY = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im5wbXRscHVyb2ZzZnV3cXNiZ3d5Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3Mjk4MjgxMjQsImV4cCI6MjA0NTQwNDEyNH0.zJXAC-xf_tRSNTNReFhYp-WG_Z7b4W93bPZQFP2L6Jg';

  static Future<void> initialize() async {
    await Supabase.initialize(
      url: SUPABASE_URL,
      anonKey: SUPABASE_ANON_KEY,
      debug: true,
    );
  }

  static SupabaseClient get client => Supabase.instance.client;
}
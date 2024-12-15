import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseConfig {
  static const String SUPABASE_URL = 'https://rwefcztluvqmkfyikllj.supabase.co';
  static const String SUPABASE_ANON_KEY = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InJ3ZWZjenRsdXZxbWtmeWlrbGxqIiwicm9sZSI6ImFub24iLCJpYXQiOjE3MzQyMzQ3MDUsImV4cCI6MjA0OTgxMDcwNX0.TFbWXI99_yNTmi4oIWfZPFCs58Ni25cM56CzqDeaJJM';

  static Future<void> initialize() async {
    const bool isDebugMode = !bool.fromEnvironment('dart.vm.product');

    try {
      await Supabase.initialize(
        url: SUPABASE_URL,
        anonKey: SUPABASE_ANON_KEY,
        debug: isDebugMode,
      );
    } catch (e) {
      print('Erreur d\'initialisation Supabase : $e');
      rethrow;
    }
  }

  static SupabaseClient get client => Supabase.instance.client;
}
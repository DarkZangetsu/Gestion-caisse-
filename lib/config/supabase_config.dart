import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseConfig {
  static const String SUPABASE_URL = 'https://rxednrvjlwazhcnewnnm.supabase.co';
  static const String SUPABASE_ANON_KEY = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InJ4ZWRucnZqbHdhemhjbmV3bm5tIiwicm9sZSI6ImFub24iLCJpYXQiOjE3MzA5NDU1ODEsImV4cCI6MjA0NjUyMTU4MX0.XwDkBkK2LEkZQ98ex7e390zxn4k2K_7TVa4EvnvsHuc';

  static Future<void> initialize() async {
    await Supabase.initialize(
      url: SUPABASE_URL,
      anonKey: SUPABASE_ANON_KEY,
      debug: true,
    );
  }

  static SupabaseClient get client => Supabase.instance.client;
}
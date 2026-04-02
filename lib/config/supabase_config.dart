import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseConfig {
  static const String supabaseUrl = 'https://pqldtytdeoitizjovxdq.supabase.co';
  static const String supabaseAnonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InBxbGR0eXRkZW9pdGl6am92eGRxIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzAwOTI0MzQsImV4cCI6MjA4NTY2ODQzNH0.BVT_cpnWEDdId7zquhb-i6EyjDySuXk6m1LvV4t16Iw';

  static Future<void> init() async {
    await Supabase.initialize(
      url: supabaseUrl,
      anonKey: supabaseAnonKey,
    );
  }

  static SupabaseClient get client => Supabase.instance.client;
}

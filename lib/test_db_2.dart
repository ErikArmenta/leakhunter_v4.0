import 'package:supabase/supabase.dart';

void main() async {
  final client = SupabaseClient(
    'https://pqldtytdeoitizjovxdq.supabase.co',
    'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InBxbGR0eXRkZW9pdGl6am92eGRxIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzAwOTI0MzQsImV4cCI6MjA4NTY2ODQzNH0.BVT_cpnWEDdId7zquhb-i6EyjDySuXk6m1LvV4t16Iw'
  );
  try {
    final response = await client.from('fugas').select().limit(1);
    print(response);
  } catch (e) {
    print('Error: \$e');
  }
}

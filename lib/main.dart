import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dashboard_page.dart';
import 'login_page.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: 'https://iujskspgtuykqigwpegv.supabase.co',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Iml1anNrc3BndHV5a3FpZ3dwZWd2Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3OTUyMzEyMjIsImV4cCI6MjExMDgwNzIyMn0.l0J7LAJfPa8Bv8Ir1lK6lIaDxLIhQVoAYxHHdilUBQk',
  );

  runApp(const SwimClubApp());
}

class SwimClubApp extends StatelessWidget {
  const SwimClubApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Manajemen Klub Renang',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF0284C7),
          brightness: Brightness.light,
        ),
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFFF8FAFC),
      ),
      home: StreamBuilder<AuthState>(
        stream: Supabase.instance.client.auth.onAuthStateChange,
        builder: (context, snapshot) {
          final session = Supabase.instance.client.auth.currentSession;
          if (session != null) {
            return const DashboardPage();
          }
          return const LoginPage();
        },
      ),
    );
  }
}
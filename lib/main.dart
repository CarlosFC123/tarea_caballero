import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'screens/auth/login_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  await Supabase.initialize(
    url: 'https://kngtqjpdmzbvwuevxarx.supabase.co',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImtuZ3RxanBkbXpidnd1ZXZ4YXJ4Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDk3NzEwNjgsImV4cCI6MjA2NTM0NzA2OH0.PgP2uS6kOs4Zlk-e3Q80TsDEQRhP6WCUaXRQv6k9wWk',
  );
  
  runApp(const FidelizacionApp());
}

class FidelizacionApp extends StatelessWidget {
  const FidelizacionApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Programa de Fidelización',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const LoginScreen(),
    );
  }
} 
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'screens/login_screen.dart';
import 'screens/dashboard_screen.dart';
import 'services/api_service.dart';

void main() {
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ApiService()),
      ],
      child: const BillerProApp(),
    ),
  );
}

class BillerProApp extends StatelessWidget {
  const BillerProApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Biller Pro',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF0D6EFD),
          primary: const Color(0xFF0D6EFD),
        ),
        useMaterial3: true,
        textTheme: GoogleFonts.interTextTheme(),
      ),
      home: const AuthWrapper(),
    );
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    final apiService = Provider.of<ApiService>(context);
    return apiService.isAuthenticated ? const DashboardScreen() : const LoginScreen();
  }
}

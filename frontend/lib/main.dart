import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'landing_page.dart';
import 'api_service.dart';
import 'patient_portal.dart';
import 'doctor_portal.dart';
import 'admin_portal.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final currentUser = await ApiService.getCurrentUser();
  runApp(ThalAgentApp(currentUser: currentUser));
}

class ThalAgentApp extends StatelessWidget {
  final Map<String, dynamic>? currentUser;
  const ThalAgentApp({super.key, this.currentUser});

  @override
  Widget build(BuildContext context) {
    Widget homeWidget = const LandingPage();

    if (currentUser != null) {
      if (currentUser!['role'] == 'patient') {
        homeWidget = const PatientPortal();
      } else if (currentUser!['role'] == 'doctor') {
        homeWidget = const DoctorPortal();
      } else if (currentUser!['role'] == 'admin') {
        homeWidget = const AdminPortal();
      }
    }

    return MaterialApp(
      title: 'Thalassemia AI Agent',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF801336),
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
        textTheme: GoogleFonts.outfitTextTheme(Theme.of(context).textTheme).apply(
          bodyColor: Colors.white,
          displayColor: Colors.white,
        ),
      ),
      home: homeWidget,
    );
  }
}

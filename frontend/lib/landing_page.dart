import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'dart:ui';
import 'patient_portal.dart';
import 'doctor_portal.dart';
import 'admin_portal.dart';
import 'api_service.dart';
import 'thal_101.dart'; // Make sure you have this screen

class LandingPage extends StatefulWidget {
  const LandingPage({super.key});

  @override
  State<LandingPage> createState() => _LandingPageState();
}

class _LandingPageState extends State<LandingPage> {
  void _showLoginDialog(BuildContext context, String role) {
    final TextEditingController usernameController = TextEditingController();
    bool isLoading = false;
    String errorMessage = '';

    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.8),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Dialog(
              backgroundColor: const Color(0xFF1A1D24),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Container(
                width: 400,
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Login or Register",
                      style: GoogleFonts.playfairDisplay(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "Enter a username for the portal.",
                      style: GoogleFonts.outfit(
                        fontSize: 14,
                        color: Colors.white70,
                      ),
                    ),
                    const SizedBox(height: 32),
                    TextField(
                      controller: usernameController,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: const Color(0xFF0B0E14),
                        hintText: "Username",
                        hintStyle: const TextStyle(color: Colors.white38),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide.none,
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(color: Color(0xFF00E5FF), width: 1.5),
                        ),
                      ),
                    ),
                    if (errorMessage.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(
                          errorMessage,
                          style: const TextStyle(color: Color(0xFFFF3B30), fontSize: 12),
                        ),
                      ),
                    const SizedBox(height: 32),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text("Cancel", style: TextStyle(color: Colors.grey)),
                        ),
                        const SizedBox(width: 16),
                        SizedBox(
                          height: 40,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF006064), // Deep Teal
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20), // Pill-shaped
                              ),
                              padding: const EdgeInsets.symmetric(horizontal: 24),
                            ),
                            onPressed: isLoading
                                ? null
                                : () async {
                                    if (usernameController.text.trim().isEmpty) {
                                      setState(() => errorMessage = "Please enter a username");
                                      return;
                                    }
                                    setState(() {
                                      isLoading = true;
                                      errorMessage = '';
                                    });

                                    try {
                                      // Attempt login
                                      final user = await ApiService.loginUser(usernameController.text.trim());
                                      if (context.mounted) {
                                        Navigator.pop(context); // Close dialog
                                        if (user['role'] == 'patient') {
                                          Navigator.pushReplacement(
                                            context,
                                            MaterialPageRoute(builder: (context) => const PatientPortal()),
                                          );
                                        } else if (user['role'] == 'doctor') {
                                          Navigator.pushReplacement(
                                            context,
                                            MaterialPageRoute(builder: (context) => const DoctorPortal()),
                                          );
                                        } else if (user['role'] == 'admin') {
                                          Navigator.pushReplacement(
                                            context,
                                            MaterialPageRoute(builder: (context) => const AdminPortal()),
                                          );
                                        }
                                      }
                                    } catch (e) {
                                      // User not found, auto register for simplicity in prototype
                                      try {
                                        await ApiService.registerUser(usernameController.text.trim(), role);
                                        final user = await ApiService.loginUser(usernameController.text.trim());
                                        if (context.mounted) {
                                          Navigator.pop(context);
                                          if (user['role'] == 'patient') {
                                            Navigator.pushReplacement(
                                              context,
                                              MaterialPageRoute(builder: (context) => const PatientPortal()),
                                            );
                                          } else {
                                            Navigator.pushReplacement(
                                              context,
                                              MaterialPageRoute(builder: (context) => const DoctorPortal()),
                                            );
                                          }
                                        }
                                      } catch (regErr) {
                                        setState(() {
                                          isLoading = false;
                                          if (regErr.toString().contains('Connection refused') || regErr.toString().contains('ClientException')) {
                                            errorMessage = "Unable to connect to server. Is the backend running?";
                                          } else {
                                            errorMessage = "Registration failed.";
                                          }
                                        });
                                      }
                                    }
                                  },
                            child: isLoading
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                                : const Text("Continue", style: TextStyle(fontWeight: FontWeight.bold)),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0B0E14),
      body: Stack(
        children: [
          // Global Background Image
          Positioned.fill(
            child: Image.asset(
              'assets/images/rbc_bg.png',
              fit: BoxFit.cover,
            ),
          ),
          // Dark Gradient Overlay for Readability
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    const Color(0xFF0B0E14).withOpacity(0.6),
                    const Color(0xFF0B0E14).withOpacity(0.85),
                  ],
                ),
              ),
            ),
          ),
          // Content
          Column(
            children: [
              Expanded(
                child: Center(
                  child: SingleChildScrollView(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Header Logo
                          _buildCustomLogo(50).animate().scale(duration: 800.ms, curve: Curves.easeOutBack),
                          
                          const SizedBox(height: 24),
                          
                          // Welcome Header
                          Text(
                            "Welcome to Thalassemia Hub",
                            textAlign: TextAlign.center,
                            style: GoogleFonts.playfairDisplay(
                              fontSize: 48,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              shadows: [
                                Shadow(
                                  color: Colors.black.withOpacity(0.8),
                                  blurRadius: 15,
                                  offset: const Offset(0, 5),
                                ),
                              ],
                            ),
                          ).animate().fade(delay: 200.ms).slideY(begin: 0.1),
                          
                          const SizedBox(height: 12),
                          
                          // Subtitle
                          Text(
                            "Your intelligent companion for Thalassemia care.",
                            textAlign: TextAlign.center,
                            style: GoogleFonts.outfit(
                              fontSize: 18,
                              color: Colors.grey.shade300,
                              letterSpacing: 1.1,
                            ),
                          ).animate().fade(delay: 400.ms),
                          
                          const SizedBox(height: 60),
                          
                          Text(
                            "Select your profile to continue:",
                            style: GoogleFonts.outfit(
                              fontSize: 16,
                              color: Colors.white,
                            ),
                          ).animate().fade(delay: 500.ms),
                          
                          const SizedBox(height: 30),
                          
                          // Persona Cards (Row/Wrap)
                          LayoutBuilder(
                            builder: (context, constraints) {
                              bool isMobile = constraints.maxWidth < 850;
                              return Wrap(
                                alignment: WrapAlignment.center,
                                spacing: 24,
                                runSpacing: 24,
                                children: [
                                  _buildPersonaCard(
                                    context: context,
                                    title: "Patient Portal",
                                    subtitle: "Personalized Tracking &\nDigital Twin",
                                    iconWidget: const Icon(Icons.water_drop, size: 60, color: Color(0xFFFF3B30)),
                                    tintColor: const Color(0xFFFF3B30),
                                    width: isMobile ? constraints.maxWidth : 260,
                                    height: isMobile ? null : 320,
                                    delay: 600,
                                    onTap: () {
                                      _showLoginDialog(context, 'patient');
                                    },
                                  ),
                                  _buildPersonaCard(
                                    context: context,
                                    title: "Doctor Portal",
                                    subtitle: "Clinical Data & Therapy\nProtocols",
                                    iconWidget: const Icon(Icons.medical_services_outlined, size: 60, color: Color(0xFF00E5FF)),
                                    tintColor: const Color(0xFF00E5FF),
                                    width: isMobile ? constraints.maxWidth : 260,
                                    height: isMobile ? null : 320,
                                    delay: 700,
                                    onTap: () {
                                      _showLoginDialog(context, 'doctor');
                                    },
                                  ),
                                  _buildPersonaCard(
                                    context: context,
                                    title: "Encyclopedia",
                                    subtitle: "Global Guidelines &\nAI Support",
                                    iconWidget: const Icon(Icons.public, size: 60, color: Color(0xFF4CD964)),
                                    tintColor: const Color(0xFF4CD964),
                                    width: isMobile ? constraints.maxWidth : 260,
                                    height: isMobile ? null : 320,
                                    delay: 800,
                                    onTap: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(builder: (context) => const Thal101Screen()),
                                      );
                                    },
                                  ),
                                ],
                              );
                            },
                          ),
                          
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              // Footer Legal Disclaimer
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 40),
                decoration: BoxDecoration(
                  border: Border(top: BorderSide(color: Colors.white.withOpacity(0.05))),
                ),
                child: Text(
                  "⚠️ Legal Disclaimer: This AI assistant provides research and data tracking and may occasionally provide inaccurate information. It is NOT a substitute for professional medical advice.",
                  textAlign: TextAlign.center,
                  style: GoogleFonts.outfit(
                    fontSize: 12,
                    color: Colors.white54,
                    height: 1.5,
                  ),
                ),
              ).animate().fade(delay: 1000.ms),
            ],
          ),
          // Admin Login Button (Placed at the end of Stack to render on top)
          Positioned(
            top: 20,
            right: 20,
            child: TextButton.icon(
              onPressed: () => _showLoginDialog(context, 'admin'),
              icon: const Icon(Icons.admin_panel_settings, color: Colors.white54, size: 16),
              label: const Text("Admin Login", style: TextStyle(color: Colors.white54, fontSize: 12)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCustomLogo(double size) {
    return SizedBox(
      width: size * 1.5,
      height: size * 1.2,
      child: Stack(
        children: [
          Positioned(
            right: 0,
            top: 0,
            child: Icon(Icons.cases_outlined, color: const Color(0xFF00E5FF), size: size * 0.9), // Medical case
          ),
          Positioned(
            left: 0,
            bottom: 0,
            child: Icon(Icons.water_drop, color: const Color(0xFFFF3B30), size: size), // Blood drop
          ),
        ],
      ),
    );
  }

  Widget _buildPersonaCard({
    required BuildContext context,
    required String title,
    required String subtitle,
    required Widget iconWidget,
    required Color tintColor,
    required double width,
    double? height,
    required int delay,
    required VoidCallback onTap,
  }) {
    return StatefulBuilder(
      builder: (context, setState) {
        bool isHovered = false;
        
        return MouseRegion(
          onEnter: (_) => setState(() => isHovered = true),
          onExit: (_) => setState(() => isHovered = false),
          child: GestureDetector(
            onTap: onTap,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOutCubic,
              transform: Matrix4.identity()..translate(0.0, isHovered ? -8.0 : 0.0),
              width: width,
              height: height,
              decoration: BoxDecoration(
                color: const Color(0xFF1A1D24).withOpacity(0.8), // Semi-transparent dark grey
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isHovered ? tintColor.withOpacity(0.8) : tintColor.withOpacity(0.2),
                  width: isHovered ? 1.5 : 1.0,
                ),
                boxShadow: isHovered
                    ? [
                        BoxShadow(
                          color: tintColor.withOpacity(0.2),
                          blurRadius: 20,
                          spreadRadius: 2,
                        )
                      ]
                    : [],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10), // Frosted glass effect
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        iconWidget,
                        const SizedBox(height: 24),
                        Text(
                          title,
                          textAlign: TextAlign.center,
                          style: GoogleFonts.outfit(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          subtitle,
                          textAlign: TextAlign.center,
                          style: GoogleFonts.outfit(
                            fontSize: 14,
                            color: Colors.white70,
                            height: 1.4,
                          ),
                        ),
                        const SizedBox(height: 24),
                        Icon(
                          Icons.arrow_forward, 
                          color: tintColor, 
                          size: 24
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ).animate().fade(delay: delay.ms).slideY(begin: 0.1);
      }
    );
  }
}

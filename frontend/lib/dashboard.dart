import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'timeline_chart.dart';
import 'thal_101.dart';

class DashboardScreen extends StatefulWidget {
  final Map<String, dynamic> patientData;
  
  const DashboardScreen({super.key, required this.patientData});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  bool _isLoading = true;
  String _aiAssessment = "Connecting to Medical AI Brain...";
  String _aiStatus = "Analyzing";
  bool _isCritical = false;

  @override
  void initState() {
    super.initState();
    _fetchAIAnalysis();
  }

  Future<void> _fetchAIAnalysis() async {
    try {
      final response = await http.post(
        Uri.parse('http://127.0.0.1:8000/analyze'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'name': widget.patientData['name'] ?? '',
          'age': widget.patientData['age'] ?? '',
          'weight': widget.patientData['weight'] ?? '',
          'sex': widget.patientData['sex'] ?? '',
          'hb': widget.patientData['hb'] ?? '',
          'iron': widget.patientData['iron'] ?? '',
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          _aiAssessment = data['patient_assessment'];
          _aiStatus = data['status'];
          _isCritical = data['status'] == 'Critical';
          _isLoading = false;
        });
      } else {
        setState(() {
          _aiAssessment = "Unable to connect to AI Brain. Status code: ${response.statusCode}";
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _aiAssessment = "AI connection failed. Ensure the FastAPI backend is running.";
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Extract data
    final String name = widget.patientData['name'] ?? 'Patient';
    final double hbLevel = double.tryParse(widget.patientData['hb']?.toString() ?? '7.2') ?? 7.2;
    final String ironLevel = widget.patientData['iron']?.toString() ?? 'Unknown';
    
    // Logic for color and pulsing based on AI Status instead of pure math
    final bool isClinical = widget.patientData['isClinical'] ?? false;
    final Color healthColor = _isCritical ? Colors.redAccent : Colors.cyanAccent;
    final int pulseDuration = _isCritical ? 600 : 1500;

    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF0F2027),
              Color(0xFF203A43),
              Color(0xFF801336),
            ],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: MediaQuery.of(context).size.height,
              ),
              child: IntrinsicHeight(
                child: Column(
                children: [
                  const SizedBox(height: 20),
                  Text(
                    isClinical ? "Clinical Dashboard: $name" : "$name's Digital Twin",
                    style: GoogleFonts.outfit(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: isClinical ? Colors.cyanAccent : Colors.white,
                    ),
                  ).animate().fade(duration: 800.ms).slideY(begin: -0.2),
                  
                  const Spacer(),
                  
                  // The Digital Twin Figure Area
                  SizedBox(
                    width: 700,
                    height: 400,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        // Background Glow Aura
                        Container(
                          width: 150,
                          height: 300,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: _isLoading ? Colors.white24 : healthColor.withOpacity(0.4),
                                blurRadius: 80,
                                spreadRadius: 30,
                              ),
                            ],
                          ),
                        ).animate(onPlay: (controller) => controller.repeat(reverse: true))
                         .scaleXY(end: 1.1, duration: pulseDuration.ms),

                        // Holographic Body Layer (Outer shell)
                        Icon(
                          Icons.accessibility_new_rounded,
                          size: 300,
                          color: (_isLoading ? Colors.grey : healthColor).withOpacity(0.3),
                        ).animate(onPlay: (controller) => controller.repeat(reverse: true))
                         .fadeIn(duration: 1.seconds).scaleXY(begin: 0.98, end: 1.02, duration: pulseDuration.ms),

                        // Core Bright Body Layer (Inner glowing core)
                        Icon(
                          Icons.accessibility_new_rounded,
                          size: 290,
                          color: _isLoading ? Colors.white70 : healthColor.withOpacity(0.9),
                        ).animate(onPlay: (controller) => controller.repeat())
                         .shimmer(duration: 2.seconds, color: Colors.white, angle: 1.5)
                         .fadeIn(duration: 800.ms),

                        // Floating Data Pop-out: Hb Level (Left Side)
                        Positioned(
                          left: 0,
                          top: 80,
                          child: _buildPopOutCard(
                            "Hb Level", 
                            "$hbLevel g/dL", 
                            _isLoading ? "Analyzing..." : (_isCritical ? "Critical" : "Stable"), 
                            _isLoading ? Colors.white : healthColor
                          ).animate().fade(delay: 500.ms).slideX(begin: -0.5),
                        ),

                        // Floating Data Pop-out: Iron Level (Right Side)
                        Positioned(
                          right: 0,
                          bottom: 80,
                          child: _buildPopOutCard(
                            "Serum Ferritin", 
                            "$ironLevel ng/mL", 
                            _isLoading ? "Analyzing..." : "Analyzed by AI", 
                            Colors.orangeAccent
                          ).animate().fade(delay: 700.ms).slideX(begin: 0.5),
                        ),
                      ],
                    ),
                  ),
                  
                  const Spacer(),

                  // AI Assessment Card
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 20),
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.white.withOpacity(0.2)),
                      boxShadow: [
                        BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 10, offset: const Offset(0, 5)),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            _isLoading 
                                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.cyanAccent, strokeWidth: 2))
                                : Icon(_isCritical ? Icons.warning_amber_rounded : Icons.check_circle_outline, color: healthColor, size: 28),
                            const SizedBox(width: 10),
                            Text(
                              "AI Medical Assessment",
                              style: GoogleFonts.outfit(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          _aiAssessment,
                          style: const TextStyle(color: Colors.white70, fontSize: 16, height: 1.4),
                        ).animate(target: _isLoading ? 0 : 1).fadeIn(duration: 500.ms),
                      ],
                    ),
                  ).animate().fade(delay: 900.ms).slideY(begin: 0.5),

                  const SizedBox(height: 20),
                  
                  ElevatedButton.icon(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.edit),
                    label: const Text("Edit Profile / Upload New Report"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white.withOpacity(0.15),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                    ),
                  ).animate().fade(delay: 1.seconds),
                  
                  const SizedBox(height: 12),
                  
                  ElevatedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => TimelineChartScreen(
                            patient: {
                              'latest_hb': hbLevel,
                              'latest_ferritin': double.tryParse(ironLevel) ?? 1000.0,
                            }
                          ),
                        ),
                      );
                    },
                    icon: const Icon(Icons.show_chart),
                    label: const Text("View Historical Timeline"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.cyanAccent.withOpacity(0.2),
                      foregroundColor: Colors.cyanAccent,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                      side: BorderSide(color: Colors.cyanAccent.withOpacity(0.5)),
                    ),
                  ).animate().fade(delay: 1.2.seconds),
                  
                  const SizedBox(height: 12),
                  
                  ElevatedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const Thal101Screen(),
                        ),
                      );
                    },
                    icon: const Icon(Icons.school),
                    label: const Text("Thalassemia 101 Hub"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.greenAccent.withOpacity(0.2),
                      foregroundColor: Colors.greenAccent,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                      side: BorderSide(color: Colors.greenAccent.withOpacity(0.5)),
                    ),
                  ).animate().fade(delay: 1.4.seconds),
                  
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ),
      ),
      ),
    );
  }

  // Helper method to create the floating data cards
  Widget _buildPopOutCard(String title, String value, String status, Color accentColor) {
    return Container(
      width: 180,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.white.withOpacity(0.2)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 14)),
          const SizedBox(height: 6),
          Text(value, style: GoogleFonts.outfit(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
          const SizedBox(height: 6),
          Text(status, style: TextStyle(color: accentColor, fontSize: 12, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

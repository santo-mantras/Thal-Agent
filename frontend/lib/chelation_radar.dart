import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';

class ChelationRadar extends StatefulWidget {
  const ChelationRadar({super.key});

  @override
  State<ChelationRadar> createState() => _ChelationRadarState();
}

class _ChelationRadarState extends State<ChelationRadar> with SingleTickerProviderStateMixin {
  late AnimationController _radarController;

  @override
  void initState() {
    super.initState();
    _radarController = AnimationController(vsync: this, duration: const Duration(seconds: 4))..repeat();
  }

  @override
  void dispose() {
    _radarController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F141A),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text("CHELATION TARGET RADAR", 
          style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold, letterSpacing: 1.5, color: Colors.cyanAccent)),
        centerTitle: true,
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          bool isMobile = constraints.maxWidth < 600;
          return Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Radar Container
                  SizedBox(
                    width: 350,
                    height: 350,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        // Static Radar Rings
                        Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.cyanAccent.withOpacity(0.2), width: 2),
                          ),
                        ),
                        Container(
                          width: 250, height: 250,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.cyanAccent.withOpacity(0.2), width: 1),
                          ),
                        ),
                        Container(
                          width: 150, height: 150,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.cyanAccent.withOpacity(0.2), width: 1),
                          ),
                        ),
                        // Crosshairs
                        Container(width: 350, height: 1, color: Colors.cyanAccent.withOpacity(0.2)),
                        Container(width: 1, height: 350, color: Colors.cyanAccent.withOpacity(0.2)),
                        
                        // Dummy Organ Background (Network Image)
                        Opacity(
                          opacity: 0.6,
                          child: ClipOval(
                            child: Image.network(
                              "https://upload.wikimedia.org/wikipedia/commons/thumb/c/ce/Heart_anterior_exterior.png/300px-Heart_anterior_exterior.png",
                              width: 200, height: 200, fit: BoxFit.contain,
                              errorBuilder: (context, error, stackTrace) => const Icon(Icons.favorite, size: 150, color: Colors.redAccent),
                            ),
                          ),
                        ),
                        
                        // Heatmap Highlights
                        Positioned(
                          top: 100, left: 100,
                          child: Container(
                            width: 60, height: 60,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: RadialGradient(
                                colors: [Colors.redAccent, Colors.redAccent.withOpacity(0.5), Colors.transparent],
                              )
                            ),
                          ).animate(onPlay: (c) => c.repeat(reverse: true)).fade(begin: 0.5, end: 1.0, duration: 2.seconds),
                        ),
                        Positioned(
                          bottom: 120, right: 120,
                          child: Container(
                            width: 40, height: 40,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: RadialGradient(
                                colors: [Colors.amberAccent, Colors.amberAccent.withOpacity(0.5), Colors.transparent],
                              )
                            ),
                          ).animate(onPlay: (c) => c.repeat(reverse: true)).fade(begin: 0.5, end: 1.0, duration: 1.5.seconds),
                        ),

                        // Sweeping Radar Animation
                        AnimatedBuilder(
                          animation: _radarController,
                          builder: (context, child) {
                            return Transform.rotate(
                              angle: _radarController.value * 2 * pi,
                              child: Container(
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  gradient: SweepGradient(
                                    colors: [
                                      Colors.transparent,
                                      Colors.transparent,
                                      Colors.cyanAccent.withOpacity(0.1),
                                      Colors.cyanAccent.withOpacity(0.6),
                                    ],
                                    stops: const [0.0, 0.7, 0.95, 1.0],
                                  ),
                                ),
                              ),
                            );
                          }
                        ),
                        
                        // Floating Text
                        Positioned(
                          top: 50, right: 20,
                          child: Text("Iron Level 18 mg/g", style: GoogleFonts.outfit(color: Colors.cyanAccent, fontSize: 12)),
                        ).animate(delay: 1.seconds).fadeIn(),
                        Positioned(
                          top: 70, right: 10,
                          child: Text("Target Met: Heart", style: GoogleFonts.outfit(color: Colors.greenAccent, fontSize: 12)),
                        ).animate(delay: 2.seconds).fadeIn(),
                        Positioned(
                          bottom: 50, right: 20,
                          child: Text("Adherence Check", style: GoogleFonts.outfit(color: Colors.white70, fontSize: 12)),
                        ).animate(delay: 3.seconds).fadeIn(),
                      ],
                    ),
                  ),
                  const SizedBox(height: 60),
                  
                  // Tracker Widgets
                  Wrap(
                    spacing: 20,
                    runSpacing: 20,
                    alignment: WrapAlignment.center,
                    children: [
                      _buildCircularTracker("Day 1 Adherence", "95%", Colors.greenAccent, 0.95),
                      _buildCircularTracker("Weekly Iron Reduction", "2%", Colors.greenAccent, 0.02),
                      _buildCircularTracker("Warning: Liver Iron", "High", Colors.amberAccent, 0.8),
                    ],
                  )
                ],
              ),
            ),
          );
        }
      ),
    );
  }

  Widget _buildCircularTracker(String title, String value, Color color, double progress) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: 80, height: 80,
          child: Stack(
            fit: StackFit.expand,
            children: [
              CircularProgressIndicator(
                value: progress,
                strokeWidth: 8,
                backgroundColor: Colors.white12,
                color: color,
              ),
              Center(child: Text(value, style: GoogleFonts.outfit(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold))),
            ],
          ),
        ),
        const SizedBox(height: 10),
        SizedBox(
          width: 100,
          child: Text(title, textAlign: TextAlign.center, style: const TextStyle(color: Colors.white70, fontSize: 12)),
        )
      ],
    );
  }
}

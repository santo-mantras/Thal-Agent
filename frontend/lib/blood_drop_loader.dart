import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';

class BloodDropLoader extends StatelessWidget {
  final String text;
  const BloodDropLoader({super.key, this.text = "ANALYZING..."});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: BoxDecoration(
        color: const Color(0xFF141414),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.redAccent.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.water_drop,
            color: Colors.redAccent,
            size: 24,
          )
          .animate(onPlay: (controller) => controller.repeat())
          .slideY(begin: 0, end: -0.4, duration: 300.ms, curve: Curves.easeOut)
          .then()
          .slideY(begin: -0.4, end: 0, duration: 400.ms, curve: Curves.bounceOut),
          
          const SizedBox(width: 16),
          Text(
            text,
            style: GoogleFonts.outfit(
              color: Colors.redAccent,
              fontWeight: FontWeight.w600,
              letterSpacing: 2.0,
              fontSize: 12,
            ),
          )
          .animate(onPlay: (controller) => controller.repeat())
          .shimmer(duration: 1500.ms, color: Colors.white),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:google_fonts/google_fonts.dart';
import 'blood_drop_loader.dart';

class TransfusionTrajectory extends StatelessWidget {
  const TransfusionTrajectory({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0B0E14),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text("TRANSFUSION TRAJECTORY SIMULATOR", 
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
                  // Chart Container
                  Container(
                    width: isMobile ? double.infinity : 600,
                    height: 400,
                    padding: const EdgeInsets.only(top: 40, right: 30, left: 10, bottom: 10),
                    decoration: BoxDecoration(
                      color: const Color(0xFF141A23),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: Colors.cyanAccent.withOpacity(0.2)),
                      boxShadow: [
                        BoxShadow(color: Colors.cyanAccent.withOpacity(0.05), blurRadius: 20, spreadRadius: 5)
                      ]
                    ),
                    child: LineChart(
                      LineChartData(
                        minX: 0,
                        maxX: 11,
                        minY: 5,
                        maxY: 16,
                        gridData: FlGridData(
                          show: true,
                          drawVerticalLine: true,
                          getDrawingHorizontalLine: (value) => FlLine(color: Colors.white12, strokeWidth: 1),
                          getDrawingVerticalLine: (value) => FlLine(color: Colors.white12, strokeWidth: 1),
                        ),
                        titlesData: FlTitlesData(
                          bottomTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              reservedSize: 30,
                              getTitlesWidget: (value, meta) {
                                const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
                                if (value.toInt() >= 0 && value.toInt() < 12) {
                                  return Padding(
                                    padding: const EdgeInsets.only(top: 8.0),
                                    child: Text(months[value.toInt()], style: const TextStyle(color: Colors.white54, fontSize: 12)),
                                  );
                                }
                                return const Text('');
                              },
                            ),
                          ),
                          leftTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              reservedSize: 40,
                              getTitlesWidget: (value, meta) {
                                return Text("${value.toInt()}", style: const TextStyle(color: Colors.white54, fontSize: 12));
                              },
                            ),
                          ),
                          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        ),
                        borderData: FlBorderData(show: true, border: Border.all(color: Colors.white12)),
                        extraLinesData: ExtraLinesData(
                          horizontalLines: [
                            HorizontalLine(
                              y: 7.0,
                              color: Colors.redAccent.withOpacity(0.8),
                              strokeWidth: 2,
                              dashArray: [5, 5],
                              label: HorizontalLineLabel(
                                show: true,
                                labelResolver: (_) => "Critical Re-entry (< 7.0)",
                                style: const TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold, fontSize: 10),
                                alignment: Alignment.topRight,
                              )
                            )
                          ]
                        ),
                        lineTouchData: LineTouchData(
                          touchTooltipData: LineTouchTooltipData(
                            getTooltipColor: (touchedSpot) => Colors.cyan.shade900,
                            getTooltipItems: (touchedSpots) {
                              return touchedSpots.map((spot) {
                                return LineTooltipItem(
                                  "${spot.y.toStringAsFixed(1)} g/dL",
                                  const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)
                                );
                              }).toList();
                            }
                          ),
                        ),
                        lineBarsData: [
                          // Historical Line
                          LineChartBarData(
                            spots: const [
                              FlSpot(0, 9.5),
                              FlSpot(1, 10.2),
                              FlSpot(2, 11.5),
                              FlSpot(3, 13.0),
                              FlSpot(4, 14.5),
                              FlSpot(5, 12.8),
                            ],
                            isCurved: true,
                            color: Colors.tealAccent,
                            barWidth: 4,
                            isStrokeCapRound: true,
                            dotData: FlDotData(show: true, getDotPainter: (spot, percent, barData, index) => FlDotCirclePainter(radius: 4, color: Colors.tealAccent, strokeWidth: 2, strokeColor: Colors.black)),
                            belowBarData: BarAreaData(
                              show: true,
                              color: Colors.tealAccent.withOpacity(0.1),
                            ),
                          ),
                          // Predicted Line
                          LineChartBarData(
                            spots: const [
                              FlSpot(5, 12.8),
                              FlSpot(6, 11.0),
                              FlSpot(7, 9.5),
                              FlSpot(8, 8.0),
                              FlSpot(9, 6.8), // Crosses critical
                            ],
                            isCurved: true,
                            color: Colors.cyanAccent,
                            barWidth: 3,
                            isStrokeCapRound: true,
                            dashArray: [8, 4],
                            dotData: FlDotData(
                              show: true, 
                              checkToShowDot: (spot, barData) => spot.x == 9,
                              getDotPainter: (spot, percent, barData, index) {
                                return FlDotCirclePainter(radius: 6, color: Colors.amber, strokeWidth: 2, strokeColor: Colors.black);
                              }
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 40),
                  
                  // Countdown Widget
                  Container(
                    width: isMobile ? double.infinity : 400,
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.5),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.tealAccent, width: 2),
                      boxShadow: [
                        BoxShadow(color: Colors.tealAccent.withOpacity(0.2), blurRadius: 30)
                      ]
                    ),
                    child: Column(
                      children: [
                        Text("Next Transfusion due in", style: GoogleFonts.outfit(color: Colors.white70, fontSize: 16)),
                        const SizedBox(height: 10),
                        Text("12 Days", style: GoogleFonts.outfit(color: Colors.white, fontSize: 48, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 20),
                        const BloodDropLoader(text: "ANALYZING TRAJECTORY..."),
                      ],
                    ),
                  )
                ],
              ),
            ),
          );
        }
      ),
    );
  }
}

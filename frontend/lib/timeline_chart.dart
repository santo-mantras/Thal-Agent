import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'api_service.dart';
import 'patient_diary_screen.dart';

class TimelineChartScreen extends StatefulWidget {
  final Map<String, dynamic> patient;
  final bool isTab;
  
  const TimelineChartScreen({super.key, required this.patient, this.isTab = false});

  @override
  State<TimelineChartScreen> createState() => _TimelineChartScreenState();
}

class _TimelineChartScreenState extends State<TimelineChartScreen> {
  String _selectedMetric = 'Hb';
  String _selectedTimeRange = 'All Time';
  String _rangeWarningMsg = '';
  List<dynamic> _visitRecords = [];
  bool _isLoadingVisits = true;

  @override
  void initState() {
    super.initState();
    _loadVisits();
  }

  void _loadVisits() async {
    final visits = await ApiService.getVisitRecords(widget.patient['user_id']);
    if (mounted) {
      setState(() {
        _visitRecords = visits;
        _isLoadingVisits = false;
      });
    }
  }

  List<String> _getLast6Months() {
    List<String> months = [];
    DateTime now = DateTime.now();
    for (int i = 5; i >= 0; i--) {
      DateTime pastMonth = DateTime(now.year, now.month - i, 1);
      String monthStr = _getMonthName(pastMonth.month);
      months.add("$monthStr ${pastMonth.year}");
    }
    return months;
  }
  
  String _getMonthName(int m) {
    const names = ["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"];
    return names[(m - 1) % 12];
  }

  String _getFormattedDate(dynamic dateString) {
    if (dateString == null) return "Unknown";
    try {
      DateTime dt = DateTime.parse(dateString.toString());
      return "${_getMonthName(dt.month)} ${dt.day}, ${dt.year}";
    } catch (e) {
      return "Unknown";
    }
  }

  List<dynamic> _getFilteredRecords() {
    if (_visitRecords.isEmpty) return [];
    
    List<dynamic> sorted = List.from(_visitRecords);
    sorted.sort((a, b) => (b['date'] ?? '').compareTo(a['date'] ?? '')); // Descending (latest first)
    
    DateTime latestDate = DateTime.parse(sorted.first['date'] ?? DateTime.now().toIso8601String());
    
    List<dynamic> filtered = [];
    String warning = '';
    
    if (_selectedTimeRange == 'All Time') {
      filtered = sorted;
    } else if (_selectedTimeRange == 'Last 6 Months') {
      DateTime cutoff = DateTime(latestDate.year, latestDate.month - 6, latestDate.day);
      filtered = sorted.where((r) => DateTime.parse(r['date']).isAfter(cutoff)).toList();
    } else if (_selectedTimeRange == 'Last 3 Months') {
      DateTime cutoff = DateTime(latestDate.year, latestDate.month - 3, latestDate.day);
      filtered = sorted.where((r) => DateTime.parse(r['date']).isAfter(cutoff)).toList();
    } else if (int.tryParse(_selectedTimeRange) != null) {
      int year = int.parse(_selectedTimeRange);
      filtered = sorted.where((r) => DateTime.parse(r['date']).year == year).toList();
      if (filtered.isEmpty) {
        warning = '$_selectedTimeRange record not available, showing latest available data.';
        filtered = sorted; 
      }
    }
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && _rangeWarningMsg != warning) {
        setState(() {
          _rangeWarningMsg = warning;
        });
      }
    });
    
    return filtered;
  }

  @override
  Widget build(BuildContext context) {
    final monthLabels = _getLast6Months();
    double currentValue = 0;
    double minY = 0;
    double maxY = 100;
    String unit = "";
    
    switch (_selectedMetric) {
      case 'Hb':
        currentValue = widget.patient['latest_hb'] ?? 10.0;
        minY = 4; maxY = 16; unit = "g/dL";
        break;
      case 'Ferritin':
        currentValue = widget.patient['latest_ferritin'] ?? 1000.0;
        minY = 0; maxY = 5000; unit = "ng/mL";
        break;
      case 'Weight':
        currentValue = widget.patient['weight'] ?? 60.0;
        minY = 20; maxY = 150; unit = "kg";
        break;
      case 'BMI':
        currentValue = widget.patient['bmi'] ?? 22.0;
        minY = 10; maxY = 40; unit = "";
        break;
      case 'Platelets':
        currentValue = widget.patient['platelets'] ?? 250.0;
        minY = 50; maxY = 500; unit = "10^9/L";
        break;
    }

    final List<FlSpot> spots = [];
    final List<String> actualMonthLabels = [];
    
    final List<dynamic> filteredDesc = _getFilteredRecords();

    if (filteredDesc.isNotEmpty) {
      final sortedAsc = List<dynamic>.from(filteredDesc);
      sortedAsc.sort((a, b) => (a['date'] ?? '').compareTo(b['date'] ?? ''));

      for (int i = 0; i < sortedAsc.length; i++) {
        var v = sortedAsc[i];
        double yVal = currentValue;
        switch (_selectedMetric) {
          case 'Hb': yVal = (v['hb'] != null) ? (v['hb'] is num ? (v['hb'] as num).toDouble() : currentValue) : currentValue; break;
          case 'Ferritin': yVal = (v['ferritin'] != null) ? (v['ferritin'] is num ? (v['ferritin'] as num).toDouble() : currentValue) : currentValue; break;
          case 'Weight': yVal = (v['weight'] != null) ? (v['weight'] is num ? (v['weight'] as num).toDouble() : currentValue) : currentValue; break;
        }
        spots.add(FlSpot(i.toDouble(), yVal));

        try {
          DateTime dt = DateTime.parse(v['date']);
          actualMonthLabels.add("${_getMonthName(dt.month)} ${dt.year}");
        } catch (e) {
          actualMonthLabels.add("Unknown");
        }
      }
    } else {
      spots.addAll([
        FlSpot(0, currentValue * 0.9),
        FlSpot(1, currentValue * 0.95),
        FlSpot(2, currentValue * 0.8),
        FlSpot(3, currentValue * 0.85),
        FlSpot(4, currentValue * 0.9),
        FlSpot(5, currentValue),
      ]);
      actualMonthLabels.addAll(monthLabels);
    }

    double maxX = spots.isNotEmpty ? (spots.length - 1).toDouble() : 5;
    double xInterval = (maxX / 5).ceil().toDouble();
    if (xInterval < 1) xInterval = 1;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Stack(
        children: [
          // Global Background Image
          Positioned.fill(
            child: Image.asset(
              'assets/images/rbc_bg.png',
              fit: BoxFit.cover,
            ),
          ),
          // Dark Gradient Overlay
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    const Color(0xFF0B0E14).withOpacity(0.8),
                    const Color(0xFF0B0E14).withOpacity(0.95),
                  ],
                ),
              ),
            ),
          ),
          
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.only(bottom: 40),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 20),
                  // Header
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24.0),
                    child: Wrap(
                      alignment: WrapAlignment.spaceBetween,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      spacing: 16,
                      runSpacing: 16,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Medical History Timeline",
                              style: GoogleFonts.playfairDisplay(
                                fontSize: 32,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ).animate().fade().slideX(begin: -0.1),
                            if (filteredDesc.isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(top: 8.0),
                                child: Text(
                                  "Records showing from ${_getFormattedDate(filteredDesc.last['date'])} to ${_getFormattedDate(filteredDesc.first['date'])}",
                                  style: const TextStyle(fontSize: 14, color: Colors.white54),
                                ),
                              ),
                          ],
                        ),
                        Wrap(
                          spacing: 12,
                          runSpacing: 12,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                              decoration: BoxDecoration(
                                color: const Color(0xFF1A1D24).withOpacity(0.8),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: const Color(0xFF00E5FF).withOpacity(0.5)),
                              ),
                              child: DropdownButtonHideUnderline(
                                child: DropdownButton<String>(
                                  value: _selectedTimeRange,
                                  dropdownColor: const Color(0xFF1A1D24),
                                  icon: const Icon(Icons.filter_list, color: Color(0xFF00E5FF)),
                                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                                  items: const [
                                    DropdownMenuItem(value: 'All Time', child: Text("All Time")),
                                    DropdownMenuItem(value: 'Last 6 Months', child: Text("Last 6 Months")),
                                    DropdownMenuItem(value: 'Last 3 Months', child: Text("Last 3 Months")),
                                    DropdownMenuItem(value: '2026', child: Text("2026")),
                                    DropdownMenuItem(value: '2025', child: Text("2025")),
                                    DropdownMenuItem(value: '2024', child: Text("2024")),
                                  ],
                                  onChanged: (val) {
                                    setState(() { _selectedTimeRange = val!; });
                                  },
                                ),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                              decoration: BoxDecoration(
                                color: const Color(0xFF1A1D24).withOpacity(0.8),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: const Color(0xFF00E5FF).withOpacity(0.5)),
                              ),
                              child: DropdownButtonHideUnderline(
                                child: DropdownButton<String>(
                                  value: _selectedMetric,
                                  dropdownColor: const Color(0xFF1A1D24),
                                  icon: const Icon(Icons.keyboard_arrow_down, color: Color(0xFF00E5FF)),
                                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                                  items: const [
                                    DropdownMenuItem(value: 'Hb', child: Text("Hemoglobin (Hb)")),
                                    DropdownMenuItem(value: 'Ferritin', child: Text("Serum Ferritin")),
                                    DropdownMenuItem(value: 'Weight', child: Text("Weight")),
                                    DropdownMenuItem(value: 'BMI', child: Text("BMI")),
                                    DropdownMenuItem(value: 'Platelets', child: Text("Platelets")),
                                  ],
                                  onChanged: (val) {
                                    setState(() { _selectedMetric = val!; });
                                  },
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 30),
                  
                  // Chart Container
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 24),
                    padding: const EdgeInsets.only(top: 40, right: 30, left: 10, bottom: 20),
                    height: 400,
                    decoration: BoxDecoration(
                      color: const Color(0xFF1A1D24).withOpacity(0.8),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.white.withOpacity(0.1)),
                      boxShadow: [
                        BoxShadow(color: Colors.black.withOpacity(0.5), blurRadius: 20),
                      ],
                    ),
                    child: LineChart(
                      LineChartData(
                        gridData: FlGridData(
                          show: true,
                          drawVerticalLine: true,
                          getDrawingHorizontalLine: (value) {
                            return FlLine(
                              color: Colors.white.withOpacity(0.05),
                              strokeWidth: 1,
                            );
                          },
                          getDrawingVerticalLine: (value) {
                            return FlLine(
                              color: Colors.white.withOpacity(0.05),
                              strokeWidth: 1,
                            );
                          },
                        ),
                        titlesData: FlTitlesData(
                          show: true,
                          rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                          topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                          bottomTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              reservedSize: 40,
                              interval: xInterval,
                              getTitlesWidget: (value, meta) {
                                const style = TextStyle(color: Colors.white70, fontSize: 12);
                                int idx = value.toInt();
                                if (idx >= 0 && idx < actualMonthLabels.length) {
                                   return SideTitleWidget(axisSide: meta.axisSide, child: Text(actualMonthLabels[idx], style: style));
                                }
                                return SideTitleWidget(axisSide: meta.axisSide, child: const Text('', style: style));
                              },
                            ),
                          ),
                          leftTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              getTitlesWidget: (value, meta) {
                                return Text(value.toInt().toString(), style: const TextStyle(color: Colors.white70, fontSize: 12));
                              },
                              reservedSize: 40,
                            ),
                          ),
                        ),
                        borderData: FlBorderData(
                          show: true,
                          border: Border.all(color: Colors.white.withOpacity(0.1)),
                        ),
                        minX: 0,
                        maxX: maxX,
                        minY: minY,
                        maxY: maxY,
                        lineBarsData: [
                          LineChartBarData(
                            spots: spots,
                            isCurved: true,
                            color: const Color(0xFF00E5FF),
                            barWidth: 4,
                            isStrokeCapRound: true,
                            dotData: FlDotData(
                              show: true,
                              getDotPainter: (spot, percent, barData, index) {
                                return FlDotCirclePainter(
                                  radius: 6,
                                  color: const Color(0xFF00E5FF),
                                  strokeWidth: 2,
                                  strokeColor: Colors.white,
                                );
                              },
                            ),
                            belowBarData: BarAreaData(
                              show: true,
                              color: const Color(0xFF00E5FF).withOpacity(0.1),
                            ),
                            shadow: const Shadow(color: Color(0xFF00E5FF), blurRadius: 10),
                          ),
                        ],
                        lineTouchData: LineTouchData(
                          touchTooltipData: LineTouchTooltipData(
                            // tooltipBgColor: const Color(0xFF0B0E14).withOpacity(0.9), // Note: newer fl_chart uses getTooltipColor
                            getTooltipColor: (touchedSpot) => const Color(0xFF0B0E14).withOpacity(0.9),
                            tooltipRoundedRadius: 8,
                            getTooltipItems: (touchedSpots) {
                              return touchedSpots.map((LineBarSpot touchedSpot) {
                                return LineTooltipItem(
                                  '${actualMonthLabels[touchedSpot.x.toInt()]}\n',
                                  const TextStyle(color: Colors.white70, fontSize: 12),
                                  children: [
                                    TextSpan(
                                      text: '${touchedSpot.y.toStringAsFixed(1)} $unit',
                                      style: const TextStyle(
                                        color: Colors.amberAccent,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                      ),
                                    ),
                                  ],
                                );
                              }).toList();
                            },
                          ),
                        ),
                      ),
                    ),
                  ).animate().fade(delay: 200.ms).scaleXY(begin: 0.95, end: 1.0, curve: Curves.easeOutBack),
                  
                  const SizedBox(height: 24),
                  
                  if (_rangeWarningMsg.isNotEmpty)
                    Container(
                      margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.amber.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.amber.withOpacity(0.5)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.info_outline, color: Colors.amber, size: 20),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              _rangeWarningMsg,
                              style: const TextStyle(color: Colors.amber, fontSize: 13),
                            ),
                          ),
                        ],
                      ),
                    ).animate().fade(),

                  // Alert Banner
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 24),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFF3B30).withOpacity(0.15),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFFF3B30).withOpacity(0.5)),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.warning_amber_rounded,
                          color: Color(0xFFFF3B30),
                          size: 28,
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Text(
                            "$_selectedMetric is currently at ${currentValue.toStringAsFixed(1)} $unit. Keep monitoring and consulting your physician.",
                            style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w500),
                          ),
                        ),
                      ],
                    ),
                  ).animate().fade(delay: 400.ms).slideY(begin: 0.2),
                  
                  const SizedBox(height: 40),

                  // Clinical Notes History Section
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24.0),
                    child: Text(
                      "Recent Clinical Notes & Prescriptions",
                      style: GoogleFonts.outfit(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ).animate().fade(delay: 500.ms),
                  
                  const SizedBox(height: 16),
                  
                  if (_isLoadingVisits)
                    const Center(child: CircularProgressIndicator(color: Colors.cyanAccent))
                  else if (filteredDesc.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 24),
                      child: Text("No clinical notes history available.", style: TextStyle(color: Colors.white54)),
                    )
                  else
                    ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: filteredDesc.length > 4 ? 4 : filteredDesc.length,
                      itemBuilder: (context, index) {
                        final visit = filteredDesc[index];
                        final dateStr = visit['date'] != null ? visit['date'].toString().split('T')[0] : 'Unknown Date';
                        final isLatest = index == 0;
                        
                        return Container(
                          padding: const EdgeInsets.all(20),
                          margin: const EdgeInsets.only(bottom: 16),
                          decoration: BoxDecoration(
                            color: isLatest ? const Color(0xFF1A1D24).withOpacity(0.8) : const Color(0xFF1A1D24).withOpacity(0.6),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: isLatest ? const Color(0xFF00E5FF).withOpacity(0.3) : Colors.white.withOpacity(0.05)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(isLatest ? "Latest Evaluation" : "Previous Evaluation", style: GoogleFonts.outfit(color: isLatest ? const Color(0xFF00E5FF) : Colors.white70, fontWeight: FontWeight.bold, fontSize: 16)),
                                  Text(dateStr, style: const TextStyle(color: Colors.white54, fontSize: 12)),
                                ],
                              ),
                              const SizedBox(height: 16),
                              const Text("Doctor's Notes", style: TextStyle(color: Colors.white54, fontWeight: FontWeight.bold, fontSize: 12, letterSpacing: 1.1)),
                              const SizedBox(height: 4),
                              Text(visit['doctor_notes']?.toString().isNotEmpty == true ? visit['doctor_notes'] : "No notes provided.", style: const TextStyle(color: Colors.white, fontSize: 15, height: 1.4)),
                              const SizedBox(height: 16),
                              const Text("Prescription & Diet", style: TextStyle(color: Colors.white54, fontWeight: FontWeight.bold, fontSize: 12, letterSpacing: 1.1)),
                              const SizedBox(height: 4),
                              Text(visit['prescription']?.toString().isNotEmpty == true ? visit['prescription'] : "No prescription.", style: const TextStyle(color: Colors.white, fontSize: 15, height: 1.4)),
                              if (visit['hb'] != null || visit['ferritin'] != null) ...[
                                const SizedBox(height: 16),
                                const Divider(color: Colors.white12),
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    if (visit['hb'] != null) Text("Hb: ${visit['hb']} g/dL   ", style: const TextStyle(color: Colors.amberAccent, fontSize: 13, fontWeight: FontWeight.bold)),
                                    if (visit['ferritin'] != null) Text("Ferritin: ${visit['ferritin']} ng/mL", style: const TextStyle(color: Colors.amberAccent, fontSize: 13, fontWeight: FontWeight.bold)),
                                  ],
                                )
                              ]
                            ],
                          ),
                        );
                      },
                    ).animate().fade(delay: 600.ms),

                  if (!_isLoadingVisits && filteredDesc.length > 4)
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.only(bottom: 40),
                        child: Tooltip(
                          message: "Click to see all previous records",
                          child: ElevatedButton.icon(
                            onPressed: () {
                              Navigator.push(context, MaterialPageRoute(builder: (_) => PatientDiaryScreen(patient: widget.patient)));
                            },
                            icon: const Icon(Icons.info_outline, color: Colors.cyanAccent, size: 20),
                            label: const Text("Patient Diary", style: TextStyle(color: Colors.white)),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF1A1D24),
                              side: const BorderSide(color: Colors.cyanAccent),
                              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

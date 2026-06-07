import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'api_service.dart';

class PatientDiaryScreen extends StatefulWidget {
  final Map<String, dynamic> patient;

  const PatientDiaryScreen({super.key, required this.patient});

  @override
  State<PatientDiaryScreen> createState() => _PatientDiaryScreenState();
}

class _PatientDiaryScreenState extends State<PatientDiaryScreen> {
  List<dynamic> _visitRecords = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchRecords();
  }

  Future<void> _fetchRecords() async {
    try {
      final records = await ApiService.getVisitRecords(widget.patient['user_id']);
      setState(() {
        _visitRecords = records;
      });
    } catch (e) {
      // Ignore
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F2027),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Patient Diary: ${widget.patient['name']}", style: GoogleFonts.outfit()),
            if (!_isLoading && _visitRecords.isNotEmpty)
              Text(
                "Records showing from ${_getFormattedDate(_visitRecords.last['date'])} to ${_getFormattedDate(_visitRecords.first['date'])}",
                style: const TextStyle(fontSize: 12, color: Colors.white54),
              ),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.cyanAccent))
          : _visitRecords.isEmpty
              ? const Center(child: Text("No clinical notes found.", style: TextStyle(color: Colors.white54)))
              : ListView.builder(
                  padding: const EdgeInsets.all(24),
                  itemCount: _visitRecords.length,
                  itemBuilder: (context, index) {
                    final record = _visitRecords[index];
                    DateTime parsedDate;
                    try {
                      parsedDate = DateTime.parse(record['date']);
                    } catch (e) {
                      parsedDate = DateTime.now();
                    }
                    String formattedDate = DateFormat.yMMMd().format(parsedDate);

                    return Card(
                      color: const Color(0xFF141414),
                      margin: const EdgeInsets.only(bottom: 20),
                      shape: RoundedRectangleBorder(
                        side: const BorderSide(color: Colors.white24),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.calendar_today, color: Colors.cyanAccent, size: 18),
                                const SizedBox(width: 8),
                                Text(
                                  formattedDate,
                                  style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.cyanAccent),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            if (record['hb'] != null || record['ferritin'] != null) ...[
                              Text("Vitals", style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white70)),
                              const SizedBox(height: 8),
                              Wrap(
                                spacing: 16,
                                runSpacing: 8,
                                children: [
                                  if (record['hb'] != null) Text("Hb: ${record['hb']} g/dL"),
                                  if (record['ferritin'] != null) Text("Ferritin: ${record['ferritin']} ng/mL"),
                                  if (record['weight'] != null) Text("Weight: ${record['weight']} kg"),
                                  if (record['bp'] != null) Text("BP: ${record['bp']}"),
                                ],
                              ),
                              const Divider(color: Colors.white24, height: 30),
                            ],
                            if (record['doctor_notes'] != null && record['doctor_notes'].toString().isNotEmpty) ...[
                              Text("Clinical Notes", style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.amberAccent)),
                              const SizedBox(height: 8),
                              Text(record['doctor_notes'], style: const TextStyle(color: Colors.white, height: 1.5)),
                              const SizedBox(height: 16),
                            ],
                            if (record['prescription'] != null && record['prescription'].toString().isNotEmpty) ...[
                              Text("Prescription", style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.cyanAccent)),
                              const SizedBox(height: 8),
                              Text(record['prescription'], style: const TextStyle(color: Colors.white, height: 1.5)),
                            ],
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }

  String _getFormattedDate(dynamic dateString) {
    if (dateString == null) return "Unknown";
    try {
      DateTime dt = DateTime.parse(dateString.toString());
      return DateFormat.yMMMd().format(dt);
    } catch (e) {
      return "Unknown";
    }
  }
}

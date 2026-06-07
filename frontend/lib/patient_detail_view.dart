import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import 'api_service.dart';
import 'timeline_chart.dart';
import 'patient_diary_screen.dart';

class PatientDetailView extends StatefulWidget {
  final Map<String, dynamic> patient;
  final int doctorId;

  const PatientDetailView({super.key, required this.patient, required this.doctorId});

  @override
  State<PatientDetailView> createState() => _PatientDetailViewState();
}

class _PatientDetailViewState extends State<PatientDetailView> {
  final TextEditingController _notesCtrl = TextEditingController();
  final TextEditingController _prescriptionCtrl = TextEditingController();
  final TextEditingController _weightCtrl = TextEditingController();
  final TextEditingController _bmiCtrl = TextEditingController();
  final TextEditingController _bpCtrl = TextEditingController();
  final TextEditingController _sugarCtrl = TextEditingController();
  final TextEditingController _plateletsCtrl = TextEditingController();
  final TextEditingController _hbCtrl = TextEditingController();
  final TextEditingController _ferritinCtrl = TextEditingController();
  final TextEditingController _thalTypeCtrl = TextEditingController();
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _notesCtrl.text = widget.patient['doctor_notes'] ?? '';
    _prescriptionCtrl.text = widget.patient['prescription'] ?? '';
    _weightCtrl.text = widget.patient['weight']?.toString() ?? '';
    _bmiCtrl.text = widget.patient['bmi']?.toString() ?? '';
    _bpCtrl.text = widget.patient['bp']?.toString() ?? '';
    _sugarCtrl.text = widget.patient['sugar']?.toString() ?? '';
    _plateletsCtrl.text = widget.patient['platelets']?.toString() ?? '';
    _hbCtrl.text = widget.patient['latest_hb']?.toString() ?? '';
    _ferritinCtrl.text = widget.patient['latest_ferritin']?.toString() ?? '';
    _thalTypeCtrl.text = widget.patient['thalassemia_type'] ?? '';
  }

  void _saveNotes() async {
    setState(() => _isSaving = true);
    
    Map<String, dynamic> visitUpdates = {
      'doctor_id': widget.doctorId,
      'date': DateTime.now().toIso8601String(),
      'doctor_notes': _notesCtrl.text,
      'prescription': _prescriptionCtrl.text,
    };
    if (_weightCtrl.text.isNotEmpty) visitUpdates['weight'] = double.tryParse(_weightCtrl.text);
    if (_bpCtrl.text.isNotEmpty) visitUpdates['bp'] = _bpCtrl.text;
    if (_hbCtrl.text.isNotEmpty) visitUpdates['hb'] = double.tryParse(_hbCtrl.text);
    if (_ferritinCtrl.text.isNotEmpty) visitUpdates['ferritin'] = double.tryParse(_ferritinCtrl.text);

    // Call visit API
    final visitSuccess = await ApiService.addVisitRecord(widget.patient['user_id'], visitUpdates);
    
    // Also update patient profile for other static fields
    Map<String, dynamic> profileUpdates = {};
    if (_bmiCtrl.text.isNotEmpty) profileUpdates['bmi'] = double.tryParse(_bmiCtrl.text);
    if (_sugarCtrl.text.isNotEmpty) profileUpdates['sugar'] = double.tryParse(_sugarCtrl.text);
    if (_plateletsCtrl.text.isNotEmpty) profileUpdates['platelets'] = double.tryParse(_plateletsCtrl.text);
    if (_thalTypeCtrl.text.isNotEmpty) profileUpdates['thalassemia_type'] = _thalTypeCtrl.text;
    
    bool profileSuccess = true;
    if (profileUpdates.isNotEmpty) {
      profileSuccess = await ApiService.updatePatientNotes(widget.patient['user_id'], profileUpdates);
    }
    
    final success = visitSuccess && profileSuccess;
    setState(() => _isSaving = false);
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(success ? "Notes saved successfully!" : "Failed to save notes."),
          backgroundColor: success ? Colors.green : Colors.red,
        )
      );
      if (success) {
        Navigator.pop(context);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F2027),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text("Patient Digital Twin: ${widget.patient['name']}", style: GoogleFonts.outfit()),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0, top: 8.0, bottom: 8.0),
            child: ElevatedButton.icon(
              onPressed: _isSaving ? null : _saveNotes,
              icon: _isSaving ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.save, size: 18),
              label: Text(_isSaving ? "Saving..." : "Save Vitals & Notes"),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.cyan.shade800,
              ),
            ),
          )
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          bool isMobile = constraints.maxWidth < 900;
          
          final leftContent = Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                  Text("Clinical Summary", style: GoogleFonts.outfit(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.cyanAccent)),
                  const SizedBox(height: 20),
                  _buildStatRow("Age/Sex", "${widget.patient['age']} / ${widget.patient['sex']}"),
                  _buildStatRow("Thalassemia Type", widget.patient['thalassemia_type'] ?? 'Unknown'),
                  _buildStatRow("Latest Hb", "${widget.patient['latest_hb']} g/dL (Tested: ${widget.patient['date_hb_test']})"),
                  _buildStatRow("Ferritin Level", "${widget.patient['latest_ferritin']} ng/mL (Tested: ${widget.patient['date_ferritin_test']})"),
                  _buildStatRow("Next Transfusion", widget.patient['next_transfusion_date'] ?? 'Not set'),
                  _buildStatRow("Spleen Removed", widget.patient['spleen_removed'] == true ? "Yes" : "No"),
                  
                  const SizedBox(height: 40),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFF141414),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.cyan.withOpacity(0.5)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.auto_awesome, color: Colors.cyan),
                            const SizedBox(width: 10),
                            Text("AI Twin Insight", style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.w600)),
                          ],
                        ),
                        const SizedBox(height: 10),
                        const Text(
                          "Based on the patient's Ferritin levels, iron chelation therapy review is recommended. Hb levels are stable but approaching transfusion threshold.",
                          style: TextStyle(color: Colors.white70, height: 1.5),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.push(context, MaterialPageRoute(builder: (_) => PatientDiaryScreen(patient: widget.patient)));
                      },
                      icon: const Icon(Icons.book),
                      label: const Text("View Patient Diary / Files"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.teal.shade900,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.push(context, MaterialPageRoute(builder: (_) => TimelineChartScreen(patient: widget.patient)));
                      },
                      icon: const Icon(Icons.timeline),
                      label: const Text("View Medical Timeline"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.cyan.shade900,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () => _showMedicalReportsDialog(context),
                      icon: const Icon(Icons.file_copy),
                      label: const Text("View Medical Reports"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blueGrey.shade900,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                    ),
                  )
                ],
              ),
          );
          
          final rightContent = Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                  Text("Update Vitals", style: GoogleFonts.outfit(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.cyanAccent)),
                  const SizedBox(height: 10),
                  GridView.count(
                    crossAxisCount: isMobile ? 1 : 2,
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    childAspectRatio: isMobile ? 5 : 3,
                    children: [
                      _buildVitalInput("Weight (kg)", _weightCtrl),
                      _buildVitalInput("BMI", _bmiCtrl),
                      _buildVitalInput("Blood Pressure", _bpCtrl),
                      _buildVitalInput("Sugar (mg/dL)", _sugarCtrl),
                      _buildVitalInput("Platelets", _plateletsCtrl),
                      _buildVitalInput("Hb (g/dL)", _hbCtrl),
                      _buildVitalInput("Ferritin (ng/mL)", _ferritinCtrl),
                      _buildVitalInput("Thal. Type", _thalTypeCtrl),
                    ],
                  ),
                  const SizedBox(height: 30),
                  Text("Clinical Notes", style: GoogleFonts.outfit(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.cyanAccent)),
                  const SizedBox(height: 20),
                  TextField(
                    controller: _notesCtrl,
                    maxLines: 8,
                    decoration: InputDecoration(
                      hintText: "Enter observation notes, treatment plans, etc...",
                      filled: true,
                      fillColor: const Color(0xFF141414),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                  
                  const SizedBox(height: 40),
                  Text("Prescription & Diet Plan", style: GoogleFonts.outfit(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.cyanAccent)),
                  const SizedBox(height: 20),
                  TextField(
                    controller: _prescriptionCtrl,
                    maxLines: 6,
                    decoration: InputDecoration(
                      hintText: "Enter prescribed medicines (e.g., Deferasirox 500mg)...",
                      filled: true,
                      fillColor: const Color(0xFF141414),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                  
                  const SizedBox(height: 30),
                  Align(
                    alignment: Alignment.centerRight,
                    child: ElevatedButton.icon(
                      onPressed: _isSaving ? null : _saveNotes,
                      icon: _isSaving ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.save),
                      label: Text(_isSaving ? "Saving..." : "Save Updates"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.cyan.shade800,
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                      ),
                    ),
                  )
                ],
              ),
          );

          if (isMobile) {
            return SingleChildScrollView(
              child: Column(
                children: [
                  leftContent,
                  const Divider(color: Colors.white24, height: 1),
                  rightContent,
                ],
              ),
            );
          } else {
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(flex: 1, child: SingleChildScrollView(child: leftContent)),
                const VerticalDivider(color: Colors.white24, width: 1),
                Expanded(flex: 1, child: SingleChildScrollView(child: rightContent)),
              ],
            );
          }
        },
      ),
    );
  }

  Widget _buildStatRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(flex: 2, child: Text(label, style: const TextStyle(color: Colors.white54, fontWeight: FontWeight.w600))),
          Expanded(flex: 3, child: Text(value, style: const TextStyle(fontWeight: FontWeight.w500))),
        ],
      ),
    );
  }

  Widget _buildVitalInput(String label, TextEditingController ctrl) {
    return TextField(
      controller: ctrl,
      decoration: InputDecoration(
        labelText: label,
        filled: true,
        fillColor: const Color(0xFF141414),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  void _showMedicalReportsDialog(BuildContext context) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (c) => const Center(child: CircularProgressIndicator(color: Colors.cyanAccent)),
    );
    try {
      final reports = await ApiService.getPatientReports(widget.patient['user_id']);
      Navigator.pop(context); // pop loading
      showDialog(
        context: context,
        builder: (c) {
          return AlertDialog(
            backgroundColor: const Color(0xFF141414),
            shape: RoundedRectangleBorder(
              side: const BorderSide(color: Colors.white24),
              borderRadius: BorderRadius.circular(12),
            ),
            title: const Text("Medical Reports", style: TextStyle(color: Colors.cyanAccent)),
            content: SizedBox(
              width: 500,
              height: 400,
              child: reports.isEmpty 
                ? const Center(child: Text("No reports uploaded.", style: TextStyle(color: Colors.white70)))
                : ListView.builder(
                    itemCount: reports.length,
                    itemBuilder: (context, i) {
                      final r = reports[i];
                      return Card(
                        color: const Color(0xFF0F2027),
                        margin: const EdgeInsets.only(bottom: 10),
                        child: ListTile(
                          leading: const Icon(Icons.picture_as_pdf, color: Colors.redAccent),
                          title: Text("${r['report_type']} - ${r['date']}", style: const TextStyle(color: Colors.white)),
                          subtitle: Text(r['analysis_summary'] ?? 'No summary available.', style: const TextStyle(color: Colors.white54), maxLines: 2, overflow: TextOverflow.ellipsis),
                          trailing: IconButton(
                            icon: const Icon(Icons.open_in_new, color: Colors.cyanAccent),
                            onPressed: () async {
                               final link = "http://127.0.0.1:8000/${r['file_path'].replaceAll(r'\\', '/')}";
                               final uri = Uri.parse(link);
                               if (await canLaunchUrl(uri)) {
                                 await launchUrl(uri);
                               }
                            }
                          ),
                        ),
                      );
                    }
                  ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(c), child: const Text("Close", style: TextStyle(color: Colors.white)))
            ],
          );
        }
      );
    } catch (e) {
      Navigator.pop(context); // pop loading
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Error fetching reports")));
    }
  }
}

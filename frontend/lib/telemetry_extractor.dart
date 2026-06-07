import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:file_picker/file_picker.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class UploadReportScreen extends StatefulWidget {
  const UploadReportScreen({super.key});

  @override
  State<UploadReportScreen> createState() => _UploadReportScreenState();
}

class _UploadReportScreenState extends State<UploadReportScreen> {
  String _selectedReportType = 'Not Sure';
  final List<String> _reportTypes = ['CBC', 'Ferritin', 'Complete Profile', 'Not Sure'];

  String _selectedOwnership = 'Own Report';
  final List<String> _ownershipTypes = ['Own Report', 'Someone Else', 'Not Sure'];

  PlatformFile? _pickedFile;
  bool _isUploading = false;
  String _statusMessage = "";
  Color _statusColor = Colors.white70;
  Map<String, dynamic>? _analysisData;

  Future<void> _pickFile() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'png', 'jpg', 'jpeg'],
    );

    if (result != null) {
      setState(() {
        _pickedFile = result.files.first;
        _statusMessage = "";
      });
    }
  }

  Future<void> _uploadAndAnalyze() async {
    if (_pickedFile == null) {
      setState(() {
        _statusMessage = "Please select a file first.";
        _statusColor = Colors.redAccent;
      });
      return;
    }

    setState(() {
      _isUploading = true;
      _statusMessage = "AI Vision Model Parsing Biomarkers...";
      _statusColor = Colors.cyanAccent;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getInt('user_id') ?? 1;

      var request = http.MultipartRequest(
          'POST', Uri.parse('http://127.0.0.1:8000/upload-report/$userId'));

      request.fields['report_type'] = _selectedReportType;
      request.fields['is_own_report'] = _selectedOwnership;

      if (_pickedFile!.bytes != null) {
        request.files.add(http.MultipartFile.fromBytes(
          'file',
          _pickedFile!.bytes!,
          filename: _pickedFile!.name,
        ));
      } else if (_pickedFile!.path != null) {
        request.files.add(await http.MultipartFile.fromPath(
          'file',
          _pickedFile!.path!,
        ));
      }

      var response = await request.send();
      var responseData = await response.stream.bytesToString();
      var data = jsonDecode(responseData);

      if (response.statusCode == 200) {
        setState(() {
          _statusMessage = data['message'] ?? "Upload successful!";
          _statusColor = Colors.greenAccent;
          
          if(data['status'] == 'failed') {
             _statusColor = Colors.orangeAccent;
          } else if (data['data'] != null) {
             _analysisData = data['data'];
          }
        });
      } else {
        setState(() {
          _statusMessage = "Error: ${data['detail'] ?? 'Failed to upload'}";
          _statusColor = Colors.redAccent;
        });
      }
    } catch (e) {
      setState(() {
        _statusMessage = "Network error occurred. Please try again.";
        _statusColor = Colors.redAccent;
      });
    } finally {
      setState(() {
        _isUploading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0B0E14), // Deep space black
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text("UPLOAD YOUR REPORTS", 
          style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold, letterSpacing: 1.5, color: Colors.cyanAccent)),
        centerTitle: true,
      ),
      body: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF0B0E14),
        ),
        padding: const EdgeInsets.all(24.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text("AI Medical Report Analyzer", 
                style: GoogleFonts.outfit(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 10),
              Text("We automatically scrub all personally identifiable information before AI processing to ensure absolute privacy.",
                style: GoogleFonts.outfit(color: Colors.white70, fontSize: 14),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 30),
              
              _buildDropdown("Report Type", _reportTypes, _selectedReportType, (v) => setState(() => _selectedReportType = v!)),
              const SizedBox(height: 20),
              _buildDropdown("Whose Report is this?", _ownershipTypes, _selectedOwnership, (v) => setState(() => _selectedOwnership = v!)),
              
              const SizedBox(height: 30),
              
              GestureDetector(
                onTap: _isUploading ? null : _pickFile,
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 30),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.05),
                    border: Border.all(color: Colors.cyanAccent.withOpacity(0.5), width: 2),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    children: [
                      Icon(Icons.cloud_upload_outlined, size: 48, color: Colors.cyanAccent),
                      const SizedBox(height: 10),
                      Text(
                        _pickedFile != null ? _pickedFile!.name : "Tap to Select PDF or Image",
                        style: GoogleFonts.outfit(color: Colors.white, fontSize: 16),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
              
              const SizedBox(height: 30),
              
              if (_isUploading)
                const Center(child: CircularProgressIndicator(color: Colors.cyanAccent))
              else
                ElevatedButton(
                  onPressed: _uploadAndAnalyze,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.cyanAccent.withOpacity(0.2),
                    side: const BorderSide(color: Colors.cyanAccent),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: Text("ANALYZE REPORT", style: GoogleFonts.outfit(color: Colors.cyanAccent, fontWeight: FontWeight.bold, letterSpacing: 2)),
                ),
                
              const SizedBox(height: 20),
              if (_statusMessage.isNotEmpty)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: _statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: _statusColor.withOpacity(0.5))
                  ),
                  child: Text(
                    _statusMessage,
                    style: GoogleFonts.outfit(color: _statusColor, fontSize: 14),
                    textAlign: TextAlign.center,
                  ),
                ),
                
              if (_analysisData != null)
                _buildAnalysisCard(),
                
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDropdown(String label, List<String> items, String value, Function(String?) onChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: GoogleFonts.outfit(color: Colors.white70, fontSize: 14)),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white24)
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: value,
              isExpanded: true,
              dropdownColor: const Color(0xFF1A1A1A),
              icon: const Icon(Icons.keyboard_arrow_down, color: Colors.cyanAccent),
              items: items.map((e) => DropdownMenuItem(value: e, child: Text(e, style: GoogleFonts.outfit(color: Colors.white)))).toList(),
              onChanged: onChanged,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAnalysisCard() {
    return Container(
      margin: const EdgeInsets.only(top: 24),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF161B22),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.cyanAccent.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.analytics, color: Colors.cyanAccent),
              const SizedBox(width: 10),
              Text(
                "Report Analysis Summary",
                style: GoogleFonts.outfit(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const Divider(color: Colors.white24, height: 30),
          if (_analysisData!['summary'] != null) ...[
            Text("Summary", style: GoogleFonts.outfit(color: Colors.cyanAccent, fontSize: 14, fontWeight: FontWeight.w600)),
            const SizedBox(height: 5),
            Text(_analysisData!['summary'].toString(), style: GoogleFonts.outfit(color: Colors.white70, fontSize: 14)),
            const SizedBox(height: 15),
          ],
          if (_analysisData!['doctor_notes'] != null) ...[
            Text("Key Observations", style: GoogleFonts.outfit(color: Colors.cyanAccent, fontSize: 14, fontWeight: FontWeight.w600)),
            const SizedBox(height: 5),
            Text(_analysisData!['doctor_notes'].toString(), style: GoogleFonts.outfit(color: Colors.white70, fontSize: 14)),
            const SizedBox(height: 15),
          ],
          Text("Extracted Biomarkers", style: GoogleFonts.outfit(color: Colors.cyanAccent, fontSize: 14, fontWeight: FontWeight.w600)),
          const SizedBox(height: 10),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: _analysisData!.entries
                .where((e) => !['summary', 'doctor_notes', 'verified_type'].contains(e.key) && e.value != null)
                .map((e) {
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.cyanAccent.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.cyanAccent.withOpacity(0.2)),
                ),
                child: Text(
                  "${e.key.toUpperCase()}: ${e.value}",
                  style: GoogleFonts.outfit(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w500),
                ),
              );
            }).toList(),
          )
        ],
      ),
    );
  }
}

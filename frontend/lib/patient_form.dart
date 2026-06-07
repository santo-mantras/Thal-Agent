import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'dashboard.dart';

class PatientFormScreen extends StatefulWidget {
  final bool isDoctor;

  const PatientFormScreen({super.key, this.isDoctor = false});

  @override
  State<PatientFormScreen> createState() => _PatientFormScreenState();
}

class _PatientFormScreenState extends State<PatientFormScreen> {
  final _formKey = GlobalKey<FormState>();
  
  // PATIENT FIELDS
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _ageController = TextEditingController();
  final _weightController = TextEditingController();
  String? _selectedSex;
  
  // CLINICAL / DOCTOR FIELDS
  final _mrnController = TextEditingController(); // Medical Record Number
  String? _selectedSubtype;
  final _preTransfusionHbController = TextEditingController();
  final _serumFerritinController = TextEditingController();
  final _licController = TextEditingController(); // Liver Iron Concentration
  String? _splenectomyStatus;
  String? _chelationTherapy;

  final List<String> _sexOptions = ['Male', 'Female', 'Other'];
  final List<String> _subtypeOptions = ['Beta Major', 'Beta Intermedia', 'Alpha Major', 'E-Beta', 'Other'];
  final List<String> _yesNoOptions = ['Yes', 'No', 'Unknown'];
  final List<String> _chelationOptions = ['Deferasirox (Oral)', 'Deferoxamine (IV/SC)', 'Deferiprone (Oral)', 'Combination', 'None'];

  void _submitForm() {
    if (_formKey.currentState!.validate()) {
      Map<String, dynamic> patientData = {};

      if (widget.isDoctor) {
        patientData = {
          'name': _firstNameController.text.trim().isNotEmpty ? _firstNameController.text.trim() : "Patient MRN: ${_mrnController.text}",
          'age': _ageController.text.isNotEmpty ? "${_ageController.text} yrs" : "N/A",
          'weight': _weightController.text,
          'sex': _selectedSex,
          'hb': _preTransfusionHbController.text,
          'iron': _serumFerritinController.text,
          'subtype': _selectedSubtype,
          'lic': _licController.text,
          'splenectomy': _splenectomyStatus,
          'chelation': _chelationTherapy,
          'isClinical': true,
        };
      } else {
        patientData = {
          'name': "${_firstNameController.text.trim()} ${_lastNameController.text.trim()}",
          'age': "${_ageController.text} yrs",
          'weight': _weightController.text,
          'sex': _selectedSex,
          'hb': _preTransfusionHbController.text,
          'iron': _serumFerritinController.text,
          'isClinical': false,
        };
      }

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => DashboardScreen(patientData: patientData),
        ),
      );
    }
  }

  Widget _buildTextField(TextEditingController controller, String label, bool isMandatory, {TextInputType type = TextInputType.text}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: TextFormField(
        controller: controller,
        keyboardType: type,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          labelText: label + (isMandatory ? ' *' : ''),
          labelStyle: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 14),
          filled: true,
          fillColor: Colors.white.withOpacity(0.05),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.white.withOpacity(0.2)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: widget.isDoctor ? Colors.cyanAccent : Colors.redAccent),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Colors.orangeAccent),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Colors.orangeAccent),
          ),
        ),
        validator: (value) {
          if (isMandatory && (value == null || value.trim().isEmpty)) {
            return 'Required';
          }
          return null;
        },
      ),
    );
  }

  Widget _buildDropdown(String label, List<String> items, String? currentValue, Function(String?) onChanged, bool isMandatory) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: DropdownButtonFormField<String>(
        value: currentValue,
        dropdownColor: const Color(0xFF141414),
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          labelText: label + (isMandatory ? ' *' : ''),
          labelStyle: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 14),
          filled: true,
          fillColor: Colors.white.withOpacity(0.05),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.white.withOpacity(0.2)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: widget.isDoctor ? Colors.cyanAccent : Colors.redAccent),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Colors.orangeAccent),
          ),
        ),
        items: items.map((String item) {
          return DropdownMenuItem(value: item, child: Text(item));
        }).toList(),
        onChanged: onChanged,
        validator: (value) {
          if (isMandatory && value == null) {
            return 'Required';
          }
          return null;
        },
      ),
    );
  }

  Widget _buildPatientForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("Personal Details", style: GoogleFonts.outfit(fontSize: 20, color: Colors.white, fontWeight: FontWeight.bold)),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(child: _buildTextField(_firstNameController, "First Name", true)),
            const SizedBox(width: 12),
            Expanded(child: _buildTextField(_lastNameController, "Last Name", true)),
          ],
        ),
        Row(
          children: [
            Expanded(flex: 2, child: _buildTextField(_ageController, "Age (Years)", true, type: TextInputType.number)),
            const SizedBox(width: 12),
            Expanded(flex: 2, child: _buildTextField(_weightController, "Weight (kg)", true, type: TextInputType.number)),
            const SizedBox(width: 12),
            Expanded(flex: 3, child: _buildDropdown("Sex", _sexOptions, _selectedSex, (val) => setState(() => _selectedSex = val), true)),
          ],
        ),
        const Padding(
          padding: EdgeInsets.symmetric(vertical: 16.0),
          child: Divider(color: Colors.white24),
        ),
        Text("Recent Health Markers", style: GoogleFonts.outfit(fontSize: 20, color: Colors.white, fontWeight: FontWeight.bold)),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(child: _buildTextField(_preTransfusionHbController, "Last Hb Level (g/dL)", false, type: TextInputType.number)),
            const SizedBox(width: 16),
            Expanded(child: _buildTextField(_serumFerritinController, "Serum Ferritin (ng/mL)", false, type: TextInputType.number)),
          ],
        ),
      ],
    );
  }

  Widget _buildDoctorForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("Patient Identifier", style: GoogleFonts.outfit(fontSize: 20, color: Colors.cyanAccent, fontWeight: FontWeight.bold)),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(child: _buildTextField(_mrnController, "Medical Record Number (MRN)", true)),
            const SizedBox(width: 12),
            Expanded(child: _buildTextField(_firstNameController, "Patient Initials/Name", false)),
          ],
        ),
        Row(
          children: [
            Expanded(flex: 2, child: _buildTextField(_ageController, "Age", true, type: TextInputType.number)),
            const SizedBox(width: 12),
            Expanded(flex: 2, child: _buildTextField(_weightController, "Weight (kg)", true, type: TextInputType.number)),
            const SizedBox(width: 12),
            Expanded(flex: 3, child: _buildDropdown("Sex", _sexOptions, _selectedSex, (val) => setState(() => _selectedSex = val), true)),
          ],
        ),
        const Padding(
          padding: EdgeInsets.symmetric(vertical: 16.0),
          child: Divider(color: Colors.white24),
        ),
        Text("Clinical Diagnosis & Parameters", style: GoogleFonts.outfit(fontSize: 20, color: Colors.cyanAccent, fontWeight: FontWeight.bold)),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(child: _buildDropdown("Thalassemia Subtype", _subtypeOptions, _selectedSubtype, (val) => setState(() => _selectedSubtype = val), true)),
            const SizedBox(width: 16),
            Expanded(child: _buildDropdown("Splenectomy", _yesNoOptions, _splenectomyStatus, (val) => setState(() => _splenectomyStatus = val), false)),
          ],
        ),
        Row(
          children: [
            Expanded(child: _buildTextField(_preTransfusionHbController, "Pre-Transfusion Hb (g/dL)", true, type: TextInputType.number)),
            const SizedBox(width: 16),
            Expanded(child: _buildTextField(_serumFerritinController, "Serum Ferritin (ng/mL)", true, type: TextInputType.number)),
          ],
        ),
        Row(
          children: [
            Expanded(child: _buildDropdown("Chelation Therapy", _chelationOptions, _chelationTherapy, (val) => setState(() => _chelationTherapy = val), true)),
            const SizedBox(width: 16),
            Expanded(child: _buildTextField(_licController, "Liver Iron Conc. (mg/g dw)", false, type: TextInputType.number)),
          ],
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeColor = widget.isDoctor ? Colors.cyanAccent : Colors.redAccent;
    final title = widget.isDoctor ? "Clinical Assessment Portal" : "Patient Digital Twin";
    final subtitle = widget.isDoctor ? "Enter patient clinical data and lab parameters" : "Create your personalized health profile";

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: themeColor),
        title: Text(title, style: GoogleFonts.outfit(color: themeColor, fontWeight: FontWeight.bold)),
      ),
      extendBodyBehindAppBar: true,
      body: Stack(
        children: [
          // Background Gradient matching landing page aesthetic
          Container(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: Alignment.topRight,
                radius: 1.5,
                colors: widget.isDoctor
                    ? [const Color(0xFF0D252E), const Color(0xFF0A1014), const Color(0xFF05080A)]
                    : [const Color(0xFF801336), const Color(0xFF0F2027), const Color(0xFF0A1014)],
              ),
            ),
          ),
          Positioned.fill(
            child: Container(color: Colors.black.withOpacity(0.3)),
          ),
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20),
                child: Container(
                  constraints: const BoxConstraints(maxWidth: 800),
                  padding: const EdgeInsets.all(32),
                  decoration: BoxDecoration(
                    color: const Color(0xFF141414).withOpacity(0.85),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: themeColor.withOpacity(0.3), width: 1.5),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.5),
                        blurRadius: 30,
                        spreadRadius: 5,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(widget.isDoctor ? Icons.monitor_heart : Icons.bloodtype, color: themeColor, size: 36),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    title,
                                    style: GoogleFonts.playfairDisplay(
                                      fontSize: 28,
                                      fontWeight: FontWeight.bold,
                                      color: themeColor,
                                    ),
                                  ),
                                  Text(
                                    subtitle,
                                    style: GoogleFonts.outfit(fontSize: 14, color: Colors.white70),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 30),
                        
                        // Dynamically render form based on persona
                        widget.isDoctor ? _buildDoctorForm() : _buildPatientForm(),
                        
                        const SizedBox(height: 30),
                        
                        SizedBox(
                          width: double.infinity,
                          height: 55,
                          child: ElevatedButton(
                            onPressed: _submitForm,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: themeColor.withOpacity(0.9),
                              foregroundColor: Colors.black87,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              elevation: 5,
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(widget.isDoctor ? Icons.analytics : Icons.person_add, size: 24),
                                const SizedBox(width: 12),
                                Text(
                                  widget.isDoctor ? "Generate Clinical Dashboard" : "Generate Digital Twin",
                                  style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ).animate().fade(duration: 400.ms).slideY(begin: 0.05),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'api_service.dart';

class DoctorOnboarding extends StatefulWidget {
  final Map<String, dynamic> user;
  final VoidCallback onComplete;

  const DoctorOnboarding({super.key, required this.user, required this.onComplete});

  @override
  State<DoctorOnboarding> createState() => _DoctorOnboardingState();
}

class _DoctorOnboardingState extends State<DoctorOnboarding> {
  final _formKey = GlobalKey<FormState>();
  
  final TextEditingController _nameCtrl = TextEditingController();
  final TextEditingController _experienceCtrl = TextEditingController();
  final TextEditingController _hospitalCtrl = TextEditingController();
  
  String _selectedSpecialty = 'Hematologist';
  final TextEditingController _otherSpecialtyCtrl = TextEditingController();
  
  final List<String> _specialties = [
    'Hematologist',
    'Pediatrician',
    'General Physician',
    'Transfusion Medicine Specialist',
    'Other'
  ];

  bool _isLoading = false;

  Widget _buildTextField(TextEditingController controller, String label, IconData icon) {
    return TextFormField(
      controller: controller,
      style: const TextStyle(fontSize: 16),
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
        prefixIcon: Icon(icon)
      ),
      validator: (v) => v!.isEmpty ? 'Required' : null,
    );
  }

  void _submit() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() => _isLoading = true);
    
    final specialty = _selectedSpecialty == 'Other' ? _otherSpecialtyCtrl.text : _selectedSpecialty;
    
    final formData = {
      'name': _nameCtrl.text,
      'specialty': specialty,
      'experience_years': int.tryParse(_experienceCtrl.text) ?? 0,
      'hospital_name': _hospitalCtrl.text,
    };

    try {
      await ApiService.saveDoctorProfile(widget.user['id'], formData);
      widget.onComplete();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: Colors.cyanAccent));
    }

    return Theme(
      data: Theme.of(context).copyWith(
        colorScheme: const ColorScheme.dark(primary: Colors.cyanAccent),
      ),
      child: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 500),
          padding: const EdgeInsets.all(24.0),
          decoration: BoxDecoration(
            color: const Color(0xFF141414),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.cyan.withOpacity(0.3)),
          ),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    const Icon(Icons.medical_services, size: 40, color: Colors.cyanAccent),
                    const SizedBox(width: 15),
                    Text('Doctor Profile', style: GoogleFonts.outfit(fontSize: 24, fontWeight: FontWeight.bold)),
                  ],
                ),
                _buildTextField(_nameCtrl, "Full Name (e.g., Dr. Smith)", Icons.person),
                const SizedBox(height: 20),
                const Text("Specialty", style: TextStyle(color: Colors.white70, fontSize: 12)),
                const SizedBox(height: 5),
                DropdownButtonFormField<String>(
                  value: _selectedSpecialty,
                  dropdownColor: const Color(0xFF141414),
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    prefixIcon: const Icon(Icons.star, color: Colors.cyan),
                    filled: true,
                    fillColor: const Color(0xFF141414),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  items: _specialties.map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
                  onChanged: (val) => setState(() => _selectedSpecialty = val!),
                ),
                if (_selectedSpecialty == 'Other') ...[
                  const SizedBox(height: 10),
                  _buildTextField(_otherSpecialtyCtrl, "Enter your specialty", Icons.edit),
                ],
                const SizedBox(height: 20),
                TextFormField(
                  controller: _experienceCtrl,
                  style: const TextStyle(fontSize: 16),
                  decoration: const InputDecoration(
                    labelText: 'Years of Experience', 
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.timeline)
                  ),
                  keyboardType: TextInputType.number,
                  validator: (v) {
                    if (v!.isEmpty) return 'Required';
                    if (int.tryParse(v) == null) return 'Must be a number';
                    return null;
                  },
                ),
                const SizedBox(height: 20),
                TextFormField(
                  controller: _hospitalCtrl,
                  style: const TextStyle(fontSize: 16),
                  decoration: const InputDecoration(
                    labelText: 'Hospital Affiliation', 
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.local_hospital)
                  ),
                  validator: (v) => v!.isEmpty ? 'Required' : null,
                ),
                const SizedBox(height: 30),
                ElevatedButton(
                  onPressed: _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.cyan.shade800,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  child: const Text('Complete Registration', style: TextStyle(fontSize: 18, color: Colors.white)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'api_service.dart';

class PatientOnboarding extends StatefulWidget {
  final Map<String, dynamic> user;
  final VoidCallback onComplete;

  const PatientOnboarding({super.key, required this.user, required this.onComplete});

  @override
  State<PatientOnboarding> createState() => _PatientOnboardingState();
}

class _PatientOnboardingState extends State<PatientOnboarding> {
  int _currentStep = 0;
  final _formKeys = [GlobalKey<FormState>(), GlobalKey<FormState>(), GlobalKey<FormState>(), GlobalKey<FormState>()];
  
  // Data Payload
  final Map<String, dynamic> _formData = {};

  // Controllers
  final _nameCtrl = TextEditingController();
  final _ageCtrl = TextEditingController();
  final _hbCtrl = TextEditingController();
  final _ferritinCtrl = TextEditingController();
  final _t2Ctrl = TextEditingController();

  String _sex = 'Male';
  bool _isMarried = false;
  bool _hasChildren = false;
  String _partnerThal = 'No';

  String? _thalType;
  bool _takesTransfusion = false;
  String? _transVolume;
  String? _transPeriod;
  DateTime? _lastTransDate;
  
  bool _isNextTransDateFixed = true;
  DateTime? _nextTransDate;
  String? _estimatedNextTrans;
  
  bool _spleenRemoved = false;
  
  DateTime? _hbDate;
  DateTime? _ferritinDate;
  DateTime? _t2Date;

  String? _adherence;
  bool _isLoading = false;

  void _submit() async {
    setState(() => _isLoading = true);
    
    _formData['name'] = _nameCtrl.text;
    _formData['age'] = int.tryParse(_ageCtrl.text) ?? 0;
    _formData['sex'] = _sex;
    _formData['is_married'] = _isMarried;
    _formData['has_children'] = _hasChildren;
    _formData['partner_thalassemic'] = _partnerThal;
    
    _formData['thalassemia_type'] = _thalType;
    if (_takesTransfusion) {
      _formData['blood_transfusion_volume'] = _transVolume;
      _formData['blood_transfusion_frequency'] = _transPeriod;
      _formData['last_transfusion_date'] = _lastTransDate?.toIso8601String();
      if (_isNextTransDateFixed) {
        _formData['next_transfusion_date'] = _nextTransDate?.toIso8601String();
      } else {
        _formData['next_transfusion_date'] = _estimatedNextTrans;
      }
    }
    _formData['spleen_removed'] = _spleenRemoved;

    _formData['latest_hb'] = double.tryParse(_hbCtrl.text);
    _formData['date_hb_test'] = _hbDate?.toIso8601String();
    _formData['latest_ferritin'] = double.tryParse(_ferritinCtrl.text);
    _formData['date_ferritin_test'] = _ferritinDate?.toIso8601String();
    _formData['latest_t2_mri'] = double.tryParse(_t2Ctrl.text);
    _formData['date_t2_mri'] = _t2Date?.toIso8601String();

    _formData['medicine_adherence'] = _adherence;

    try {
      await ApiService.savePatientRecord(widget.user['id'], _formData);
      widget.onComplete();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _pickDate(BuildContext context, {required bool isPast, required Function(DateTime) onPicked}) async {
    final now = DateTime.now();
    final firstDate = isPast ? now.subtract(const Duration(days: 90)) : now;
    final lastDate = isPast ? now : now.add(const Duration(days: 90));

    final date = await showDatePicker(
      context: context,
      initialDate: isPast ? now : now.add(const Duration(days: 1)),
      firstDate: firstDate,
      lastDate: lastDate,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.dark(
              primary: Colors.redAccent,
              onPrimary: Colors.white,
              surface: const Color(0xFF141414),
              onSurface: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );
    if (date != null) onPicked(date);
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: Colors.redAccent));
    }

    return Theme(
      data: Theme.of(context).copyWith(
        canvasColor: const Color(0xFF141414),
        colorScheme: const ColorScheme.dark(primary: Colors.redAccent),
      ),
      child: Stepper(
        type: StepperType.vertical,
        currentStep: _currentStep,
        onStepContinue: () {
          if (_formKeys[_currentStep].currentState!.validate()) {
            if (_currentStep < 3) {
              setState(() => _currentStep += 1);
            } else {
              _submit();
            }
          }
        },
        onStepCancel: () {
          if (_currentStep > 0) setState(() => _currentStep -= 1);
        },
        steps: [
          Step(
            title: Text('Personal Details', style: GoogleFonts.outfit()),
            isActive: _currentStep >= 0,
            content: Form(
              key: _formKeys[0],
              child: Column(
                children: [
                  const SizedBox(height: 10),
                  TextFormField(
                    controller: _nameCtrl,
                    style: const TextStyle(fontSize: 18),
                    decoration: const InputDecoration(
                      labelText: 'Full Name', 
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.person)
                    ),
                    validator: (v) => v!.isEmpty ? 'Required' : null,
                  ),
                  const SizedBox(height: 20),
                  TextFormField(
                    controller: _ageCtrl,
                    style: const TextStyle(fontSize: 18),
                    decoration: const InputDecoration(
                      labelText: 'Age', 
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.cake)
                    ),
                    keyboardType: TextInputType.number,
                    validator: (v) {
                      if (v!.isEmpty) return 'Required';
                      final age = int.tryParse(v);
                      if (age == null || age < 0 || age > 120) return 'Invalid age';
                      return null;
                    },
                  ),
                  const SizedBox(height: 20),
                  DropdownButtonFormField<String>(
                    value: _sex,
                    decoration: const InputDecoration(
                      labelText: 'Sex', 
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.wc)
                    ),
                    items: ['Male', 'Female', 'Other'].map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
                    onChanged: (v) => setState(() => _sex = v!),
                  ),
                  const SizedBox(height: 20),
                  Container(
                    decoration: BoxDecoration(border: Border.all(color: Colors.white24), borderRadius: BorderRadius.circular(4)),
                    child: SwitchListTile(
                      title: const Text('Married?', style: TextStyle(fontSize: 16)),
                      value: _isMarried,
                      onChanged: (v) => setState(() => _isMarried = v),
                      activeColor: Colors.redAccent,
                    ),
                  ),
                  if (_isMarried) ...[
                    const SizedBox(height: 10),
                    Container(
                      decoration: BoxDecoration(border: Border.all(color: Colors.white24), borderRadius: BorderRadius.circular(4)),
                      child: SwitchListTile(
                        title: const Text('Do you have children?', style: TextStyle(fontSize: 16)),
                        value: _hasChildren,
                        onChanged: (v) => setState(() => _hasChildren = v),
                        activeColor: Colors.redAccent,
                      ),
                    ),
                    const SizedBox(height: 20),
                    DropdownButtonFormField<String>(
                      value: _partnerThal,
                      decoration: const InputDecoration(
                        labelText: 'Is Partner Thalassemic?', 
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.favorite)
                      ),
                      items: ['Yes', 'No', 'Don\'t Know'].map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
                      onChanged: (v) => setState(() => _partnerThal = v!),
                    ),
                  ],
                  const SizedBox(height: 10),
                ],
              ),
            ),
          ),
          Step(
            title: Text('Clinical History', style: GoogleFonts.outfit()),
            isActive: _currentStep >= 1,
            content: Form(
              key: _formKeys[1],
              child: Column(
                children: [
                  const SizedBox(height: 10),
                  DropdownButtonFormField<String>(
                    value: _thalType,
                    decoration: const InputDecoration(
                      labelText: 'Thalassemia Type (Optional)', 
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.bloodtype)
                    ),
                    items: ['Beta Major', 'Beta Minor', 'Intermedia', 'Alpha'].map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
                    onChanged: (v) => setState(() => _thalType = v),
                  ),
                  const SizedBox(height: 20),
                  Container(
                    decoration: BoxDecoration(border: Border.all(color: Colors.white24), borderRadius: BorderRadius.circular(4)),
                    child: SwitchListTile(
                      title: const Text('Do you take Blood Transfusions?', style: TextStyle(fontSize: 16)),
                      value: _takesTransfusion,
                      onChanged: (v) => setState(() => _takesTransfusion = v),
                      activeColor: Colors.redAccent,
                    ),
                  ),
                  if (_takesTransfusion) ...[
                    const SizedBox(height: 20),
                    DropdownButtonFormField<String>(
                      value: _transVolume,
                      decoration: const InputDecoration(
                        labelText: 'Blood Quantity', 
                        border: OutlineInputBorder(),
                      ),
                      items: ['250ml', '400-500ml', '500-600ml', '700-800ml', '900-1200ml', '1500+ml'].map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
                      onChanged: (v) => setState(() => _transVolume = v),
                    ),
                    const SizedBox(height: 20),
                    DropdownButtonFormField<String>(
                      value: _transPeriod,
                      decoration: const InputDecoration(
                        labelText: 'Period of Transfusion', 
                        border: OutlineInputBorder(),
                      ),
                      items: ['Every 10 Days', '15 Days', '20-25 Days', '30-35 Days', '40-60 Days'].map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
                      onChanged: (v) => setState(() => _transPeriod = v),
                    ),
                    const SizedBox(height: 20),
                    Container(
                      decoration: BoxDecoration(border: Border.all(color: Colors.white24), borderRadius: BorderRadius.circular(4)),
                      child: ListTile(
                        title: Text(_lastTransDate == null ? 'Select Last Transfusion Date' : 'Last Transfusion: ${DateFormat('yyyy-MM-dd').format(_lastTransDate!)}'),
                        trailing: const Icon(Icons.calendar_month, color: Colors.redAccent),
                        onTap: () => _pickDate(context, isPast: true, onPicked: (d) => setState(() => _lastTransDate = d)),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Container(
                      decoration: BoxDecoration(border: Border.all(color: Colors.white24), borderRadius: BorderRadius.circular(4)),
                      child: SwitchListTile(
                        title: const Text('Is the next Transfusion Date fixed?'),
                        value: _isNextTransDateFixed,
                        onChanged: (v) => setState(() => _isNextTransDateFixed = v),
                        activeColor: Colors.redAccent,
                      ),
                    ),
                    const SizedBox(height: 10),
                    if (_isNextTransDateFixed)
                      Container(
                        decoration: BoxDecoration(border: Border.all(color: Colors.white24), borderRadius: BorderRadius.circular(4)),
                        child: ListTile(
                          title: Text(_nextTransDate == null ? 'Select Next Transfusion Date' : 'Next Transfusion: ${DateFormat('yyyy-MM-dd').format(_nextTransDate!)}'),
                          trailing: const Icon(Icons.calendar_month, color: Colors.redAccent),
                          onTap: () => _pickDate(context, isPast: false, onPicked: (d) => setState(() => _nextTransDate = d)),
                        ),
                      )
                    else
                      DropdownButtonFormField<String>(
                        value: _estimatedNextTrans,
                        decoration: const InputDecoration(
                          labelText: 'Estimate Next Transfusion', 
                          border: OutlineInputBorder(),
                        ),
                        items: ['In 10 Days', 'In 15 Days', 'In 20 Days', 'In 30 Days'].map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
                        onChanged: (v) => setState(() => _estimatedNextTrans = v),
                      ),
                  ],
                  const SizedBox(height: 20),
                  Container(
                    decoration: BoxDecoration(border: Border.all(color: Colors.white24), borderRadius: BorderRadius.circular(4)),
                    child: SwitchListTile(
                      title: const Text('Spleen Removed?', style: TextStyle(fontSize: 16)),
                      value: _spleenRemoved,
                      onChanged: (v) => setState(() => _spleenRemoved = v),
                      activeColor: Colors.redAccent,
                    ),
                  ),
                  const SizedBox(height: 10),
                ],
              ),
            ),
          ),
          Step(
            title: Text('Test Results', style: GoogleFonts.outfit()),
            isActive: _currentStep >= 2,
            content: Form(
              key: _formKeys[2],
              child: Column(
                children: [
                  const SizedBox(height: 10),
                  TextFormField(
                    controller: _hbCtrl,
                    style: const TextStyle(fontSize: 18),
                    decoration: const InputDecoration(
                      labelText: 'Latest Hemoglobin (g/dL)', 
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.opacity)
                    ),
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    validator: (v) {
                      if (v == null || v.isEmpty) return null;
                      final hb = double.tryParse(v);
                      if (hb == null || hb < 2.0 || hb > 20.0) return 'Enter a valid Hb (e.g., 7.5)';
                      return null;
                    },
                  ),
                  const SizedBox(height: 10),
                  Container(
                    decoration: BoxDecoration(border: Border.all(color: Colors.white24), borderRadius: BorderRadius.circular(4)),
                    child: ListTile(
                      title: Text(_hbDate == null ? 'Select Date of Hb Test' : 'Hb Test Date: ${DateFormat('yyyy-MM-dd').format(_hbDate!)}'),
                      trailing: const Icon(Icons.calendar_month, color: Colors.redAccent),
                      onTap: () => _pickDate(context, isPast: true, onPicked: (d) => setState(() => _hbDate = d)),
                    ),
                  ),
                  const SizedBox(height: 20),
                  TextFormField(
                    controller: _ferritinCtrl,
                    style: const TextStyle(fontSize: 18),
                    decoration: const InputDecoration(
                      labelText: 'Latest Serum Ferritin (ng/mL)', 
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.science)
                    ),
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    validator: (v) {
                      if (v == null || v.isEmpty) return null;
                      final f = double.tryParse(v);
                      if (f == null || f < 0 || f > 20000) return 'Enter a valid Ferritin level';
                      return null;
                    },
                  ),
                  const SizedBox(height: 10),
                  Container(
                    decoration: BoxDecoration(border: Border.all(color: Colors.white24), borderRadius: BorderRadius.circular(4)),
                    child: ListTile(
                      title: Text(_ferritinDate == null ? 'Select Date of Ferritin Test' : 'Ferritin Date: ${DateFormat('yyyy-MM-dd').format(_ferritinDate!)}'),
                      trailing: const Icon(Icons.calendar_month, color: Colors.redAccent),
                      onTap: () => _pickDate(context, isPast: true, onPicked: (d) => setState(() => _ferritinDate = d)),
                    ),
                  ),
                  const SizedBox(height: 10),
                ],
              ),
            ),
          ),
          Step(
            title: Text('Medication Adherence', style: GoogleFonts.outfit()),
            isActive: _currentStep >= 3,
            content: Form(
              key: _formKeys[3],
              child: Column(
                children: [
                  const SizedBox(height: 10),
                  DropdownButtonFormField<String>(
                    value: _adherence,
                    decoration: const InputDecoration(
                      labelText: 'Do you take medicine regularly?', 
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.medication)
                    ),
                    items: [
                      'Always on time',
                      'Miss sometimes',
                      'Miss most of the time due to poor time management',
                    ].map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
                    onChanged: (v) => setState(() => _adherence = v),
                    validator: (v) => v == null ? 'Required' : null,
                  ),
                  const SizedBox(height: 10),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

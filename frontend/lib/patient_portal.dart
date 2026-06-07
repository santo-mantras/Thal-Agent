import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'dart:convert';
import 'api_service.dart';
import 'landing_page.dart';
import 'patient_onboarding.dart';
import 'timeline_chart.dart';
import 'patient_diary_screen.dart';
import 'transfusion_trajectory.dart';
import 'telemetry_extractor.dart';
import 'chelation_radar.dart';
import 'dart:ui';

class PatientPortal extends StatefulWidget {
  const PatientPortal({super.key});

  @override
  State<PatientPortal> createState() => _PatientPortalState();
}

class _PatientPortalState extends State<PatientPortal> {
  Map<String, dynamic>? currentUser;
  Map<String, dynamic>? patientRecord;
  bool isLoading = true;

  // Chat Variables
  final TextEditingController _chatCtrl = TextEditingController();
  final ScrollController _scrollCtrl = ScrollController();
  List<Map<String, String>> _messages = [];
  bool _isTyping = false;
  List<dynamic> _chatSessions = [];
  bool _isChatExpanded = false;
  final FocusNode _chatFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _loadData();
    _chatFocusNode.addListener(() {
      if (_chatFocusNode.hasFocus && !_isChatExpanded) {
        setState(() => _isChatExpanded = true);
        _scrollToBottom();
      }
    });
  }

  @override
  void dispose() {
    _chatFocusNode.dispose();
    _chatCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    final user = await ApiService.getCurrentUser();
    if (user == null) {
      if (mounted) {
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const LandingPage()));
      }
      return;
    }
    
    setState(() {
      currentUser = user;
    });

    try {
      final record = await ApiService.getPatientRecord(user['id']);
      if (record.isNotEmpty) {
        setState(() {
          patientRecord = record;
        });
        _loadChatHistory();
      }
    } catch (e) {
      // no record yet
    }
    setState(() {
      isLoading = false;
    });
    _loadChatSessions();
  }

  void _loadChatSessions() async {
    final sessions = await ApiService.getChatSessions(currentUser!['id']);
    if (mounted) {
      setState(() {
        _chatSessions = sessions;
      });
    }
  }

  void _startNewChat() async {
    if (_messages.isNotEmpty) {
      await ApiService.saveChatSession(currentUser!['id'], _messages);
    }
    setState(() {
      _messages.clear();
      _isChatExpanded = true;
    });
    _loadChatSessions();
    _triggerProactiveAnalysis();
  }

  void _loadOldSession(String messagesJson) {
    if (_messages.isNotEmpty) {
      ApiService.saveChatSession(currentUser!['id'], _messages);
    }
    final List<dynamic> decoded = json.decode(messagesJson);
    setState(() {
      _messages = decoded.map((e) => Map<String, String>.from(e)).toList();
      _isChatExpanded = true;
    });
    _loadChatSessions();
    _scrollToBottom();
  }

  Future<void> _loadChatHistory() async {
    if (_messages.isEmpty) {
      _triggerProactiveAnalysis();
    }
  }

  void _triggerProactiveAnalysis() async {
    setState(() => _isTyping = true);
    
    String contextStr = "Patient Name: ${patientRecord?['name']}. Age: ${patientRecord?['age']}. "
        "Latest Hb: ${patientRecord?['latest_hb']}. Last Transfusion: ${patientRecord?['last_transfusion_date']}. "
        "Ferritin: ${patientRecord?['latest_ferritin']}. Adherence: ${patientRecord?['medicine_adherence']}.";
        
    String prompt = "You are a friendly Thalassemia AI. Analyze my data and give me a proactive, engaging summary of how I am doing. If my Hb is low (<6) or transfusion is overdue, encourage me to book an appointment. If I am doing well, praise me. Keep it conversational.";
    
    final response = await ApiService.askAI(prompt, context: contextStr);
    
    if (mounted) {
      setState(() {
        _messages.add({"role": "agent", "text": response});
        _isTyping = false;
      });
      _scrollToBottom();
    }
  }

  void _sendMessage() async {
    if (_chatCtrl.text.trim().isEmpty) return;
    String userMsg = _chatCtrl.text;
    
    setState(() {
      _messages.add({"role": "user", "text": userMsg});
      _chatCtrl.clear();
      _isTyping = true;
      _isChatExpanded = true;
    });
    
    _scrollToBottom();
    
    String contextStr = "Patient Name: ${patientRecord?['name']}. Age: ${patientRecord?['age']}. Weight: ${patientRecord?['weight']}. Height: ${patientRecord?['height']}. BMI: ${patientRecord?['bmi']}. Latest Hb: ${patientRecord?['latest_hb']}. Ferritin: ${patientRecord?['latest_ferritin']}. Platelets: ${patientRecord?['platelets']}. BP: ${patientRecord?['bp']}. Sugar: ${patientRecord?['sugar']}. Doctor: Dr. ${patientRecord?['doctor_name'] ?? 'Not Assigned'}.";
    final response = await ApiService.askAI(userMsg, context: contextStr, chatHistory: _messages);
    
    if (mounted) {
      setState(() {
        _messages.add({"role": "agent", "text": response});
        _isTyping = false;
      });
      _scrollToBottom();
    }
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(_scrollCtrl.position.maxScrollExtent, duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
      }
    });
  }

  void _logout() async {
    await ApiService.logout();
    if (mounted) {
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const LandingPage()));
    }
  }

  void _showUpdateDialog() {
    final nameCtrl = TextEditingController(text: patientRecord?['name']);
    final hbCtrl = TextEditingController(text: patientRecord?['latest_hb']?.toString());
    final ferCtrl = TextEditingController(text: patientRecord?['latest_ferritin']?.toString());
    final weightCtrl = TextEditingController(text: patientRecord?['weight']?.toString());
    final heightCtrl = TextEditingController(text: patientRecord?['height']?.toString());
    final bpCtrl = TextEditingController(text: patientRecord?['bp']?.toString());
    final sugarCtrl = TextEditingController(text: patientRecord?['sugar']?.toString());
    final plateletsCtrl = TextEditingController(text: patientRecord?['platelets']?.toString());
    final cityCtrl = TextEditingController(text: patientRecord?['city'] ?? '');
    final stateCtrl = TextEditingController(text: patientRecord?['state'] ?? '');
    final hospitalNameCtrl = TextEditingController(text: patientRecord?['hospital_name'] ?? '');

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1A1D24),
          title: Text("Update Profile & Vitals", style: GoogleFonts.outfit(color: Colors.white)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(controller: nameCtrl, style: const TextStyle(color: Colors.white), decoration: const InputDecoration(labelText: "Full Name", labelStyle: TextStyle(color: Colors.white54))),
                TextField(controller: hbCtrl, style: const TextStyle(color: Colors.white), decoration: const InputDecoration(labelText: "Latest Hb (g/dL)", labelStyle: TextStyle(color: Colors.white54))),
                TextField(controller: ferCtrl, style: const TextStyle(color: Colors.white), decoration: const InputDecoration(labelText: "Latest Ferritin (ng/mL)", labelStyle: TextStyle(color: Colors.white54))),
                TextField(controller: weightCtrl, style: const TextStyle(color: Colors.white), decoration: const InputDecoration(labelText: "Weight (kg)", labelStyle: TextStyle(color: Colors.white54))),
                TextField(controller: heightCtrl, style: const TextStyle(color: Colors.white), decoration: const InputDecoration(labelText: "Height (cm)", labelStyle: TextStyle(color: Colors.white54))),
                TextField(controller: bpCtrl, style: const TextStyle(color: Colors.white), decoration: const InputDecoration(labelText: "Blood Pressure", labelStyle: TextStyle(color: Colors.white54))),
                TextField(controller: sugarCtrl, style: const TextStyle(color: Colors.white), decoration: const InputDecoration(labelText: "Blood Sugar", labelStyle: TextStyle(color: Colors.white54))),
                TextField(controller: plateletsCtrl, style: const TextStyle(color: Colors.white), decoration: const InputDecoration(labelText: "Platelets (10^9/L)", labelStyle: TextStyle(color: Colors.white54))),
                TextField(controller: cityCtrl, style: const TextStyle(color: Colors.white), decoration: const InputDecoration(labelText: "City", labelStyle: TextStyle(color: Colors.white54))),
                TextField(controller: stateCtrl, style: const TextStyle(color: Colors.white), decoration: const InputDecoration(labelText: "State", labelStyle: TextStyle(color: Colors.white54))),
                TextField(controller: hospitalNameCtrl, style: const TextStyle(color: Colors.white), decoration: const InputDecoration(labelText: "Hospital Name", labelStyle: TextStyle(color: Colors.white54))),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel", style: TextStyle(color: Colors.white54))),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF00E5FF), foregroundColor: Colors.black),
              onPressed: () async {
                Map<String, dynamic> updates = {
                  'name': nameCtrl.text.isNotEmpty ? nameCtrl.text : patientRecord!['name'],
                  'age': patientRecord!['age'],
                  'sex': patientRecord!['sex'],
                };
                if (hbCtrl.text.isNotEmpty) updates['latest_hb'] = double.tryParse(hbCtrl.text);
                if (ferCtrl.text.isNotEmpty) updates['latest_ferritin'] = double.tryParse(ferCtrl.text);
                if (weightCtrl.text.isNotEmpty) updates['weight'] = double.tryParse(weightCtrl.text);
                if (heightCtrl.text.isNotEmpty) updates['height'] = double.tryParse(heightCtrl.text);
                if (bpCtrl.text.isNotEmpty) updates['bp'] = bpCtrl.text;
                if (sugarCtrl.text.isNotEmpty) updates['sugar'] = double.tryParse(sugarCtrl.text);
                if (plateletsCtrl.text.isNotEmpty) updates['platelets'] = double.tryParse(plateletsCtrl.text);
                if (cityCtrl.text.isNotEmpty) updates['city'] = cityCtrl.text;
                if (stateCtrl.text.isNotEmpty) updates['state'] = stateCtrl.text;
                if (hospitalNameCtrl.text.isNotEmpty) updates['hospital_name'] = hospitalNameCtrl.text;
                
                try {
                  await ApiService.savePatientRecord(currentUser!['id'], updates);
                } catch (e) {
                  // Ignore for now
                }
                
                _loadData(); // reload
                if (mounted) Navigator.pop(context);
              },
              child: const Text("Save"),
            )
          ],
        );
      }
    );
  }

  List<InlineSpan> _buildHighlightedText(String text) {
    List<InlineSpan> spans = [];
    text.splitMapJoin(
      RegExp(r'\b\d+(\.\d+)?\s*(g/dL|ng/mL)\b'),
      onMatch: (m) {
        spans.add(TextSpan(text: m.group(0), style: const TextStyle(color: Colors.amberAccent, fontWeight: FontWeight.bold)));
        return '';
      },
      onNonMatch: (n) {
        spans.add(TextSpan(text: n, style: const TextStyle(color: Colors.white, height: 1.5)));
        return '';
      }
    );
    return spans;
  }

  Widget _buildAdvancedNavButton(BuildContext context, String title, IconData icon, VoidCallback onTap) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: onTap,
        icon: Icon(icon, color: Colors.amberAccent),
        label: Text(title, style: const TextStyle(color: Colors.white)),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.amber.withOpacity(0.1),
          side: BorderSide(color: Colors.amberAccent.withOpacity(0.5)),
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          alignment: Alignment.centerLeft,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading || currentUser == null) {
      return const Scaffold(
        backgroundColor: Color(0xFF0B0E14),
        body: Center(child: CircularProgressIndicator(color: Color(0xFFFF3B30))),
      );
    }

    if (patientRecord == null) {
      return Scaffold(
        backgroundColor: const Color(0xFF0B0E14),
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () async {
              await ApiService.logout();
              if (mounted) {
                Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const LandingPage()));
              }
            },
          ),
          title: const Text('Cancel Registration', style: TextStyle(color: Colors.white, fontSize: 16)),
        ),
        body: Center(
          child: PatientOnboarding(
            user: currentUser!,
            onComplete: () {
              _loadData();
            },
          ),
        ),
      );
    }

    double hb = patientRecord?['latest_hb'] != null ? (patientRecord!['latest_hb'] is int ? (patientRecord!['latest_hb'] as int).toDouble() : patientRecord!['latest_hb']) : 0.0;
    bool isCriticalHb = hb > 0 && hb < 7.0;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        title: Text(
          "Patient Portal - ${patientRecord?['name']}",
          style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(icon: const Icon(Icons.edit, color: Colors.cyanAccent), onPressed: _showUpdateDialog),
          IconButton(icon: const Icon(Icons.logout, color: Colors.white54), onPressed: _logout),
        ],
      ),
      drawer: Drawer(
        backgroundColor: const Color(0xFF0B0E14),
        child: Column(
          children: [
            DrawerHeader(
              decoration: BoxDecoration(color: const Color(0xFF1A1D24).withOpacity(0.8)),
              child: Center(child: Text("Chat History", style: GoogleFonts.outfit(fontSize: 24, color: const Color(0xFF00E5FF)))),
            ),
            Expanded(
              child: ListView.builder(
                itemCount: _chatSessions.length,
                itemBuilder: (context, index) {
                  final session = _chatSessions[index];
                  List<dynamic> msgs = json.decode(session['messages']);
                  String preview = msgs.isNotEmpty ? msgs.first['text'] : "Empty Chat";
                  if (preview.length > 30) preview = preview.substring(0, 30) + "...";
                  return ListTile(
                    leading: const Icon(Icons.chat_bubble_outline, color: Colors.white54),
                    title: Text(preview, style: const TextStyle(color: Colors.white)),
                    subtitle: Text(session['created_at'].split('T')[0], style: const TextStyle(color: Colors.white38)),
                    onTap: () {
                      Navigator.pop(context); // close drawer
                      _loadOldSession(session['messages']);
                    },
                  );
                },
              ),
            )
          ],
        ),
      ),
      body: Stack(
        children: [
          // Background Image
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
                    const Color(0xFF0B0E14).withOpacity(0.7),
                    const Color(0xFF0B0E14).withOpacity(0.9),
                  ],
                ),
              ),
            ),
          ),
          // Content
          SafeArea(
            child: Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        bool isMobile = constraints.maxWidth < 900;
                        return Wrap(
                          spacing: 24,
                          runSpacing: 24,
                          alignment: WrapAlignment.start,
                          children: [
                            // 1. Health Vitals Card (Red Theme)
                            Container(
                              width: isMobile ? constraints.maxWidth : (constraints.maxWidth - 48) / 3,
                              padding: const EdgeInsets.all(24),
                              decoration: BoxDecoration(
                                color: const Color(0xFF1A1D24).withOpacity(0.8),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: const Color(0xFFFF3B30).withOpacity(0.3)),
                                boxShadow: [BoxShadow(color: const Color(0xFFFF3B30).withOpacity(0.1), blurRadius: 20)],
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(isCriticalHb ? "Latest Hb (CRITICAL)" : "Latest Hb", style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold, color: isCriticalHb ? const Color(0xFFFF3B30) : Colors.white70)),
                                  const SizedBox(height: 8),
                                  Text("${patientRecord?['latest_hb'] ?? 'N/A'} g/dL", style: GoogleFonts.outfit(fontSize: 48, fontWeight: FontWeight.bold, color: isCriticalHb ? const Color(0xFFFF3B30) : Colors.white)),
                                  const SizedBox(height: 24),
                                  Text("Latest Ferritin", style: GoogleFonts.outfit(fontSize: 14, color: Colors.white70)),
                                  Text("${patientRecord?['latest_ferritin'] ?? 'N/A'} ng/mL", style: GoogleFonts.outfit(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white)),
                                  const SizedBox(height: 24),
                                  const Divider(color: Colors.white12),
                                  const SizedBox(height: 12),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text("Weight", style: GoogleFonts.outfit(fontSize: 12, color: Colors.white54)),
                                          Text("${patientRecord?['weight'] ?? 'N/A'} kg", style: GoogleFonts.outfit(fontSize: 16, color: Colors.white)),
                                        ],
                                      ),
                                      Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text("BMI", style: GoogleFonts.outfit(fontSize: 12, color: Colors.white54)),
                                          Text("${patientRecord?['bmi'] ?? 'N/A'}", style: GoogleFonts.outfit(fontSize: 16, color: Colors.white)),
                                        ],
                                      ),
                                    ],
                                  )
                                ],
                              ),
                            ).animate().fade(delay: 200.ms).slideY(begin: 0.1),

                            // 2. AI Insight & Notes Card (Teal Theme)
                            Container(
                              width: isMobile ? constraints.maxWidth : (constraints.maxWidth - 48) / 3,
                              padding: const EdgeInsets.all(24),
                              decoration: BoxDecoration(
                                color: const Color(0xFF1A1D24).withOpacity(0.8),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: const Color(0xFF00E5FF).withOpacity(0.3)),
                                boxShadow: [BoxShadow(color: const Color(0xFF00E5FF).withOpacity(0.1), blurRadius: 20)],
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      const Icon(Icons.auto_awesome, color: Color(0xFF00E5FF), size: 20),
                                      const SizedBox(width: 8),
                                      Text("AI Insights", style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold, color: const Color(0xFF00E5FF))),
                                    ],
                                  ),
                                  const SizedBox(height: 16),
                                  RichText(
                                    text: TextSpan(
                                      children: _buildHighlightedText(
                                        isCriticalHb 
                                          ? "Clinical Alert: Your Hb level of ${patientRecord?['latest_hb']} g/dL is significantly below the safe threshold. Immediate consultation is advised. Additionally, your Ferritin is ${patientRecord?['latest_ferritin']} ng/mL, requiring continued chelation therapy adherence." 
                                          : "Your health vitals are currently stable with an Hb level of ${patientRecord?['latest_hb']} g/dL and Ferritin of ${patientRecord?['latest_ferritin']} ng/mL. Keep tracking your parameters and attend your scheduled appointments."
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ).animate().fade(delay: 300.ms).slideY(begin: 0.1),

                            // 3. Actions Card (Teal Theme)
                            Container(
                              width: isMobile ? constraints.maxWidth : (constraints.maxWidth - 48) / 3,
                              padding: const EdgeInsets.all(24),
                              decoration: BoxDecoration(
                                color: const Color(0xFF1A1D24).withOpacity(0.8),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: Colors.white.withOpacity(0.1)),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text("Quick Actions", style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                                  const SizedBox(height: 20),
                                  SizedBox(
                                    width: double.infinity,
                                    child: ElevatedButton(
                                      onPressed: () {
                                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Redirecting to Appointment Scheduler...")));
                                      },
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: const Color(0xFF006064),
                                        padding: const EdgeInsets.symmetric(vertical: 16),
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                      ),
                                      child: const Text("Schedule Transfusion Appointment", style: TextStyle(color: Colors.white), textAlign: TextAlign.center),
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  SizedBox(
                                    width: double.infinity,
                                    child: ElevatedButton(
                                      onPressed: () {
                                        Navigator.push(context, MaterialPageRoute(builder: (_) => TimelineChartScreen(patient: patientRecord!)));
                                      },
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: const Color(0xFF006064),
                                        padding: const EdgeInsets.symmetric(vertical: 16),
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                      ),
                                      child: const Text("Go to History Timeline", style: TextStyle(color: Colors.white), textAlign: TextAlign.center),
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  SizedBox(
                                    width: double.infinity,
                                    child: ElevatedButton(
                                      onPressed: () {
                                        _chatFocusNode.requestFocus();
                                        setState(() => _isChatExpanded = true);
                                      },
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: const Color(0xFF006064),
                                        padding: const EdgeInsets.symmetric(vertical: 16),
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                      ),
                                      child: const Text("Ask AI", style: TextStyle(color: Colors.white), textAlign: TextAlign.center),
                                    ),
                                  ),
                                ],
                              ),
                            ).animate().fade(delay: 400.ms).slideY(begin: 0.1),

                            // 4. Advanced Hub Card (Sci-Fi Theme)
                            Container(
                              width: isMobile ? constraints.maxWidth : (constraints.maxWidth - 48) / 3,
                              padding: const EdgeInsets.all(24),
                              decoration: BoxDecoration(
                                color: const Color(0xFF1A1D24).withOpacity(0.8),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: Colors.amberAccent.withOpacity(0.3)),
                                boxShadow: [BoxShadow(color: Colors.amberAccent.withOpacity(0.1), blurRadius: 20)],
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      const Icon(Icons.science, color: Colors.amberAccent, size: 20),
                                      const SizedBox(width: 8),
                                      Text("Advanced Hub", style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.amberAccent)),
                                    ],
                                  ),
                                  const SizedBox(height: 16),
                                  _buildAdvancedNavButton(context, "Patient Diary", Icons.book, () {
                                    Navigator.push(context, MaterialPageRoute(builder: (_) => PatientDiaryScreen(patient: patientRecord!)));
                                  }),
                                  const SizedBox(height: 12),
                                  _buildAdvancedNavButton(context, "Transfusion Trajectory", Icons.show_chart, () {
                                    Navigator.push(context, MaterialPageRoute(builder: (_) => const TransfusionTrajectory()));
                                  }),
                                  const SizedBox(height: 12),
                                  _buildAdvancedNavButton(context, "Upload Your Reports", Icons.document_scanner, () {
                                    Navigator.push(context, MaterialPageRoute(builder: (_) => const UploadReportScreen()));
                                  }),
                                  const SizedBox(height: 12),
                                  _buildAdvancedNavButton(context, "Chelation Radar", Icons.radar, () {
                                    Navigator.push(context, MaterialPageRoute(builder: (_) => const ChelationRadar()));
                                  }),
                                ],
                              ),
                            ).animate().fade(delay: 500.ms).slideY(begin: 0.1),
                          ],
                        );
                      },
                    ),
                  ),
                ),
                
                // Fixed Bottom AI Chat Area
                AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                  height: _isChatExpanded ? 400 : 90,
                  decoration: BoxDecoration(
                    color: const Color(0xFF0B0E14),
                    border: Border(top: BorderSide(color: const Color(0xFF00E5FF).withOpacity(0.3), width: 1)),
                    boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.5), blurRadius: 10, offset: const Offset(0, -5))],
                  ),
                  child: Column(
                    children: [
                      // Expand/Collapse drag handle
                      GestureDetector(
                        onTap: () => setState(() => _isChatExpanded = !_isChatExpanded),
                        child: Container(
                          width: double.infinity,
                          height: 20,
                          color: Colors.transparent,
                          alignment: Alignment.center,
                          child: Container(
                            width: 40,
                            height: 4,
                            decoration: BoxDecoration(color: Colors.white38, borderRadius: BorderRadius.circular(2)),
                          ),
                        ),
                      ),
                      
                      if (_isChatExpanded)
                        Expanded(
                          child: ListView.builder(
                            controller: _scrollCtrl,
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                            itemCount: _messages.length + (_isTyping ? 1 : 0),
                            itemBuilder: (context, index) {
                              if (index == _messages.length && _isTyping) {
                                return const Align(
                                  alignment: Alignment.centerLeft,
                                  child: Padding(
                                    padding: EdgeInsets.all(16.0),
                                    child: CircularProgressIndicator(color: Color(0xFF00E5FF)),
                                  ),
                                );
                              }
                              
                              final msg = _messages[index];
                              final isAgent = msg['role'] == 'agent';
                              
                              return Align(
                                alignment: isAgent ? Alignment.centerLeft : Alignment.centerRight,
                                child: Container(
                                  margin: const EdgeInsets.symmetric(vertical: 8),
                                  padding: const EdgeInsets.all(16),
                                  constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.7),
                                  decoration: BoxDecoration(
                                    color: isAgent ? const Color(0xFF1A1D24) : const Color(0xFF006064),
                                    borderRadius: BorderRadius.circular(16),
                                    border: isAgent ? Border.all(color: Colors.white.withOpacity(0.1)) : null,
                                  ),
                                  child: isAgent 
                                    ? MarkdownBody(
                                        data: msg['text']!,
                                        styleSheet: MarkdownStyleSheet(
                                          p: GoogleFonts.outfit(fontSize: 14, color: Colors.white),
                                          strong: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.amberAccent),
                                        ),
                                      )
                                    : Text(
                                        msg['text']!,
                                        style: GoogleFonts.outfit(fontSize: 14, color: Colors.white),
                                      ),
                                ),
                              );
                            },
                          ),
                        ),
                        
                      // Input Row
                      Padding(
                        padding: const EdgeInsets.fromLTRB(20, 0, 20, 15),
                        child: Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: _chatCtrl,
                                focusNode: _chatFocusNode,
                                style: const TextStyle(color: Colors.white),
                                decoration: InputDecoration(
                                  hintText: "Ask your AI companion...",
                                  hintStyle: const TextStyle(color: Colors.white38),
                                  filled: true,
                                  fillColor: const Color(0xFF1A1D24),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(30),
                                    borderSide: BorderSide.none,
                                  ),
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                                ),
                                onSubmitted: (_) => _sendMessage(),
                              ),
                            ),
                            const SizedBox(width: 12),
                            CircleAvatar(
                              radius: 25,
                              backgroundColor: const Color(0xFFFF3B30),
                              child: IconButton(
                                icon: const Icon(Icons.send, color: Colors.white),
                                onPressed: _sendMessage,
                              ),
                            )
                          ],
                        ),
                      )
                    ],
                  ),
                )
              ],
            ),
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:convert';
import 'api_service.dart';
import 'landing_page.dart';
import 'doctor_onboarding.dart';
import 'patient_detail_view.dart';
import 'blood_drop_loader.dart';

class DoctorPortal extends StatefulWidget {
  const DoctorPortal({super.key});

  @override
  State<DoctorPortal> createState() => _DoctorPortalState();
}

class _DoctorPortalState extends State<DoctorPortal> {
  Map<String, dynamic>? currentUser;
  Map<String, dynamic>? doctorProfile;
  bool isLoading = true;

  final TextEditingController _searchCtrl = TextEditingController();
  List<dynamic> _searchResults = [];
  List<dynamic> _assignedPatients = [];
  bool _isSearching = false;
  bool _hasSearched = false;
  int _currentIndex = 0;

  final TextEditingController _researchCtrl = TextEditingController();
  List<dynamic> _researchResults = [];
  bool _isResearching = false;
  String _researchSource = 'pubmed';

  // Chat Variables
  final TextEditingController _chatCtrl = TextEditingController();
  final ScrollController _scrollCtrl = ScrollController();
  List<Map<String, String>> _messages = [];
  bool _isTyping = false;
  List<dynamic> _chatSessions = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final user = await ApiService.getCurrentUser();
    if (user == null || user['role'] != 'doctor') {
      if (mounted) {
        Navigator.pushReplacement(
            context, MaterialPageRoute(builder: (_) => const LandingPage()));
      }
      return;
    }
    setState(() {
      currentUser = user;
    });

    try {
      final profile = await ApiService.getDoctorProfile(user['id']);
      if (profile.isNotEmpty) {
        setState(() {
          doctorProfile = profile;
        });
      }
    } catch (e) {
      // Profile not found
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
    });
    _loadChatSessions();
  }

  void _loadOldSession(String messagesJson) {
    if (_messages.isNotEmpty) {
      ApiService.saveChatSession(currentUser!['id'], _messages);
    }
    final List<dynamic> decoded = json.decode(messagesJson);
    setState(() {
      _messages = decoded.map((e) => Map<String, String>.from(e)).toList();
      _currentIndex = 2; // Jump to chat tab
    });
    _loadChatSessions();
  }

  void _sendMessage() async {
    if (_chatCtrl.text.trim().isEmpty) return;
    String userMsg = _chatCtrl.text;
    
    setState(() {
      _messages.add({"role": "user", "text": userMsg});
      _chatCtrl.clear();
      _isTyping = true;
    });
    
    _scrollToBottom();
    
    // Construct context from all assigned patients
    String contextStr = "Doctor Context. I am Dr. ${doctorProfile?['name']}, Specialty: ${doctorProfile?['specialty']}. Assigned Patients:\n";
    for(var p in _assignedPatients) {
       contextStr += "- ${p['name']}, Age ${p['age']}, Sex ${p['sex']}, Hb ${p['latest_hb']}, Ferritin ${p['latest_ferritin']}. Notes: ${p['doctor_notes']}\n";
       try {
           final reports = await ApiService.getPatientReports(p['user_id']);
           if (reports.isNotEmpty) {
               contextStr += "  Medical Reports Available for ${p['name']}:\n";
               for (int i=0; i<reports.length; i++) {
                   final r = reports[i];
                   final link = "http://127.0.0.1:8000/${r['file_path'].replaceAll(r'\\', '/')}";
                   contextStr += "  ${i+1}. ${r['report_type']} Date - ${r['date']} View Report Option: $link \n  Summary: ${r['analysis_summary']}\n";
               }
           }
       } catch(e){}
    }

    final response = await ApiService.askAI(userMsg, context: contextStr, chatHistory: _messages);
    
    setState(() {
      _messages.add({"role": "agent", "text": response});
      _isTyping = false;
    });
    
    _scrollToBottom();
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(_scrollCtrl.position.maxScrollExtent, duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
      }
    });
  }

  void _searchPatients() async {
    final q = _searchCtrl.text.trim();
    if (q.isEmpty) return;

    setState(() {
      _isSearching = true;
      _hasSearched = true;
    });
    try {
      final results = await ApiService.searchPatients(q);
      setState(() {
        _searchResults = results;
      });
    } catch (e) {
      // ignore
    } finally {
      setState(() => _isSearching = false);
    }
  }

  void _searchResearch() async {
    final q = _researchCtrl.text.trim();
    if (q.isEmpty) return;
    
    setState(() => _isResearching = true);
    try {
      final results = await ApiService.searchResearch(q, _researchSource);
      setState(() {
        _researchResults = results;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      setState(() => _isResearching = false);
    }
  }

  void _assignPatient(dynamic patient) async {
    bool success = await ApiService.assignDoctor(patient['user_id'], currentUser!['id']);
    if (success) {
      setState(() {
        if (!_assignedPatients.any((p) => p['id'] == patient['id'])) {
          _assignedPatients.add(patient);
        }
        _searchResults.removeWhere((p) => p['id'] == patient['id']);
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to assign patient')));
    }
  }

  void _logout() async {
    await ApiService.logout();
    if (mounted) {
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const LandingPage()));
    }
  }

  void _showUpdateDialog() {
    final nameCtrl = TextEditingController(text: doctorProfile?['name'] ?? '');
    final specialtyCtrl = TextEditingController(text: doctorProfile?['specialty'] ?? '');
    final expCtrl = TextEditingController(text: doctorProfile?['experience_years']?.toString() ?? '');
    final hospitalCtrl = TextEditingController(text: doctorProfile?['hospital_name'] ?? '');
    final cityCtrl = TextEditingController(text: doctorProfile?['city'] ?? '');
    final stateCtrl = TextEditingController(text: doctorProfile?['state'] ?? '');

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1A1D24),
          title: Text("Update Doctor Profile", style: GoogleFonts.outfit(color: Colors.white)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(controller: nameCtrl, style: const TextStyle(color: Colors.white), decoration: const InputDecoration(labelText: "Full Name", labelStyle: TextStyle(color: Colors.white54))),
                TextField(controller: specialtyCtrl, style: const TextStyle(color: Colors.white), decoration: const InputDecoration(labelText: "Specialty", labelStyle: TextStyle(color: Colors.white54))),
                TextField(controller: expCtrl, style: const TextStyle(color: Colors.white), decoration: const InputDecoration(labelText: "Experience (Years)", labelStyle: TextStyle(color: Colors.white54))),
                TextField(controller: hospitalCtrl, style: const TextStyle(color: Colors.white), decoration: const InputDecoration(labelText: "Hospital Name", labelStyle: TextStyle(color: Colors.white54))),
                TextField(controller: cityCtrl, style: const TextStyle(color: Colors.white), decoration: const InputDecoration(labelText: "City", labelStyle: TextStyle(color: Colors.white54))),
                TextField(controller: stateCtrl, style: const TextStyle(color: Colors.white), decoration: const InputDecoration(labelText: "State", labelStyle: TextStyle(color: Colors.white54))),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel", style: TextStyle(color: Colors.white54))),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF00E5FF), foregroundColor: Colors.black),
              onPressed: () async {
                Map<String, dynamic> updates = {
                  'name': nameCtrl.text.isNotEmpty ? nameCtrl.text : 'Unknown',
                  'specialty': specialtyCtrl.text.isNotEmpty ? specialtyCtrl.text : 'Unknown',
                  'experience_years': int.tryParse(expCtrl.text) ?? 0,
                };
                if (hospitalCtrl.text.isNotEmpty) updates['hospital_name'] = hospitalCtrl.text;
                if (cityCtrl.text.isNotEmpty) updates['city'] = cityCtrl.text;
                if (stateCtrl.text.isNotEmpty) updates['state'] = stateCtrl.text;
                
                try {
                  await ApiService.saveDoctorProfile(currentUser!['id'], updates);
                } catch (e) {
                  // Ignore
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

  void _showMedicalReportsDialog(BuildContext context, Map<String, dynamic> patient) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (c) => const Center(child: CircularProgressIndicator(color: Colors.cyanAccent)),
    );
    try {
      final reports = await ApiService.getPatientReports(patient['user_id']);
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
            title: Text("Medical Reports: ${patient['name']}", style: const TextStyle(color: Colors.cyanAccent)),
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

  @override
  Widget build(BuildContext context) {
    if (isLoading || currentUser == null) {
      return const Scaffold(
        backgroundColor: Color(0xFF0F2027),
        body: Center(child: CircularProgressIndicator(color: Colors.cyanAccent)),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFF0F2027),
      appBar: doctorProfile == null ? AppBar(
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
      ) : null,
      body: doctorProfile == null 
          ? Center(child: _buildOnboardingFlow())
          : Column(
              children: [
                // Top Custom Header
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                  decoration: const BoxDecoration(color: Color(0xFF141414)),
                  child: Wrap(
                    alignment: WrapAlignment.spaceBetween,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: 16,
                    runSpacing: 10,
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.medical_services_outlined, color: Colors.cyanAccent),
                          const SizedBox(width: 10),
                          Text("Thalassemia Hub", style: GoogleFonts.outfit(color: Colors.cyanAccent, fontWeight: FontWeight.bold, fontSize: 18)),
                        ],
                      ),
                      Wrap(
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          Text("Dr. ${currentUser?['username'] ?? ''}", style: const TextStyle(color: Colors.white70)),
                          const SizedBox(width: 10),
                          IconButton(icon: const Icon(Icons.edit, color: Colors.cyanAccent, size: 20), onPressed: _showUpdateDialog),
                          IconButton(icon: const Icon(Icons.logout, color: Colors.white54, size: 20), onPressed: _logout),
                        ],
                      )
                    ],
                  ),
                ),
                Expanded(
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      bool isMobile = constraints.maxWidth < 900;
                      
                      if (isMobile) {
                        return Column(
                          children: [
                            Expanded(
                              child: _currentIndex == 0 
                                ? _buildDashboard() 
                                : _currentIndex == 1 
                                  ? _buildResearchTab() 
                                  : _buildChatTab(),
                            ),
                            Container(
                              decoration: const BoxDecoration(
                                border: Border(top: BorderSide(color: Colors.white12)),
                                color: Color(0xFF141414),
                              ),
                              child: BottomNavigationBar(
                                backgroundColor: Colors.transparent,
                                elevation: 0,
                                selectedItemColor: Colors.cyanAccent,
                                unselectedItemColor: Colors.white54,
                                currentIndex: _currentIndex,
                                onTap: (index) => setState(() => _currentIndex = index),
                                items: const [
                                  BottomNavigationBarItem(icon: Icon(Icons.people), label: "Patients Hub"),
                                  BottomNavigationBarItem(icon: Icon(Icons.science), label: "Medical Research"),
                                  BottomNavigationBarItem(icon: Icon(Icons.chat), label: "AI Chat"),
                                ],
                              ),
                            )
                          ],
                        );
                      }
                      
                      // Desktop split-screen layout
                      double w = constraints.maxWidth > 1000 ? constraints.maxWidth : 1000;
                      return SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: SizedBox(
                          width: w,
                          child: Row(
                            children: [
                              // Left Pane: Patients & Research (50%)
                              Expanded(
                                flex: 1,
                                child: Column(
                                  children: [
                                    Expanded(
                                      child: _currentIndex == 0 || _currentIndex == 2 ? _buildDashboard() : _buildResearchTab(),
                                    ),
                                    // Small Bottom Nav just for the left pane
                                    Container(
                                      decoration: const BoxDecoration(
                                        border: Border(top: BorderSide(color: Colors.white12)),
                                        color: Color(0xFF141414),
                                      ),
                                      child: BottomNavigationBar(
                                        backgroundColor: Colors.transparent,
                                        elevation: 0,
                                        selectedItemColor: Colors.cyanAccent,
                                        unselectedItemColor: Colors.white54,
                                        currentIndex: _currentIndex == 2 ? 0 : _currentIndex, // Ignore chat tab index
                                        onTap: (index) => setState(() => _currentIndex = index),
                                        items: const [
                                          BottomNavigationBarItem(icon: Icon(Icons.people), label: "Patients Hub"),
                                          BottomNavigationBarItem(icon: Icon(Icons.science), label: "Medical Research"),
                                        ],
                                      ),
                                    )
                                  ],
                                ),
                              ),
                              // Divider
                              Container(width: 1, color: Colors.white12),
                              // Right Pane: AI Assistant (50%)
                              Expanded(
                                flex: 1,
                                child: _buildChatTab(),
                              ),
                            ],
                          ),
                        ),
                      );
                    }
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildOnboardingFlow() {
    return DoctorOnboarding(
      user: currentUser!,
      onComplete: () {
        _loadData(); // reload to get the newly created profile
      },
    );
  }

  Widget _buildDashboard() {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.medical_information, size: 40, color: Colors.cyanAccent),
              const SizedBox(width: 15),
              Text("Welcome, ${doctorProfile?['name'] ?? ''}", style: GoogleFonts.outfit(fontSize: 28, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            "${doctorProfile?['specialty'] ?? ''} | ${doctorProfile?['hospital_affiliation'] ?? ''} | ${doctorProfile?['experience_years'] ?? 0} Years Exp",
            style: const TextStyle(fontSize: 16, color: Colors.white70),
          ),
          const SizedBox(height: 40),
          
          Text("Patient Search", style: GoogleFonts.outfit(fontSize: 22, fontWeight: FontWeight.w600)),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _searchCtrl,
                  decoration: InputDecoration(
                    hintText: "Search patients by Name...",
                    filled: true,
                    fillColor: const Color(0xFF141414),
                    prefixIcon: const Icon(Icons.search, color: Colors.white54),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: Colors.white24),
                    ),
                  ),
                  onSubmitted: (_) => _searchPatients(),
                ),
              ),
              const SizedBox(width: 15),
              ElevatedButton.icon(
                onPressed: _searchPatients,
                icon: const Icon(Icons.person_add),
                label: const Text("Search"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.cyan.shade800,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                ),
              )
            ],
          ),
          if (_isSearching) const Padding(padding: EdgeInsets.all(10), child: CircularProgressIndicator(color: Colors.cyanAccent)),
          if (_hasSearched && _searchResults.isEmpty && !_isSearching)
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: Text("Patient record not found.", style: TextStyle(color: Colors.redAccent)),
            ),
          if (_searchResults.isNotEmpty) ...[
            const SizedBox(height: 20),
            Container(
              decoration: BoxDecoration(border: Border.all(color: Colors.white24), borderRadius: BorderRadius.circular(8)),
              constraints: const BoxConstraints(maxHeight: 200),
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: _searchResults.length,
                itemBuilder: (context, index) {
                  final patient = _searchResults[index];
                  return ListTile(
                    leading: const Icon(Icons.person, color: Colors.cyanAccent),
                    title: Text(patient['name']),
                    subtitle: Text("Age: ${patient['age']} | Hb: ${patient['latest_hb'] ?? 'N/A'}"),
                    trailing: IconButton(
                      icon: const Icon(Icons.add_circle, color: Colors.cyan),
                      onPressed: () => _assignPatient(patient),
                    ),
                  );
                },
              ),
            ),
          ],
          const SizedBox(height: 40),
          
          Text("Assigned Patients", style: GoogleFonts.outfit(fontSize: 22, fontWeight: FontWeight.w600)),
          const SizedBox(height: 10),
          Expanded(
            child: _assignedPatients.isEmpty 
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.group_off, size: 60, color: Colors.white24),
                      const SizedBox(height: 10),
                      Text("No patients assigned yet", style: TextStyle(color: Colors.white54, fontSize: 16)),
                    ],
                  ),
                )
              : ListView.builder(
                  itemCount: _assignedPatients.length,
                  itemBuilder: (context, index) {
                    final p = _assignedPatients[index];
                    return Card(
                      color: const Color(0xFF141414),
                      shape: RoundedRectangleBorder(
                        side: const BorderSide(color: Colors.white24),
                        borderRadius: BorderRadius.circular(8)
                      ),
                      child: ListTile(
                        leading: const CircleAvatar(backgroundColor: Colors.cyan, child: Icon(Icons.person, color: Colors.black)),
                        title: Text(p['name'], style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text("Age: ${p['age']} | Sex: ${p['sex']} | Thalassemia: ${p['thalassemia_type'] ?? 'Unknown'}"),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            ElevatedButton(
                              onPressed: () => _showMedicalReportsDialog(context, p),
                              style: ElevatedButton.styleFrom(backgroundColor: Colors.blueGrey.shade900),
                              child: const Text("Reports", style: TextStyle(color: Colors.white)),
                            ),
                            const SizedBox(width: 8),
                            ElevatedButton(
                              onPressed: () {
                                Navigator.push(context, MaterialPageRoute(builder: (_) => PatientDetailView(patient: p, doctorId: currentUser!['id'])));
                              },
                              style: ElevatedButton.styleFrom(backgroundColor: Colors.cyan.shade900),
                              child: const Text("View File", style: TextStyle(color: Colors.white)),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
          )
        ],
      ),
    );
  }

  Widget _buildResearchTab() {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Medical Research Hub", style: GoogleFonts.outfit(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.cyanAccent)),
          const SizedBox(height: 10),
          const Text("Search PubMed for papers, ClinicalTrials for recruiting trials, or OpenFDA for drug adverse events.", style: TextStyle(color: Colors.white70)),
          const SizedBox(height: 30),
          
          LayoutBuilder(
            builder: (context, constraints) {
              bool isMobile = constraints.maxWidth < 600;
              final searchField = TextField(
                controller: _researchCtrl,
                decoration: InputDecoration(
                  hintText: "e.g., Deferasirox, Gene Therapy...",
                  filled: true,
                  fillColor: const Color(0xFF141414),
                  prefixIcon: const Icon(Icons.search, color: Colors.white54),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                ),
                onSubmitted: (_) => _searchResearch(),
              );
              
              final sourceDropdown = DropdownButtonFormField<String>(
                value: _researchSource,
                dropdownColor: const Color(0xFF141414),
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  filled: true,
                  fillColor: const Color(0xFF141414),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                ),
                items: const [
                  DropdownMenuItem(value: 'pubmed', child: Text("PubMed (Papers)")),
                  DropdownMenuItem(value: 'clinicaltrials', child: Text("ClinicalTrials.gov")),
                  DropdownMenuItem(value: 'openfda', child: Text("OpenFDA (Drug Safety)")),
                  DropdownMenuItem(value: 'all', child: Text("All Sources")),
                ],
                onChanged: (val) => setState(() => _researchSource = val!),
              );
              
              final searchBtn = ElevatedButton.icon(
                onPressed: _searchResearch,
                icon: const Icon(Icons.search),
                label: const Text("Search"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.cyan.shade800,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                ),
              );

              if (isMobile) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    searchField,
                    const SizedBox(height: 15),
                    sourceDropdown,
                    const SizedBox(height: 15),
                    searchBtn,
                  ],
                );
              }
              return Row(
                children: [
                  Expanded(flex: 2, child: searchField),
                  const SizedBox(width: 15),
                  Expanded(flex: 1, child: sourceDropdown),
                  const SizedBox(width: 15),
                  searchBtn,
                ],
              );
            }
          ),
          const SizedBox(height: 30),
          
          if (_isResearching) const Center(child: CircularProgressIndicator(color: Colors.cyanAccent)),
          if (!_isResearching) Expanded(
            child: ListView.builder(
              itemCount: _researchResults.length,
              itemBuilder: (context, index) {
                final res = _researchResults[index];
                String title = res['title'] ?? 'Unknown';
                String subtitle = '';
                IconData trailingIcon = Icons.link;
                Color trailingColor = Colors.cyan;
                
                if (res['pmid'] != null) {
                  subtitle = "Authors: ${(res['authors'] as List).join(', ')} | Date: ${res['pubdate']}";
                } else if (res['nctId'] != null) {
                  subtitle = "NCT ID: ${res['nctId']} | Status: ${res['status']}";
                  trailingIcon = Icons.science;
                } else if (res['reactions'] != null) {
                  title = res['serious'] ? "Serious Adverse Event" : "Adverse Event";
                  subtitle = "Reactions: ${res['reactions']}";
                  trailingIcon = Icons.warning;
                  trailingColor = Colors.amber;
                }

                return Card(
                  color: const Color(0xFF141414),
                  child: ListTile(
                    title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text(subtitle),
                    trailing: Icon(trailingIcon, color: trailingColor),
                    onTap: () async {
                      if (res['link'] != null) {
                        final Uri url = Uri.parse(res['link']);
                        if (!await launchUrl(url)) {
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Could not launch URL')));
                        }
                      }
                    },
                  ),
                );
              },
            ),
          )
        ],
      ),
    );
  }

  Widget _buildChatTab() {
    return Container(
      color: const Color(0xFF0F2027),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
            width: double.infinity,
            color: const Color(0xFF141414),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.chat, color: Colors.cyanAccent),
                    const SizedBox(width: 10),
                    Text(
                      "AI Assistant", 
                      style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.cyanAccent)
                    ),
                  ],
                ),
                ElevatedButton.icon(
                  onPressed: _startNewChat,
                  icon: const Icon(Icons.add, size: 16),
                  label: const Text("New Chat"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.cyan.shade900,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                )
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              controller: _scrollCtrl,
              padding: const EdgeInsets.all(20),
              itemCount: _messages.length + (_isTyping ? 1 : 0),
              itemBuilder: (context, index) {
                if (index == _messages.length && _isTyping) {
                  return const Align(
                    alignment: Alignment.centerLeft,
                    child: Padding(
                      padding: EdgeInsets.all(16.0),
                      child: BloodDropLoader(text: "ANALYZING PATIENT..."),
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
                      color: isAgent ? const Color(0xFF141414) : Colors.cyan.shade900,
                      borderRadius: BorderRadius.circular(16),
                      border: isAgent ? Border.all(color: Colors.cyanAccent.withOpacity(0.3)) : null,
                    ),
                    child: isAgent 
                      ? MarkdownBody(
                          data: msg['text']!,
                          styleSheet: MarkdownStyleSheet(
                            p: GoogleFonts.outfit(fontSize: 16, color: Colors.white),
                            strong: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.amberAccent),
                          ),
                        )
                      : Text(
                          msg['text']!,
                          style: GoogleFonts.outfit(fontSize: 16, color: Colors.white),
                        ),
                  ),
                );
              },
            ),
          ),
          
          // Input Field
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
            color: const Color(0xFF141414),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _chatCtrl,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: "Ask about your patients, research...",
                      hintStyle: const TextStyle(color: Colors.white54),
                      filled: true,
                      fillColor: const Color(0xFF0F2027),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(30),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    onSubmitted: (_) => _sendMessage(),
                  ),
                ),
                const SizedBox(width: 10),
                CircleAvatar(
                  radius: 25,
                  backgroundColor: Colors.cyanAccent,
                  child: IconButton(
                    icon: const Icon(Icons.send, color: Colors.black),
                    onPressed: _sendMessage,
                  ),
                )
              ],
            ),
          )
        ],
      ),
    );
  }

}

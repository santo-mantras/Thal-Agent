import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'dart:ui';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:file_picker/file_picker.dart';
import 'api_service.dart';
import 'blood_drop_loader.dart';

class Thal101Screen extends StatefulWidget {
  const Thal101Screen({super.key});

  @override
  State<Thal101Screen> createState() => _Thal101ScreenState();
}

class _Thal101ScreenState extends State<Thal101Screen> {
  final TextEditingController _chatCtrl = TextEditingController();
  final ScrollController _scrollCtrl = ScrollController();
  List<Map<String, String>> _messages = [
    {
      "role": "agent",
      "text": "Hello! I am CareMate AI. How can I assist you with your Thalassemia care today?"
    }
  ];
  bool _isTyping = false;
  PlatformFile? _selectedFile;

  void _pickFile() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'png', 'jpg', 'jpeg'],
    );
    if (result != null) {
      setState(() {
        _selectedFile = result.files.first;
      });
    }
  }

  void _sendMessage([String? predefinedMsg]) async {
    final msg = predefinedMsg ?? _chatCtrl.text.trim();
    if (msg.isEmpty) return;
    
    setState(() {
      _messages.add({"role": "user", "text": msg});
      if (predefinedMsg == null) _chatCtrl.clear();
      _isTyping = true;
    });
    
    _scrollToBottom();
    
    PlatformFile? fileToSend = _selectedFile;
    setState(() {
      _selectedFile = null;
    });
    
    try {
      String response;
      if (fileToSend != null) {
        response = await ApiService.askWithFile(msg, fileToSend, chatHistory: _messages);
      } else {
        response = await ApiService.askAI(msg, chatHistory: _messages);
      }
      
      if (mounted) {
        setState(() {
          _messages.add({"role": "agent", "text": response});
          _isTyping = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _messages.add({"role": "agent", "text": "I'm sorry, I'm having trouble connecting to the servers right now. Please try again later."});
          _isTyping = false;
        });
      }
    }
    
    _scrollToBottom();
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(_scrollCtrl.position.maxScrollExtent, duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0B0E14),
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        title: Text(
          "CareChat & Encyclopedia",
          style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold),
        ),
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
          // Dark Gradient Overlay for Readability
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    const Color(0xFF0B0E14).withOpacity(0.7),
                    const Color(0xFF0B0E14).withOpacity(0.95),
                  ],
                ),
              ),
            ),
          ),
          
          SafeArea(
            child: Column(
              children: [
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        bool isMobile = constraints.maxWidth < 900;
                        if (isMobile) {
                          return Column(
                            children: [
                              Expanded(
                                child: _buildCenterChat(isMobile: true),
                              ),
                              const SizedBox(height: 8),
                              _buildRightSidebar(isMobile: true),
                            ],
                          );
                        } else {
                          return Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Center Chat Interface (Flex 7)
                              Expanded(
                                flex: 7,
                                child: _buildCenterChat(isMobile: false),
                              ),
                              const SizedBox(width: 24),
                              
                              // Right Sidebar (Flex 3)
                              Expanded(
                                flex: 3,
                                child: _buildRightSidebar(isMobile: false),
                              ),
                            ],
                          );
                        }
                      },
                    ),
                  ),
                ),
                
                // Footer
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  child: Text(
                    "⚠️ Legal Disclaimer: This AI assistant provides research and data tracking and may occasionally provide inaccurate information. It is NOT a substitute for professional medical advice.",
                    style: GoogleFonts.outfit(color: Colors.white54, fontSize: 12),
                    textAlign: TextAlign.center,
                  ),
                )
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Left sidebar removed

  Widget _buildCenterChat({required bool isMobile}) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
        child: Container(
          decoration: BoxDecoration(
            color: const Color(0xFF0F2027).withOpacity(0.7),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.tealAccent.withOpacity(0.3), width: 1.5),
          ),
          child: Column(
            children: [
              // Chat Header
              Container(
                padding: const EdgeInsets.symmetric(vertical: 20),
                decoration: BoxDecoration(
                  border: Border(bottom: BorderSide(color: Colors.white.withOpacity(0.1))),
                ),
                child: Column(
                  children: [
                    const CircleAvatar(
                      radius: 30,
                      backgroundColor: Colors.tealAccent,
                      child: Icon(Icons.smart_toy, size: 36, color: Colors.black),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "CareMate AI",
                      style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                    Text(
                      "Your 24/7 Thalassemia Expert",
                      style: GoogleFonts.outfit(fontSize: 14, color: Colors.white70),
                    ),
                  ],
                ),
              ),
              
              // Quick Actions
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildQuickAction("What is Thalassemia?", Colors.redAccent),
                      _buildQuickAction("Signs of Emergency", Colors.amber),
                      _buildQuickAction("What should I eat?", Colors.greenAccent),
                      _buildQuickAction("Chelation Therapy", Colors.tealAccent),
                    ],
                  ),
                ),
              ),
              
              // Chat Area
              Expanded(
                child: ListView.builder(
                  controller: _scrollCtrl,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
                  itemCount: _messages.length + (_isTyping ? 1 : 0),
                  itemBuilder: (context, index) {
                    if (index == _messages.length && _isTyping) {
                      return const Align(
                        alignment: Alignment.centerLeft,
                        child: Padding(
                          padding: EdgeInsets.all(16.0),
                          child: BloodDropLoader(text: "CAREMATE IS THINKING..."),
                        ),
                      );
                    }
                    
                    final msg = _messages[index];
                    final isAgent = msg['role'] == 'agent';
                    
                    return Align(
                      alignment: isAgent ? Alignment.centerLeft : Alignment.centerRight,
                      child: Container(
                        margin: const EdgeInsets.symmetric(vertical: 8),
                        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * (isMobile ? 0.8 : 0.35)),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            if (isAgent) ...[
                              const CircleAvatar(
                                radius: 16,
                                backgroundColor: Colors.tealAccent,
                                child: Icon(Icons.smart_toy, size: 18, color: Colors.black),
                              ),
                              const SizedBox(width: 8),
                            ],
                            Flexible(
                              child: Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: isAgent 
                                      ? const Color(0xFF141D26) // Dark grey/teal
                                      : const Color(0xFF4A1525), // Dark burgundy/red
                                  borderRadius: BorderRadius.only(
                                    topLeft: const Radius.circular(16),
                                    topRight: const Radius.circular(16),
                                    bottomLeft: isAgent ? Radius.zero : const Radius.circular(16),
                                    bottomRight: isAgent ? const Radius.circular(16) : Radius.zero,
                                  ),
                                ),
                                child: isAgent 
                                  ? MarkdownBody(
                                      data: msg['text']!,
                                      styleSheet: MarkdownStyleSheet(
                                        p: GoogleFonts.outfit(fontSize: 15, color: Colors.white),
                                        strong: GoogleFonts.outfit(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.amberAccent),
                                      ),
                                    )
                                  : Text(
                                      msg['text']!,
                                      style: GoogleFonts.outfit(fontSize: 15, color: Colors.white),
                                    ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ).animate().fade().slideY(begin: 0.1);
                  },
                ),
              ),
              
              // Input Bar
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFF0B0E14).withOpacity(0.5),
                  border: Border(top: BorderSide(color: Colors.white.withOpacity(0.1))),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (_selectedFile != null)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8.0, left: 8.0),
                        child: Chip(
                          backgroundColor: Colors.tealAccent.withOpacity(0.2),
                          side: const BorderSide(color: Colors.tealAccent),
                          label: Text(_selectedFile!.name, style: const TextStyle(color: Colors.white, fontSize: 12)),
                          onDeleted: () => setState(() => _selectedFile = null),
                          deleteIconColor: Colors.white,
                        ),
                      ),
                    Row(
                      children: [
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            decoration: BoxDecoration(
                              color: const Color(0xFF1A1D24),
                              borderRadius: BorderRadius.circular(30),
                              border: Border.all(color: Colors.white24),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: TextField(
                                    controller: _chatCtrl,
                                    style: const TextStyle(color: Colors.white),
                                    decoration: InputDecoration(
                                      hintText: "Ask CareMate anything about your care...",
                                      hintStyle: const TextStyle(color: Colors.white38),
                                      border: InputBorder.none,
                                    ),
                                    onSubmitted: (_) => _sendMessage(),
                                  ),
                                ),
                                IconButton(
                                  icon: Icon(Icons.attach_file, color: _selectedFile != null ? Colors.tealAccent : Colors.white54),
                                  onPressed: _pickFile,
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        CircleAvatar(
                          radius: 25,
                          backgroundColor: const Color(0xFF00E5FF),
                          child: IconButton(
                            icon: const Icon(Icons.send, color: Colors.black),
                            onPressed: () => _sendMessage(),
                          ),
                        )
                      ],
                    ),
                  ],
                ),
              )
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuickAction(String text, Color color) {
    return Padding(
      padding: const EdgeInsets.only(right: 8.0),
      child: ActionChip(
        backgroundColor: color.withOpacity(0.15),
        side: BorderSide(color: color.withOpacity(0.5)),
        label: Text(text, style: TextStyle(color: color, fontSize: 12)),
        onPressed: () => _sendMessage(text),
      ),
    );
  }

  Widget _buildRightSidebar({bool isMobile = false}) {
    Widget articles = ListView(
      shrinkWrap: isMobile,
      physics: isMobile ? const NeverScrollableScrollPhysics() : null,
      children: [
        _buildArticleCard(
          "Symptoms of Iron Overload",
          "Learn how to spot the early warning signs of iron toxicity from repeated transfusions.",
          "Read Article",
          "https://www.thalassemia.org/iron-overload/"
        ),
        const SizedBox(height: 16),
        _buildArticleCard(
          "Managing Fatigue",
          "Practical daily tips and dietary adjustments to keep your energy levels stable.",
          "View Guide",
          "https://www.thalassemia.org/living-with-thalassemia/"
        ),
        const SizedBox(height: 16),
        _buildArticleCard(
          "Latest Gene Therapy Trials",
          "Discover upcoming FDA-approved clinical trials and see if you are eligible.",
          "Explore Trials",
          "https://clinicaltrials.gov/search?cond=Thalassemia"
        ),
      ],
    );

    if (isMobile) {
      return Container(
        decoration: BoxDecoration(
          color: const Color(0xFF1A1D24).withOpacity(0.6),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white24),
        ),
        child: Theme(
          data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
          child: ExpansionTile(
            title: Text(
              "Knowledge Hub",
              style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
            ),
            subtitle: Text("Suggested reads", style: GoogleFonts.outfit(fontSize: 12, color: Colors.white54)),
            leading: const Icon(Icons.menu_book, color: Colors.cyanAccent),
            iconColor: Colors.cyanAccent,
            collapsedIconColor: Colors.white54,
            children: [
              Container(
                constraints: const BoxConstraints(maxHeight: 400),
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                child: SingleChildScrollView(child: articles),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.menu_book, color: Colors.cyanAccent),
            const SizedBox(width: 10),
            Text(
              "Knowledge Hub",
              style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          "Suggested reads",
          style: GoogleFonts.outfit(fontSize: 14, color: Colors.white54),
        ),
        const SizedBox(height: 20),
        Expanded(
          child: articles,
        ),
      ],
    );
  }

  Widget _buildArticleCard(String title, String summary, String linkText, String url) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: const Color(0xFF1A1D24).withOpacity(0.6),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withOpacity(0.1), width: 1),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: GoogleFonts.outfit(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                summary,
                style: const TextStyle(color: Colors.grey, fontSize: 13, height: 1.4),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 12),
              InkWell(
                onTap: () async {
                  final Uri uri = Uri.parse(url);
                  if (await canLaunchUrl(uri)) {
                    await launchUrl(uri, mode: LaunchMode.externalApplication);
                  } else {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("Could not open article")),
                      );
                    }
                  }
                }, 
                child: Text(
                  linkText,
                  style: const TextStyle(color: Colors.tealAccent, fontWeight: FontWeight.w600, fontSize: 13),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'api_service.dart';
import 'landing_page.dart';

class AdminPortal extends StatefulWidget {
  const AdminPortal({super.key});

  @override
  State<AdminPortal> createState() => _AdminPortalState();
}

class _AdminPortalState extends State<AdminPortal> {
  List<dynamic> _users = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchUsers();
  }

  void _fetchUsers() async {
    setState(() => _isLoading = true);
    try {
      final users = await ApiService.getAllUsers();
      setState(() {
        _users = users;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error fetching users: $e")));
    }
  }

  void _deleteUser(int userId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        backgroundColor: const Color(0xFF1A1D24),
        title: const Text("Delete User", style: TextStyle(color: Colors.white)),
        content: const Text("Are you sure you want to permanently delete this user and all their data? This action cannot be undone.", style: TextStyle(color: Colors.white70)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c, false), child: const Text("Cancel", style: TextStyle(color: Colors.white54))),
          TextButton(onPressed: () => Navigator.pop(c, true), child: const Text("Delete", style: TextStyle(color: Colors.redAccent))),
        ],
      ),
    );

    if (confirm == true) {
      bool success = await ApiService.deleteUser(userId);
      if (success) {
        _fetchUsers();
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("User deleted successfully")));
      } else {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Failed to delete user")));
      }
    }
  }

  void _editUser(Map<String, dynamic> user) {
    final nameCtrl = TextEditingController(text: user['name'] == 'Unknown' ? '' : user['name']);
    
    showDialog(
      context: context,
      builder: (c) => AlertDialog(
        backgroundColor: const Color(0xFF1A1D24),
        title: Text("Edit ${user['role'].toString().toUpperCase()}", style: const TextStyle(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameCtrl,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(labelText: "Name", labelStyle: TextStyle(color: Colors.white54)),
            ),
            // We can add more fields if we want to expand editing
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c), child: const Text("Cancel", style: TextStyle(color: Colors.white54))),
          TextButton(
            onPressed: () async {
              Navigator.pop(c);
              bool success = await ApiService.updateUser(user['id'], {'name': nameCtrl.text});
              if (success) {
                _fetchUsers();
                if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("User updated")));
              }
            }, 
            child: const Text("Save", style: TextStyle(color: Colors.cyanAccent))
          ),
        ],
      ),
    );
  }

  void _logout() async {
    await ApiService.logout();
    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => const LandingPage()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0B0E14),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A1D24),
        title: Text("Admin Dashboard", style: GoogleFonts.outfit(color: Colors.white)),
        actions: [
          IconButton(icon: const Icon(Icons.refresh, color: Colors.white), onPressed: _fetchUsers),
          IconButton(icon: const Icon(Icons.logout, color: Colors.white), onPressed: _logout),
        ],
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator(color: Colors.cyanAccent))
        : ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: _users.length,
            itemBuilder: (context, index) {
              final u = _users[index];
              return Card(
                color: const Color(0xFF141414),
                shape: RoundedRectangleBorder(
                  side: const BorderSide(color: Colors.white24),
                  borderRadius: BorderRadius.circular(8)
                ),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: u['role'] == 'admin' ? Colors.redAccent : (u['role'] == 'doctor' ? Colors.cyan : Colors.tealAccent),
                    child: Icon(Icons.person, color: Colors.black),
                  ),
                  title: Text(u['username'] + (u['name'] != 'Unknown' ? " (${u['name']})" : ""), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  subtitle: Text("Role: ${u['role']}", style: const TextStyle(color: Colors.white54)),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (u['role'] != 'admin')
                        IconButton(icon: const Icon(Icons.edit, color: Colors.cyanAccent), onPressed: () => _editUser(u)),
                      if (u['role'] != 'admin')
                        IconButton(icon: const Icon(Icons.delete, color: Colors.redAccent), onPressed: () => _deleteUser(u['id'])),
                    ],
                  ),
                ),
              );
            },
          ),
    );
  }
}

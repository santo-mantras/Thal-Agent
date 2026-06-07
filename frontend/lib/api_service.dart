import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:file_picker/file_picker.dart';

import 'package:flutter/foundation.dart'; // Add kReleaseMode import

class ApiService {
  // Use empty string for production (Docker/HF) and localhost for local development
  static const String baseUrl = kReleaseMode ? '' : 'http://127.0.0.1:8000';

  // --- AUTH ---
  static Future<Map<String, dynamic>> registerUser(String username, String role) async {
    final response = await http.post(
      Uri.parse('$baseUrl/users/'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({'username': username, 'role': role}),
    );
    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to register user: ${response.body}');
    }
  }

  static Future<Map<String, dynamic>> loginUser(String username) async {
    final response = await http.get(Uri.parse('$baseUrl/users/$username'));
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      
      // Save session
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('user_id', data['id']);
      await prefs.setString('username', data['username']);
      await prefs.setString('role', data['role']);
      
      return data;
    } else {
      throw Exception('User not found');
    }
  }

  static Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }

  static Future<Map<String, dynamic>?> getCurrentUser() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getInt('user_id');
    if (userId == null) return null;
    return {
      'id': userId,
      'username': prefs.getString('username'),
      'role': prefs.getString('role')
    };
  }

  static Future<List<dynamic>> searchPatients(String query) async {
    final response = await http.get(Uri.parse('$baseUrl/patients/search/?query=$query'));
    if (response.statusCode == 200) {
      return json.decode(response.body);
    }
    return [];
  }

  static Future<List<dynamic>> searchResearch(String query, String source) async {
    final response = await http.post(
      Uri.parse('$baseUrl/research'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({'query': query, 'source': source}),
    );
    if (response.statusCode == 200) {
      return json.decode(response.body)['results'] ?? [];
    }
    return [];
  }

  static Future<Map<String, dynamic>> getPatientRecord(int userId) async {
    final response = await http.get(Uri.parse('$baseUrl/patients/$userId'));
    if (response.statusCode == 200) {
      return json.decode(response.body);
    }
    return {};
  }

  static Future<bool> updatePatientNotes(int userId, Map<String, dynamic> updates) async {
    final response = await http.put(
      Uri.parse('$baseUrl/patients/$userId/notes'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode(updates),
    );
    return response.statusCode == 200;
  }

  static Future<bool> assignDoctor(int patientUserId, int doctorId) async {
    final response = await http.put(
      Uri.parse('$baseUrl/patients/$patientUserId/doctor'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({'doctor_id': doctorId}),
    );
    return response.statusCode == 200;
  }

  static Future<Map<String, dynamic>> savePatientRecord(int userId, Map<String, dynamic> data) async {
    final response = await http.post(
      Uri.parse('$baseUrl/patients/$userId'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode(data),
    );
    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to save patient record: ${response.body}');
    }
  }

  // --- VISIT RECORDS ---
  static Future<bool> addVisitRecord(int userId, Map<String, dynamic> data) async {
    final response = await http.post(
      Uri.parse('$baseUrl/patients/$userId/visits'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode(data),
    );
    return response.statusCode == 200;
  }

  static Future<List<dynamic>> getVisitRecords(int userId) async {
    final response = await http.get(Uri.parse('$baseUrl/patients/$userId/visits'));
    if (response.statusCode == 200) {
      return json.decode(response.body);
    }
    return [];
  }

  // --- DOCTOR PROFILES ---
  static Future<Map<String, dynamic>> getDoctorProfile(int userId) async {
    final response = await http.get(Uri.parse('$baseUrl/doctors/$userId'));
    if (response.statusCode == 200) {
      return json.decode(response.body);
    }
    return {};
  }

  static Future<Map<String, dynamic>> saveDoctorProfile(int userId, Map<String, dynamic> data) async {
    final response = await http.post(
      Uri.parse('$baseUrl/doctors/$userId'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode(data),
    );
    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to save doctor profile: ${response.body}');
    }
  }

  // --- CHAT SESSIONS ---
  static Future<List<dynamic>> getChatSessions(int userId) async {
    final response = await http.get(Uri.parse('$baseUrl/chat/$userId'));
    if (response.statusCode == 200) {
      return json.decode(response.body);
    }
    return [];
  }

  static Future<bool> saveChatSession(int userId, List<Map<String, String>> messages) async {
    final response = await http.post(
      Uri.parse('$baseUrl/chat/$userId'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({'messages': json.encode(messages)}),
    );
    return response.statusCode == 200;
  }

  static Future<String> askAI(String query, {String? context, List<Map<String, String>>? chatHistory}) async {
    final body = <String, dynamic>{'query': query};
    if (context != null) {
      body['context'] = context;
    }
    if (chatHistory != null) {
      body['chat_history'] = chatHistory;
    }
    final response = await http.post(
      Uri.parse('$baseUrl/ask'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode(body),
    );
    
    if (response.statusCode == 200) {
      return json.decode(response.body)['answer'] ?? "No response";
    } else {
      return "AI Backend Error: ${response.statusCode}";
    }
  }

  static Future<String> askWithFile(String query, PlatformFile file, {List<Map<String, String>>? chatHistory}) async {
    var request = http.MultipartRequest('POST', Uri.parse('$baseUrl/ask-with-file'));
    request.fields['query'] = query;
    request.fields['chat_history'] = chatHistory != null ? json.encode(chatHistory) : "";

    if (file.bytes != null) {
      request.files.add(http.MultipartFile.fromBytes('file', file.bytes!, filename: file.name));
    } else if (file.path != null) {
      request.files.add(await http.MultipartFile.fromPath('file', file.path!));
    }

    try {
      var response = await request.send();
      var responseData = await response.stream.bytesToString();
      if (response.statusCode == 200) {
        return json.decode(responseData)['answer'] ?? "No response";
      } else {
        return "Backend Error: ${response.statusCode}";
      }
    } catch (e) {
      return "Network Error: $e";
    }
  }

  static Future<List<dynamic>> getPatientReports(int userId) async {
    final response = await http.get(Uri.parse('$baseUrl/patients/$userId/reports'));
    if (response.statusCode == 200) {
      return json.decode(response.body);
    }
    return [];
  }

  // --- ADMIN ---
  static Future<List<dynamic>> getAllUsers() async {
    final response = await http.get(Uri.parse('$baseUrl/admin/users'));
    if (response.statusCode == 200) {
      return json.decode(response.body);
    }
    return [];
  }

  static Future<bool> deleteUser(int userId) async {
    final response = await http.delete(Uri.parse('$baseUrl/admin/users/$userId'));
    return response.statusCode == 200;
  }

  static Future<bool> updateUser(int userId, Map<String, dynamic> updates) async {
    final response = await http.put(
      Uri.parse('$baseUrl/admin/users/$userId'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode(updates),
    );
    return response.statusCode == 200;
  }
}

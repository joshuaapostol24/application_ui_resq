import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';

class MongoService {
  // Replace with your co-worker's backend URL
  static const String _baseUrl = 'https://resq-system.onrender.com';

  // Automatically attaches the Supabase JWT token to every request
  static Future<Map<String, String>> _headers() async {
    final session = Supabase.instance.client.auth.currentSession;
    final token = session?.accessToken ?? '';
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  // ── Submit a new incident report ─────────────────────────────────────────
  static Future<Map<String, dynamic>> submitReport({
    required String userId,
    required String category,
    required String severity,
    required double latitude,
    required double longitude,
    required String address,
    String? imageUrl,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/reports'),
        headers: await _headers(),
        body: jsonEncode({
          'user_id': userId,
          'category': category,
          'severity': severity,
          'latitude': latitude,
          'longitude': longitude,
          'address': address,
          'image_url': imageUrl,
          'status': 'pending',
        }),
      );

      final data = jsonDecode(response.body);
      if (response.statusCode == 200 || response.statusCode == 201) {
        return {'success': true, 'data': data};
      }
      return {'success': false, 'message': data['detail'] ?? 'Submit failed'};
    } catch (e) {
      return {'success': false, 'message': 'Could not connect to server.'};
    }
  }

  // ── Get all reports (for map view) ───────────────────────────────────────
  static Future<Map<String, dynamic>> getReports() async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/reports'),
        headers: await _headers(),
      );

      final data = jsonDecode(response.body);
      if (response.statusCode == 200) {
        return {'success': true, 'data': data};
      }
      return {'success': false, 'message': 'Failed to fetch reports'};
    } catch (e) {
      return {'success': false, 'message': 'Could not connect to server.'};
    }
  }

  // ── Get reports by a specific user ───────────────────────────────────────
  static Future<Map<String, dynamic>> getUserReports({
    required String userId,
  }) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/reports/user/$userId'),
        headers: await _headers(),
      );

      final data = jsonDecode(response.body);
      if (response.statusCode == 200) {
        return {'success': true, 'data': data};
      }
      return {'success': false, 'message': 'Failed to fetch your reports'};
    } catch (e) {
      return {'success': false, 'message': 'Could not connect to server.'};
    }
  }
} 
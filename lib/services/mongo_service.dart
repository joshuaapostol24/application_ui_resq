import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/report_model.dart';

class MongoService {
  static const String _baseUrl = 'https://resq-app-xsb98.ondigitalocean.app';

  // ── Auth header ───────────────────────────────────────────────────────────
  static Future<Map<String, String>> _headers() async {
    final session = Supabase.instance.client.auth.currentSession;
    final token = session?.accessToken ?? '';
    return {
      'Content-Type': 'application/json',
      if (token.isNotEmpty) 'Authorization': 'Bearer $token',
    };
  }

  // ── Generic GET helper ────────────────────────────────────────────────────
  static Future<Map<String, dynamic>> _get(String path) async {
    try {
      final response = await http
          .get(Uri.parse('$_baseUrl$path'), headers: await _headers())
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        // Backend may return a list directly or wrap it in { data: [...] }
        if (decoded is List) {
          return {'success': true, 'data': decoded};
        }
        return {'success': true, 'data': decoded['data'] ?? decoded};
      }

      debugPrint('MongoService GET $path → ${response.statusCode}: ${response.body}');
      return {
        'success': false,
        'message': 'Server error ${response.statusCode}',
      };
    } on Exception catch (e) {
      debugPrint('MongoService GET $path error: $e');
      return {'success': false, 'message': 'Could not reach the server. Check your connection.'};
    }
  }

  // ── Fetch ALL reports (for map view) ──────────────────────────────────────
  // Returns a typed list of ReportModel objects.
  static Future<List<ReportModel>> getReports() async {
    final result = await _get('/public/reports');
    if (!result['success']) {
      debugPrint('getReports failed: ${result['message']}');
      return [];
    }
    final list = result['data'];
    if (list is! List) return [];
    return list
        .map((e) {
          try {
            final raw = e as Map<String, dynamic>;

            final transformed = {
              'id': raw['_id']?['\$oid'] ?? raw['_id'],
              'category': raw['type'],
              'severity': raw['priority'],
              'latitude': raw['coordinates']?['lat'],
              'longitude': raw['coordinates']?['lng'],
              'address': raw['location'],
              'description': raw['description'],
              'status': raw['status'],
              'image_url': raw['image_url'],
              'created_at': raw['submittedAt'],
            };
            return ReportModel.fromJson(transformed);
          } catch (err) {
            debugPrint('ReportModel.fromJson error: $err  |  raw: $e');
            return null;
          }
        })
        .whereType<ReportModel>()
        .toList();
  }

  // ── Fetch reports for a specific user (for profile / history) ────────────
  static Future<List<ReportModel>> getUserReports({
    required String userId,
  }) async {
    final result = await _get('/public/reports/user/$userId');
    if (!result['success']) {
      debugPrint('getUserReports failed: ${result['message']}');
      return [];
    }
    final list = result['data'];
    if (list is! List) return [];
    return list
        .map((e) {
          try {
            return ReportModel.fromJson(e as Map<String, dynamic>);
          } catch (err) {
            debugPrint('ReportModel.fromJson error: $err  |  raw: $e');
            return null;
          }
        })
        .whereType<ReportModel>()
        .toList();
  }

  // ── Submit a new report ───────────────────────────────────────────────────
  // Kept for compatibility — you may be using Supabase for writes and
  // Mongo for reads. Remove if you only write to one backend.
  static Future<Map<String, dynamic>> submitReport({
    required String userId,
    required String category,
    required String severity,
    required double latitude,
    required double longitude,
    required String address,
    required String description,
    String? imageUrl,
  }) async {
    try {
      final response = await http
          .post(
            Uri.parse('$_baseUrl/reports'),
            headers: await _headers(),
            body: jsonEncode({
              'user_id': userId,
              'category': category,
              'severity': severity,
              'latitude': latitude,
              'longitude': longitude,
              'address': address,
              'description': description,
              'image_url': imageUrl,
              'status': 'pending',
            }),
          )
          .timeout(const Duration(seconds: 15));

      final data = jsonDecode(response.body);
      if (response.statusCode == 200 || response.statusCode == 201) {
        return {'success': true, 'data': data};
      }
      return {
        'success': false,
        'message': data['detail'] ?? 'Submit failed',
      };
    } on Exception catch (e) {
      return {'success': false, 'message': 'Could not connect to server: $e'};
    }
  }
}
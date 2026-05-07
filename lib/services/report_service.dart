import 'package:supabase_flutter/supabase_flutter.dart';

class ReportService {
  static final _supabase = Supabase.instance.client;

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
      await _supabase.from('reports').insert({
        'user_id': userId,
        'category': category,
        'severity': severity,
        'latitude': latitude,
        'longitude': longitude,
        'address': address,
        'image_url': imageUrl,
        'status': 'pending',
      });

      return {'success': true};
    } catch (e) {
      return {
        'success': false,
        'message': e.toString(),
      };
    }
  }
}
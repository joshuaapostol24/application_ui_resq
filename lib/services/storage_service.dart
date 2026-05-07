import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';

class StorageService {
  static final _supabase = Supabase.instance.client;

  static Future<String?> uploadReportImage(File imageFile) async {
    try {
      final fileName =
          'report_${DateTime.now().millisecondsSinceEpoch}.jpg';

      await _supabase.storage
          .from('report-images')
          .upload(fileName, imageFile);

      final imageUrl = _supabase.storage
          .from('report-images')
          .getPublicUrl(fileName);

      return imageUrl;
    } catch (e) {
      print('IMAGE UPLOAD ERROR: $e');
      return null;
    }
  }
}
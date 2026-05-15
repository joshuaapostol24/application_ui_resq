import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class StorageService {
  static final _supabase = Supabase.instance.client;

  static Future<String> uploadIdImage(
    File imageFile,
) async {

  try {

    debugPrint(
      'ID STORAGE: Starting upload...',
    );

    if (!await imageFile.exists()) {
      throw Exception(
        'Selected image does not exist.',
      );
    }

    final fileSize =
        await imageFile.length();

    debugPrint(
      'ID STORAGE: File size = $fileSize',
    );

    final fileName =
        'id_${DateTime.now().millisecondsSinceEpoch}.jpg';

    debugPrint(
      'ID STORAGE: Uploading to valid-ids/$fileName',
    );

    await _supabase.storage
        .from('valid-ids')
        .upload(
          fileName,
          imageFile,
          fileOptions: const FileOptions(
            contentType: 'image/jpeg',
            upsert: false,
          ),
        )
        .timeout(
          const Duration(seconds: 20),
        );

    debugPrint(
      'ID STORAGE: Upload complete',
    );

    final imageUrl = _supabase.storage
        .from('valid-ids')
        .getPublicUrl(fileName);

    debugPrint(
      'ID STORAGE URL: $imageUrl',
    );

    return imageUrl;

  } on StorageException catch (e) {

    debugPrint(
      'ID STORAGE ERROR: ${e.message}',
    );

    throw Exception(
      'ID upload failed: ${e.message}',
    );

  } catch (e) {

    debugPrint(
      'ID STORAGE GENERAL ERROR: $e',
    );

    throw Exception(
      'ID upload failed: $e',
    );
  }
}

  static Future<String?> uploadReportImage(File imageFile) async {
    try {
      // ── Validate file exists and has content ──────────────────────────────
      if (!await imageFile.exists()) {
        debugPrint('STORAGE ERROR: File does not exist at ${imageFile.path}');
        return null;
      }

      final fileSize = await imageFile.length();
      if (fileSize == 0) {
        debugPrint('STORAGE ERROR: File is empty');
        return null;
      }
      debugPrint('STORAGE: Uploading file — size: $fileSize bytes, path: ${imageFile.path}');

      // ── Build a unique file name ──────────────────────────────────────────
      // Include user ID in the path so per-user RLS policies work correctly.
      // Path format: user_id/timestamp.jpg
      final userId = _supabase.auth.currentSession?.user.id ?? 'anonymous';
      final fileName = '$userId/${DateTime.now().millisecondsSinceEpoch}.jpg';

      debugPrint('STORAGE: Uploading to bucket "report-images" at path "$fileName"');

      // ── Upload ────────────────────────────────────────────────────────────
      await _supabase.storage
          .from('report-images')
          .upload(
            fileName,
            imageFile,
            fileOptions: const FileOptions(
              contentType: 'image/jpeg',
              upsert: false,
            ),
          );

      // ── Get public URL ────────────────────────────────────────────────────
      final imageUrl = _supabase.storage
          .from('report-images')
          .getPublicUrl(fileName);

      debugPrint('STORAGE: Upload successful. Public URL: $imageUrl');
      return imageUrl;

    } on StorageException catch (e) {
      // Supabase storage-specific errors (RLS, bucket not found, etc.)
      debugPrint('STORAGE StorageException: ${e.message} | statusCode: ${e.statusCode}');
      debugPrint('STORAGE Hint: Check bucket RLS policies — "report-images" bucket must allow INSERT for authenticated users.');
      rethrow; // Re-throw so _submitReport can show the actual error to the user
    } catch (e, stack) {
      debugPrint('STORAGE unexpected error: $e');
      debugPrint('$stack');
      rethrow;
    }
  }
}
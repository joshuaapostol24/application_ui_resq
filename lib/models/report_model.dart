import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';

class ReportModel {
  final String id;
  final String userId;
  final String category;
  final String severity;
  final double latitude;
  final double longitude;
  final String address;
  final String description;
  final String? imageUrl;
  final String status;
  final DateTime createdAt;

  ReportModel({
    required this.id,
    required this.userId,
    required this.category,
    required this.severity,
    required this.latitude,
    required this.longitude,
    required this.address,
    required this.description,
    this.imageUrl,
    required this.status,
    required this.createdAt,
  });

  LatLng get latLng => LatLng(latitude, longitude);

  // ── Parse from MongoDB/backend JSON ──────────────────────────────────────
  // Handles both Mongo _id and Supabase-style id fields gracefully.
  factory ReportModel.fromJson(Map<String, dynamic> json) {
    // ID — MongoDB uses '_id' which may be a string or a nested {'$oid': '...'}
    String id = '';
    if (json['_id'] != null) {
      final raw = json['_id'];
      id = raw is Map ? (raw['\$oid'] ?? '').toString() : raw.toString();
    } else if (json['id'] != null) {
      id = json['id'].toString();
    }

    // Coordinates — accept both top-level fields and a nested 'location' object
    double lat = 0;
    double lng = 0;
    if (json['latitude'] != null && json['longitude'] != null) {
      lat = _toDouble(json['latitude']);
      lng = _toDouble(json['longitude']);
    } else if (json['location'] is Map) {
      final loc = json['location'] as Map;
      // GeoJSON stores [longitude, latitude]
      final coords = loc['coordinates'];
      if (coords is List && coords.length >= 2) {
        lng = _toDouble(coords[0]);
        lat = _toDouble(coords[1]);
      }
    }

    // Timestamp — accept ISO strings, epoch ints, or Mongo $date objects
    DateTime createdAt = DateTime.now();
    final raw = json['created_at'] ?? json['createdAt'] ?? json['timestamp'];
    if (raw != null) {
      if (raw is String) {
        createdAt = DateTime.tryParse(raw) ?? DateTime.now();
      } else if (raw is int) {
        createdAt = DateTime.fromMillisecondsSinceEpoch(raw);
      } else if (raw is Map && raw['\$date'] != null) {
        final d = raw['\$date'];
        createdAt = d is String
            ? DateTime.tryParse(d) ?? DateTime.now()
            : DateTime.fromMillisecondsSinceEpoch(d as int);
      }
    }

    return ReportModel(
      id: id,
      userId: (json['user_id'] ?? json['userId'] ?? '').toString(),
      category: (json['category'] ?? 'Unknown').toString(),
      severity: (json['severity'] ?? 'Unknown').toString(),
      latitude: lat,
      longitude: lng,
      address: (json['address'] ?? '').toString(),
      description: (json['description'] ?? '').toString(),
      imageUrl: json['image_url']?.toString() ?? json['imageUrl']?.toString(),
      status: (json['status'] ?? 'pending').toString(),
      createdAt: createdAt,
    );
  }

  static double _toDouble(dynamic v) {
    if (v == null) return 0;
    if (v is double) return v;
    if (v is int) return v.toDouble();
    return double.tryParse(v.toString()) ?? 0;
  }

  // ── UI helpers ────────────────────────────────────────────────────────────

  Color get categoryColor {
    switch (category.toLowerCase()) {
      case 'flood':
        return const Color(0xFF1565C0);
      case 'fire':
        return const Color(0xFFB71C1C);
      case 'earthquake':
        return const Color(0xFF6A1B9A);
      case 'landslide':
        return const Color(0xFF4E342E);
      case 'power':
        return const Color(0xFFF9A825);
      default:
        return const Color(0xFF546E7A);
    }
  }

  IconData get categoryIcon {
    switch (category.toLowerCase()) {
      case 'flood':
        return Icons.flood_outlined;
      case 'fire':
        return Icons.local_fire_department_outlined;
      case 'earthquake':
        return Icons.crisis_alert_outlined;
      case 'landslide':
        return Icons.landscape_outlined;
      case 'power':
        return Icons.bolt_outlined;
      default:
        return Icons.warning_amber_outlined;
    }
  }

  Color get severityColor {
    switch (severity.toLowerCase()) {
      case 'critical':
        return const Color(0xFFB71C1C);
      case 'high':
        return const Color(0xFFE53935);
      case 'medium':
        return const Color(0xFFF5A623);
      case 'low':
        return const Color(0xFF43A047);
      default:
        return const Color(0xFF546E7A);
    }
  }

  String get timeAgo {
    final diff = DateTime.now().difference(createdAt);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${createdAt.day}/${createdAt.month}/${createdAt.year}';
  }
}
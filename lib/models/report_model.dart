import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';

class ReportModel {
  final String id;
  final String title;
  final String type;       // Supabase column: 'type'  (was 'category')
  final String priority;   // Supabase column: 'priority' (was 'severity')
  final String status;
  final String reporter;
  final String mobile;
  final String location;   // Supabase column: 'location' (was 'address')
  final String description;
  final String assignedTo;
  final String responder;
  final int etaMinutes;
  final double lat;        // Supabase column: 'lat'
  final double lng;        // Supabase column: 'lng'
  final String? imageUrl;
  final DateTime createdAt;

  ReportModel({
    required this.id,
    required this.title,
    required this.type,
    required this.priority,
    required this.status,
    required this.reporter,
    required this.mobile,
    required this.location,
    required this.description,
    required this.assignedTo,
    required this.responder,
    required this.etaMinutes,
    required this.lat,
    required this.lng,
    this.imageUrl,
    required this.createdAt,
  });

  LatLng get latLng => LatLng(lat, lng);

  // ── Convenience aliases so existing code keeps working ────────────────────
  String get category => type;
  String get severity => priority;
  String get address => location;

  // ── Parse from Supabase row ───────────────────────────────────────────────
  factory ReportModel.fromJson(Map<String, dynamic> json) {
    return ReportModel(
      id: (json['id'] ?? '').toString(),
      title: (json['title'] ?? '').toString(),
      type: (json['type'] ?? 'Others').toString(),
      priority: (json['priority'] ?? 'medium').toString(),
      status: (json['status'] ?? 'received').toString(),
      reporter: (json['reporter'] ?? 'Anonymous').toString(),
      mobile: (json['mobile'] ?? '').toString(),
      location: (json['location'] ?? '').toString(),
      description: (json['description'] ?? '').toString(),
      assignedTo: (json['assigned_to'] ?? 'Unassigned').toString(),
      responder: (json['responder'] ?? '').toString(),
      etaMinutes: _toInt(json['eta_minutes']),
      lat: _toDouble(json['lat']),
      lng: _toDouble(json['lng']),
      imageUrl: json['image_url']?.toString(),
      createdAt: _parseDate(json['created_at']),
    );
  }

  static double _toDouble(dynamic v) {
    if (v == null) return 0;
    if (v is double) return v;
    if (v is int) return v.toDouble();
    return double.tryParse(v.toString()) ?? 0;
  }

  static int _toInt(dynamic v) {
    if (v == null) return 0;
    if (v is int) return v;
    return int.tryParse(v.toString()) ?? 0;
  }

  static DateTime _parseDate(dynamic v) {
    if (v == null) return DateTime.now();
    if (v is String) return DateTime.tryParse(v) ?? DateTime.now();
    return DateTime.now();
  }

  // ── UI helpers ────────────────────────────────────────────────────────────

  Color get categoryColor {
    switch (type.toLowerCase()) {
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
    switch (type.toLowerCase()) {
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
    switch (priority.toLowerCase()) {
      case 'critical':
        return const Color(0xFFB71C1C);
      case 'high':
        return const Color(0xFFE53935);
      case 'medium':
      case 'moderate':
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
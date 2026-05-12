import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class NewsScreen extends StatefulWidget {
  const NewsScreen({super.key});

  @override
  State<NewsScreen> createState() => _NewsScreenState();
}

class _NewsScreenState extends State<NewsScreen> {
  static const String _baseUrl =
      'https://resq-app-xsb98.ondigitalocean.app';

  List<Map<String, dynamic>> _news = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchNews();
  }

  Future<void> _fetchNews() async {
  setState(() {
    _isLoading = true;
    _error = null;
  });

  try {
    final response = await http
        .get(Uri.parse('$_baseUrl/api/news/all'))
        .timeout(const Duration(seconds: 15));

    if (response.statusCode == 200) {
      final decoded = jsonDecode(response.body);

      List<dynamic> rawList;
      if (decoded is List) {
        rawList = decoded;
      } else if (decoded is Map && decoded['data'] is List) {
        rawList = decoded['data'];
      } else if (decoded is Map && decoded['announcements'] is List) {
        rawList = decoded['announcements'];
      } else {
        rawList = [];
        debugPrint('Unexpected shape: ${decoded.runtimeType} → $decoded');
      }

      final sorted = rawList
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .toList();

      sorted.sort((a, b) => _parseItemDate(b).compareTo(_parseItemDate(a)));

      setState(() {
        _news = sorted;
        _isLoading = false;
      });

    } else {
      setState(() {
        _error = 'Server error ${response.statusCode}.';
        _isLoading = false;
      });
    }
  } catch (e) {
    setState(() {
      _error = 'Could not connect to the server.';
      _isLoading = false;
    });
  }
}

  // ── Pinned item (shown at the top if present) ─────────────────────────────
  Map<String, dynamic>? get _pinned {
    try {
      return _news.firstWhere(
        (item) => (item['pinned'] ?? '').toString().toLowerCase() == 'yes',
      );
    } catch (_) {
      return null;
    }
  }

  // ── Non-pinned items ──────────────────────────────────────────────────────
  List<Map<String, dynamic>> get _latest => _news
      .where(
        (item) => (item['pinned'] ?? '').toString().toLowerCase() != 'yes',
      )
      .toList();

  // ── Icon by category ──────────────────────────────────────────────────────
  IconData _icon(String category) {
    switch (category.toLowerCase()) {
      case 'weather':
        return Icons.cloud_outlined;
      case 'emergency':
        return Icons.warning_amber_rounded;
      case 'disaster alert':
      case 'disaster':
        return Icons.crisis_alert_outlined;
      case 'advisory':
        return Icons.campaign_outlined;
      case 'missing person':
      case 'missing':
        return Icons.person_search_outlined;
      case 'health':
        return Icons.health_and_safety_outlined;
      default:
        return Icons.notifications_outlined;
    }
  }

  // ── Accent color by priority ──────────────────────────────────────────────
  Color _color(String priority) {
    switch (priority.toLowerCase()) {
      case 'emergency':
      case 'critical':
        return const Color(0xFFB71C1C);
      case 'high':
        return const Color(0xFFE65100);
      case 'moderate':
      case 'medium':
        return const Color(0xFF1565C0);
      case 'low':
      case 'normal':
      default:
        return const Color(0xFF00695C);
    }
  }

  // ── Date formatter ────────────────────────────────────────────────────────
  // AFTER
  // AFTER
String _formatDate(dynamic raw) {
  if (raw == null || raw.toString().isEmpty) return 'No date';
  try {
    final dt = DateTime.parse(raw.toString()).toLocal();
    final months = [
      '', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    final hour = dt.hour > 12 ? dt.hour - 12 : dt.hour == 0 ? 12 : dt.hour;
    final minute = dt.minute.toString().padLeft(2, '0');
    final ampm = dt.hour >= 12 ? 'PM' : 'AM';
    return '${months[dt.month]} ${dt.day}, ${dt.year}  $hour:$minute $ampm';
  } catch (_) {
    return raw.toString();
  }
}

    DateTime _parseItemDate(Map<String, dynamic> item) {
    // mirrors admin JS: createdAt || date
    final raw = item['createdAt'] ?? item['date'];
    if (raw == null || raw.toString().isEmpty) return DateTime(0);
    return DateTime.tryParse(raw.toString()) ?? DateTime(0);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F0EB),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF5F0EB),
        elevation: 0,
        centerTitle: true,
        title: const Text(
          'News & Alerts',
          style: TextStyle(
              color: Colors.black87, fontWeight: FontWeight.w600),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.black54),
            onPressed: _fetchNews,
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    // ── Loading ──
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFFF5A623)),
      );
    }

    // ── Error ──
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.wifi_off_outlined,
                  size: 48, color: Colors.black26),
              const SizedBox(height: 16),
              const Text('Could not load announcements',
                  style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.black54)),
              const SizedBox(height: 8),
              Text(_error!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      fontSize: 13, color: Colors.black38)),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFF5A623),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
                onPressed: _fetchNews,
                icon: const Icon(Icons.refresh,
                    color: Colors.white, size: 16),
                label: const Text('Retry',
                    style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
        ),
      );
    }

    // ── Empty ──
    if (_news.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.campaign_outlined,
                size: 48, color: Colors.black26),
            const SizedBox(height: 16),
            const Text('No announcements yet',
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.black54)),
            const SizedBox(height: 8),
            const Text('New alerts will appear here when posted.',
                style: TextStyle(fontSize: 13, color: Colors.black38)),
            const SizedBox(height: 24),
            TextButton.icon(
              onPressed: _fetchNews,
              icon: const Icon(Icons.refresh,
                  size: 16, color: Color(0xFFF5A623)),
              label: const Text('Refresh',
                  style: TextStyle(color: Color(0xFFF5A623))),
            ),
          ],
        ),
      );
    }

    // ── Content ──
    return RefreshIndicator(
      color: const Color(0xFFF5A623),
      onRefresh: _fetchNews,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ── Pinned banner ──
          if (_pinned != null) ...[
            _PinnedCard(
              item: _pinned!,
              icon: _icon(_pinned!['category'] ?? ''),
              color: _color(_pinned!['priority'] ?? ''),
              date: _formatDate(_pinned!['date']),
            ),
            const SizedBox(height: 16),
            const Padding(
              padding: EdgeInsets.only(bottom: 10),
              child: Text(
                'Latest Announcements',
                style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: Colors.black45,
                    letterSpacing: 0.5),
              ),
            ),
          ],

          // ── Latest list ──
          ..._latest.map((item) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _NewsCard(
                  item: item,
                  icon: _icon(item['category'] ?? ''),
                  color: _color(item['priority'] ?? ''),
                  date: _formatDate(item['date']),
                ),
              )),
        ],
      ),
    );
  }
}

// ── Pinned Card ───────────────────────────────────────────────────────────────

class _PinnedCard extends StatelessWidget {
  final Map<String, dynamic> item;
  final IconData icon;
  final Color color;
  final String date;

  const _PinnedCard({
    required this.item,
    required this.icon,
    required this.color,
    required this.date,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.07),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.35), width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 18),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  item['title'] ?? '',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: color,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  'PINNED',
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    letterSpacing: 0.8,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            item['message'] ?? '',
            style: const TextStyle(
                fontSize: 14, color: Colors.black87, height: 1.45),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 6,
            runSpacing: 4,
            children: [
              _MetaChip(label: item['category'] ?? '', color: color),
              _MetaChip(label: item['priority'] ?? '', color: color),
              if ((item['audience'] ?? '').toString().isNotEmpty)
                _MetaChip(label: item['audience'].toString(), color: color),
              if (date.isNotEmpty)
                _MetaChip(label: date, color: Colors.black38),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Regular News Card ─────────────────────────────────────────────────────────

class _NewsCard extends StatelessWidget {
  final Map<String, dynamic> item;
  final IconData icon;
  final Color color;
  final String date;

  const _NewsCard({
    required this.item,
    required this.icon,
    required this.color,
    required this.date,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE8E0D8)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        item['title'] ?? '',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 7, vertical: 2),
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        (item['priority'] ?? '').toString().toUpperCase(),
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                          color: color,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  item['message'] ?? '',
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                      fontSize: 13, color: Colors.black54, height: 1.4),
                ),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  children: [
                    _MetaChip(
                        label: item['category'] ?? '',
                        color: color,
                        small: true),
                    if ((item['audience'] ?? '').toString().isNotEmpty)
                      _MetaChip(
                          label: item['audience'].toString(),
                          color: Colors.black38,
                          small: true),
                    if (date.isNotEmpty)
                      _MetaChip(
                          label: date,
                          color: Colors.black38,
                          small: true),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Meta Chip ─────────────────────────────────────────────────────────────────

class _MetaChip extends StatelessWidget {
  final String label;
  final Color color;
  final bool small;

  const _MetaChip({
    required this.label,
    required this.color,
    this.small = false,
  });

  @override
  Widget build(BuildContext context) {
    if (label.isEmpty) return const SizedBox.shrink();
    return Container(
      padding: EdgeInsets.symmetric(
          horizontal: small ? 6 : 8, vertical: small ? 1 : 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: small ? 10 : 11,
          fontWeight: FontWeight.w500,
          color: color,
        ),
      ),
    );
  }
}
import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../services/report_service.dart';

class ReportHistoryScreen extends StatefulWidget {
  const ReportHistoryScreen({super.key});

  @override
  State<ReportHistoryScreen> createState() =>
      _ReportHistoryScreenState();
}

class _ReportHistoryScreenState
    extends State<ReportHistoryScreen> {

  late Future<List<Map<String, dynamic>>> _reportsFuture;

  @override
  void initState() {
    super.initState();

    final user = AuthService().currentUser!;

    _reportsFuture =
        ReportService.getUserReports(user.id);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F0EB),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF5F0EB),
        elevation: 0,
        title: const Text(
          'Report History',
          style: TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _reportsFuture,
        builder: (context, snapshot) {

          if (snapshot.connectionState ==
              ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (!snapshot.hasData ||
              snapshot.data!.isEmpty) {
            return const Center(
              child: Text('No reports yet'),
            );
          }

          final reports = snapshot.data!;

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: reports.length,
            itemBuilder: (context, index) {

              final report = reports[index];

              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: const Color(0xFFE8E0D8),
                  ),
                ),
                // AFTER
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 12),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                          color: const Color(0xFFF5A623).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          Icons.warning_amber_rounded,
                          color: Color(0xFFF5A623),
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // ── Title + severity ──
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    report['type'] ?? report['category'] ?? 'Unknown',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 15,
                                    ),
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: Colors.red.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    report['priority'] ?? report['severity'] ?? '',
                                    style: const TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.red,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),

                            // ── Location ──
                            if ((report['location'] ?? report['address'] ?? '').isNotEmpty)
                              Row(
                                children: [
                                  const Icon(Icons.location_on_outlined,
                                    size: 13, color: Colors.black45),
                                  const SizedBox(width: 4),
                                  Expanded(
                                    child: Text(
                                      report['location'] ?? report['address'] ?? '',
                                      style: const TextStyle(
                                        fontSize: 12, color: Colors.black54),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),

                              // ── Description ──
                              if ((report['description'] ?? '').isNotEmpty)
                                Text(
                                  report['description'] ?? '',
                                  style: const TextStyle(
                                    fontSize: 12, color: Colors.black45),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              const SizedBox(height: 6),

                              // ── Date/time + status ──
                              Row(
                                children: [
                                  const Icon(Icons.access_time_outlined,
                                    size: 13, color: Colors.black38),
                                  const SizedBox(width: 4),
                                  Text(
                                    () {
                                      final raw = report['created_at'];
                                      if (raw == null) return 'No date';
                                      try {
                                        final dt = DateTime.parse(raw.toString()).toLocal();
                                        const months = [
                                          '', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
                                          'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
                                        ];
                                        final hour = dt.hour > 12
                                          ? dt.hour - 12
                                          : dt.hour == 0 ? 12 : dt.hour;
                                        final minute = dt.minute.toString().padLeft(2, '0');
                                        final ampm = dt.hour >= 12 ? 'PM' : 'AM';
                                        return '${months[dt.month]} ${dt.day}, ${dt.year}  $hour:$minute $ampm';
                                        } catch (_) {
                                          return raw.toString();
                                        }
                                      }(),
                                      style: const TextStyle(
                                        fontSize: 11, color: Colors.black38),
                                  ),
                                  const Spacer(),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFF5A623).withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Text(
                                      report['status'] ?? '',
                                      style: const TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                        color: Color(0xFFF5A623),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
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
                child: ListTile(
                  leading: const Icon(
                    Icons.warning_amber_rounded,
                    color: Color(0xFFF5A623),
                  ),

                  title: Text(
                    report['category'] ?? 'Unknown',
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                    ),
                  ),

                  subtitle: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 4),

                      Text(
                        report['address'] ?? '',
                      ),

                      const SizedBox(height: 4),

                      Text(
                        report['description'] ?? '',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),

                  trailing: Column(
                    mainAxisAlignment:
                        MainAxisAlignment.center,
                    children: [
                      Text(
                        report['severity'] ?? '',
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          color: Colors.red,
                        ),
                      ),

                      const SizedBox(height: 4),

                      Text(
                        report['status'] ?? '',
                        style: const TextStyle(
                          fontSize: 11,
                          color: Colors.black45,
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
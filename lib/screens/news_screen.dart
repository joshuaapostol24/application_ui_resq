import 'package:flutter/material.dart';

class NewsScreen extends StatelessWidget {
  const NewsScreen({super.key});

  final List<Map<String, dynamic>> news = const [
    {
      'title': 'Flood Warning',
      'subtitle': 'Stay alert in low-lying areas',
      'icon': Icons.flood_outlined,
      'color': Color(0xFF1565C0),
      'time': '2h ago',
    },
    {
      'title': 'Earthquake Alert',
      'subtitle': 'Magnitude 5.2 — Minor damage reported',
      'icon': Icons.crisis_alert_outlined,
      'color': Color(0xFFB71C1C),
      'time': '5h ago',
    },
    {
      'title': 'Typhoon Update',
      'subtitle': 'Signal No. 1 raised in Northern Luzon',
      'icon': Icons.storm_outlined,
      'color': Color(0xFF00838F),
      'time': '1d ago',
    },
    {
      'title': 'Fire Incident',
      'subtitle': 'Residential fire in Barangay 5 contained',
      'icon': Icons.local_fire_department_outlined,
      'color': Color(0xFFF5A623),
      'time': '1d ago',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F0EB),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF5F0EB),
        elevation: 0,
        title: const Text('News & Alerts',
            style: TextStyle(color: Colors.black87, fontWeight: FontWeight.w600)),
        centerTitle: true,
      ),
      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: news.length,
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (context, index) {
          final item = news[index];
          return Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFE8E0D8)),
            ),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: (item['color'] as Color).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(item['icon'] as IconData,
                      color: item['color'] as Color, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(item['title'] as String,
                          style: const TextStyle(
                              fontWeight: FontWeight.w600, fontSize: 15)),
                      const SizedBox(height: 2),
                      Text(item['subtitle'] as String,
                          style: const TextStyle(
                              color: Colors.black45, fontSize: 13)),
                    ],
                  ),
                ),
                Text(item['time'] as String,
                    style: const TextStyle(color: Colors.black38, fontSize: 11)),
              ],
            ),
          );
        },
      ),
    );
  }
}
import 'package:flutter/material.dart';


class HotlineScreen extends StatelessWidget {
  const HotlineScreen({super.key});

  final List<Map<String, dynamic>> hotlines = const [
    {'title': 'Police', 'number': '911', 'icon': Icons.local_police_outlined, 'color': Color(0xFF1565C0)},
    {'title': 'Fire Department', 'number': '160', 'icon': Icons.local_fire_department_outlined, 'color': Color(0xFFB71C1C)},
    {'title': 'Ambulance', 'number': '143', 'icon': Icons.medical_services_outlined, 'color': Color(0xFF2E7D32)},
    {'title': 'Coast Guard', 'number': '5757', 'icon': Icons.anchor_outlined, 'color': Color(0xFF00838F)},
    {'title': 'NDRRMC', 'number': '911', 'icon': Icons.crisis_alert_outlined, 'color': Color(0xFFF5A623)},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F0EB),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF5F0EB),
        elevation: 0,
        title: const Text(
          'Emergency Hotlines',
          style: TextStyle(color: Colors.black87, fontWeight: FontWeight.w600),
        ),
        centerTitle: true,
      ),
      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: hotlines.length,
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (context, index) {
          final h = hotlines[index];
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
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
                    color: (h['color'] as Color).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(h['icon'] as IconData, color: h['color'] as Color, size: 22),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(h['title'] as String,
                          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
                      Text(h['number'] as String,
                          style: const TextStyle(color: Colors.black45, fontSize: 13)),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.call, color: Color(0xFFF5A623)),
                  onPressed: () {},
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

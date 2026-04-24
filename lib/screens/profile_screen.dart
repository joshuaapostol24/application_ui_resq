import 'package:flutter/material.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F0EB),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF5F0EB),
        elevation: 0,
        title: const Text('Profile',
            style: TextStyle(color: Colors.black87, fontWeight: FontWeight.w600)),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const SizedBox(height: 16),
            // Avatar
            CircleAvatar(
              radius: 48,
              backgroundColor: const Color(0xFFF5A623).withOpacity(0.15),
              child: const Icon(Icons.person, size: 48, color: Color(0xFFF5A623)),
            ),
            const SizedBox(height: 12),
            const Text('Joshua dela Cruz',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
            const Text('joshua@email.com',
                style: TextStyle(color: Colors.black45, fontSize: 14)),
            const SizedBox(height: 24),
            // Options
            ...[
              {'icon': Icons.history_outlined, 'label': 'Report History'},
              {'icon': Icons.notifications_outlined, 'label': 'Notifications'},
              {'icon': Icons.lock_outline, 'label': 'Change Password'},
              {'icon': Icons.help_outline, 'label': 'Help & Support'},
              {'icon': Icons.logout, 'label': 'Logout'},
            ].map(
                  (item) => Container(
                margin: const EdgeInsets.only(bottom: 10),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFFE8E0D8)),
                ),
                child: ListTile(
                  leading: Icon(item['icon'] as IconData,
                      color: const Color(0xFFF5A623)),
                  title: Text(item['label'] as String,
                      style: const TextStyle(fontWeight: FontWeight.w500)),
                  trailing: const Icon(Icons.chevron_right, color: Colors.black38),
                  onTap: () {},
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
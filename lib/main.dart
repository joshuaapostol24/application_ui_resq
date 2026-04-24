import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'screens/report_screen.dart';
import 'screens/hotline_screen.dart';
import 'screens/map_screen.dart';
import 'screens/news_screen.dart';
import 'screens/profile_screen.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

void main() {
  runApp(const ResQApp());
}

class ResQApp extends StatelessWidget {
  const ResQApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'ResQ App',
      theme: ThemeData(
        primarySwatch: Colors.red,
        scaffoldBackgroundColor: const Color(0xFFF5F0EB),
      ),
      home: const MainScreen(),
    );
  }
}

// ── MAIN SCREEN ──────────────────────────────────────────────────────────────

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int currentIndex = 0;

  final List<Widget> screens = const [
    ReportScreen(),
    HotlineScreen(),
    MapScreen(),
    NewsScreen(),
    ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F0EB),
      body: screens[currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: currentIndex,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: const Color(0xFFF5A623),
        unselectedItemColor: Colors.black45,
        backgroundColor: Colors.white,
        elevation: 12,
        onTap: (index) => setState(() => currentIndex = index),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.report_outlined), label: "Report"),
          BottomNavigationBarItem(icon: Icon(Icons.phone_outlined), label: "Hotline"),
          BottomNavigationBarItem(icon: Icon(Icons.map_outlined), label: "Map"),
          BottomNavigationBarItem(icon: Icon(Icons.article_outlined), label: "News"),
          BottomNavigationBarItem(icon: Icon(Icons.person_outline), label: "Profile"),
        ],
      ),
    );
  }
}


import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'screens/report_screen.dart';
import 'screens/hotline_screen.dart';
import 'screens/map_screen.dart';
import 'screens/news_screen.dart';
import 'screens/profile_screen.dart';
import 'services/auth_service.dart';
import 'package:firebase_core/firebase_core.dart';
import 'services/notification_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

    await Firebase.initializeApp();

    await Supabase.initialize(
      url: 'https://jpovamcznyzoemcnjrgs.supabase.co',       // from Supabase dashboard
      anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Impwb3ZhbWN6bnl6b2VtY25qcmdzIiwicm9sZSI6ImFub24iLCJpYXQiOjE3Nzc4ODMwMTcsImV4cCI6MjA5MzQ1OTAxN30.1WTdf3j4F6z-attUvvPi5Z7i8Q81hB4hhQtpyrgU8ao',      // from Supabase dashboard
    );
  FlutterError.onError = (FlutterErrorDetails details) {
  FlutterError.presentError(details);
  debugPrint(details.exceptionAsString());
  debugPrintStack(stackTrace: details.stack);
  };
  runApp(const ResQApp());
}

// Helper to access Supabase client anywhere in the app 
//final supabase = Supabase.instance.client;

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

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int currentIndex = 0;
  final AuthService _authService = AuthService();


  @override
  void initState() {
    super.initState();

    // Check if app was opened from a notification
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final nav = NotificationService.pendingNavigation;
      if (nav == 'news') {
        setState(() => currentIndex = 3); // News tab index
        NotificationService.pendingNavigation = null;
      } else if (nav == 'report') {
        setState(() => currentIndex = 2); // Map tab index
        NotificationService.pendingNavigation = null;
      }
    });
  }



  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _authService,
      builder: (context, _) {
        final bool canReport = _authService.isLoggedIn;

        final List<Widget> screens = [
          canReport
              ? const ReportScreen()
              : const _GuestReportBlock(),
          const HotlineScreen(),
          const MapScreen(),
          const NewsScreen(),
          const ProfileScreen(),
        ];

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
              BottomNavigationBarItem(
                  icon: Icon(Icons.report_outlined), label: "Report"),
              BottomNavigationBarItem(
                  icon: Icon(Icons.phone_outlined), label: "Hotline"),
              BottomNavigationBarItem(
                  icon: Icon(Icons.map_outlined), label: "Map"),
              BottomNavigationBarItem(
                  icon: Icon(Icons.article_outlined), label: "News"),
              BottomNavigationBarItem(
                  icon: Icon(Icons.person_outline), label: "Profile"),
            ],
          ),
        );
      },
    );
  }
}

class _GuestReportBlock extends StatelessWidget {
  const _GuestReportBlock();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F0EB),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF5F0EB),
        elevation: 0,
        title: const Text('Report',
            style:
                TextStyle(color: Colors.black87, fontWeight: FontWeight.w600)),
        centerTitle: true,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: const Color(0xFFF5A623).withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.lock_outline,
                    size: 40, color: Color(0xFFF5A623)),
              ),
              const SizedBox(height: 20),
              const Text(
                'Sign in to make a report',
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Colors.black87),
              ),
              const SizedBox(height: 8),
              const Text(
                'You need an account to submit incident reports. Guest users can only view reports.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13, color: Colors.black45),
              ),
              const SizedBox(height: 28),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFF5A623),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    elevation: 0,
                  ),
                  onPressed: () {
                    final mainState =
                        context.findAncestorStateOfType<_MainScreenState>();
                    mainState?.setState(() => mainState.currentIndex = 4);
                  },
                  child: const Text('Go to Profile',
                      style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 15)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}


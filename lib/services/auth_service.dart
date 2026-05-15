import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'notification_service.dart';

class UserModel {
  final String id;
  final String name;
  final String address;
  final String email;
  final String mobileNumber;
  final String approvalStatus; 

  UserModel({
    required this.id,
    required this.name,
    required this.address,
    required this.email,
    required this.mobileNumber,
    required this.approvalStatus,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      address: json['address'] ?? '',
      email: json['email'] ?? '',
      mobileNumber: json['mobile_number'] ?? '',
      approvalStatus: json['status'] ?? 'pending',
    );
  }
}

class AuthService extends ChangeNotifier {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal() {
    // Listen to Supabase auth state changes automatically
    Supabase.instance.client.auth.onAuthStateChange.listen((data) {
      final event = data.event;
      if (event == AuthChangeEvent.signedIn) {
        _loadUserProfile();
      } else if (event == AuthChangeEvent.signedOut) {
        _currentUser = null;
        _isGuest = false;
        notifyListeners();
      }
    });

    // Check if there's already an active session on app start
    final existingSession = Supabase.instance.client.auth.currentSession;
    if (existingSession != null) {
      _loadUserProfile();
    }
  }

  SupabaseClient get _supabase =>
    Supabase.instance.client;

  UserModel? _currentUser;
  bool _isGuest = false;
  bool _isLoading = false;

  UserModel? get currentUser => _currentUser;
  bool get isGuest => _isGuest;
  bool get isLoggedIn =>
    _supabase.auth.currentSession != null &&
    _currentUser != null;
  bool get isLoading => _isLoading;

  // ── Load profile from Supabase 'profiles' table ──────────────────────────
  Future<void> _loadUserProfile() async {
  try {
    _isLoading = true;
    notifyListeners();

    final userId = _supabase.auth.currentSession?.user.id;

    if (userId == null) {
      _isLoading = false;
      notifyListeners();
      return;
    }

    final data = await _supabase
        .from('users')
        .select()
        .eq('id', userId)
        .maybeSingle();

    // NO PROFILE FOUND
    if (data == null) {
      await _supabase.auth.signOut();

      _currentUser = null;

      _isLoading = false;
      notifyListeners();
      return;
    }

    final status =
      (data['status'] ?? 'pending')
        .toString()
        .toLowerCase();

    if (status == 'pending' ||
      status == 'rejected') {

      _currentUser = null;

      _isGuest = false;

      return;
    }

    // APPROVED USER
    _currentUser = UserModel.fromJson(data);

    _isGuest = false;
    debugPrint('🔔 About to call NotificationService.initialize()');
    await NotificationService().initialize();
    debugPrint('🔔 NotificationService.initialize() completed');

  } catch (e) {
    debugPrint('Error loading profile: $e');

  } finally {
    _isLoading = false;
    notifyListeners();
  }
}

  // ── Sign Up ───────────────────────────────────────────────────────────────
Future<Map<String, dynamic>> signUp({
  required String name,
  required String address,
  required String email,
  required String mobileNumber,
  required String idType,
  required String idNumber,
  required String password,
  String? idImageUrl,
}) async {

  try {

    _isLoading = true;
    notifyListeners();

    // ─────────────────────────────────────────────
    // CHECK IF EMAIL ALREADY EXISTS FIRST
    // ─────────────────────────────────────────────
    final existingUser = await _supabase
        .from('users')
        .select('email')
        .eq('email', email)
        .maybeSingle();

    if (existingUser != null) {

      return {
        'success': false,
        'message':
            'An account with this email already exists.',
      };
    }

    await _supabase.auth.signOut();

    // ─────────────────────────────────────────────
    // CREATE AUTH ACCOUNT
    // ─────────────────────────────────────────────
    final response =
        await _supabase.auth.signUp(
      email: email,
      password: password,
      data: {
        'name': name,
        'address': address,
        'mobile_number': mobileNumber,
      },
    );

    if (response.user == null) {

      return {
        'success': false,
        'message':
            'Sign up failed. Please try again.',
      };
    }

    // ─────────────────────────────────────────────
    // INSERT USER PROFILE
    // ─────────────────────────────────────────────
    await _supabase.from('users').insert({
      'id': response.user!.id,
      'name': name,
      'address': address,
      'email': email,
      'mobile_number': mobileNumber,
      'id_type': idType,
      'id_number': idNumber,
      'id_image_url': idImageUrl,
      'status': 'pending',
    });

    // OPTIONAL:
    // SIGN OUT IMMEDIATELY AFTER SIGNUP
    await _supabase.auth.signOut();

    return {
      'success': true,
      'message':
          'Your account has been created successfully and is now under review by the admin.',
    };

  } on AuthException catch (e) {

    return {
      'success': false,
      'message': e.message,
    };

  } on PostgrestException catch (e) {

    return {
      'success': false,
      'message': e.message,
    };

  } catch (e) {

    debugPrint('SIGNUP ERROR: $e');

    return {
      'success': false,
      'message':
          'Something went wrong. Please try again.',
    };

  } finally {

    _isLoading = false;
    notifyListeners();
  }
}

  // ── Login with Email ──────────────────────────────────────────────────────
  Future<Map<String, dynamic>> login({
  required String email,
  required String password,
}) async {

  try {

    _isLoading = true;

    // FIRST: check database BEFORE auth login
    final existingUser = await _supabase
        .from('users')
        .select()
        .eq('email', email)
        .maybeSingle();

    if (existingUser == null) {

      return {
        'success': false,
        'message': 'Incorrect email or password. Please enter appropriate details.',
      };
    }

    final status =
        existingUser['status']
            .toString()
            .toLowerCase();

    // BLOCK pending users BEFORE login
    if (status == 'pending') {

      return {
        'success': false,
        'message':
            'Your account is still under review by the admin.',
      };
    }

    // BLOCK rejected users BEFORE login
    if (status == 'rejected') {

      return {
        'success': false,
        'message':
            'Your account has been rejected by the admin.',
      };
    }

    // ONLY approved users continue
    final response =
        await _supabase.auth.signInWithPassword(
      email: email,
      password: password,
    );

    if (response.user == null) {

      return {
        'success': false,
        'message': 'Incorrect email or password. Please enter appropriate details.',
      };
    }

    _currentUser =
        UserModel.fromJson(existingUser);

    notifyListeners();

    return {
      'success': true,
      'message': 'Login successful.',
    };

  } on AuthException {

    return {
      'success': false,
      'message': 'Incorrect email or password. Please enter appropriate details.',
    };

  } catch (e) {

    return {
      'success': false,
      'message': 'Something went wrong.',
    };

  } finally {

    _isLoading = false;
  }
}


  // ── Email OTP — Step 1: Send OTP ─────────────────────────────────────────
Future<Map<String, dynamic>> sendEmailOtp({required String email}) async {
  try {
    _isLoading = true;
    notifyListeners();

    await _supabase.auth.signInWithOtp(
      email: email,
      shouldCreateUser: false,  // creates account if it doesn't exist yet
    );

    return {'success': true};
  } on AuthException catch (e) {
    return {'success': false, 'message': e.message};
  } catch (e) {
    return {'success': false, 'message': 'Could not send OTP email.'};
  } finally {
    _isLoading = false;
    notifyListeners();
  }
}

// ── Email OTP — Step 2: Verify OTP ───────────────────────────────────────
Future<Map<String, dynamic>> verifyEmailOtp({
  required String email,
  required String otp,
}) async {
  try {
    _isLoading = true;
    notifyListeners();

    await _supabase.auth.verifyOTP(
      email: email,
      token: otp,
      type: OtpType.email,   // changed from OtpType.sms
    );

    // Create a profile stub if this is a new user
    final userId = _supabase.auth.currentSession?.user.id;
    if (userId != null) {
      final existing = await _supabase
          .from('users')
          .select()
          .eq('id', userId)
          .maybeSingle();

      if (existing == null) {
        await _supabase.from('users').insert({
          'id': userId,
          'name': '',
          'address': '',
          'email': email,
          'mobile_number': '',
        });
      }
    }

    await _loadUserProfile();
    return {'success': true};
  } on AuthException catch (e) {
    return {'success': false, 'message': e.message};
  } catch (e) {
    return {'success': false, 'message': 'OTP verification failed.'};
  } finally {
    _isLoading = false;
    notifyListeners();
  }
}

  // ── Change Password ───────────────────────────────────────────────────────
  Future<Map<String, dynamic>> changePassword({
    required String newPassword,
  }) async {
    try {
      await _supabase.auth.updateUser(
        UserAttributes(password: newPassword),
      );
      return {'success': true};
    } on AuthException catch (e) {
      return {'success': false, 'message': e.message};
    } catch (e) {
      return {'success': false, 'message': 'Could not change password.'};
    }
  }

  Future<Map<String, dynamic>> sendPasswordResetEmail(
  String email,
) async {
  try {
    await _supabase.auth.resetPasswordForEmail(
      email,
      redirectTo: 'resq://reset-password',
    );

    return {
      'success': true,
      'message': 'Password reset email has been sent.',
    };

  } on AuthException catch (e) {
    return {
      'success': false,
      'message': e.message,
    };

  } catch (e) {
    return {
      'success': false,
      'message': 'Failed to send password reset email.',
    };
  }
}


  // ── Guest ─────────────────────────────────────────────────────────────────
  void loginAsGuest() {
    _isGuest = true;
    _currentUser = null;
    notifyListeners();
  }

  // ── Logout ────────────────────────────────────────────────────────────────
  Future<void> logout() async {
  // Wrap in try-catch so a notification error never blocks logout
  try {
    await NotificationService().clearTokenOnLogout();
  } catch (e) {
    debugPrint('clearTokenOnLogout error (non-fatal): $e');
  }
  
  // This must always run regardless
  await _supabase.auth.signOut();
}
}
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

    final existingSession = Supabase.instance.client.auth.currentSession;
    if (existingSession != null) {
      _loadUserProfile();
    }
  }

  SupabaseClient get _supabase => Supabase.instance.client;

  UserModel? _currentUser;
  bool _isGuest = false;
  bool _isLoading = false;

  UserModel? get currentUser => _currentUser;
  bool get isGuest => _isGuest;
  bool get isLoggedIn =>
      _supabase.auth.currentSession != null && _currentUser != null;
  bool get isLoading => _isLoading;

  // ── Load profile from Supabase 'users' table ──────────────────────────────
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

      if (data == null) {
        // No profile row — sign out fully so the session doesn't linger
        await _supabase.auth.signOut();
        _currentUser = null;
        _isLoading = false;
        notifyListeners();
        return;
      }

      final status = (data['status'] ?? 'pending').toString().toLowerCase();

      if (status == 'pending' || status == 'rejected' || status == 'banned') {
        // BUG FIX: sign out of Supabase Auth so the JWT doesn't remain live
        // while the app shows the user as a guest.
        await _supabase.auth.signOut();
        _currentUser = null;
        _isGuest = false;
        _isLoading = false;
        notifyListeners();
        return;
      }

      _currentUser = UserModel.fromJson(data);
      _isGuest = false;

      // Initialize notifications now that we have a confirmed, approved user
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

      // Check if email already exists before creating an auth account
      final existingUser = await _supabase
          .from('users')
          .select('email')
          .eq('email', email)
          .maybeSingle();

      if (existingUser != null) {
        return {
          'success': false,
          'message': 'An account with this email already exists.',
        };
      }

      await _supabase.auth.signOut();

      final response = await _supabase.auth.signUp(
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
          'message': 'Sign up failed. Please try again.',
        };
      }

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

      // Sign out immediately — account needs admin approval before use
      await _supabase.auth.signOut();

      return {
        'success': true,
        'message':
            'Your account has been created successfully and is now under '
            'review by the admin.',
      };
    } on AuthException catch (e) {
      return {'success': false, 'message': e.message};
    } on PostgrestException catch (e) {
      return {'success': false, 'message': e.message};
    } catch (e) {
      debugPrint('SIGNUP ERROR: $e');
      return {
        'success': false,
        'message': 'Something went wrong. Please try again.',
      };
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ── Login with Email + Password ───────────────────────────────────────────
  Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    try {
      _isLoading = true;

      // Check DB status BEFORE attempting auth, so pending/rejected users
      // never receive a valid session token.
      final existingUser = await _supabase
          .from('users')
          .select()
          .eq('email', email)
          .maybeSingle();

      if (existingUser == null) {
        return {
          'success': false,
          'message':
              'Incorrect email or password. Please enter appropriate details.',
        };
      }

      final status =
          existingUser['status'].toString().toLowerCase();

      if (status == 'pending') {
        return {
          'success': false,
          'message': 'Your account is still under review by the admin.',
        };
      }

      if (status == 'rejected') {
        return {
          'success': false,
          'message': 'Your account has been rejected by the admin.',
        };
      }

      if (status == 'banned') {
        return {
          'success': false,
          'message': 'Your account has been banned. Please contact the administrator for assistance.',
        };
      }

      // Only approved users continue to auth
      final response = await _supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );

      if (response.user == null) {
        return {
          'success': false,
          'message':
              'Incorrect email or password. Please enter appropriate details.',
        };
      }

      // BUG FIX: Call _loadUserProfile() so that NotificationService is
      // initialized for the email/password login path.  Previously this was
      // bypassed, meaning push notifications never registered for these users.
      await _loadUserProfile();

      return {'success': true, 'message': 'Login successful.'};
    } on AuthException {
      return {
        'success': false,
        'message':
            'Incorrect email or password. Please enter appropriate details.',
      };
    } catch (e) {
      return {'success': false, 'message': 'Something went wrong.'};
    } finally {
      _isLoading = false;
    }
  }

  // ── Change Password ───────────────────────────────────────────────────────
  // BUG FIX: Previously called updateUser() directly without verifying the
  // current password, allowing anyone with an open session to change the
  // password without knowing what it was.  Now re-authenticates first.
  Future<Map<String, dynamic>> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    try {
      final email = _supabase.auth.currentSession?.user.email;
      if (email == null) {
        return {'success': false, 'message': 'No active session found.'};
      }

      // Re-authenticate to confirm the caller knows the current password
      final reAuthResponse = await _supabase.auth.signInWithPassword(
        email: email,
        password: currentPassword,
      );

      if (reAuthResponse.user == null) {
        return {'success': false, 'message': 'Current password is incorrect.'};
      }

      // Verified — now update to the new password
      await _supabase.auth.updateUser(
        UserAttributes(password: newPassword),
      );

      return {'success': true};
    } on AuthException catch (e) {
      if (e.message.toLowerCase().contains('invalid login credentials') ||
          e.message.toLowerCase().contains('invalid credentials')) {
        return {'success': false, 'message': 'Current password is incorrect.'};
      }
      return {'success': false, 'message': e.message};
    } catch (e) {
      return {'success': false, 'message': 'Could not change password.'};
    }
  }

  // ── Password Reset Email ──────────────────────────────────────────────────
  Future<Map<String, dynamic>> sendPasswordResetEmail(String email) async {
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
      return {'success': false, 'message': e.message};
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
    try {
      await NotificationService().clearTokenOnLogout();
    } catch (e) {
      debugPrint('clearTokenOnLogout error (non-fatal): $e');
    }
    await _supabase.auth.signOut();
  }
}
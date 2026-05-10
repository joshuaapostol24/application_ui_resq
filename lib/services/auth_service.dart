import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

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
  bool get isLoggedIn => _supabase.auth.currentSession != null;
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

    // APPROVED USER
    _currentUser = UserModel.fromJson(data);

    _isGuest = false;

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

      // 1. Create auth account in Supabase
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
        return {'success': false, 'message': 'Sign up failed. Try again.'};
      }

      // 2. Insert profile into the profiles table
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

      //Sign out immediately
      await _supabase.auth.signOut();

      

      _currentUser = UserModel(
        id: response.user!.id,
        name: name,
        address: address,
        email: email,
        mobileNumber: mobileNumber,
        approvalStatus: 'pending',
      );

      return {
        'success': true,
        'message': 'Account created! Awaiting admin approval.'
      };
    } on AuthException catch (e) {
      return {'success': false, 'message': e.message};
    } catch (e) {
      return {'success': false, 'message': 'Something went wrong.'};
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
    notifyListeners();

    final response = await _supabase.auth.signInWithPassword(
      email: email,
      password: password,
    );

    final userId = response.user?.id;

    if (userId == null) {
      return {
        'success': false,
        'message': 'Login failed.',
      };
    }

    final profile = await _supabase
        .from('users')
        .select()
        .eq('id', userId)
        .single();

    // BLOCK PENDING USERS
    if (profile['status'] != 'approved') {

      // IMPORTANT:
      // clear local session WITHOUT triggering UI race
      _currentUser = null;

      await _supabase.auth.signOut();

      return {
        'success': false,
        'message':
            'Your account is still pending admin approval.',
      };
    }

    _currentUser = UserModel.fromJson(profile);

    return {'success': true};

  } on AuthException catch (e) {
    return {
      'success': false,
      'message': e.message,
    };

  } catch (e) {
    return {
      'success': false,
      'message': 'Something went wrong.',
    };

  } finally {
    _isLoading = false;
    notifyListeners();
  }
}

  // ── Email OTP — Step 1: Send OTP ─────────────────────────────────────────
Future<Map<String, dynamic>> sendEmailOtp({required String email}) async {
  try {
    _isLoading = true;
    notifyListeners();

    await _supabase.auth.signInWithOtp(
      email: email,
      shouldCreateUser: true,  // creates account if it doesn't exist yet
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

  // ── Guest ─────────────────────────────────────────────────────────────────
  void loginAsGuest() {
    _isGuest = true;
    _currentUser = null;
    notifyListeners();
  }

  // ── Logout ────────────────────────────────────────────────────────────────
  Future<void> logout() async {
    await _supabase.auth.signOut();
    // onAuthStateChange listener handles the rest
  }
}
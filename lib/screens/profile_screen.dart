import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import '../services/auth_service.dart';
import 'otp_screen.dart';
import 'report_history_screen.dart';
import '../services/storage_service.dart';
import 'dart:io';
import '../main.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: AuthService(),
      builder: (context, _) {
        final auth = AuthService();
        if (auth.isLoggedIn && auth.currentUser != null) {
          return _LoggedInProfile(user: auth.currentUser!);
        }

        if (auth.isLoading) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        return const _AuthGate();
      },
    );
  }
}

// ── AUTH GATE (not logged in) ─────────────────────────────────────────────────

class _AuthGate extends StatefulWidget {
  const _AuthGate();

  @override
  State<_AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<_AuthGate>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override 
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F0EB),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF5F0EB),
        elevation: 0,
        title: const Text('Profile',
            style:
                TextStyle(color: Colors.black87, fontWeight: FontWeight.w600)),
        centerTitle: true,
        bottom: TabBar(
          controller: _tabController,
          labelColor: const Color(0xFFF5A623),
          unselectedLabelColor: Colors.black45,
          indicatorColor: const Color(0xFFF5A623),
          tabs: const [
            Tab(text: 'Sign In'),
            Tab(text: 'Sign Up'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _LoginForm(onSwitchToSignUp: () => _tabController.animateTo(1)),
          _SignUpForm(onSwitchToLogin: () => _tabController.animateTo(0)),
        ],
      ),
    );
  }
}

// ── LOGIN FORM ────────────────────────────────────────────────────────────────

class _LoginForm extends StatefulWidget {
  final VoidCallback onSwitchToSignUp;
  const _LoginForm({required this.onSwitchToSignUp});

  @override
  State<_LoginForm> createState() => _LoginFormState();
}

class _LoginFormState extends State<_LoginForm> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _showForgotPasswordDialog() async {
  final emailController = TextEditingController();

  await showDialog(
  context: context,
  builder: (ctx) => AlertDialog(
  shape: RoundedRectangleBorder(
  borderRadius: BorderRadius.circular(16),
  ),
  title: const Text(
  'Reset Password',
  style: TextStyle(fontWeight: FontWeight.w700),
  ),
  content: Column(
  mainAxisSize: MainAxisSize.min,
  children: [
  const Text(
  'Enter your email address and we will send a password reset link.',
  style: TextStyle(
  color: Colors.black54,
  fontSize: 13,
  ),
  ),
  const SizedBox(height: 16),
  TextField(
  controller: emailController,
  keyboardType: TextInputType.emailAddress,
  decoration: InputDecoration(
  hintText: 'you@email.com',
  border: OutlineInputBorder(
  borderRadius: BorderRadius.circular(12),
  ),
  ),
  ),
  ],
  ),
  actions: [
  TextButton(
  onPressed: () => Navigator.pop(ctx),
  child: const Text(
  'Cancel',
  style: TextStyle(color: Colors.black45),
  ),
  ),
  TextButton(
  onPressed: () async {
  final result =
  await AuthService().sendPasswordResetEmail(
  emailController.text.trim(),
  );
        if (mounted) {
          Navigator.pop(ctx);

          scaffoldMessengerKey.currentState?.showSnackBar(
            SnackBar(
              content: Text(result['message']),
              backgroundColor: result['success']
                  ? const Color(0xFF4CAF50)
                  : Colors.red,
            ),
          );
        }
      },
      child: const Text(
        'Send',
        style: TextStyle(
          color: Color(0xFFF5A623),
          fontWeight: FontWeight.w600,
        ),
      ),
    ),
  ],
),
);
}




  void _handleLogin() async {

  if (!_formKey.currentState!.validate()) return;

  setState(() => _isLoading = true);

  final result = await AuthService().login(
    email: _emailController.text.trim(),
    password: _passwordController.text,
  );

  if (!mounted) return;

  setState(() => _isLoading = false);

  if (!result['success']) {

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Login Failed'),
        content: Text(result['message']),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}

  void _continueAsGuest() {
    AuthService().loginAsGuest();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 8),
            const Text('Welcome back',
                style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: Colors.black87)),
            const SizedBox(height: 4),
            const Text('Sign in to your ResQ account',
                style: TextStyle(fontSize: 14, color: Colors.black45)),
            const SizedBox(height: 28),

            // Email
            _FormLabel(label: 'Email Address'),
            const SizedBox(height: 6),
            _ResQTextField(
              controller: _emailController,
              hint: 'you@email.com',
              keyboardType: TextInputType.emailAddress,
              validator: (v) {
                if (v == null || v.isEmpty) return 'Email is required';
                if (!RegExp(r'^[\w-.]+@([\w-]+\.)+[\w-]{2,}$')
                    .hasMatch(v.trim())) {
                  return 'Enter a valid email';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Password
            _FormLabel(label: 'Password'),
            const SizedBox(height: 6),
            _ResQTextField(
              controller: _passwordController,
              hint: '••••••••',
              obscureText: _obscurePassword,
              suffixIcon: IconButton(
                icon: Icon(
                  _obscurePassword
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined,
                  color: Colors.black38,
                  size: 20,
                ),
                onPressed: () =>
                    setState(() => _obscurePassword = !_obscurePassword),
              ),
              validator: (v) {
                if (v == null || v.isEmpty) return 'Password is required';
                if (v.length < 6) return 'Minimum 6 characters';
                return null;
              },
            ),
            Align(
            alignment: Alignment.centerRight,
            child: TextButton(
            onPressed: _showForgotPasswordDialog,
            child: const Text(
            'Forgot Password?',
            style: TextStyle(
            color: Color(0xFFF5A623),
            fontWeight: FontWeight.w600,
            ),
            ),
            ),
            ),

            const SizedBox(height: 28),

            // Sign in button
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFF5A623),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                ),
                onPressed: _isLoading ? null : _handleLogin,
                child: _isLoading
                  ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2.5,
                    ),
                  )
                : const Text('Sign In',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 15)),
              ),
            ),
            const SizedBox(height: 16),

            // Divider
            Row(children: [
              const Expanded(child: Divider()),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Text('or',
                    style:
                        TextStyle(color: Colors.black38, fontSize: 13)),
              ),
              const Expanded(child: Divider()),
            ]),
            const SizedBox(height: 16),

            // Continue as guest
            SizedBox(
              width: double.infinity,
              height: 50,
              child: OutlinedButton(
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Color(0xFFE8E0D8)),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: _continueAsGuest,
                child: const Text('Continue as Guest',
                    style: TextStyle(
                        color: Colors.black54,
                        fontWeight: FontWeight.w500,
                        fontSize: 15)),
              ),
            ),
            const SizedBox(height: 24),

            // Switch to sign up
            Center(
              child: GestureDetector(
                onTap: () async {
                  // Ask for email address instead of phone number
                  final emailController = TextEditingController();
                  final confirmed = await showDialog<bool>(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                      title: const Text('Login with Email OTP',
                        style: TextStyle(fontWeight: FontWeight.w700)),
                      content: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Enter your email and we\'ll send you a 6-digit code.',
                            style: TextStyle(
                              fontSize: 13, color: Colors.black45),
                          ),
                          const SizedBox(height: 12),
                          TextField(
                            controller: emailController,
                            keyboardType: TextInputType.emailAddress,
                            decoration: InputDecoration(
                              hintText: 'you@email.com',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide:
                                  const BorderSide(color: Color(0xFFE8E0D8)),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: const BorderSide(
                                  color: Color(0xFFF5A623), width: 1.5),
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 12),
                            ),
                          ),
                        ],
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(ctx, false),
                          child: const Text('Cancel',
                            style: TextStyle(color: Colors.black45)),
                        ),
                        TextButton(
                          onPressed: () => Navigator.pop(ctx, true),
                          child: const Text('Send OTP',
                            style: TextStyle(
                              color: Color(0xFFF5A623),
                              fontWeight: FontWeight.w600)),
                        ),
                      ],
                    ),
                  );

                  if (confirmed == true && emailController.text.isNotEmpty) {
                    final result = await AuthService()
                      .sendEmailOtp(email: emailController.text.trim());
                    if (result['success'] && context.mounted) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                            OtpScreen(email: emailController.text.trim()),
                        ),
                      );
                    } else if (context.mounted) {
                      scaffoldMessengerKey.currentState?.showSnackBar(
                        SnackBar(
                          content: Text(result['message']),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  }
                },
                child: const Text(
                  'Login with Email OTP instead',   // updated label
                  style: TextStyle(
                    color: Color(0xFFF5A623),
                    fontWeight: FontWeight.w500,
                    fontSize: 13),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── SIGN UP FORM ──────────────────────────────────────────────────────────────

class _SignUpForm extends StatefulWidget {
  final VoidCallback onSwitchToLogin;
  const _SignUpForm({required this.onSwitchToLogin});

  @override
  State<_SignUpForm> createState() => _SignUpFormState();
}

class _SignUpFormState extends State<_SignUpForm> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _addressController = TextEditingController();
  final _emailController = TextEditingController();
  final _mobileController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirm = true;
  bool _isLoading = false;

  final _idNumberController = TextEditingController();
  String? _successMessage;
  String _selectedIdType = 'National ID';

  final List<String> _idTypes = [
    'National ID',
    'Driver License',
    'Passport',
    'UMID',
    'SSS ID',
    'PhilHealth ID',
    'Postal ID',
    'Student ID',
    'Barangay ID',
  ];

  File? _selectedIdImage;

  final ImagePicker _picker = ImagePicker();

  Future<void> _pickIdImage() async {
  final XFile? image = await _picker.pickImage(
    source: ImageSource.gallery,
    imageQuality: 70,
  );

  if (image != null) {
    setState(() {
      _selectedIdImage = File(image.path);
    });
  }
}

  @override
  void dispose() {
    _nameController.dispose();
    _addressController.dispose();
    _emailController.dispose();
    _mobileController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _idNumberController.dispose();
    super.dispose();
  }

  String? idImageUrl;

  void _handleSignUp() async {

  try {

    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_selectedIdImage == null) {

      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Valid ID Required'),
          content: const Text(
            'Please upload a valid ID image.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('OK'),
            ),
          ],
        ),
      );

      return;
    }

    setState(() => _isLoading = true);

    final result = await AuthService().signUp(
      name: _nameController.text.trim(),
      address: _addressController.text.trim(),
      email: _emailController.text.trim(),
      mobileNumber: _mobileController.text.trim(),
      idType: _selectedIdType,
      idNumber: _idNumberController.text.trim(),
      idImageUrl: null,
      password: _passwordController.text,
    );

    // ALWAYS stop loading first
    if (mounted) {
      setState(() => _isLoading = false);
    }

    // ───────────────── SUCCESS ─────────────────
    if (result['success']) {

      final userId =
          Supabase.instance.client.auth.currentUser?.id;

      String? uploadedImageUrl;

      if (_selectedIdImage != null) {
        uploadedImageUrl =
            await StorageService.uploadIdImage(
          _selectedIdImage!,
        );
      }

      if (userId != null &&
          uploadedImageUrl != null) {

        await Supabase.instance.client
            .from('users')
            .update({
              'id_image_url': uploadedImageUrl,
            })
            .eq('id', userId);
      }


      
 
      await Supabase.instance.client.auth.signOut();

      

      // SHOW SUCCESS MESSAGE
      scaffoldMessengerKey.currentState?.showSnackBar(
        const SnackBar(
          content: Text(
            'Your account has been created successfully and is now under review by the admin.',
          ),
          backgroundColor: Color(0xFF4CAF50),
          duration: Duration(seconds: 4),
        ),
      );

      return;
    }

    // ───────────────── FAILURE ─────────────────
    scaffoldMessengerKey.currentState?.showSnackBar(
      SnackBar(
        content: Text(result['message']),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 4),
      ),
    );

  } catch (e) {

    debugPrint('SIGNUP ERROR: $e');

    if (mounted) {
      setState(() => _isLoading = false);
    }

    scaffoldMessengerKey.currentState?.showSnackBar(
      SnackBar(
        content: Text(e.toString()),
        backgroundColor: Colors.red,
      ),
    );
  }
}

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 8),
            const Text('Create an account',
                style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: Colors.black87)),
            const SizedBox(height: 4),
            const Text('Join ResQ to report incidents in your area',
                style: TextStyle(fontSize: 14, color: Colors.black45)),
            const SizedBox(height: 28),

            // Full name
            _FormLabel(label: 'Full Name'),
            const SizedBox(height: 6),
            _ResQTextField(
              controller: _nameController,
              hint: 'Juan dela Cruz',
              keyboardType: TextInputType.name,
              validator: (v) {
                if (v == null || v.trim().isEmpty) return 'Full name is required';
                if (v.trim().length < 3) return 'Enter your full name';
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Address
            _FormLabel(label: 'Home Address'),
            const SizedBox(height: 6),
            _ResQTextField(
              controller: _addressController,
              hint: 'Barangay, Municipality, Province',
              keyboardType: TextInputType.streetAddress,
              validator: (v) {
                if (v == null || v.trim().isEmpty) return 'Address is required';
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Email
            _FormLabel(label: 'Email Address'),
            const SizedBox(height: 6),
            _ResQTextField(
              controller: _emailController,
              hint: 'you@email.com',
              keyboardType: TextInputType.emailAddress,
              validator: (v) {
                if (v == null || v.isEmpty) return 'Email is required';
                if (!RegExp(r'^[\w-.]+@([\w-]+\.)+[\w-]{2,}$')
                    .hasMatch(v.trim())) {
                  return 'Enter a valid email address';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Mobile number
            _FormLabel(label: 'Mobile Number'),
            const SizedBox(height: 6),
            _ResQTextField(
              controller: _mobileController,
              hint: '09XX XXX XXXX',
              keyboardType: TextInputType.phone,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(11),
              ],
              validator: (v) {
                if (v == null || v.isEmpty) return 'Mobile number is required';
                // Philippine mobile: starts with 09, exactly 11 digits
                if (!RegExp(r'^09\d{9}$').hasMatch(v.trim())) {
                  return 'Enter a valid PH mobile number (09XX XXX XXXX)';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            // ID Type
            _FormLabel(label: 'Valid ID Type'),
            const SizedBox(height: 6),

            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: const Color(0xFFE8E0D8),
                ),
              ),

              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _selectedIdType,
                  isExpanded: true,

                  items: _idTypes.map((type) {
                    return DropdownMenuItem(
                      value: type,
                      child: Text(type),
                    );
                  }).toList(),

                  onChanged: (value) {
                    if (value != null) {
                      setState(() {
                        _selectedIdType = value;
                      });
                    }
                  },
                ),
              ),
            ),

            const SizedBox(height: 16),

            // ID Number
            _FormLabel(label: 'ID Number'),
            const SizedBox(height: 6),

            _ResQTextField(
              controller: _idNumberController,
              hint: 'Enter ID number',

              validator: (v) {
                if (v == null || v.trim().isEmpty) {
                  return 'ID number is required';
                }

                return null;
              },
            ),

            const SizedBox(height: 16),

          // Upload ID
          _FormLabel(label: 'Upload Valid ID'),
          const SizedBox(height: 6),

          GestureDetector(
            onTap: _pickIdImage,

            child: Container(
              height: 140,
              width: double.infinity,

              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: const Color(0xFFE8E0D8),
                ),
              ),

              child: _selectedIdImage != null
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(12),

                    child: Image.file(
                      _selectedIdImage!,
                      fit: BoxFit.cover,
                    ),
                  )

                : const Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.upload_file_outlined,
                      size: 34,
                      color: Color(0xFFF5A623),
                    ),

                    SizedBox(height: 8),

                    Text(
                      'Tap to upload ID',
                      style: TextStyle(
                        color: Colors.black45,
                      ),
                    ),
                  ],
                ),
            ),
          ),

          const SizedBox(height: 16),

            // Password
            _FormLabel(label: 'Password'),
            const SizedBox(height: 6),
            _ResQTextField(
              controller: _passwordController,
              hint: 'Minimum 6 characters',
              obscureText: _obscurePassword,
              suffixIcon: IconButton(
                icon: Icon(
                  _obscurePassword
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined,
                  color: Colors.black38,
                  size: 20,
                ),
                onPressed: () =>
                    setState(() => _obscurePassword = !_obscurePassword),
              ),
              validator: (v) {
                if (v == null || v.isEmpty) return 'Password is required';
                if (v.length < 6) return 'Minimum 6 characters';
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Confirm password
            _FormLabel(label: 'Confirm Password'),
            const SizedBox(height: 6),
            _ResQTextField(
              controller: _confirmPasswordController,
              hint: 'Re-enter your password',
              obscureText: _obscureConfirm,
              suffixIcon: IconButton(
                icon: Icon(
                  _obscureConfirm
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined,
                  color: Colors.black38,
                  size: 20,
                ),
                onPressed: () =>
                    setState(() => _obscureConfirm = !_obscureConfirm),
              ),
              validator: (v) {
                if (v == null || v.isEmpty) return 'Please confirm your password';
                if (v != _passwordController.text) {
                  return 'Passwords do not match';
                }
                return null;
              },
            ),
            const SizedBox(height: 28),

            // Sign up button
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFF5A623),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                ),
                onPressed: _isLoading ? null : _handleSignUp,
                child: _isLoading
                  ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2.5,
                    ),
                  )
                  : const Text('Create Account',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 15)),
                ),
            ),
            const SizedBox(height: 24),

            // Switch to login
            Center(
              child: GestureDetector(
                onTap: widget.onSwitchToLogin,
                child: RichText(
                  text: const TextSpan(
                    text: 'Already have an account? ',
                    style: TextStyle(color: Colors.black45, fontSize: 13),
                    children: [
                      TextSpan(
                        text: 'Sign In',
                        style: TextStyle(
                            color: Color(0xFFF5A623),
                            fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}

// ── LOGGED IN PROFILE ─────────────────────────────────────────────────────────

class _LoggedInProfile extends StatelessWidget {
  final UserModel user;
  const _LoggedInProfile({required this.user});

  void _handleLogout(BuildContext context) {
  showDialog(
    context: context,
    builder: (ctx) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: const Text('Log Out',
          style: TextStyle(fontWeight: FontWeight.w700)),
      content: const Text('Are you sure you want to log out?'),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx),
          child: const Text('Cancel',
              style: TextStyle(color: Colors.black45)),
        ),
        TextButton(
          onPressed: () async {
            Navigator.pop(ctx);
            await AuthService().logout();   // now async
          },
          child: const Text('Log Out',
              style: TextStyle(
                  color: Color(0xFFF5A623),
                  fontWeight: FontWeight.w600)),
        ),
      ],
    ),
  );
}

  void _handleChangePassword(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const _ChangePasswordSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F0EB),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF5F0EB),
        elevation: 0,
        title: const Text('Profile',
            style:
                TextStyle(color: Colors.black87, fontWeight: FontWeight.w600)),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const SizedBox(height: 16),

            // ── Avatar & info ──
            CircleAvatar(
              radius: 48,
              backgroundColor: const Color(0xFFF5A623).withOpacity(0.15),
              child: Text(
                user.name.isNotEmpty
                    ? user.name.trim().split(' ').map((e) => e[0]).take(2).join()
                    : '?',
                style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFFF5A623)),
              ),
            ),
            const SizedBox(height: 12),
            Text(user.name,
                style: const TextStyle(
                    fontSize: 18, fontWeight: FontWeight.w700)),
            const SizedBox(height: 2),
            Text(user.email,
                style:
                    const TextStyle(color: Colors.black45, fontSize: 13)),
            const SizedBox(height: 4),
            Text(user.mobileNumber,
                style:
                    const TextStyle(color: Colors.black45, fontSize: 13)),
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.location_on_outlined,
                    size: 14, color: Colors.black38),
                const SizedBox(width: 4),
                Text(user.address,
                    style: const TextStyle(
                        color: Colors.black38, fontSize: 12)),
              ],
            ),

            const SizedBox(height: 24),

            // ── Menu items ──
            _ProfileMenuItem(   
              icon: Icons.history_outlined,
              label: 'Report History',
              onTap: () { 
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const ReportHistoryScreen()
                  ),
                );  
              },
            ),
            _ProfileMenuItem(
              icon: Icons.lock_outline,
              label: 'Change Password',
              onTap: () => _handleChangePassword(context),
            ),
            const SizedBox(height: 8),
            _ProfileMenuItem(
              icon: Icons.logout,
              label: 'Logout',
              labelColor: Colors.red,
              iconColor: Colors.red,
              onTap: () => _handleLogout(context),
            ),

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

// ── CHANGE PASSWORD BOTTOM SHEET ──────────────────────────────────────────────

class _ChangePasswordSheet extends StatefulWidget {
  const _ChangePasswordSheet();

  @override
  State<_ChangePasswordSheet> createState() => _ChangePasswordSheetState();
}

class _ChangePasswordSheetState extends State<_ChangePasswordSheet> {
  final _formKey = GlobalKey<FormState>();
  final _currentController = TextEditingController();
  final _newController = TextEditingController();
  final _confirmController = TextEditingController();
  bool _obscureCurrent = true;
  bool _obscureNew = true;
  bool _obscureConfirm = true;

  @override
  void dispose() {
    _currentController.dispose();
    _newController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  // Inside _ChangePasswordSheetState, replace _handleSave with:
  void _handleSave() async {
    if (!_formKey.currentState!.validate()) return;

    final result = await AuthService().changePassword(
      newPassword: _newController.text,
    );

    if (mounted) {
      Navigator.pop(context);
      scaffoldMessengerKey.currentState?.showSnackBar(
        SnackBar(
          content: Text(result['success']
            ? 'Password changed successfully'
            : result['message']),
          backgroundColor: result['success']
            ? const Color(0xFF4CAF50)
            : Colors.red,
        ),
      );
    }
}

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.black12,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              const Text('Change Password',
                  style: TextStyle(
                      fontSize: 18, fontWeight: FontWeight.w700)),
              const SizedBox(height: 20),

              _FormLabel(label: 'Current Password'),
              const SizedBox(height: 6),
              _ResQTextField(
                controller: _currentController,
                hint: '••••••••',
                obscureText: _obscureCurrent,
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscureCurrent
                        ? Icons.visibility_off_outlined
                        : Icons.visibility_outlined,
                    color: Colors.black38,
                    size: 20,
                  ),
                  onPressed: () =>
                      setState(() => _obscureCurrent = !_obscureCurrent),
                ),
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Enter current password';
                  return null;
                },
              ),
              const SizedBox(height: 14),

              _FormLabel(label: 'New Password'),
              const SizedBox(height: 6),
              _ResQTextField(
                controller: _newController,
                hint: 'Minimum 6 characters',
                obscureText: _obscureNew,
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscureNew
                        ? Icons.visibility_off_outlined
                        : Icons.visibility_outlined,
                    color: Colors.black38,
                    size: 20,
                  ),
                  onPressed: () =>
                      setState(() => _obscureNew = !_obscureNew),
                ),
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Enter new password';
                  if (v.length < 6) return 'Minimum 6 characters';
                  if (v == _currentController.text) {
                    return 'New password must differ from current';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 14),

              _FormLabel(label: 'Confirm New Password'),
              const SizedBox(height: 6),
              _ResQTextField(
                controller: _confirmController,
                hint: 'Re-enter new password',
                obscureText: _obscureConfirm,
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscureConfirm
                        ? Icons.visibility_off_outlined
                        : Icons.visibility_outlined,
                    color: Colors.black38,
                    size: 20,
                  ),
                  onPressed: () =>
                      setState(() => _obscureConfirm = !_obscureConfirm),
                ),
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Please confirm password';
                  if (v != _newController.text) return 'Passwords do not match';
                  return null;
                },
              ),
              const SizedBox(height: 24),

              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFF5A623),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    elevation: 0,
                  ),
                  onPressed: _handleSave,
                  child: const Text('Save Password',
                      style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 15)),
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }
}

// ── SHARED WIDGETS ────────────────────────────────────────────────────────────

class _ProfileMenuItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color? iconColor;
  final Color? labelColor;

  const _ProfileMenuItem({
    required this.icon,
    required this.label,
    required this.onTap,
    this.iconColor,
    this.labelColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE8E0D8)),
      ),
      child: ListTile(
        leading: Icon(icon, color: iconColor ?? const Color(0xFFF5A623)),
        title: Text(label,
            style: TextStyle(
                fontWeight: FontWeight.w500,
                color: labelColor ?? Colors.black87)),
        trailing:
            const Icon(Icons.chevron_right, color: Colors.black38),
        onTap: onTap,
      ),
    );
  }
}

class _FormLabel extends StatelessWidget {
  final String label;
  const _FormLabel({required this.label});

  @override
  Widget build(BuildContext context) {
    return Text(label,
        style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: Colors.black87));
  }
}

class _ResQTextField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final bool obscureText;
  final TextInputType? keyboardType;
  final Widget? suffixIcon;
  final String? Function(String?)? validator;
  final List<TextInputFormatter>? inputFormatters;

  const _ResQTextField({
    required this.controller,
    required this.hint,
    this.obscureText = false,
    this.keyboardType,
    this.suffixIcon,
    this.validator,
    this.inputFormatters,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      validator: validator,
      style: const TextStyle(fontSize: 14, color: Colors.black87),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Colors.black38, fontSize: 14),
        suffixIcon: suffixIcon,
        filled: true,
        fillColor: Colors.white,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFE8E0D8)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFE8E0D8)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide:
              const BorderSide(color: Color(0xFFF5A623), width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.red),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.red, width: 1.5),
        ),
      ),
    );
  }
}
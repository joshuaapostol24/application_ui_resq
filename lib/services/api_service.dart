import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  // Change this to your co-worker's machine IP when testing on a
  // real device. Use 10.0.2.2 for Android emulator, localhost for iOS sim.
  static const String _baseUrl = 'http://10.0.2.2:8000';

  static Future<Map<String, dynamic>> signUp({
    required String name,
    required String address,
    required String email,
    required String mobileNumber,
    required String password,
  }) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/auth/signup'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'name': name,
        'address': address,
        'email': email,
        'mobile_number': mobileNumber,
        'password': password,
      }),
    );

    final data = jsonDecode(response.body);

    if (response.statusCode == 200) {
      return {'success': true, 'data': data};
    } else {
      return {
        'success': false,
        'message': data['detail'] ?? 'Sign up failed'
      };
    }
  }

  static Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/auth/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'email': email,
        'password': password,
      }),
    );

    final data = jsonDecode(response.body);

    if (response.statusCode == 200) {
      return {'success': true, 'data': data};
    } else {
      return {
        'success': false,
        'message': data['detail'] ?? 'Login failed'
      };
    }
  }
}
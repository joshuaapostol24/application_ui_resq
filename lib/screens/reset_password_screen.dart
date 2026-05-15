import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ResetPasswordScreen extends StatefulWidget {
  const ResetPasswordScreen({super.key});

  @override
  State<ResetPasswordScreen> createState() =>
      _ResetPasswordScreenState();
}

class _ResetPasswordScreenState
    extends State<ResetPasswordScreen> {

  final _passwordController = TextEditingController();

  Future<void> _updatePassword() async {

    try {

      await Supabase.instance.client.auth.updateUser(
        UserAttributes(
          password: _passwordController.text,
        ),
      );

      if (mounted) {

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Password updated successfully'),
          ),
        );

        Navigator.pop(context);
      }

    } catch (e) {

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString()),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      appBar: AppBar(
        title: const Text('Reset Password'),
      ),

      body: Padding(
        padding: const EdgeInsets.all(20),

        child: Column(
          children: [

            TextField(
              controller: _passwordController,
              obscureText: true,

              decoration: const InputDecoration(
                hintText: 'Enter new password',
              ),
            ),

            const SizedBox(height: 20),

            ElevatedButton(
              onPressed: _updatePassword,
              child: const Text('Update Password'),
            ),
          ],
        ),
      ),
    );
  }
}
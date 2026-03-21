import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:senior_fall_detection/constants.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPassword = TextEditingController();
  bool _isloading = false;
  String? _error;

  Future<void> _submit() async {
    if (_formKey.currentState?.validate() ?? false) {
      setState(() {
        _isloading = true;
        _error = null;
      });

      try {
        final credential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
        );

        final user = credential.user;
        if (user != null && _nameController.text.trim().isNotEmpty) {
          await FirebaseFirestore.instance.collection("Users").doc(user.uid).set({
            "name": _nameController.text.trim(),
            "email": _emailController.text.trim(),
            "createdAt": FieldValue.serverTimestamp(),
            "totalAlerts": 0,
            "alertsToday": 0,
            "profileImageUrl":
                "https://images.rawpixel.com/image_png_800/czNmcy1wcml2YXRl"
                "L3Jhd3BpeGVsX2ltYWdlcy93ZWJzaXRlX2NvbnRlbnQvbHIvdjkzNy1hZXctMTY1LnBuZw.png",
          });
        }
        if (!mounted) return;
        Navigator.pushReplacementNamed(context, "/personal_info");
      } catch (e) {
        setState(() {
          _error = "Sign up failed. Please try again.";
        });
      } finally {
        if (mounted) setState(() => _isloading = false);
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPassword.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: surface_color,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: text_primary,
        title: const Text("Create account"),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 8),
                Text(
                  "Name",
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: text_secondary,
                  ),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _nameController,
                  textCapitalization: TextCapitalization.words,
                  decoration: const InputDecoration(
                    hintText: "Your name",
                    prefixIcon: Icon(Icons.person_outline, size: 22),
                  ),
                  validator: (value) =>
                      value == null || value.isEmpty ? 'Enter your name' : null,
                ),
                const SizedBox(height: 16),
                Text(
                  "Email",
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: text_secondary,
                  ),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                    hintText: "you@example.com",
                    prefixIcon: Icon(Icons.email_outlined, size: 22),
                  ),
                  validator: (value) =>
                      value == null || !value.contains("@") ? 'Enter a valid email' : null,
                ),
                const SizedBox(height: 16),
                Text(
                  "Password",
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: text_secondary,
                  ),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _passwordController,
                  obscureText: true,
                  decoration: const InputDecoration(
                    hintText: "At least 5 characters",
                    prefixIcon: Icon(Icons.lock_outline, size: 22),
                  ),
                  validator: (value) =>
                      value == null || value.length < 5 ? 'Use at least 5 characters' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _confirmPassword,
                  obscureText: true,
                  decoration: const InputDecoration(
                    hintText: "Confirm password",
                    prefixIcon: Icon(Icons.lock_outline, size: 22),
                  ),
                  validator: (value) =>
                      value == null || value != _passwordController.text ? 'Passwords do not match' : null,
                ),
                if (_error != null) ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: error_color.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(input_radius),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.error_outline, color: error_color, size: 20),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            _error!,
                            style: TextStyle(color: error_color, fontSize: 14),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 28),
                SizedBox(
                  height: 52,
                  child: ElevatedButton(
                    onPressed: _isloading ? null : _submit,
                    child: _isloading
                        ? const SizedBox(
                            height: 24,
                            width: 24,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : const Text("Sign up"),
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      "Already have an account? ",
                      style: TextStyle(color: text_secondary, fontSize: 15),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pushReplacementNamed(context, '/login'),
                      style: TextButton.styleFrom(
                        foregroundColor: primary_color,
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                      ),
                      child: const Text("Log in"),
                    ),
                  ],
                ),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

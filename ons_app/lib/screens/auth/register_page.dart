// lib/screens/auth/register_page.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:ons_app/core/theme/app_theme.dart';
import 'package:ons_app/models/user.dart';
import 'package:ons_app/services/auth_service.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _formKey = GlobalKey<FormState>();

  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();

  UserRole _selectedRole = UserRole.family;
  bool _isSubmitting = false;
  String? _error;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
    _passwordCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    if (_passwordCtrl.text != _confirmCtrl.text) {
      setState(() => _error = "Passwords do not match");
      return;
    }

    setState(() {
      _isSubmitting = true;
      _error = null;
    });

    final auth = AuthService();
    final success = await auth.register(
      name: _nameCtrl.text.trim(),
      email: _emailCtrl.text.trim(),
      password: _passwordCtrl.text,
      telephone: _phoneCtrl.text.trim(),
      role: _selectedRole,
    );

    setState(() {
      _isSubmitting = false;
    });

    if (!success) {
      setState(() {
        _error = "Registration failed. Please try again.";
      });
      return;
    }

    if (!mounted) return;

    // On success: go back to login
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Account created. You can now log in.")),
    );
    Navigator.of(context).pop(); // back to LoginPage
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: AppTheme.cream,
      appBar: AppBar(
        backgroundColor: AppTheme.cream,
        elevation: 0,
        title: Text(
          "Create Ons Account",
          style: GoogleFonts.playfairDisplay(
            color: AppTheme.deepNavy,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 500),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    "Welcome to Ons",
                    style: GoogleFonts.playfairDisplay(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.deepNavy,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "Create an account and choose your role.",
                    style: GoogleFonts.playfairDisplay(
                      fontSize: 14,
                      color: colors.onSurface.withOpacity(0.7),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Name
                  TextFormField(
                    controller: _nameCtrl,
                    decoration: const InputDecoration(
                      labelText: "Full Name",
                    ),
                    validator: (v) =>
                        v == null || v.trim().isEmpty ? "Required" : null,
                  ),
                  const SizedBox(height: 16),

                  // Email
                  TextFormField(
                    controller: _emailCtrl,
                    decoration: const InputDecoration(
                      labelText: "Email",
                    ),
                    validator: (v) =>
                        v == null || !v.contains("@") ? "Enter a valid email" : null,
                  ),
                  const SizedBox(height: 16),

                  // Phone
                  TextFormField(
                    controller: _phoneCtrl,
                    decoration: const InputDecoration(
                      labelText: "Phone number",
                    ),
                    validator: (v) =>
                        v == null || v.trim().isEmpty ? "Required" : null,
                  ),
                  const SizedBox(height: 16),

                  // Password
                  TextFormField(
                    controller: _passwordCtrl,
                    obscureText: true,
                    decoration: const InputDecoration(
                      labelText: "Password",
                    ),
                    validator: (v) =>
                        v == null || v.length < 6 ? "Min 6 characters" : null,
                  ),
                  const SizedBox(height: 16),

                  // Confirm password
                  TextFormField(
                    controller: _confirmCtrl,
                    obscureText: true,
                    decoration: const InputDecoration(
                      labelText: "Confirm Password",
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Role dropdown
                  DropdownButtonFormField<UserRole>(
                    value: _selectedRole,
                    decoration: const InputDecoration(
                      labelText: "Role",
                    ),
                    items: const [
                      DropdownMenuItem(
                        value: UserRole.family,
                        child: Text("Family Member"),
                      ),
                      DropdownMenuItem(
                        value: UserRole.caregiver,
                        child: Text("Caregiver"),
                      ),
                      DropdownMenuItem(
                        value: UserRole.retirementHome,
                        child: Text("Retirement Home Admin"),
                      ),
                    ],
                    onChanged: (value) {
                      if (value != null) {
                        setState(() => _selectedRole = value);
                      }
                    },
                  ),
                  const SizedBox(height: 24),

                  if (_error != null) ...[
                    Text(
                      _error!,
                      style: const TextStyle(color: Colors.red),
                    ),
                    const SizedBox(height: 12),
                  ],

                  FilledButton(
                    onPressed: _isSubmitting ? null : _submit,
                    child: _isSubmitting
                        ? const SizedBox(
                            height: 18,
                            width: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text("Sign Up"),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

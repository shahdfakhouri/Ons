// lib/screens/auth/login_page.dart
import 'package:flutter/material.dart';
import 'package:ons_app/core/theme/app_theme.dart';
import 'package:ons_app/models/user.dart';
import 'package:ons_app/screens/auth/register_page.dart';
import 'package:ons_app/screens/auth/role_navigator.dart';
import 'package:ons_app/services/auth_service.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();

  final _formKey = GlobalKey<FormState>();
  bool _isSubmitting = false;
  String? _error;

  UserRole _selectedRole = UserRole.admin;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  String _roleLabel(UserRole r) {
    switch (r) {
      case UserRole.admin: return 'Admin';
      case UserRole.retirementHome: return 'Retirement Home';
      case UserRole.caregiver: return 'Caregiver';
      case UserRole.family: return 'Family';
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSubmitting = true;
      _error = null;
    });

    final email = _emailCtrl.text.trim();
    final password = _passwordCtrl.text;

    final User? user = await AuthService().login(
      email: email,
      password: password,
      role: _selectedRole,
    );

    setState(() {
      _isSubmitting = false;
    });

    if (user == null) {
      setState(() {
        _error = "Invalid email, password, or role.";
      });
      return;
    }

    if (!mounted) return;
    navigateToRoleHome(context, user);
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: AppTheme.cream,
      // Use a Stack to overlay the back button on top of the centered card
      body: Stack(
        children: [
          // --- GO BACK BUTTON ---
          Positioned(
            top: 40, // Adjust height based on status bar
            left: 20,
            child: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new),
              color: AppTheme.deepNavy,
              onPressed: () {
                // Returns to the previous screen (HomePage)
                Navigator.of(context).pop();
              },
              tooltip: 'Go back to Home',
            ),
          ),
          
          // --- LOGIN CARD ---
          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          "Welcome back to Ons",
                          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                color: AppTheme.deepNavy,
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          "Log in to access your dashboard",
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                        const SizedBox(height: 24),

                        DropdownButtonFormField<UserRole>(
                          value: _selectedRole,
                          decoration: const InputDecoration(
                            labelText: "Role",
                            prefixIcon: Icon(Icons.badge_outlined),
                          ),
                          items: const [
                            DropdownMenuItem(value: UserRole.admin, child: Text("Admin")),
                            DropdownMenuItem(value: UserRole.retirementHome, child: Text("Retirement Home")),
                            DropdownMenuItem(value: UserRole.caregiver, child: Text("Caregiver")),
                            DropdownMenuItem(value: UserRole.family, child: Text("Family")),
                          ],
                          onChanged: _isSubmitting
                              ? null
                              : (v) {
                                  if (v == null) return;
                                  setState(() => _selectedRole = v);
                                },
                        ),
                        const SizedBox(height: 16),

                        TextFormField(
                          controller: _emailCtrl,
                          decoration: const InputDecoration(
                            labelText: "Email",
                            prefixIcon: Icon(Icons.email),
                          ),
                          keyboardType: TextInputType.emailAddress,
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) return "Please enter your email";
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),

                        TextFormField(
                          controller: _passwordCtrl,
                          decoration: const InputDecoration(
                            labelText: "Password",
                            prefixIcon: Icon(Icons.lock),
                          ),
                          obscureText: true,
                          validator: (value) {
                            if (value == null || value.isEmpty) return "Please enter your password";
                            if (value.length < 5) return "Password must be at least 5 characters";
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),

                        if (_error != null)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 8.0),
                            child: Text(
                              _error!,
                              style: TextStyle(color: colors.error, fontSize: 13),
                            ),
                          ),

                        const SizedBox(height: 8),

                        SizedBox(
                          width: double.infinity,
                          child: FilledButton(
                            onPressed: _isSubmitting ? null : _submit,
                            child: _isSubmitting
                                ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(strokeWidth: 2),
                                  )
                                : Text("Login as ${_roleLabel(_selectedRole)}"),
                          ),
                        ),

                        const SizedBox(height: 12),

                        TextButton(
                          onPressed: _isSubmitting
                              ? null
                              : () {
                                  Navigator.of(context).push(
                                    MaterialPageRoute(builder: (_) => const RegisterPage()),
                                  );
                                },
                          child: const Text("Don't have an account? Sign up"),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme.dart';
import '../../providers/auth_provider.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _submitting = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _createAccount() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    if (_submitting) {
      return;
    }

    setState(() => _submitting = true);

    try {
      final provider = context.read<AuthProvider>();
      await provider.signUpWithEmailAndPassword(
        fullName: _nameController.text.trim(),
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );

      if (mounted) {
        if (provider.isAuthenticated) {
          // Unwind login + register back to the app shell.
          Navigator.of(context).popUntil((route) => route.isFirst);
        } else if (provider.state == AuthState.error) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(provider.lastError ?? 'Account creation failed.'),
              backgroundColor: AppColors.error,
            ),
          );
        }
      }
    } on AuthException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.message),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _submitting = false);
      }
    }
  }

  void _goBackToLogin() {
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new),
          onPressed: _submitting ? null : _goBackToLogin,
        ),
        title: const Text('Create Account'),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(height: 8),
                  appLogoPage(),
                  const SizedBox(height: 24),
                  Text(
                    'Fill in your details to start',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppColors.textPrimary.withValues(alpha: 0.6),
                        ),
                  ),
                  const SizedBox(height: 28),
                  _NameField(
                    controller: _nameController,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Enter your full name';
                      }
                      if (value.trim().length < 2) {
                        return 'Name is too short';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 18),
                  _EmailField(
                    controller: _emailController,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Enter your email address';
                      }
                      if (!value.contains('@')) {
                        return 'Enter a valid email address';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 18),
                  _PasswordField(
                    controller: _passwordController,
                    obscureText: _obscurePassword,
                    enableRightOverlay: true,
                    rightOverlay: IconButton(
                      icon: Icon(
                        _obscurePassword
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                        size: 22,
                      ),
                      onPressed: () {
                        setState(() => _obscurePassword = !_obscurePassword);
                      },
                    ),
                    textInputAction: TextInputAction.done,
                    onSubmitted: (_) => _createAccount(),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Enter your password';
                      }
                      if (value.length < 6) {
                        return 'Password must be at least 6 characters';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 30),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: _submitting ? null : _createAccount,
                      icon: _submitting
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: AppColors.white,
                              ),
                            )
                          : const Icon(Icons.arrow_forward, size: 20),
                      label: Text(_submitting ? 'Creating account...' : 'CREATE MY ACCOUNT'),
                    ),
                  ),
                  const SizedBox(height: 18),
                  TextButton(
                    onPressed: _submitting ? null : _goBackToLogin,
                    child: const Text('Already have an account? Sign In'),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _NameField extends StatefulWidget {
  final TextEditingController controller;
  final FormFieldValidator<String>? validator;

  const _NameField({
    required this.controller,
    this.validator,
  });

  @override
  State<_NameField> createState() => _NameFieldState();
}

class _NameFieldState extends State<_NameField> {
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Your Full Name',
          style: Theme.of(context).textTheme.titleSmall,
        ),
        const SizedBox(height: 6),
        ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 52),
          child: TextField(
            controller: widget.controller,
            textInputAction: TextInputAction.next,
            decoration: const InputDecoration(
              hintText: 'Enter your full name',
              filled: true,
              fillColor: AppColors.white,
              contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.all(Radius.circular(12)),
                borderSide: BorderSide(color: Color(0xFFD1D5DB)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.all(Radius.circular(12)),
                borderSide: BorderSide(color: Color(0xFFD1D5DB)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.all(Radius.circular(12)),
                borderSide: BorderSide(color: AppColors.primary, width: 2),
              ),
              errorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.all(Radius.circular(12)),
                borderSide: BorderSide(color: AppColors.error, width: 2),
              ),
            ),
            style: Theme.of(context).textTheme.bodyLarge,
          ),
        ),
      ],
    );
  }
}

class _EmailField extends StatefulWidget {
  final TextEditingController controller;
  final FormFieldValidator<String>? validator;

  const _EmailField({
    required this.controller,
    this.validator,
  });

  @override
  State<_EmailField> createState() => _EmailFieldState();
}

class _EmailFieldState extends State<_EmailField> {
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Your Email',
          style: Theme.of(context).textTheme.titleSmall,
        ),
        const SizedBox(height: 6),
        ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 52),
          child: TextField(
            controller: widget.controller,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.next,
            decoration: const InputDecoration(
              hintText: 'student@prepup.ai',
              filled: true,
              fillColor: AppColors.white,
              contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.all(Radius.circular(12)),
                borderSide: BorderSide(color: Color(0xFFD1D5DB)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.all(Radius.circular(12)),
                borderSide: BorderSide(color: Color(0xFFD1D5DB)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.all(Radius.circular(12)),
                borderSide: BorderSide(color: AppColors.primary, width: 2),
              ),
              errorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.all(Radius.circular(12)),
                borderSide: BorderSide(color: AppColors.error, width: 2),
              ),
            ),
            style: Theme.of(context).textTheme.bodyLarge,
          ),
        ),
      ],
    );
  }
}

class _PasswordField extends StatefulWidget {
  final TextEditingController controller;
  final bool obscureText;
  final bool enableRightOverlay;
  final Widget? rightOverlay;
  final TextInputAction? textInputAction;
  final ValueChanged<String>? onSubmitted;
  final FormFieldValidator<String>? validator;

  const _PasswordField({
    required this.controller,
    this.obscureText = false,
    this.enableRightOverlay = false,
    this.rightOverlay,
    this.textInputAction,
    this.onSubmitted,
    this.validator,
  });

  @override
  State<_PasswordField> createState() => _PasswordFieldState();
}

class _PasswordFieldState extends State<_PasswordField> {
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Your Password',
          style: Theme.of(context).textTheme.titleSmall,
        ),
        const SizedBox(height: 6),
        ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 52),
          child: TextField(
            controller: widget.controller,
            obscureText: widget.obscureText,
            textInputAction: widget.textInputAction,
            onSubmitted: widget.onSubmitted,
            decoration: InputDecoration(
              hintText: 'Enter your password',
              filled: true,
              fillColor: AppColors.white,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              suffixIcon: widget.enableRightOverlay
                  ? widget.rightOverlay
                  : null,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.all(Radius.circular(12)),
                borderSide: const BorderSide(color: Color(0xFFD1D5DB)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.all(Radius.circular(12)),
                borderSide: const BorderSide(color: Color(0xFFD1D5DB)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.all(Radius.circular(12)),
                borderSide: const BorderSide(color: AppColors.primary, width: 2),
              ),
              errorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.all(Radius.circular(12)),
                borderSide: const BorderSide(color: AppColors.error, width: 2),
              ),
            ),
            style: Theme.of(context).textTheme.bodyLarge,
          ),
        ),
      ],
    );
  }
}

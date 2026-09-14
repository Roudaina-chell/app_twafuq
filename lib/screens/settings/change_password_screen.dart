// screens/settings/change_password_screen.dart
//
// شاشة "كلمة المرور". تدعم حالتين:
// - الحساب عندو provider "password" → فورم تعديل عادي (كلمة مرور
//   حالية + جديدة + تأكيد) مع reauthenticate قبل updatePassword.
// - الحساب دخل بـ Google فقط (ماعندوش provider "password") → فورم
//   إنشاء كلمة مرور (بلا حقل الكلمة الحالية) عبر linkWithCredential،
//   ومن بعد كينجاح كينتقل تلقائيا لفورم التعديل العادي.

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class AppColors {
  static const darkGreen = Color(0xFF0F3D2E);
  static const background = Color(0xFFFAF7F2);
  static const gold = Color(0xFFC9A24B);
}

class ChangePasswordScreen extends StatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _obscureCurrent = true;
  bool _obscureNew = true;
  bool _obscureConfirm = true;
  bool _isSaving = false;
  bool _isLoading = true;
  bool _hasPasswordProvider = true;

  @override
  void initState() {
    super.initState();
    _loadPasswordProviderState();
  }

  @override
  void dispose() {
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _loadPasswordProviderState() {
    final user = FirebaseAuth.instance.currentUser;
    final hasPassword =
        user?.providerData.any((p) => p.providerId == 'password') ?? true;
    setState(() {
      _hasPasswordProvider = hasPassword;
      _isLoading = false;
    });
  }

  Future<void> _savePassword() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      final email = user?.email;
      if (user != null && email != null) {
        final credential = EmailAuthProvider.credential(
          email: email,
          password: _currentPasswordController.text,
        );
        await user.reauthenticateWithCredential(credential);
        await user.updatePassword(_newPasswordController.text);
      }
      if (!mounted) return;
      _showMessage('تم تحديث كلمة المرور بنجاح');
      Navigator.maybePop(context);
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      _showMessage(_errorMessageFor(e.code, isCreate: false));
    } catch (e) {
      debugPrint('ChangePasswordScreen._savePassword error: $e');
      if (!mounted) return;
      _showMessage('حدث خطأ، حاول مرة أخرى');
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _createPassword() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      final email = user?.email;
      if (user == null || email == null) {
        throw FirebaseAuthException(
          code: 'no-user',
          message: 'لا يوجد مستخدم مسجل الدخول',
        );
      }

      final credential = EmailAuthProvider.credential(
        email: email,
        password: _newPasswordController.text,
      );
      await user.linkWithCredential(credential);

      if (!mounted) return;
      _showMessage('تم إنشاء كلمة المرور بنجاح');

      // الحساب دابا عندو provider "password" → نبدلو للفورم العادي
      setState(() {
        _hasPasswordProvider = true;
        _currentPasswordController.clear();
        _newPasswordController.clear();
        _confirmPasswordController.clear();
      });
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      _showMessage(_errorMessageFor(e.code, isCreate: true));
    } catch (e) {
      debugPrint('ChangePasswordScreen._createPassword error: $e');
      if (!mounted) return;
      _showMessage('حدث خطأ، حاول مرة أخرى');
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  String _errorMessageFor(String code, {required bool isCreate}) {
    if (isCreate) {
      return switch (code) {
        'weak-password' => 'كلمة المرور ضعيفة جدًا',
        'provider-already-linked' => 'لديك كلمة مرور محددة مسبقًا',
        'credential-already-in-use' =>
          'كلمة المرور هذه مستخدمة من قبل حساب آخر، جرّب كلمة مرور أخرى',
        _ => 'حدث خطأ، حاول مرة أخرى',
      };
    }
    return switch (code) {
      'wrong-password' => 'كلمة المرور الحالية غير صحيحة',
      'weak-password' => 'كلمة المرور الجديدة ضعيفة جدًا',
      _ => 'حدث خطأ، حاول مرة أخرى',
    };
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: AppColors.background,
        body: Center(
          child: CircularProgressIndicator(color: AppColors.darkGreen),
        ),
      );
    }

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
            children: [
              _Header(hasPasswordProvider: _hasPasswordProvider),
              const SizedBox(height: 6),
              _Subtitle(hasPasswordProvider: _hasPasswordProvider),
              if (!_hasPasswordProvider) const _GoogleAccountNotice(),
              const SizedBox(height: 22),
              Form(
                key: _formKey,
                child: Column(
                  children: [
                    if (_hasPasswordProvider) ...[
                      _PasswordField(
                        label: 'كلمة المرور الحالية',
                        controller: _currentPasswordController,
                        obscure: _obscureCurrent,
                        onToggle: () => setState(
                          () => _obscureCurrent = !_obscureCurrent,
                        ),
                        validator: (v) => (v == null || v.isEmpty)
                            ? 'أدخل كلمة المرور الحالية'
                            : null,
                      ),
                      const SizedBox(height: 14),
                    ],
                    _PasswordField(
                      label: _hasPasswordProvider
                          ? 'كلمة المرور الجديدة'
                          : 'كلمة المرور',
                      controller: _newPasswordController,
                      obscure: _obscureNew,
                      onToggle: () =>
                          setState(() => _obscureNew = !_obscureNew),
                      validator: (v) {
                        if (v == null || v.isEmpty) {
                          return 'أدخل كلمة المرور';
                        }
                        if (v.length < 8) {
                          return 'يجب أن تحتوي على 8 أحرف على الأقل';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 14),
                    _PasswordField(
                      label: _hasPasswordProvider
                          ? 'تأكيد كلمة المرور الجديدة'
                          : 'تأكيد كلمة المرور',
                      controller: _confirmPasswordController,
                      obscure: _obscureConfirm,
                      onToggle: () =>
                          setState(() => _obscureConfirm = !_obscureConfirm),
                      validator: (v) => v != _newPasswordController.text
                          ? 'كلمتا المرور غير متطابقتين'
                          : null,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              _SubmitButton(
                isSaving: _isSaving,
                hasPasswordProvider: _hasPasswordProvider,
                onPressed: _hasPasswordProvider
                    ? _savePassword
                    : _createPassword,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  final bool hasPasswordProvider;

  const _Header({required this.hasPasswordProvider});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const SizedBox(width: 44),
        Expanded(
          child: Text(
            hasPasswordProvider ? 'كلمة المرور' : 'إنشاء كلمة مرور',
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: AppColors.darkGreen,
              letterSpacing: -0.4,
            ),
          ),
        ),
        _CircleIconButton(
          icon: Icons.arrow_back,
          onTap: () => Navigator.maybePop(context),
        ),
      ],
    );
  }
}

class _Subtitle extends StatelessWidget {
  final bool hasPasswordProvider;

  const _Subtitle({required this.hasPasswordProvider});

  @override
  Widget build(BuildContext context) {
    return Text(
      hasPasswordProvider
          ? 'حدّث كلمة مرورك للحفاظ على أمان حسابك'
          : 'أنشئ كلمة مرور لحسابك',
      textAlign: TextAlign.center,
      style: TextStyle(fontSize: 13, color: Colors.grey.shade500),
    );
  }
}

class _GoogleAccountNotice extends StatelessWidget {
  const _GoogleAccountNotice();

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 14),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.gold.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.info_outline_rounded,
            color: AppColors.darkGreen,
            size: 18,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'لقد سجّلت الدخول بحساب Google، وليس لديك كلمة مرور محددة '
              'بعد. أنشئ واحدة حتى تتمكن من الدخول بالبريد الإلكتروني '
              'وكلمة المرور أيضًا.',
              style: TextStyle(fontSize: 12.5, color: Colors.grey.shade700),
            ),
          ),
        ],
      ),
    );
  }
}

class _SubmitButton extends StatelessWidget {
  final bool isSaving;
  final bool hasPasswordProvider;
  final VoidCallback onPressed;

  const _SubmitButton({
    required this.isSaving,
    required this.hasPasswordProvider,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton(
        onPressed: isSaving ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.darkGreen,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
        ),
        child: isSaving
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2.4,
                ),
              )
            : Text(
                hasPasswordProvider ? 'حفظ التغييرات' : 'إنشاء كلمة المرور',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
      ),
    );
  }
}

class _PasswordField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final bool obscure;
  final VoidCallback onToggle;
  final String? Function(String?) validator;

  const _PasswordField({
    required this.label,
    required this.controller,
    required this.obscure,
    required this.onToggle,
    required this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: AppColors.darkGreen.withValues(alpha: 0.05),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: TextFormField(
        controller: controller,
        obscureText: obscure,
        validator: validator,
        style: const TextStyle(
          color: AppColors.darkGreen,
          fontWeight: FontWeight.w600,
        ),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(color: Colors.grey.shade500),
          filled: true,
          fillColor: Colors.white,
          suffixIcon: IconButton(
            icon: Icon(
              obscure
                  ? Icons.visibility_off_rounded
                  : Icons.visibility_rounded,
              color: AppColors.darkGreen.withValues(alpha: 0.6),
            ),
            onPressed: onToggle,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(18),
            borderSide: BorderSide.none,
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 14,
          ),
        ),
      ),
    );
  }
}

class _CircleIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _CircleIconButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: AppColors.darkGreen.withValues(alpha: 0.08),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Icon(
            icon,
            color: AppColors.darkGreen,
            size: 20,
            textDirection: TextDirection.ltr,
          ),
        ),
      ),
    );
  }
}

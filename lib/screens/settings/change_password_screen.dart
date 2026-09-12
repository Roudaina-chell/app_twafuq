// screens/settings/change_password_screen.dart
//
// ✅ شاشة "كلمة المرور" — الوصول ليها من كارت "كلمة المرور" فـ
// SecurityPrivacyScreen.
//
// ✅ زدت case "Continuer avec Google": إلا كان الحساب دخل بـ Google
// وماعندوش provider "password" (يعني حتى بمرة ماخلق كلمة مرور
// للتطبيق)، الشاشة كتبدل تلقائيا لفورم "إنشاء كلمة مرور" (بلا حقل
// كلمة المرور الحالية — لأن ماكايناش)، وكتستعمل linkWithCredential
// باش تزيد provider "password" فوق حساب Google.
// من بعد ما يخلق كلمة المرور، الحساب كيولي عندو جوج طرق دخول
// (Google + Email/كلمة مرور)، وفـ زيارة جاية للشاشة كيبان تلقائيا
// الفورم العادي "تعديل كلمة المرور" (current + new + confirm) لأن
// دابا provider "password" كاين.
//
// ✅ ماعادش كتعتمد على widget/page_background_decor.dart — الألوان
// وCircleIconButton معرّفين محليا هنا.
//
// ✅ تعديل جديد: زر الرجوع دابا مثبت فعليا عل اليسار (بدّلنا مكانو
// فـ الـ Row لآخر العناصر).

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

const Color kDarkGreen = Color(0xFF0F3D2E);
const Color kBg = Color(0xFFFAF7F2);
const Color kGold = Color(0xFFC9A24B);

class ChangePasswordScreen extends StatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _currentCtrl = TextEditingController();
  final _newCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();

  bool _obscureCurrent = true;
  bool _obscureNew = true;
  bool _obscureConfirm = true;
  bool _isSaving = false;
  bool _isLoading = true;

  // ✅ true = الحساب عندو provider "password" (دخل بـ email/كلمة
  // مرور، ولو زاد Google من بعد). false = دخل غير بـ Google وماعندو
  // حتى كلمة مرور — خاصو "ينشئ" وحدة قبل ما "يبدلها".
  bool _hasPasswordProvider = true;

  @override
  void initState() {
    super.initState();
    _checkPasswordProvider();
  }

  void _checkPasswordProvider() {
    final user = FirebaseAuth.instance.currentUser;
    final hasPassword =
        user?.providerData.any((p) => p.providerId == 'password') ?? true;
    setState(() {
      _hasPasswordProvider = hasPassword;
      _isLoading = false;
    });
  }

  @override
  void dispose() {
    _currentCtrl.dispose();
    _newCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  // ============================================================
  // ✅ Cas 1: الحساب عندو password provider من قبل → تعديل عادي
  // (يخص reauthenticate بكلمة المرور الحالية قبل updatePassword)
  // ============================================================
  Future<void> _savePassword() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);
    try {
      final user = FirebaseAuth.instance.currentUser;
      final email = user?.email;
      if (user != null && email != null) {
        final cred = EmailAuthProvider.credential(
          email: email,
          password: _currentCtrl.text,
        );
        await user.reauthenticateWithCredential(cred);
        await user.updatePassword(_newCtrl.text);
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تم تحديث كلمة المرور بنجاح')),
      );
      Navigator.maybePop(context);
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      final msg = switch (e.code) {
        'wrong-password' => 'كلمة المرور الحالية غير صحيحة',
        'weak-password' => 'كلمة المرور الجديدة ضعيفة جدا',
        _ => 'حدث خطأ، حاول مرة أخرى',
      };
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
    } catch (e) {
      debugPrint('❌ ChangePassword: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('حدث خطأ، حاول مرة أخرى')));
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  // ============================================================
  // ✅ Cas 2: الحساب دخل بـ Google وماعندوش كلمة مرور → linkWithCredential
  // باش يزيد provider "password" فوق نفس الحساب (بلا ما يمسح Google).
  // من بعد هاذي، الحساب يقدر يدخل بجوج الطرق: Google أو Email+كلمة مرور.
  // ============================================================
  Future<void> _createPassword() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);
    try {
      final user = FirebaseAuth.instance.currentUser;
      final email = user?.email;
      if (user == null || email == null) {
        throw FirebaseAuthException(
          code: 'no-user',
          message: 'ماكاين حتى مستخدم مسجل الدخول',
        );
      }
      final cred = EmailAuthProvider.credential(
        email: email,
        password: _newCtrl.text,
      );
      await user.linkWithCredential(cred);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تم إنشاء كلمة المرور بنجاح')),
      );
      // ✅ دابا الحساب عندو provider "password" — نبدلو الفورم للوضع
      // العادي (تعديل) بلا ما نخرجو من الشاشة.
      setState(() {
        _hasPasswordProvider = true;
        _currentCtrl.clear();
        _newCtrl.clear();
        _confirmCtrl.clear();
      });
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      final msg = switch (e.code) {
        'weak-password' => 'كلمة المرور ضعيفة جدا',
        'provider-already-linked' => 'عندك كلمة مرور محددة من قبل',
        'credential-already-in-use' =>
          'هاذي الكلمة مستعملة من حساب آخر، جرب وحدة أخرى',
        _ => 'حدث خطأ، حاول مرة أخرى',
      };
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
    } catch (e) {
      debugPrint('❌ CreatePassword: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('حدث خطأ، حاول مرة أخرى')));
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: kBg,
        body: Center(child: CircularProgressIndicator(color: kDarkGreen)),
      );
    }

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: kBg,
        body: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
            children: [
              Row(
                children: [
                  const SizedBox(width: 44),
                  Expanded(
                    child: Text(
                      _hasPasswordProvider ? 'كلمة المرور' : 'إنشاء كلمة مرور',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: kDarkGreen,
                        letterSpacing: -0.4,
                      ),
                    ),
                  ),
                  _CircleIconButton(
                    icon: Icons.arrow_back,
                    onTap: () => Navigator.maybePop(context),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                _hasPasswordProvider
                    ? 'حدّث كلمة مرورك للحفاظ على أمان حسابك'
                    : 'أنشئ كلمة مرور لحسابك',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13, color: Colors.grey.shade500),
              ),
              if (!_hasPasswordProvider) ...[
                const SizedBox(height: 4),
                Container(
                  margin: const EdgeInsets.only(top: 10),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: kGold.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.info_outline_rounded,
                        color: kDarkGreen,
                        size: 18,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'دخلتي بحساب Google، ماعندكش كلمة مرور محددة '
                          'بعد. أنشئ وحدة باش تقدر تدخل بالإيميل وكلمة '
                          'المرور أيضا.',
                          style: TextStyle(
                            fontSize: 12.5,
                            color: Colors.grey.shade700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 22),
              Form(
                key: _formKey,
                child: Column(
                  children: [
                    if (_hasPasswordProvider)
                      _PasswordField(
                        label: 'كلمة المرور الحالية',
                        controller: _currentCtrl,
                        obscure: _obscureCurrent,
                        onToggle: () =>
                            setState(() => _obscureCurrent = !_obscureCurrent),
                        validator: (v) => (v == null || v.isEmpty)
                            ? 'أدخل كلمة المرور الحالية'
                            : null,
                      ),
                    if (_hasPasswordProvider) const SizedBox(height: 14),
                    _PasswordField(
                      label: _hasPasswordProvider
                          ? 'كلمة المرور الجديدة'
                          : 'كلمة المرور',
                      controller: _newCtrl,
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
                      controller: _confirmCtrl,
                      obscure: _obscureConfirm,
                      onToggle: () =>
                          setState(() => _obscureConfirm = !_obscureConfirm),
                      validator: (v) => v != _newCtrl.text
                          ? 'كلمتا المرور غير متطابقتين'
                          : null,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _isSaving
                      ? null
                      : (_hasPasswordProvider
                            ? _savePassword
                            : _createPassword),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: kDarkGreen,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                  ),
                  child: _isSaving
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2.4,
                          ),
                        )
                      : Text(
                          _hasPasswordProvider
                              ? 'حفظ التغييرات'
                              : 'إنشاء كلمة المرور',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                ),
              ),
            ],
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
            color: kDarkGreen.withValues(alpha: 0.05),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: TextFormField(
        controller: controller,
        obscureText: obscure,
        validator: validator,
        style: const TextStyle(color: kDarkGreen, fontWeight: FontWeight.w600),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(color: Colors.grey.shade500),
          filled: true,
          fillColor: Colors.white,
          suffixIcon: IconButton(
            icon: Icon(
              obscure ? Icons.visibility_off_rounded : Icons.visibility_rounded,
              color: kDarkGreen.withValues(alpha: 0.6),
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

// ================================================================
// ✅ زر دائري (رجوع) — معرّف محليا، بلا اعتماد على أي ملف مشترك
// ================================================================
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
                color: kDarkGreen.withValues(alpha: 0.08),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Icon(
            icon,
            color: kDarkGreen,
            size: 20,
            textDirection: TextDirection.ltr,
          ),
        ),
      ),
    );
  }
}
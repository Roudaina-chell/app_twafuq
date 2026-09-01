// screens/legal/legal_screen.dart
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../auth/login_screen.dart';

class LegalScreen extends StatefulWidget {
  const LegalScreen({super.key});

  @override
  State<LegalScreen> createState() => _LegalScreenState();
}

class _LegalScreenState extends State<LegalScreen> {
  bool _agreed = false;

  static const Color darkGreen = Color(0xFF0F3D2E);
  static const Color gold = Color(0xFFC9A24B);
  static const Color bg = Color(0xFFFAF7F2);

  Future<void> _acceptAndContinue() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('hasAcceptedLegal', true);

    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(
        child: Column(
          children: [
            // الشعار
            Padding(
              padding: const EdgeInsets.only(top: 24),
              child: Image.asset(
                'assets/images/logo.png',
                width: 70,
                height: 70,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'الشروط والأحكام',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: darkGreen,
              ),
            ),
            const SizedBox(height: 8),
            // النص القابل للتمرير
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ===== شروط الاستخدام =====
                    const Text(
                      'شروط الاستخدام',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: darkGreen,
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'يرجى قراءة هذه الشروط بعناية قبل استخدام المنصة.\n'
                      'إن ضغطك على زر "أوافق" يُعد إقراراً قانونياً بالتزامك الكامل بكافة البنود الواردة أدناه.',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey,
                        height: 1.6,
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'نص شروط الاستخدام الكامل:\n'
                      'هذا هو النص الكامل لشروط الاستخدام لمنصة "توافق".\n'
                      'يحتوي على جميع البنود القانونية التي تنظم علاقتك بالمنصة.\n'
                      'البند الأول: قبول الشروط ...\n'
                      'البند الثاني: التعديلات ...\n'
                      'البند الثالث: الخصوصية ...\n'
                      'البند الرابع: المسؤولية ...\n'
                      'البند الخامس: إنهاء الخدمة ...\n',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.black87,
                        height: 1.8,
                      ),
                    ),
                    const Divider(height: 30, color: Colors.grey),

                    // ===== سياسة الخصوصية =====
                    const Text(
                      'سياسة الخصوصية',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: darkGreen,
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'نحن ملتزمون بحماية بياناتك الشخصية وفقاً للتشريعات الجزائرية المعمول بها.\n'
                      'نقرأ سياسة الخصوصية لفهم كيف نجمع بياناتك وتستخدمها ونحميها.',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey,
                        height: 1.6,
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'نص سياسة الخصوصية الكامل:\n'
                      'نحن نلتزم بحماية خصوصيتك وبياناتك الشخصية.\n'
                      'جمع البيانات: نقوم بجمع البيانات التي تقدمها عند التسجيل.\n'
                      'استخدام البيانات: نستخدم بياناتك لتقديم الخدمات.\n'
                      'حماية البيانات: نتخذ إجراءات أمنية مشددة.\n'
                      'مشاركة البيانات: لا نشارك بياناتك مع أطراف ثالثة إلا بموافقتك.\n'
                      'حقوقك: لديك الحق في الوصول إلى بياناتك وتعديلها أو حذفها.',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.black87,
                        height: 1.8,
                      ),
                    ),
                    const Divider(height: 30, color: Colors.grey),

                    // ===== إخلاء المسؤولية =====
                    const Text(
                      'إخلاء المسؤولية القانونية',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: darkGreen,
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'تقتصر مسؤولية المنصة على توفير الوساطة الرقمية فقط. لا تحمل أي مسؤولية عن التصرفات أو السلوكيات الشخصية بين المستخدمين داخل أو خارج المقهى الشريك.',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey,
                        height: 1.6,
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'نص إخلاء المسؤولية الكامل:\n'
                      'المنصة تعمل كوسيط رقمي لتسهيل التواصل بين المستخدمين.\n'
                      'المنصة ليست مسؤولة عن أي تصرفات أو سلوكيات تحدث بين المستخدمين.\n'
                      'أي نزاعات أو خلافات تنشأ بينهم تكون تحت مسؤوليتهم الشخصية.\n'
                      'لا تتحمل المنصة أي مسؤولية عن الأضرار المباشرة أو غير المباشرة.\n'
                      'ننصح المستخدمين بالتواصل مع الإدارة في حالة حدوث أي مشكلة.',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.black87,
                        height: 1.8,
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
            // ===== أسفل الصفحة (Checkbox والزر) =====
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, -4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  // Checkbox
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: bg,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: Row(
                      children: [
                        Checkbox(
                          value: _agreed,
                          activeColor: darkGreen,
                          onChanged: (val) {
                            setState(() {
                              _agreed = val ?? false;
                            });
                          },
                        ),
                        const Expanded(
                          child: Text(
                            'أوافق على جميع البنود والشروط والسياسات المذكورة أعلاه',
                            style: TextStyle(fontSize: 14),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'لن تظهر هذه الصفحة مرة أخرى',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: ElevatedButton(
                      onPressed: _agreed ? _acceptAndContinue : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: darkGreen,
                        disabledBackgroundColor: Colors.grey.shade300,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: const Text(
                        'أوافق وأبدأ',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
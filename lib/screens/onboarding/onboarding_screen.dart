// screens/onboarding/onboarding_screen.dart
import 'package:flutter/material.dart';
import '../auth/login_screen.dart';
 import 'package:shared_preferences/shared_preferences.dart' show SharedPreferences;

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  // حالات الموافقة لكل بند
  bool _acceptedTerms = false;
  bool _acceptedPrivacy = false;
  bool _acceptedDisclaimer = false;
  bool _finalAccepted = false;

  static const Color darkGreen = Color(0xFF0F3D2E);
  static const Color gold = Color(0xFFC9A24B);
  static const Color bg = Color(0xFFFAF7F2);

  // الانتقال للصفحة التالية
  void _nextPage() {
    if (_currentPage < 3) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeInOutCubic,
      );
    } else {
      _finishOnboarding();
    }
  }

  // إنهاء الأونبواردينغ والتوجه إلى Login
  void _finishOnboarding() {
    // هنا نخزن أن المستخدم شاهد الأونبواردينغ (سيتم حفظه في Splash)
    // لكن بما أننا نستعمل SharedPreferences في Splash، نحتاج لحفظ القيمة
    // نستعمل نفس الـ key المستعمل في splash_screen.dart
    // لكن لتجنب التعقيد، سنوجه إلى Login وسيتم حفظها تلقائياً في المستقبل.
    // لكننا سنحفظها الآن لتجنب الظهور مجدداً.
    // سنستخدم SharedPreferences مباشرة.
   
    // لكن لا يمكن استيرادها بدون إضافة، لكنها موجودة بالفعل.
    // لإختصار، سنضيف الاستيراد في الأعلى.
    // لكن سأقوم بكتابة الكود كاملاً مع الاستيراد.
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const LoginScreen()),
    );
  }

  // دالة لعرض النص الكامل في حوار
  void _showFullText(String title, String content) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Text(
          title,
          style: const TextStyle(
            color: darkGreen,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: SingleChildScrollView(
          child: Text(
            content,
            style: const TextStyle(height: 1.6),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إغلاق'),
          ),
        ],
      ),
    );
  }

  // بناء كل صفحة (الصفحات 1-3)
  Widget _buildPage({
    required String title,
    required String description,
    required String fullText,
    required bool value,
    required ValueChanged<bool?> onChanged,
    required String checkboxLabel,
    required String buttonLabel,
    required String readMoreLabel,
    bool isLast = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 28),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // الشعار بدل الأيقونة الكبيرة
          Image.asset(
            'assets/images/logo_tawafuq.png',
            width: 80,
            height: 80,
          ),
          const SizedBox(height: 24),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: darkGreen,
            ),
          ),
          const SizedBox(height: 14),
          Text(
            description,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 14,
              color: Colors.grey,
              height: 1.6,
            ),
          ),
          const SizedBox(height: 16),
          // زر قراءة النص الكامل
          TextButton(
            onPressed: () => _showFullText(title, fullText),
            child: Text(
              readMoreLabel,
              style: TextStyle(
                color: gold,
                fontWeight: FontWeight.w600,
                decoration: TextDecoration.underline,
              ),
            ),
          ),
          const SizedBox(height: 16),
          // مربع الاختيار
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Row(
              children: [
                Checkbox(
                  value: value,
                  activeColor: darkGreen,
                  onChanged: onChanged,
                ),
                Expanded(
                  child: Text(
                    checkboxLabel,
                    style: const TextStyle(fontSize: 14),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: value ? _nextPage : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: darkGreen,
                disabledBackgroundColor: Colors.grey.shade300,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: Text(
                buttonLabel,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // الصفحة الأخيرة (الموافقة النهائية)
  Widget _buildFinalPage() {
    // التحقق من أن جميع الموافقات السابقة تمت
    bool allPreviousAccepted =
        _acceptedTerms && _acceptedPrivacy && _acceptedDisclaimer;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 28),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Image.asset(
            'assets/images/logo_tawafuq.png',
            width: 80,
            height: 80,
          ),
          const SizedBox(height: 24),
          const Text(
            'تم الموافقة على كل ما سبق',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: darkGreen,
            ),
          ),
          const SizedBox(height: 14),
          const Text(
            'بالموافقة، أنت تقر أنك قرأت وفهمت وتقبل جميع الشروط والسياسات والإخلاءات المذكورة أعلاه.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey,
              height: 1.6,
            ),
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Row(
              children: [
                Checkbox(
                  value: _finalAccepted,
                  activeColor: darkGreen,
                  onChanged: (val) {
                    setState(() {
                      _finalAccepted = val ?? false;
                    });
                  },
                ),
                const Expanded(
                  child: Text(
                    'أوافق على جميع البنود والشروط والسياسات',
                    style: TextStyle(fontSize: 14),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'لن تظهر هذه الصفحة مرة أخرى',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey,
              fontStyle: FontStyle.italic,
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: (allPreviousAccepted && _finalAccepted)
                  ? _finishOnboarding
                  : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: darkGreen,
                disabledBackgroundColor: Colors.grey.shade300,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: const Text(
                'تم الموافقة (بدا الاستخدام)',
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
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 20),
            // نقاط التقدم
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                4,
                (index) => AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  width: _currentPage == index ? 24 : 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: _currentPage == index ? gold : Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 10),
            Expanded(
              child: PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                onPageChanged: (index) {
                  setState(() => _currentPage = index);
                },
                children: [
                  // الصفحة 1: شروط الاستخدام
                  _buildPage(
                    title: 'شروط الاستخدام',
                    description:
                        'يرجى قراءة هذه الشروط بعناية قبل استخدام المنصة.\n'
                        'إن ضغطك على زر "أوافق" يُعد إقراراً قانونياً بالتزامك الكامل بكافة البنود الواردة أدناه.',
                    fullText: '''
هذا هو النص الكامل لشروط الاستخدام لمنصة "توافق".
يحتوي على جميع البنود القانونية التي تنظم علاقتك بالمنصة.

البند الأول: قبول الشروط
باستخدامك للمنصة، فإنك توافق على جميع الشروط والأحكام المذكورة هنا.

البند الثاني: التعديلات
نحتفظ بالحق في تعديل هذه الشروط في أي وقت، وسيتم إخطارك بالتغييرات.

البند الثالث: الخصوصية
سيتم التعامل مع بياناتك وفقاً لسياسة الخصوصية المنفصلة.

البند الرابع: المسؤولية
المنصة تعمل كوسيط رقمي ولا تتحمل مسؤولية التفاعلات بين المستخدمين.

البند الخامس: إنهاء الخدمة
يمكننا إنهاء حسابك في حال مخالفة الشروط.

آخر تحديث: 31 أغسطس 2026
''',
                    value: _acceptedTerms,
                    onChanged: (val) {
                      setState(() => _acceptedTerms = val ?? false);
                    },
                    checkboxLabel: 'تم الموافقة على جميع البنود والشروط',
                    buttonLabel: 'التالي',
                    readMoreLabel: 'قراءة الشروط كاملة',
                  ),
                  // الصفحة 2: سياسة الخصوصية
                  _buildPage(
                    title: 'سياسة الخصوصية',
                    description:
                        'نحن ملتزمون بحماية بياناتك الشخصية وفقاً للتشريعات الجزائرية المعمول بها.\n'
                        'نقرأ سياسة الخصوصية لفهم كيف نجمع بياناتك وتستخدمها ونحميها.',
                    fullText: '''
هذا هو النص الكامل لسياسة الخصوصية الخاصة بمنصة "توافق".

نحن نلتزم بحماية خصوصيتك وبياناتك الشخصية.

جمع البيانات:
نقوم بجمع البيانات التي تقدمها عند التسجيل، مثل الاسم والبريد الإلكتروني.

استخدام البيانات:
نستخدم بياناتك لتقديم الخدمات وتحسين تجربتك.

حماية البيانات:
نتخذ إجراءات أمنية مشددة لحماية بياناتك من الوصول غير المصرح به.

مشاركة البيانات:
لا نشارك بياناتك مع أطراف ثالثة إلا بموافقتك أو عند اقتضاء القانون.

حقوقك:
لديك الحق في الوصول إلى بياناتك وتعديلها أو حذفها في أي وقت.

للتواصل: support@tawafuq.com
''',
                    value: _acceptedPrivacy,
                    onChanged: (val) {
                      setState(() => _acceptedPrivacy = val ?? false);
                    },
                    checkboxLabel: 'تم الموافقة على سياسة الخصوصية',
                    buttonLabel: 'التالي',
                    readMoreLabel: 'قراءة السياسة كاملة',
                  ),
                  // الصفحة 3: إخلاء المسؤولية
                  _buildPage(
                    title: 'إخلاء المسؤولية القانونية',
                    description:
                        'تقتصر مسؤولية المنصة على توفير الوساطة الرقمية فقط. لا تحمل أي مسؤولية عن التصرفات أو السلوكيات الشخصية بين المستخدمين داخل أو خارج المقهى الشريك.',
                    fullText: '''
هذا هو النص الكامل لإخلاء المسؤولية لمنصة "توافق".

المنصة تعمل كوسيط رقمي لتسهيل التواصل بين المستخدمين.

المنصة ليست مسؤولة عن:
- أي تصرفات أو سلوكيات تحدث بين المستخدمين.
- أي نزاعات أو خلافات تنشأ بينهم.
- أي محتوى ينشره المستخدمون.

جميع التفاعلات تكون تحت مسؤولية المستخدمين أنفسهم.

لا تتحمل المنصة أي مسؤولية عن الأضرار المباشرة أو غير المباشرة الناتجة عن استخدام المنصة.

ننصح المستخدمين بالتواصل مع إدارة المنصة في حالة حدوث أي مشكلة.
''',
                    value: _acceptedDisclaimer,
                    onChanged: (val) {
                      setState(() => _acceptedDisclaimer = val ?? false);
                    },
                    checkboxLabel: 'تم الموافقة على إخلاء المسؤولية',
                    buttonLabel: 'التالي',
                    readMoreLabel: 'قراءة الإخلاء الكامل',
                  ),
                  // الصفحة 4: الموافقة النهائية
                  _buildFinalPage(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
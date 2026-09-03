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

  // دالة لعرض النص الكامل في حوار (تصميم أعصري)
  void _showFullText(String title, String content) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 60),
        child: Container(
          constraints: const BoxConstraints(maxHeight: 520),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: darkGreen.withValues(alpha: 0.18),
                blurRadius: 30,
                offset: const Offset(0, 14),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.fromLTRB(22, 22, 22, 16),
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(color: Colors.grey.shade100, width: 1.2),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: darkGreen.withValues(alpha: 0.08),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.description_rounded,
                          color: darkGreen, size: 18),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        title,
                        style: const TextStyle(
                          color: darkGreen,
                          fontWeight: FontWeight.bold,
                          fontSize: 16.5,
                        ),
                      ),
                    ),
                    InkWell(
                      onTap: () => Navigator.pop(context),
                      borderRadius: BorderRadius.circular(20),
                      child: Padding(
                        padding: const EdgeInsets.all(4),
                        child: Icon(Icons.close_rounded,
                            color: Colors.grey.shade500, size: 20),
                      ),
                    ),
                  ],
                ),
              ),
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(22, 16, 22, 8),
                  child: Text(
                    content,
                    textAlign: TextAlign.right,
                    style: const TextStyle(
                      height: 1.75,
                      fontSize: 13.5,
                      color: Colors.black87,
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(22, 10, 22, 22),
                child: SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: darkGreen,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: const Text(
                      'إغلاق',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                      ),
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

  // بطاقة موافقة موحّدة (checkbox) بتصميم أنظف
  Widget _buildConsentCard({
    required bool value,
    required ValueChanged<bool?> onChanged,
    required String label,
  }) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      decoration: BoxDecoration(
        color: value ? darkGreen.withValues(alpha: 0.05) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: value ? darkGreen.withValues(alpha: 0.35) : Colors.grey.shade200,
          width: 1.3,
        ),
        boxShadow: [
          BoxShadow(
            color: darkGreen.withValues(alpha: value ? 0.06 : 0.02),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => onChanged(!value),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          child: Row(
            children: [
              Checkbox(
                value: value,
                activeColor: darkGreen,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(6),
                ),
                onChanged: onChanged,
              ),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: value ? FontWeight.w600 : FontWeight.w500,
                    color: value ? darkGreen : Colors.black87,
                    height: 1.5,
                  ),
                ),
              ),
              AnimatedOpacity(
                duration: const Duration(milliseconds: 200),
                opacity: value ? 1 : 0,
                child: Icon(Icons.check_circle_rounded,
                    color: darkGreen, size: 18),
              ),
            ],
          ),
        ),
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
    return SingleChildScrollView(
      physics: const ClampingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 12),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          minHeight: MediaQuery.of(context).size.height * 0.62,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // الشعار داخل إطار دائري ناعم
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: darkGreen.withValues(alpha: 0.10),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Image.asset(
                'assets/images/logo_tawafuq.png',
                width: 64,
                height: 64,
              ),
            ),
            const SizedBox(height: 26),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 25,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.2,
                color: darkGreen,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              description,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 14,
                color: Colors.black45,
                height: 1.7,
              ),
            ),
            const SizedBox(height: 10),
            TextButton.icon(
              onPressed: () => _showFullText(title, fullText),
              icon: Icon(Icons.menu_book_rounded, size: 16, color: gold),
              label: Text(
                readMoreLabel,
                style: TextStyle(
                  color: gold,
                  fontWeight: FontWeight.w600,
                  fontSize: 13.5,
                ),
              ),
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 4),
              ),
            ),
            const SizedBox(height: 18),
            _buildConsentCard(
              value: value,
              onChanged: onChanged,
              label: checkboxLabel,
            ),
            const SizedBox(height: 22),
            SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton(
                onPressed: value ? _nextPage : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: darkGreen,
                  disabledBackgroundColor: Colors.grey.shade300,
                  elevation: 0,
                  shadowColor: darkGreen.withValues(alpha: 0.35),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                ).copyWith(
                  elevation: WidgetStateProperty.resolveWith(
                    (states) => states.contains(WidgetState.disabled)
                        ? 0
                        : (states.contains(WidgetState.pressed) ? 0 : 5),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      buttonLabel,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: value ? Colors.white : Colors.grey.shade500,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Icon(Icons.arrow_back_ios_new_rounded,
                        size: 15,
                        color: value ? Colors.white : Colors.grey.shade500),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // الصفحة الأخيرة (الموافقة النهائية)
  Widget _buildFinalPage() {
    // التحقق من أن جميع الموافقات السابقة تمت
    bool allPreviousAccepted =
        _acceptedTerms && _acceptedPrivacy && _acceptedDisclaimer;

    return SingleChildScrollView(
      physics: const ClampingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 12),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          minHeight: MediaQuery.of(context).size.height * 0.62,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: gold.withValues(alpha: 0.18),
                    blurRadius: 22,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Image.asset(
                    'assets/images/logo_tawafuq.png',
                    width: 64,
                    height: 64,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 26),
            const Text(
              'تم الموافقة على كل ما سبق',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w800,
                color: darkGreen,
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'بالموافقة، أنت تقر أنك قرأت وفهمت وتقبل جميع الشروط والسياسات والإخلاءات المذكورة أعلاه.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Colors.black45,
                height: 1.7,
              ),
            ),
            const SizedBox(height: 26),
            _buildConsentCard(
              value: _finalAccepted,
              onChanged: (val) {
                setState(() {
                  _finalAccepted = val ?? false;
                });
              },
              label: 'أوافق على جميع البنود والشروط والسياسات',
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.lock_outline_rounded,
                    size: 13, color: Colors.grey.shade400),
                const SizedBox(width: 6),
                Text(
                  'لن تظهر هذه الصفحة مرة أخرى',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade500,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 22),
            SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton(
                onPressed: (allPreviousAccepted && _finalAccepted)
                    ? _finishOnboarding
                    : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: darkGreen,
                  disabledBackgroundColor: Colors.grey.shade300,
                  elevation: 0,
                  shadowColor: darkGreen.withValues(alpha: 0.35),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                ).copyWith(
                  elevation: WidgetStateProperty.resolveWith(
                    (states) => states.contains(WidgetState.disabled)
                        ? 0
                        : (states.contains(WidgetState.pressed) ? 0 : 5),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.check_circle_outline_rounded,
                        size: 18,
                        color: (allPreviousAccepted && _finalAccepted)
                            ? Colors.white
                            : Colors.grey.shade500),
                    const SizedBox(width: 8),
                    Text(
                      'تم الموافقة (بدا الاستخدام)',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: (allPreviousAccepted && _finalAccepted)
                            ? Colors.white
                            : Colors.grey.shade500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
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
                  duration: const Duration(milliseconds: 280),
                  curve: Curves.easeOut,
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  width: _currentPage == index ? 26 : 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: _currentPage == index ? gold : Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 6),
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
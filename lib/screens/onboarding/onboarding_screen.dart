// screens/onboarding/onboarding_screen.dart
import 'package:flutter/material.dart';
import '../auth/login_screen.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen>
    with TickerProviderStateMixin {
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

  // أنيميشن الدخول لمحتوى كل صفحة
  late final AnimationController _entranceController;
  late final Animation<double> _entranceFade;
  late final Animation<Offset> _entranceSlide;

  // أنيميشن تعويم الشعار (Idle float)
  late final AnimationController _floatController;

  double _pageOffset = 0;

  @override
  void initState() {
    super.initState();

    _entranceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..forward();

    _entranceFade = CurvedAnimation(
      parent: _entranceController,
      curve: Curves.easeOut,
    );

    _entranceSlide = Tween<Offset>(
      begin: const Offset(0, 0.05),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _entranceController,
      curve: Curves.easeOutCubic,
    ));

    _floatController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat(reverse: true);

    _pageController.addListener(() {
      final page = _pageController.page;
      if (page != null) {
        setState(() => _pageOffset = page);
      }
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    _entranceController.dispose();
    _floatController.dispose();
    super.dispose();
  }

  void _replayEntrance() {
    _entranceController
      ..reset()
      ..forward();
  }

  // الانتقال للصفحة التالية
  void _nextPage() {
    if (_currentPage < 3) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 420),
        curve: Curves.easeInOutCubic,
      );
    } else {
      _finishOnboarding();
    }
  }

  // إنهاء الأونبواردينغ والتوجه إلى Login بانتقال ناعم
  void _finishOnboarding() {
    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 500),
        pageBuilder: (context, animation, secondaryAnimation) =>
            const LoginScreen(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          final fade = CurvedAnimation(parent: animation, curve: Curves.easeOut);
          return FadeTransition(
            opacity: fade,
            child: ScaleTransition(
              scale: Tween<double>(begin: 0.97, end: 1).animate(fade),
              child: child,
            ),
          );
        },
      ),
    );
  }

  // دالة لعرض النص الكامل في حوار (تصميم أعصري + أنيميشن)
  void _showFullText(String title, String content) {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: title,
      barrierColor: Colors.black.withValues(alpha: 0.45),
      transitionDuration: const Duration(milliseconds: 320),
      pageBuilder: (context, anim1, anim2) => const SizedBox.shrink(),
      transitionBuilder: (context, anim, secondaryAnim, child) {
        final curved = CurvedAnimation(parent: anim, curve: Curves.easeOutCubic);
        return Opacity(
          opacity: curved.value,
          child: Transform.scale(
            scale: 0.92 + (0.08 * curved.value),
            child: Dialog(
              backgroundColor: Colors.transparent,
              insetPadding:
                  const EdgeInsets.symmetric(horizontal: 24, vertical: 60),
              child: Container(
                constraints: const BoxConstraints(maxHeight: 560),
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
                          bottom:
                              BorderSide(color: Colors.grey.shade100, width: 1.2),
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
                            height: 1.8,
                            fontSize: 13.3,
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
          ),
        );
      },
    );
  }

  // خلفية ناعمة بدوائر متحركة (Ambient background)
  Widget _buildAnimatedBackground() {
    return AnimatedBuilder(
      animation: _floatController,
      builder: (context, _) {
        final t = _floatController.value;
        return Stack(
          children: [
            Positioned(
              top: -60 + (t * 14),
              right: -50,
              child: Container(
                width: 190,
                height: 190,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: gold.withValues(alpha: 0.10),
                ),
              ),
            ),
            Positioned(
              bottom: -70 - (t * 10),
              left: -60,
              child: Container(
                width: 220,
                height: 220,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: darkGreen.withValues(alpha: 0.06),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  // بطاقة موافقة موحّدة (checkbox) مع أنيميشن ضغط
  Widget _buildConsentCard({
    required bool value,
    required ValueChanged<bool?> onChanged,
    required String label,
  }) {
    return _PressableScale(
      onTap: () => onChanged(!value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOut,
        decoration: BoxDecoration(
          color: value ? darkGreen.withValues(alpha: 0.05) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color:
                value ? darkGreen.withValues(alpha: 0.35) : Colors.grey.shade200,
            width: 1.3,
          ),
          boxShadow: [
            BoxShadow(
              color: darkGreen.withValues(alpha: value ? 0.08 : 0.02),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
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
              AnimatedScale(
                duration: const Duration(milliseconds: 260),
                curve: Curves.elasticOut,
                scale: value ? 1 : 0,
                child: Icon(Icons.check_circle_rounded,
                    color: darkGreen, size: 18),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // زر رئيسي بأنيميشن ضغط + تدرّج
  Widget _buildPrimaryButton({
    required bool enabled,
    required VoidCallback? onPressed,
    required Widget child,
  }) {
    return _PressableScale(
      onTap: enabled ? onPressed : null,
      minScale: 0.97,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        width: double.infinity,
        height: 54,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          gradient: enabled
              ? const LinearGradient(
                  colors: [darkGreen, Color(0xFF165C43)],
                  begin: Alignment.centerRight,
                  end: Alignment.centerLeft,
                )
              : null,
          color: enabled ? null : Colors.grey.shade300,
          boxShadow: enabled
              ? [
                  BoxShadow(
                    color: darkGreen.withValues(alpha: 0.30),
                    blurRadius: 16,
                    offset: const Offset(0, 8),
                  ),
                ]
              : [],
        ),
        alignment: Alignment.center,
        child: child,
      ),
    );
  }

  // شعار عائم مع أنيميشن دخول
  Widget _buildFloatingLogo() {
    return AnimatedBuilder(
      animation: _floatController,
      builder: (context, child) {
        final dy = (_floatController.value - 0.5) * 10;
        return Transform.translate(offset: Offset(0, dy), child: child);
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: darkGreen.withValues(alpha: 0.12),
              blurRadius: 24,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Image.asset(
          'assets/images/logo_tawafuq.png',
          width: 64,
          height: 64,
        ),
      ),
    );
  }

  // محتوى الصفحة ملفوف بأنيميشن دخول (fade + slide)
  Widget _animatedEntrance(Widget child) {
    return FadeTransition(
      opacity: _entranceFade,
      child: SlideTransition(position: _entranceSlide, child: child),
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
  }) {
    return SingleChildScrollView(
      physics: const ClampingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 12),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          minHeight: MediaQuery.of(context).size.height * 0.62,
        ),
        child: _animatedEntrance(
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildFloatingLogo(),
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
              _buildPrimaryButton(
                enabled: value,
                onPressed: _nextPage,
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
            ],
          ),
        ),
      ),
    );
  }

  // الصفحة الأخيرة (الموافقة النهائية)
  Widget _buildFinalPage() {
    bool allPreviousAccepted =
        _acceptedTerms && _acceptedPrivacy && _acceptedDisclaimer;

    return SingleChildScrollView(
      physics: const ClampingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 12),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          minHeight: MediaQuery.of(context).size.height * 0.62,
        ),
        child: _animatedEntrance(
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              TweenAnimationBuilder<double>(
                tween: Tween(begin: 0, end: 1),
                duration: const Duration(milliseconds: 700),
                curve: Curves.elasticOut,
                builder: (context, v, child) {
                  return Transform.scale(scale: v, child: child);
                },
                child: Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: gold.withValues(alpha: 0.22),
                        blurRadius: 26,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Icon(Icons.verified_rounded, color: gold, size: 60),
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
                  setState(() => _finalAccepted = val ?? false);
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
              _buildPrimaryButton(
                enabled: allPreviousAccepted && _finalAccepted,
                onPressed: _finishOnboarding,
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
                      'أوافق وأتابع',
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
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(
        child: Stack(
          children: [
            Positioned.fill(child: _buildAnimatedBackground()),
            Column(
              children: [
                const SizedBox(height: 20),
                // نقاط التقدم مع أنيميشن مرنة
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(
                    4,
                    (index) {
                      final distance = (_pageOffset - index).abs().clamp(0.0, 1.0);
                      final isActive = _currentPage == index;
                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeOutBack,
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        width: isActive ? 26 : 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: Color.lerp(
                            gold,
                            Colors.grey.shade300,
                            distance,
                          ),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 6),
                Expanded(
                  child: PageView(
                    controller: _pageController,
                    physics: const NeverScrollableScrollPhysics(),
                    onPageChanged: (index) {
                      setState(() => _currentPage = index);
                      _replayEntrance();
                    },
                    children: [
                      // الصفحة 1: شروط الاستخدام
                      _buildPage(
                        title: 'شروط الاستخدام',
                        description:
                            'PACT تطبيق رقمي يهدف إلى تسهيل التعارف الجاد الذي ينتهي بالخطبة والزواج، وفق القوانين والقيم المعمول بها.\n'
                            'يرجى قراءة الشروط كاملة قبل المتابعة.',
                        fullText: '''
شروط الاستخدام – PACT

1. طبيعة تطبيق PACT
PACT هو تطبيق رقمي يهدف إلى تسهيل التعارف الجاد بين الأشخاص الراغبين في بناء علاقة تنتهي بالخطبة والزواج، وفق القوانين المعمول بها والقيم الاجتماعية والثقافية السائدة.
التطبيق مخصص للتعارف الجاد، ولا يُقصد به أن يكون منصة للمواعدة العشوائية أو الترفيه أو العلاقات غير الجادة أو المحتوى غير اللائق.
استخدام التطبيق يعني التزام المستخدم بالاحترام والجدية وحسن التعامل مع الطرف الآخر.
ولا تضمن PACT حصول المستخدم على قبول من الطرف الآخر أو استمرار التعارف أو الوصول إلى الخطبة أو الزواج.

2. إنشاء الحساب والمعلومات المقدمة
يلتزم المستخدم عند إنشاء حسابه بتقديم معلومات صحيحة ودقيقة قدر الإمكان، وعدم انتحال شخصية شخص آخر أو استخدام معلومات مضللة عمداً.
يتحمل المستخدم مسؤولية المعلومات التي يضعها في حسابه، وعن أي استخدام غير مشروع أو مسيء للحساب.
في النسخة الحالية من PACT، لا يُعد التطبيق نظاماً رسمياً لإثبات الهوية الشخصية.
وقد تتم إضافة وسائل إضافية للتحقق من الحساب أو تعزيز الأمان مستقبلاً، وفقاً للخصائص التي يتم اعتمادها والقوانين المعمول بها.

3. المحادثات والنقاط
قد يتطلب فتح محادثة أو استخدام بعض خدمات PACT دفع نقاط أو رصيد وفقاً للنظام المعتمد داخل التطبيق.
النقاط أو الرصيد مخصصان للاستفادة من الخدمات الرقمية التي يوفرها التطبيق، ولا يمثل دفع النقاط ضماناً لقبول الطرف الآخر أو استمرار العلاقة أو حدوث لقاء أو خطبة أو زواج.
عند بدء المحادثة واستفادة الطرفين من الخدمة، تخضع عملية الاسترداد للقواعد التقنية المعتمدة داخل النظام.

4. الاسترداد التلقائي
قد يحدد نظام PACT، بشكل آلي، الحالات التي يكون فيها المستخدم مؤهلاً لاسترداد النقاط أو جزء منها، بناءً على قواعد محددة مسبقاً مثل عدم وجود استجابة من الطرف الآخر خلال المدة المحددة، أو تحقق شروط تقنية أخرى تعتمدها PACT.
ولا يعني تقديم المستخدم لطلب استرداد أن الاسترداد سيتم تلقائياً، إذ يخضع ذلك لقواعد النظام وشروط الأهلية المعتمدة.

5. مدة المحادثة
المحادثات داخل PACT قد تكون محددة المدة وفقاً لنظام التطبيق. عند انتهاء المدة، يمكن أن تتوقف المحادثة أو يتم تمديدها وفقاً للخيارات والقواعد المتاحة داخل التطبيق في ذلك الوقت.
وتعتبر مدة المحادثة جزءاً من آلية تنظيم التعارف داخل PACT وليست ضماناً لاستمرار العلاقة بين المستخدمين.

6. طلب اللقاء
قد يوفر PACT للمستخدمين إمكانية الانتقال من مرحلة التعارف داخل التطبيق إلى طلب لقاء في مكان عام ومناسب. يمكن للتطبيق اقتراح بعض الأماكن العامة أو العائلية كخيارات ممكنة للقاء.
هذه الاقتراحات لا تعني وجود شراكة أو ضمان من PACT تجاه المكان، ولا تتحمل PACT مسؤولية جودة خدمات المكان أو الحجز أو الأسعار أو تصرفات العاملين فيه.
وينبغي للمستخدمين اتخاذ احتياطات السلامة المناسبة عند الانتقال إلى لقاء واقعي.

7. الأفعال الممنوعة
يُمنع استخدام PACT في: انتحال شخصية الغير، تقديم عمر أو معلومات شخصية كاذبة بقصد الخداع، التحرش أو التهديد أو الابتزاز، الاحتيال المالي أو طلب الأموال من المستخدمين، نشر أو مشاركة معلومات أو محتوى خاص بشخص آخر دون حق، تسجيل أو نشر المحادثات أو محتوى المستخدمين بصورة مخالفة للشروط، استخدام التطبيق لأغراض غير الزواج أو التعارف الجاد وفق طبيعة PACT، نشر محتوى غير قانوني أو مسيء أو غير لائق، استغلال التطبيق للإضرار بالآخرين أو خداعهم، أو أي استخدام يخالف القوانين المعمول بها.

8. إيقاف أو حظر الحساب
في حالة مخالفة شروط الاستخدام، يمكن لـPACT اتخاذ إجراءات تتناسب مع طبيعة المخالفة، منها: التنبيه، تقييد بعض الخصائص، إيقاف الحساب مؤقتاً أو نهائياً، أو منع إنشاء حسابات مرتبطة بسلوك مسيء أو احتيالي.
وفي الحالات الخطيرة، مثل الاحتيال أو الابتزاز أو انتحال الهوية أو التحرش الجسيم، يمكن اتخاذ إجراءات فورية لحماية المستخدمين والمنصة، وقد يترتب على المخالفات فقدان بعض الخدمات أو المزايا أو النقاط.

9. التحديثات والتغييرات
قد تقوم PACT مستقبلاً بإضافة أو تعديل أو إزالة بعض الخصائص والخدمات، بما في ذلك خصائص الأمان والتحقق وطرق التسجيل والدفع والتواصل. عند إجراء تغييرات جوهرية على الشروط أو السياسة، يمكن تحديث هذه الوثيقة وإبلاغ المستخدمين بالطريقة المناسبة وفقاً لما يقتضيه القانون.

باستخدامك للتطبيق، فإنك تقر بأنك قرأت وفهمت هذه الشروط وتوافق على الالتزام بها.
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
                            'نحرص في PACT على حماية بياناتك الشخصية ومعالجتها وفقاً للتشريع الجزائري المعمول به.\n'
                            'نرجو قراءة سياسة الخصوصية كاملة لمعرفة كيفية جمع بياناتك واستخدامها.',
                        fullText: '''
سياسة الخصوصية – PACT

3. الخصوصية وحماية البيانات
تحرص PACT على حماية البيانات التي يقدمها المستخدم واستخدامها بالقدر اللازم لتشغيل التطبيق وتقديم خدماته وتعزيز الأمان ومكافحة الاحتيال وإساءة الاستخدام.
قد تشمل البيانات التي تتم معالجتها، بحسب الخصائص المستخدمة في التطبيق، معلومات الحساب والملف الشخصي وبيانات الاستخدام والبيانات التقنية وبيانات العمليات والدفع وغيرها من المعلومات اللازمة لتقديم الخدمة.
تتم معالجة البيانات وفقاً للتشريع الجزائري المعمول به في مجال حماية البيانات الشخصية والخصوصية.
ولا يتم استخدام بيانات المستخدم لأغراض تختلف جوهرياً عن الغرض الذي جُمعت من أجله إلا وفقاً لما يسمح به القانون أو بعد الحصول على الموافقات اللازمة عندما تكون مطلوبة.

4. بيانات الموقع الجغرافي
قد يطلب تطبيق PACT الوصول إلى الموقع الجغرافي للمستخدم عند التسجيل أو عند الحاجة إلى تحديد المنطقة التي ينتمي إليها الحساب أو تطبيق نطاق الخدمة.
يُستخدم الموقع الجغرافي للغرض المحدد داخل التطبيق، ولا يعني السماح بالوصول إلى الموقع أن PACT تقوم بتتبع المستخدم بشكل مباشر ومستمر.
وإذا تم اعتماد تحديد الموقع مرة واحدة أثناء التسجيل في النسخة الحالية، فيُستخدم لهذا الغرض دون تشغيل تتبع مباشر مستمر للمستخدم أثناء الاستخدام العادي للتطبيق.
وقد تتغير طريقة استخدام الموقع مستقبلاً عند إضافة خصائص جديدة، مع تحديث الشروط والسياسات عند الحاجة.

14. التعامل مع الجهات المختصة
في الحالات التي يفرض فيها القانون ذلك أو يسمح به، يمكن لـPACT تقديم البيانات ذات الصلة إلى الجهات القضائية أو الجهات المختصة قانوناً، في حدود البيانات اللازمة وللأغراض التي يسمح بها أو يفرضها القانون، مثل التحقيق في الجرائم الإلكترونية أو الاحتيال أو الابتزاز أو التهديد أو غيرها من الحالات القانونية.
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
                            'PACT منصة تقنية لتسهيل التعارف، ولا تُعد طرفاً في العلاقات أو الاتفاقات أو الوعود التي تتم بين المستخدمين.',
                        fullText: '''
إخلاء المسؤولية القانونية – PACT

5. حماية المستخدم ومكافحة إساءة الاستخدام
تسعى PACT إلى توفير بيئة أكثر أماناً وخصوصية للمستخدمين، وقد تستخدم وسائل تقنية وإجراءات داخلية لاكتشاف ومحاولة الحد من: الحسابات الوهمية أو المنتحلة، الاحتيال والخداع، التحرش والمضايقة، التهديد والابتزاز، طلب الأموال أو استغلال المستخدمين مالياً، نشر المعلومات الخاصة للغير، أو أي سلوك يخالف شروط استخدام التطبيق.
يمكن للمستخدم الإبلاغ عن الحسابات أو التصرفات المخالفة من خلال الوسائل التي يوفرها التطبيق.

9. حماية المحتوى ومنع تسجيل الشاشة
تعمل PACT على استخدام الوسائل التقنية المتاحة لمحاولة تقليل إمكانية تسجيل الشاشة أو التقاط محتوى المحادثات أو نسخه، قدر الإمكان ووفقاً لما تسمح به أنظمة التشغيل والأجهزة المستخدمة.
ومع ذلك، لا يمكن ضمان منع تسجيل المحتوى بنسبة 100% في جميع الحالات، خصوصاً عند استخدام جهاز أو وسيلة خارجية لتصوير الشاشة.
ويُمنع المستخدم من تسجيل أو نسخ أو نشر محادثات أو صور أو معلومات تخص مستخدماً آخر دون حق أو إذن، ويُعتبر ذلك مخالفة لشروط الاستخدام وقد يؤدي إلى تقييد الحساب أو إيقافه أو حظره وفقاً لخطورة المخالفة.

11. مسؤولية المستخدم
PACT هي منصة تقنية لتسهيل التعارف ولا تعتبر طرفاً في العلاقة الشخصية أو الاتفاقات أو الوعود التي تتم بين المستخدمين. يتحمل كل مستخدم مسؤولية تصرفاته وقراراته والمعلومات التي يقدمها للطرف الآخر.
وعلى المستخدم عدم إرسال الأموال أو مشاركة المعلومات الحساسة أو الوثائق الخاصة مع أشخاص تعرّف عليهم عبر التطبيق دون التأكد من الحاجة والمخاطر.
ولا تتحمل PACT مسؤولية الوعود أو التصريحات الكاذبة أو النزاعات الشخصية أو الخلافات التي قد تحدث بين المستخدمين، مع احتفاظها بحق اتخاذ الإجراءات المناسبة داخل المنصة عند وجود مخالفة لشروط الاستخدام.

15. حدود مسؤولية PACT
تبذل PACT جهوداً معقولة لتوفير خدمة آمنة ومستقرة، لكنها لا تضمن أن التطبيق سيعمل دون انقطاع أو أخطاء تقنية في جميع الأوقات، كما لا تضمن صحة جميع المعلومات التي يقدمها المستخدمون أو صدق نواياهم أو سلوكهم خارج التطبيق.
ولا تعتبر PACT طرفاً في أي علاقة أو اتفاق أو وعد يتم بين المستخدمين، وتبقى مسؤولية المستخدم قائمة عن قراراته وتصرفاته واختياراته.
ولا يهدف أي بند في هذه الشروط إلى إعفاء PACT من المسؤوليات التي لا يجوز قانوناً استبعادها.
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
          ],
        ),
      ),
    );
  }
}

// ويدجت مساعد: يعطي تأثير ضغط (scale down) لأي عنصر عند اللمس
class _PressableScale extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final double minScale;

  const _PressableScale({
    required this.child,
    required this.onTap,
    this.minScale = 0.96,
  });

  @override
  State<_PressableScale> createState() => _PressableScaleState();
}

class _PressableScaleState extends State<_PressableScale> {
  double _scale = 1;

  void _setPressed(bool pressed) {
    setState(() => _scale = pressed ? widget.minScale : 1);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      onTapDown: widget.onTap == null ? null : (_) => _setPressed(true),
      onTapUp: widget.onTap == null ? null : (_) => _setPressed(false),
      onTapCancel: widget.onTap == null ? null : () => _setPressed(false),
      child: AnimatedScale(
        scale: _scale,
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOut,
        child: widget.child,
      ),
    );
  }
}
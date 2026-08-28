Roudaina Chelloug, [28/08/2026 06:52]
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../pages/location_check_page.dart';

class LegalScreen extends StatefulWidget {
  const LegalScreen({super.key});

  @override
  State<LegalScreen> createState() => _LegalScreenState();
}

class _LegalScreenState extends State<LegalScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  bool _acceptedTerms = false;
  bool _acceptedPrivacy = false;
  bool _acceptedResponsibility = false;

  static const Color darkGreen = Color(0xFF0F3D2E);
  static const Color gold = Color(0xFFC9A24B);

  Future<void> _finishLegal() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('hasAcceptedLegal', true);

    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const LocationCheckPage()),
    );
  }

  void _nextPage() {
    if (_currentPage < 3) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      _finishLegal();
    }
  }

  bool get _allAccepted =>
      _acceptedTerms && _acceptedPrivacy && _acceptedResponsibility;

  Widget _buildPage({
    required IconData icon,
    required String title,
    required String description,
    required bool value,
    required ValueChanged<bool?> onChanged,
    required String checkboxLabel,
    required String buttonLabel,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 28),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 110,
            height: 110,
            decoration: BoxDecoration(
              color: darkGreen.withOpacity(0.08),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 48, color: darkGreen),
          ),
          const SizedBox(height: 28),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 22,
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
          const SizedBox(height: 28),
          Row(
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
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: value ? _nextPage : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: darkGreen,
                disabledBackgroundColor: Colors.grey.shade300,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: Text(
                buttonLabel,
                style: const TextStyle(fontSize: 16, color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFinalPage() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 28),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,

Roudaina Chelloug, [28/08/2026 06:52]
children: [
          Container(
            width: 110,
            height: 110,
            decoration: BoxDecoration(
              color: darkGreen.withOpacity(0.08),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.check_circle_outline,
                size: 48, color: darkGreen),
          ),
          const SizedBox(height: 28),
          const Text(
            'الموافقة النهائية',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: darkGreen,
            ),
          ),
          const SizedBox(height: 20),
          _summaryRow('الشروط والأحكام', _acceptedTerms),
          _summaryRow('سياسة الخصوصية', _acceptedPrivacy),
          _summaryRow('المسؤولية', _acceptedResponsibility),
          const SizedBox(height: 28),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: _allAccepted ? _finishLegal : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: darkGreen,
                disabledBackgroundColor: Colors.grey.shade300,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: const Text(
                'أوافق وأكمل',
                style: TextStyle(fontSize: 16, color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _summaryRow(String label, bool accepted) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(
            accepted ? Icons.check_circle : Icons.radio_button_unchecked,
            color: accepted ? darkGreen : Colors.grey,
            size: 20,
          ),
          const SizedBox(width: 10),
          Text(label, style: const TextStyle(fontSize: 15)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAF7F2),
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                4,
                (index) => AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  width: _currentPage == index ? 22 : 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: _currentPage == index
                        ? gold
                        : Colors.grey.shade300,
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
                  _buildPage(
                    icon: Icons.description_outlined,
                    title: 'الشروط والأحكام',
                    description:
                        'يرجى قراءة الشروط والأحكام بعناية قبل استخدام التطبيق',
                    value: _acceptedTerms,
                    onChanged: (val) {
                      setState(() => _acceptedTerms = val ?? false);
                    },
                    checkboxLabel: 'أوافق على الشروط والأحكام',

Roudaina Chelloug, [28/08/2026 06:52]
buttonLabel: 'متابعة',
                  ),
                  _buildPage(
                    icon: Icons.shield_outlined,
                    title: 'سياسة الخصوصية',
                    description:
                        'نحن نحرص على خصوصيتك وحماية بياناتك وفق أعلى المعايير',
                    value: _acceptedPrivacy,
                    onChanged: (val) {
                      setState(() => _acceptedPrivacy = val ?? false);
                    },
                    checkboxLabel: 'أوافق على سياسة الخصوصية',
                    buttonLabel: 'متابعة',
                  ),
                  _buildPage(
                    icon: Icons.balance_outlined,
                    title: 'المسؤولية',
                    description:
                        'أنت مسؤول عن المعلومات التي تقدمها للاستخدام وفقاً لسياسة التطبيق',
                    value: _acceptedResponsibility,
                    onChanged: (val) {
                      setState(() => _acceptedResponsibility = val ?? false);
                    },
                    checkboxLabel: 'أوافق على المسؤولية',
                    buttonLabel: 'متابعة',
                  ),
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

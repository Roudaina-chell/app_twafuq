// screens/home/home_screen.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../auth/login_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  static const Color darkGreen = Color(0xFF0F3D2E);
  static const Color gold = Color(0xFFC9A24B);
  static const Color bg = Color(0xFFFAF7F2);

  int _selectedIndex = 0;
  bool _isLoading = true;
  String? _errorMessage;

  // بيانات المستخدم
  String _userName = '';
  String? _avatarId;
  int _matches = 0;
  int _messages = 0;
  int _likes = 0;

  // خريطة تحويل avatarId إلى إيموجي
  static const Map<String, String> _avatarMap = {
    'f_1': '👩',
    'f_2': '👱‍♀️',
    'f_3': '👩‍🦱',
    'f_4': '👩‍🦰',
    'f_5': '🧕',
    'f_6': '👩‍🦳',
    'm_1': '👨',
    'm_2': '👱‍♂️',
    'm_3': '👨‍🦱',
    'm_4': '👨‍🦰',
    'm_5': '🧔',
    'm_6': '👨‍🦳',
  };

  Future<void> _loadUserData() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        setState(() {
          _errorMessage = 'المستخدم غير مسجل';
          _isLoading = false;
        });
        return;
      }

      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      if (!doc.exists) {
        setState(() {
          _isLoading = false;
        });
        return;
      }

      final data = doc.data()!;
      setState(() {
        _userName = data['fullName'] ?? data['name'] ?? user.displayName ?? user.email ?? 'مستخدم';
        _avatarId = data['avatarId'] as String?;
        // الإحصاءات وهمية (يمكن جلبها من Firestore لاحقاً)
        _matches = 24;
        _messages = 12;
        _likes = 8;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'حدث خطأ أثناء التحميل';
        _isLoading = false;
      });
    }
  }

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _logout(BuildContext context) async {
    await FirebaseAuth.instance.signOut();
    if (context.mounted) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (route) => false,
      );
    }
  }

  // الحصول على الإيموجي المناسب للأفاتار
  String _getAvatarEmoji() {
    if (_avatarId != null && _avatarMap.containsKey(_avatarId)) {
      return _avatarMap[_avatarId!]!;
    }
    // إذا لم يوجد، نرجع إيموجي افتراضي حسب الجنس (لو مخزن) أو عام
    return '👤';
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: bg,
        body: Center(
          child: CircularProgressIndicator(color: darkGreen),
        ),
      );
    }

    if (_errorMessage != null) {
      return Scaffold(
        backgroundColor: bg,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, color: Colors.red, size: 48),
              const SizedBox(height: 16),
              Text(_errorMessage!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.red)),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _loadUserData,
                style: ElevatedButton.styleFrom(
                  backgroundColor: darkGreen,
                ),
                child: const Text('إعادة المحاولة'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 12),

              // ============================================================
              // HEADER: الأفاتار + الترحيب + أيقونات
              // ============================================================
              Row(
                children: [
                  // الأفاتار مع إطار ذهبي
                  Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: gold, width: 2.5),
                      boxShadow: [
                        BoxShadow(
                          color: gold.withValues(alpha: 0.2),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: CircleAvatar(
                      radius: 32,
                      backgroundColor: darkGreen.withValues(alpha: 0.1),
                      child: Text(
                        _getAvatarEmoji(),
                        style: const TextStyle(fontSize: 36),
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'مرحباً بك 👋',
                          style: TextStyle(
                            color: Colors.grey,
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _userName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: darkGreen,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // أيقونة الإشعارات
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withValues(alpha: 0.1),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.notifications_outlined,
                          color: darkGreen),
                      onPressed: () {
                        // TODO: فتح صفحة الإشعارات
                      },
                    ),
                  ),
                  const SizedBox(width: 4),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withValues(alpha: 0.1),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: IconButton(
                      icon:
                          const Icon(Icons.settings_outlined, color: darkGreen),
                      onPressed: () {
                        // TODO: فتح صفحة الإعدادات
                      },
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // ============================================================
              // بطاقة الإحصاءات (المتوافقين، الرسائل، الإعجابات)
              // ============================================================
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [darkGreen, Color(0xFF1A6B4A)],
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: darkGreen.withValues(alpha: 0.25),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildStatItem('المتوافقين', '$_matches',
                        Icons.people_rounded),
                    _buildStatItem('الرسائل', '$_messages',
                        Icons.chat_rounded),
                    _buildStatItem('الإعجابات', '$_likes',
                        Icons.favorite_rounded),
                  ],
                ),
              ),

              const SizedBox(height: 28),

              // ============================================================
              // عنوان: الخيارات السريعة
              // ============================================================
              const Text(
                'الخيارات السريعة',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: darkGreen,
                ),
              ),
              const SizedBox(height: 14),

              // ============================================================
              // شبكة الخيارات السريعة (4 خيارات)
              // ============================================================
              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 4,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                children: [
                  _buildQuickAction(
                    icon: Icons.person_outline_rounded,
                    label: 'الملف الشخصي',
                    color: Colors.blue.shade700,
                    onTap: () {
                      // TODO: فتح صفحة الملف الشخصي
                    },
                  ),
                  _buildQuickAction(
                    icon: Icons.search_rounded,
                    label: 'البحث',
                    color: darkGreen,
                    onTap: () {
                      // TODO: فتح صفحة البحث
                    },
                  ),
                  _buildQuickAction(
                    icon: Icons.chat_bubble_outline_rounded,
                    label: 'الرسائل',
                    color: Colors.orange.shade700,
                    onTap: () {
                      // TODO: فتح صفحة الرسائل
                    },
                  ),
                  _buildQuickAction(
                    icon: Icons.favorite_outline_rounded,
                    label: 'المفضلة',
                    color: Colors.red.shade400,
                    onTap: () {
                      // TODO: فتح صفحة المفضلة
                    },
                  ),
                ],
              ),

              const SizedBox(height: 28),

              // ============================================================
              // عنوان: أحدث التوصيات
              // ============================================================
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'أحدث التوصيات',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: darkGreen,
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      // TODO: عرض الكل
                    },
                    style: TextButton.styleFrom(
                      foregroundColor: gold,
                    ),
                    child: const Text('عرض الكل'),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // ============================================================
              // قائمة أفقية للتوصيات
              // ============================================================
              SizedBox(
                height: 160,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: 5,
                  itemBuilder: (context, index) {
                    return Container(
                      width: 140,
                      margin: const EdgeInsets.only(right: 12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.withValues(alpha: 0.08),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            height: 90,
                            decoration: BoxDecoration(
                              color: darkGreen.withValues(alpha: 0.06),
                              borderRadius: const BorderRadius.vertical(
                                top: Radius.circular(16),
                              ),
                            ),
                            child: Center(
                              child: Text(
                                ['👨', '👩', '🧑', '👨‍🦱', '👩‍🦰'][index],
                                style: const TextStyle(fontSize: 44),
                              ),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(10),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'شخص ${index + 1}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: darkGreen,
                                    fontSize: 14,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Row(
                                  children: [
                                    const Icon(
                                      Icons.location_on_rounded,
                                      size: 12,
                                      color: Colors.grey,
                                    ),
                                    const SizedBox(width: 2),
                                    Text(
                                      'الجزائر',
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: Colors.grey.shade600,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),

              const SizedBox(height: 20),

              // ============================================================
              // زر تسجيل الخروج (أكثر أناقة)
              // ============================================================
              SizedBox(
                width: double.infinity,
                height: 50,
                child: OutlinedButton.icon(
                  onPressed: () => _logout(context),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: darkGreen.withValues(alpha: 0.2)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    backgroundColor: Colors.white,
                  ),
                  icon: Icon(Icons.logout_rounded,
                      color: darkGreen, size: 20),
                  label: const Text(
                    'تسجيل الخروج',
                    style: TextStyle(
                      color: darkGreen,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),

      // ============================================================
      // شريط التنقل السفلي
      // ============================================================
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withValues(alpha: 0.1),
              blurRadius: 16,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: _selectedIndex,
          onTap: (index) {
            setState(() {
              _selectedIndex = index;
            });
          },
          selectedItemColor: darkGreen,
          unselectedItemColor: Colors.grey.shade400,
          selectedLabelStyle:
              const TextStyle(fontWeight: FontWeight.w600),
          type: BottomNavigationBarType.fixed,
          elevation: 0,
          backgroundColor: Colors.transparent,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.home_rounded),
              label: 'الرئيسية',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.search_rounded),
              label: 'البحث',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.favorite_rounded),
              label: 'المفضلة',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person_rounded),
              label: 'الملف',
            ),
          ],
        ),
      ),
    );
  }

  // دالة مساعدة لعنصر الإحصاء
  Widget _buildStatItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Row(
          children: [
            Icon(icon, color: gold, size: 18),
            const SizedBox(width: 6),
            Text(
              value,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.white.withValues(alpha: 0.7),
          ),
        ),
      ],
    );
  }

  // دالة مساعدة للخيارات السريعة
  Widget _buildQuickAction({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(
              icon,
              color: color,
              size: 28,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: Colors.black87,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
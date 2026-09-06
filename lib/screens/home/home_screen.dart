// screens/home/home_screen.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../auth/login_screen.dart';
import '../profile/profile_edit_screen.dart';
import '../chat/chat_list_tab.dart';
import '../settings/settings_screen.dart';
import 'discover_tab.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _NearbyPerson {
  final String uid;
  final String name;
  final String city;
  final int? age;
  final String? avatarAsset;
  final bool isOnline;
  // ✅ وسم الاهتمام (اختياري) يبان فـ كارت الشبكة (مثلا: تصميم / تكنولوجيا)
  final String? interest;

  const _NearbyPerson({
    required this.uid,
    required this.name,
    required this.city,
    required this.age,
    required this.avatarAsset,
    required this.isOnline,
    this.interest,
  });
}

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  static const Color darkGreen = Color(0xFF0F3D2E);
  static const Color gold = Color(0xFFC9A24B);
  static const Color bg = Color(0xFFFAF7F2);

  List<_NearbyPerson> _nearbyPeople = [];
  bool _isLoadingNearby = true;

  // ✅ 0 = الرئيسية | 1 = الإعجابات (اكتشف) | 2 = الدردشة | 3 = الملف الشخصي
  int _selectedIndex = 0;
  bool _isLoading = true;
  String? _errorMessage;

  // بيانات المستخدم
  String _userName = '';
  String? _avatarAsset;
  String? _myCity;
  int _matches = 0;
  int _messages = 0;
  int _likes = 0;
  int _points = 0;

  // ✅ حالة "متصل الآن" اليدوية (Ghost mode) — دابا كنبدلوها بالضغط
  // المطول/العادي على النقطة الخضراء فوق الأفاتار (شوف _buildHeroHeader)
  bool _isOnline = true;
  bool _isTogglingOnline = false;

  // ✅ TODO: اربطها بعدد الإشعارات غير المقروءة الحقيقي من Firestore
  // (مثلا: collection('notifications').where('seen', isEqualTo:false).count())
  final int _notificationsCount = 0;

  final Set<String> _likedUids = {};

  // ============================================================
  // تحميل بيانات المستخدم
  // ============================================================
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
        _userName =
            data['fullName'] ??
            data['name'] ??
            user.displayName ??
            user.email ??
            'مستخدم';
        _avatarAsset =
            (data['avatarAsset'] as String?) ?? (data['avatarPath'] as String?);
        _myCity = data['city'] as String?;
        _isOnline = data['isOnline'] as bool? ?? true;
        _points = (data['points'] as num?)?.toInt() ?? 0;
        _isLoading = false;
      });

      // ✅ الإحصائيات الحقيقية من Firestore (matches/messages/likes)
      _loadRealStats(user.uid);

      // ✅ الناس القريبين (نفس المدينة)
      if (_myCity != null && _myCity!.isNotEmpty) {
        _loadNearbyPeople(user.uid, _myCity!);
      } else {
        setState(() => _isLoadingNearby = false);
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'حدث خطأ أثناء التحميل';
        _isLoading = false;
      });
    }
  }

  // ============================================================
  // ✅ جلب مستخدمين حقيقيين مسجلين فـ نفس المدينة (city)
  // ============================================================
  Future<void> _loadNearbyPeople(String myUid, String city) async {
    setState(() => _isLoadingNearby = true);
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('users')
          .where('city', isEqualTo: city)
          .limit(15)
          .get();

      final List<_NearbyPerson> people = snapshot.docs
          .where((d) => d.id != myUid)
          .map((d) {
            final data = d.data();
            return _NearbyPerson(
              uid: d.id,
              name:
                  (data['fullName'] as String?) ??
                  (data['name'] as String?) ??
                  'مستخدم',
              city: (data['city'] as String?) ?? city,
              age: (data['age'] as num?)?.toInt(),
              avatarAsset:
                  (data['avatarAsset'] as String?) ??
                  (data['avatarPath'] as String?),
              isOnline: data['isOnline'] == true,
              interest:
                  (data['interest'] as String?) ??
                  (data['profession'] as String?),
            );
          })
          .toList();

      if (mounted) {
        setState(() {
          _nearbyPeople = people;
          _isLoadingNearby = false;
        });
      }
    } catch (e) {
      debugPrint('❌ Nearby people load failed: $e');
      if (mounted) setState(() => _isLoadingNearby = false);
    }
  }

  // ============================================================
  // ✅ يكتب isOnline + lastSeen فـ Firestore (يُستدعى تلقائياً من
  // دورة حياة التطبيق، ويدوياً من نقطة الحالة فوق الأفاتار)
  // ============================================================
  Future<void> _setOnlineStatus(bool online) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    try {
      await FirebaseFirestore.instance.collection('users').doc(uid).set({
        'isOnline': online,
        'lastSeen': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      debugPrint('❌ isOnline update failed: $e');
    }
  }

  Future<void> _toggleOnlineStatus() async {
    if (_isTogglingOnline) return;
    setState(() {
      _isOnline = !_isOnline;
      _isTogglingOnline = true;
    });
    await _setOnlineStatus(_isOnline);
    if (!mounted) return;
    setState(() => _isTogglingOnline = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: darkGreen,
        duration: const Duration(seconds: 2),
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        content: Row(
          children: [
            Icon(
              _isOnline
                  ? Icons.visibility_rounded
                  : Icons.visibility_off_rounded,
              color: gold,
              size: 18,
            ),
            const SizedBox(width: 10),
            Text(
              _isOnline
                  ? 'أنتَ الآن ظاهر للجميع'
                  : 'وضع التخفي مفعّل (Ghost mode)',
              style: const TextStyle(color: Colors.white),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // ✅ إحصائيات حقيقية من Firestore (aggregate count queries)
  // ============================================================
  Future<void> _loadRealStats(String uid) async {
    try {
      final likesQuery = FirebaseFirestore.instance
          .collection('likes')
          .where('toUserId', isEqualTo: uid)
          .count();
      final matchesQuery = FirebaseFirestore.instance
          .collection('matches')
          .where('users', arrayContains: uid)
          .count();
      final messagesQuery = FirebaseFirestore.instance
          .collection('messages')
          .where('toUserId', isEqualTo: uid)
          .count();

      final results = await Future.wait([
        likesQuery.get(),
        matchesQuery.get(),
        messagesQuery.get(),
      ]);

      if (!mounted) return;
      setState(() {
        _likes = results[0].count ?? 0;
        _matches = results[1].count ?? 0;
        _messages = results[2].count ?? 0;
      });
    } catch (e) {
      debugPrint('❌ Real stats load failed: $e');
    }
  }

  // ============================================================
  // ✅ دورة حياة التطبيق
  // ============================================================
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      if (_isOnline) _setOnlineStatus(true);
    } else if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached) {
      _setOnlineStatus(false);
    }
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadUserData();
    _setOnlineStatus(true);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _setOnlineStatus(false);
    super.dispose();
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

  // ============================================================
  // ✅ صورة الأفاتار — تدعم رابط شبكة (Firebase Storage) و asset محلي
  // ولي دابا كتدعم شكلين: دائرة (borderRadius = null، كيفما كان
  // قبل) أو مربع بحواف مدورة من فوق فقط (كارت الشبكة الجديد).
  // ============================================================
  static Widget buildAvatar({
    required String? source,
    required double size,
    required Color fallbackColor,
    BorderRadius? borderRadius,
  }) {
    if (source == null || source.trim().isEmpty) {
      return Icon(Icons.person, size: size * 0.6, color: fallbackColor);
    }

    final isNetwork =
        source.startsWith('http://') || source.startsWith('https://');

    final Widget image = isNetwork
        ? Image.network(
            source,
            fit: BoxFit.cover,
            width: size,
            height: size,
            alignment: Alignment.topCenter,
            loadingBuilder: (context, child, progress) {
              if (progress == null) return child;
              return Center(
                child: SizedBox(
                  width: size * 0.35,
                  height: size * 0.35,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: fallbackColor,
                    value: progress.expectedTotalBytes != null
                        ? (progress.cumulativeBytesLoaded /
                              progress.expectedTotalBytes!)
                        : null,
                  ),
                ),
              );
            },
            errorBuilder: (context, error, stack) {
              debugPrint('❌ Avatar (network) load failed: $source -> $error');
              return Icon(Icons.person, size: size * 0.6, color: fallbackColor);
            },
          )
        : Image.asset(
            source,
            fit: BoxFit.cover,
            width: size,
            height: size,
            alignment: Alignment.topCenter,
            errorBuilder: (context, error, stack) {
              debugPrint('❌ Avatar (asset) load failed: $source -> $error');
              return Icon(Icons.person, size: size * 0.6, color: fallbackColor);
            },
          );

    return SizedBox(
      width: size,
      height: size,
      child: borderRadius == null
          ? ClipOval(child: image)
          : ClipRRect(borderRadius: borderRadius, child: image),
    );
  }

  // ============================================================
  // ✅ يفتح شاشة تعديل الملف الشخصي
  // ============================================================
  Future<void> _openProfile() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const ProfileEditScreen()),
    );
    if (!mounted) return;
    _loadUserData();
  }

  void _onNavTap(int index) {
    if (index == 3) {
      _openProfile();
      return;
    }
    setState(() => _selectedIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: bg,
        body: Center(
          child: CircularProgressIndicator(color: darkGreen, strokeWidth: 2.4),
        ),
      );
    }

    if (_errorMessage != null) {
      return Scaffold(
        backgroundColor: bg,
        body: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(22),
                  decoration: BoxDecoration(
                    color: const Color(0xFFDE3B40).withValues(alpha: 0.08),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.error_outline_rounded,
                    color: Color(0xFFDE3B40),
                    size: 40,
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  _errorMessage!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Color(0xFFDE3B40),
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  height: 52,
                  child: ElevatedButton.icon(
                    onPressed: _loadUserData,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: darkGreen,
                      elevation: 0,
                      shadowColor: darkGreen.withValues(alpha: 0.4),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 26),
                    ),
                    icon: const Icon(
                      Icons.refresh_rounded,
                      color: Colors.white,
                    ),
                    label: const Text(
                      'إعادة المحاولة',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
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

    return Scaffold(
      backgroundColor: bg,
      extendBody: true,
      body: SafeArea(
        bottom: false,
        child: IndexedStack(
          index: _selectedIndex,
          children: [
            _buildHomeTab(),
            const DiscoverTab(),
            const ChatsListTab(),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  // ============================================================
  // محتوى تبويب "الرئيسية" — هيدر "hero" بصورة خلفية، بطاقة
  // إحصائيات "عائمة" فوق حده، وبعدها شبكة (Grid) لـ 3 أعمدة
  // للأشخاص المقترحين بدل الكاروسيل القديم.
  // ============================================================
  Widget _buildHomeTab() {
    return RefreshIndicator(
      color: darkGreen,
      onRefresh: _loadUserData,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.zero,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeroHeader(),
            Transform.translate(
              offset: const Offset(0, -34),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: _buildStatsCard(),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSearchBar(),
                  const SizedBox(height: 26),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'الأشخاص المقترحون لك',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: darkGreen,
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          // TODO: فتح صفحة كل الأشخاص المقترحين
                        },
                        style: TextButton.styleFrom(
                          padding: EdgeInsets.zero,
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        child: Text(
                          'عرض الكل',
                          style: TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w700,
                            color: Colors.grey.shade500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            _buildNearbyGrid(),
            const SizedBox(height: 26),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Center(
                child: TextButton.icon(
                  onPressed: () => _logout(context),
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.grey.shade500,
                  ),
                  icon: const Icon(Icons.logout_rounded, size: 17),
                  label: const Text(
                    'تسجيل الخروج',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 13.5,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 90),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // 🟢 HERO HEADER: خلفية خضراء غامقة صافية (بلا صورة) للجزء
  // العلوي (أفاتار/ترحيب/أيقونات)، وتحتها كارت مستقل بخلفية صورة
  // طبيعة (assets/images/hero_nature.jpg) فيه جملة الترحيب، بحواف
  // سفلية مدورة للهيدر كامل.
  // ============================================================
  Widget _buildHeroHeader() {
    return ClipRRect(
      borderRadius: const BorderRadius.only(
        bottomLeft: Radius.circular(36),
        bottomRight: Radius.circular(36),
      ),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 56),
        color: darkGreen,
        child: Stack(
          children: [
            // ✅ زخرفة دوائر خفيفة فوق الأخضر الصافي (تكسر الفراغ
            // بلا ما تأثر على قراءة النص)
            Positioned(
              top: -40,
              left: -30,
              child: Container(
                width: 140,
                height: 140,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.04),
                ),
              ),
            ),
            Positioned(
              top: 30,
              right: -20,
              child: Container(
                width: 90,
                height: 90,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: gold.withValues(alpha: 0.07),
                ),
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    GestureDetector(
                      onTap: _openProfile,
                      child: Stack(
                        clipBehavior: Clip.none,
                        children: [
                          Container(
                            width: 54,
                            height: 54,
                            padding: const EdgeInsets.all(2.5),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: gold.withValues(alpha: 0.85),
                                width: 1.6,
                              ),
                            ),
                            child: Container(
                              decoration: const BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.white,
                              ),
                              child: buildAvatar(
                                source: _avatarAsset,
                                size: 49,
                                fallbackColor: darkGreen,
                              ),
                            ),
                          ),
                          // ✅ نقطة الحالة: ضغطة عليها كتبدل الحالة
                          // (ظاهر / وضع التخفي) بدل زر العين لي كان
                          // فوق فـ الهيدر
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: GestureDetector(
                              onTap: _toggleOnlineStatus,
                              child: Container(
                                width: 13,
                                height: 13,
                                decoration: BoxDecoration(
                                  color: _isOnline
                                      ? Colors.green.shade400
                                      : Colors.grey.shade400,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: darkGreen,
                                    width: 2,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'مرحباً بك 👋',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.7),
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            _userName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                    _HeroIconButton(
                      icon: Icons.search_rounded,
                      onTap: () {
                        // TODO: فتح شاشة بحث مخصصة، أو ركّز شريط
                        // البحث لي تحت (_buildSearchBar)
                      },
                    ),
                    const SizedBox(width: 8),
                    _HeroNotificationButton(
                      count: _notificationsCount,
                      onTap: () {
                        // TODO: فتح صفحة الإشعارات
                      },
                    ),
                    const SizedBox(width: 8),
                    _HeroIconButton(
                      icon: Icons.settings_rounded,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const SettingsScreen(),
                          ),
                        );
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                _buildHeroNatureCard(),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // 🌿 كارت الطبيعة الداخلي — الصورة (hero_nature.jpg) فيها البلاصة
  // النص "كل شيء جميل يبدأ من هنا" + القلب مدمجين معاها من الأصل،
  // فـ الكود هنا كيعرض الصورة فقط (بلا ما يرسم نص فوقها مرة أخرى)
  // ويحترم النسبة الحقيقية ديال الصورة (3:1) باش ما يقصّها.
  // ============================================================
  Widget _buildHeroNatureCard() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(28),
      child: AspectRatio(
        aspectRatio: 3, // ✅ نفس نسبة صورة hero_nature.jpg (2172x724)
        child: Image.asset(
          'assets/images/hero_nature.jpg',
          fit: BoxFit.cover,
          errorBuilder: (context, error, stack) => Container(
            color: darkGreen.withValues(alpha: 0.15),
            alignment: Alignment.center,
            child: Icon(
              Icons.image_not_supported_rounded,
              color: darkGreen.withValues(alpha: 0.4),
              size: 28,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      height: 54,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.grey.shade100),
        boxShadow: [
          BoxShadow(
            color: darkGreen.withValues(alpha: 0.06),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          Icon(Icons.search_rounded, color: darkGreen.withValues(alpha: 0.6)),
          const SizedBox(width: 10),
          Expanded(
            child: TextField(
              textAlign: TextAlign.right,
              decoration: InputDecoration(
                border: InputBorder.none,
                hintText: 'ابحث عن شخص...',
                hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // 🃏 بطاقات الإحصائيات — 3 كروت بيضاء منفصلة "عائمة" فوق حد
  // الهيدر (بدل كارت واحد بفواصل)، وأيقونة ذهبية مسطحة بلا خلفية
  // دائرية، بحال التصميم المرجعي بالضبط
  // ============================================================
  Widget _buildStatsCard() {
    return Row(
      children: [
        Expanded(
          child: _buildStatItem(
            'المتابعين',
            '$_matches',
            Icons.people_alt_outlined,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _buildStatItem(
            'الرسائل',
            '$_messages',
            Icons.chat_bubble_outline_rounded,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _buildStatItem(
            'الإعجابات',
            '$_likes',
            Icons.favorite_border_rounded,
          ),
        ),
      ],
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: darkGreen.withValues(alpha: 0.10),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(icon, color: gold, size: 22),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: darkGreen,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(fontSize: 10.5, color: Colors.grey.shade500),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // ✅ شبكة (Grid) 3 أعمدة "أشخاص مقترحون" — بدل الكاروسيل الأفقي
  // القديم. كل كارت: صورة مربعة + اسم/عمر + مدينة + وسم اهتمام
  // ============================================================
  Widget _buildNearbyGrid() {
    if (_isLoadingNearby) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 30),
        child: Center(
          child: CircularProgressIndicator(color: darkGreen, strokeWidth: 2.4),
        ),
      );
    }
    if (_nearbyPeople.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 30),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.grey.shade100),
          ),
          child: Column(
            children: [
              Icon(
                Icons.people_outline_rounded,
                color: Colors.grey.shade300,
                size: 34,
              ),
              const SizedBox(height: 10),
              Text(
                'ماكاين حتى حد فـ نفس مدينتك دابا',
                style: TextStyle(color: Colors.grey.shade500, fontSize: 13),
              ),
            ],
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: _nearbyPeople.length,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          crossAxisSpacing: 10,
          mainAxisSpacing: 14,
          childAspectRatio: 0.62,
        ),
        itemBuilder: (context, index) {
          final person = _nearbyPeople[index];
          return _SuggestedGridCard(
            person: person,
            darkGreen: darkGreen,
            gold: gold,
            isLiked: _likedUids.contains(person.uid),
            onLikeTap: () {
              setState(() {
                if (_likedUids.contains(person.uid)) {
                  _likedUids.remove(person.uid);
                } else {
                  _likedUids.add(person.uid);
                }
              });
            },
            onViewProfile: () {
              // TODO: فتح صفحة الملف الشخصي لهذا الشخص
            },
          );
        },
      ),
    );
  }

  // ============================================================
  // ✅ شريط تنقل سفلي: العنصر المختار عندو خلفية بيضاوية ملونة،
  // وتاب "المحادثات" عندو badge أحمر بعدد الرسائل غير المقروءة
  // ============================================================
  Widget _buildBottomNav() {
    final items = <_NavItemData>[
      _NavItemData(icon: Icons.home_rounded, label: 'الرئيسية'),
      _NavItemData(icon: Icons.favorite_rounded, label: 'الإعجابات'),
      _NavItemData(icon: Icons.chat_bubble_rounded, label: 'الدردشة'),
      _NavItemData(icon: Icons.person_rounded, label: 'ملفي'),
    ];

    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 14),
        decoration: BoxDecoration(
          color: darkGreen,
          borderRadius: BorderRadius.circular(26),
          boxShadow: [
            BoxShadow(
              color: darkGreen.withValues(alpha: 0.32),
              blurRadius: 22,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: List.generate(items.length, (index) {
            final selected = _selectedIndex == index;
            final isProfile = index == 3;
            return GestureDetector(
              onTap: () => _onNavTap(index),
              behavior: HitTestBehavior.opaque,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                padding: EdgeInsets.symmetric(
                  horizontal: selected ? 16 : 10,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: selected ? gold : Colors.transparent,
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    isProfile
                        ? _buildProfileNavIcon(selected)
                        : _buildNavIconWithBadge(
                            index,
                            items[index].icon,
                            selected,
                          ),
                    if (selected) ...[
                      const SizedBox(width: 7),
                      Text(
                        items[index].label,
                        style: const TextStyle(
                          color: darkGreen,
                          fontWeight: FontWeight.w800,
                          fontSize: 12.5,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            );
          }),
        ),
      ),
    );
  }

  // ✅ أيقونة الدردشة عندها badge أحمر بعدد الرسائل إلا كانت > 0
  Widget _buildNavIconWithBadge(int index, IconData icon, bool selected) {
    final iconWidget = Icon(
      icon,
      color: selected ? darkGreen : Colors.white.withValues(alpha: 0.55),
      size: 22,
    );
    if (index == 2 && _messages > 0) {
      return Stack(
        clipBehavior: Clip.none,
        children: [
          iconWidget,
          Positioned(
            top: -4,
            right: -8,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
              constraints: const BoxConstraints(minWidth: 15),
              decoration: BoxDecoration(
                color: Colors.red.shade400,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: darkGreen, width: 1.3),
              ),
              child: Text(
                _messages > 9 ? '9+' : '$_messages',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 8,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
        ],
      );
    }
    return iconWidget;
  }

  Widget _buildProfileNavIcon(bool selected) {
    return Container(
      width: 22,
      height: 22,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: selected ? darkGreen : Colors.white.withValues(alpha: 0.55),
          width: 1.6,
        ),
      ),
      child: buildAvatar(
        source: _avatarAsset,
        size: 22,
        fallbackColor: selected
            ? darkGreen
            : Colors.white.withValues(alpha: 0.55),
      ),
    );
  }
}

// ============================================================
// عنصر مساعد: زر أيقونة دائري شفاف يستعمل فوق الهيدر
// ============================================================
class _HeroIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _HeroIconButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.14),
        shape: BoxShape.circle,
      ),
      child: IconButton(
        icon: Icon(icon, color: Colors.white, size: 19),
        onPressed: onTap,
        padding: const EdgeInsets.all(8),
        constraints: const BoxConstraints(),
      ),
    );
  }
}

class _NavItemData {
  final IconData icon;
  final String label;
  const _NavItemData({required this.icon, required this.label});
}

// ============================================================
// زر "الإشعارات" فوق الهيدر — دائرة شفافة + عداد أحمر بعدد
// الإشعارات غير المقروءة (بحال بادج الدردشة فـ الشريط السفلي)
// ============================================================
class _HeroNotificationButton extends StatelessWidget {
  final int count;
  final VoidCallback onTap;

  const _HeroNotificationButton({required this.count, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.14),
              shape: BoxShape.circle,
            ),
            child: IconButton(
              icon: const Icon(
                Icons.notifications_none_rounded,
                color: Colors.white,
                size: 19,
              ),
              onPressed: onTap,
              padding: const EdgeInsets.all(8),
              constraints: const BoxConstraints(),
            ),
          ),
          if (count > 0)
            Positioned(
              top: -2,
              right: -4,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                constraints: const BoxConstraints(minWidth: 16),
                decoration: BoxDecoration(
                  color: Colors.red.shade400,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: const Color(0xFF0F3D2E),
                    width: 1.3,
                  ),
                ),
                child: Text(
                  count > 9 ? '9+' : '$count',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 9,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ============================================================
// كارت الشبكة "شخص مقترح" — صورة مربعة فوق، وتحتها الاسم/العمر،
// المدينة، ووسم اهتمام صغير (إلا كان موجود)
// ============================================================
class _SuggestedGridCard extends StatelessWidget {
  final _NearbyPerson person;
  final Color darkGreen;
  final Color gold;
  final bool isLiked;
  final VoidCallback onLikeTap;
  final VoidCallback onViewProfile;

  const _SuggestedGridCard({
    required this.person,
    required this.darkGreen,
    required this.gold,
    required this.isLiked,
    required this.onLikeTap,
    required this.onViewProfile,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onViewProfile,
      child: Container(
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: darkGreen.withValues(alpha: 0.08),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              children: [
                AspectRatio(
                  aspectRatio: 1,
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      return _HomeScreenState.buildAvatar(
                        source: person.avatarAsset,
                        size: constraints.maxWidth,
                        fallbackColor: Colors.grey.shade300,
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(16),
                        ),
                      );
                    },
                  ),
                ),
                if (person.isOnline)
                  Positioned(
                    top: 8,
                    left: 8,
                    child: Container(
                      width: 9,
                      height: 9,
                      decoration: BoxDecoration(
                        color: Colors.green.shade400,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 1.5),
                      ),
                    ),
                  ),
                Positioned(
                  top: 6,
                  right: 6,
                  child: GestureDetector(
                    onTap: onLikeTap,
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.92),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        isLiked
                            ? Icons.favorite_rounded
                            : Icons.favorite_border_rounded,
                        size: 13,
                        color: isLiked ? Colors.red.shade400 : darkGreen,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 8, 8, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    person.age != null
                        ? '${person.name}، ${person.age}'
                        : person.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 12,
                      color: darkGreen,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Row(
                    children: [
                      Icon(Icons.location_on_rounded, size: 10, color: gold),
                      const SizedBox(width: 2),
                      Expanded(
                        child: Text(
                          person.city,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 9.5,
                            color: Colors.grey.shade500,
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (person.interest != null &&
                      person.interest!.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: gold.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        person.interest!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                          color: darkGreen,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

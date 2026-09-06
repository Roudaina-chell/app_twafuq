// screens/home/home_screen.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../auth/login_screen.dart';
import '../profile/profile_edit_screen.dart';
import '../chat/chat_list_tab.dart';
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

  const _NearbyPerson({
    required this.uid,
    required this.name,
    required this.city,
    required this.age,
    required this.avatarAsset,
    required this.isOnline,
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

  // ✅ حالة "متصل الآن" اليدوية (Ghost mode)
  bool _isOnline = true;
  bool _isTogglingOnline = false;

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
  // دورة حياة التطبيق، ويدوياً من زر Ghost mode)
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
  // هذا هو الإصلاح: قبل كان الكود يستعمل Image.asset بشكل دائم حتى
  // إلا كان avatarAsset فـ الحقيقة رابط http (من Firebase Storage) ،
  // ولي كان كيبان errorBuilder ويرجع للأيقونة الافتراضية بصمت.
  // ============================================================
  static Widget buildAvatar({
    required String? source,
    required double size,
    required Color fallbackColor,
  }) {
    if (source == null || source.trim().isEmpty) {
      return Icon(Icons.person, size: size * 0.6, color: fallbackColor);
    }

    final isNetwork =
        source.startsWith('http://') || source.startsWith('https://');

    return ClipOval(
      child: SizedBox(
        width: size,
        height: size,
        child: isNetwork
            ? Image.network(
                source,
                fit: BoxFit.cover,
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
                  debugPrint(
                    '❌ Avatar (network) load failed: $source -> $error',
                  );
                  return Icon(
                    Icons.person,
                    size: size * 0.6,
                    color: fallbackColor,
                  );
                },
              )
            : Image.asset(
                source,
                fit: BoxFit.cover,
                alignment: Alignment.topCenter,
                errorBuilder: (context, error, stack) {
                  debugPrint('❌ Avatar (asset) load failed: $source -> $error');
                  return Icon(
                    Icons.person,
                    size: size * 0.6,
                    color: fallbackColor,
                  );
                },
              ),
      ),
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
  // محتوى تبويب "الرئيسية" — تصميم جديد كليا: هيدر "hero" أخضر
  // بحواف سفلية مدورة، بطاقة إحصائيات "عائمة" فوق حده، وبعدها
  // كاروسيل أفقي للأشخاص المقترحين بدل الشبكة القديمة.
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
                      Row(
                        children: [
                          Container(
                            width: 4,
                            height: 18,
                            decoration: BoxDecoration(
                              color: gold,
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Text(
                            'أشخاص مقترحون',
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w800,
                              color: darkGreen,
                            ),
                          ),
                        ],
                      ),
                      Text(
                        '${_nearbyPeople.length}',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: Colors.grey.shade400,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            _buildNearbyCarousel(),
            const SizedBox(height: 26),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Center(
                child: TextButton.icon(
                  onPressed: () => _logout(context),
                  style: TextButton.styleFrom(foregroundColor: Colors.grey.shade500),
                  icon: const Icon(Icons.logout_rounded, size: 17),
                  label: const Text(
                    'تسجيل الخروج',
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13.5),
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
  // 🟢 HERO HEADER: قسم أخضر بحواف سفلية مدورة يحتوي الأفاتار،
  // الترحيب، أزرار سريعة، والشعار — كليا مختلف عن الهيدر الأبيض
  // القديم.
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
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [darkGreen, Color(0xFF1A6B4A)],
          ),
        ),
        child: Stack(
          children: [
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
                          Positioned(
                            bottom: 0,
                            right: 0,
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
                      icon: _isOnline
                          ? Icons.visibility_rounded
                          : Icons.visibility_off_rounded,
                      onTap: _toggleOnlineStatus,
                    ),
                    const SizedBox(width: 8),
                    _HeroPointsButton(points: _points, gold: gold, onTap: () {
                      // TODO: فتح صفحة النقاط / المتجر
                    }),
                    const SizedBox(width: 8),
                    _HeroIconButton(
                      icon: Icons.settings_outlined,
                      onTap: () {
                        // TODO: فتح صفحة الإعدادات
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 22),
                RichText(
                  text: const TextSpan(
                    children: [
                      TextSpan(
                        text: 'ابحث عن شخص يشاركك الاهتمامات ',
                        style: TextStyle(
                          fontSize: 19,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                          height: 1.4,
                        ),
                      ),
                      TextSpan(text: '✨', style: TextStyle(fontSize: 18)),
                    ],
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'اكتشف أشخاص جدد وتعرّف عليهم',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.white.withValues(alpha: 0.65),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ],
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
  // 🃏 بطاقة الإحصائيات — دابا بيضاء "عائمة" فوق حد الهيدر الأخضر
  // (بدل ما كانت هي نفسها خضراء بالكامل)
  // ============================================================
  Widget _buildStatsCard() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: darkGreen.withValues(alpha: 0.14),
            blurRadius: 26,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatItem('المتوافقين', '$_matches', Icons.people_rounded),
          _statDivider(),
          _buildStatItem('الرسائل', '$_messages', Icons.chat_rounded),
          _statDivider(),
          _buildStatItem('الإعجابات', '$_likes', Icons.favorite_rounded),
        ],
      ),
    );
  }

  Widget _statDivider() {
    return Container(width: 1, height: 34, color: Colors.grey.shade100);
  }

  Widget _buildStatItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(9),
          decoration: BoxDecoration(
            color: gold.withValues(alpha: 0.12),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: gold, size: 16),
        ),
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
    );
  }

  // ============================================================
  // ✅ كاروسيل أفقي "أشخاص مقترحون" — كليا مختلف عن الشبكة القديمة
  // ============================================================
  Widget _buildNearbyCarousel() {
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

    return SizedBox(
      height: 226,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: _nearbyPeople.length,
        separatorBuilder: (_, __) => const SizedBox(width: 14),
        itemBuilder: (context, index) {
          final person = _nearbyPeople[index];
          return _SuggestedCarouselCard(
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
  // ✅ شريط تنقل سفلي جديد كليا: شريط مسطح بحواف مدورة، كل عنصر
  // فيه أيقونة + تسمية، والعنصر المختار عندو خلفية بيضاوية ملونة
  // (بدل المؤشر الدائري المتحرك القديم).
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
                        : Icon(
                            items[index].icon,
                            color: selected
                                ? darkGreen
                                : Colors.white.withValues(alpha: 0.55),
                            size: 22,
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
        fallbackColor: selected ? darkGreen : Colors.white.withValues(alpha: 0.55),
      ),
    );
  }
}

// ============================================================
// عنصر مساعد: زر أيقونة دائري شفاف يستعمل فوق الهيدر الأخضر
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
// زر "النقاط" فوق الهيدر الأخضر — دائرة شفافة + badge ذهبي بعدد
// النقاط الحالي
// ============================================================
class _HeroPointsButton extends StatelessWidget {
  final int points;
  final Color gold;
  final VoidCallback onTap;

  const _HeroPointsButton({
    required this.points,
    required this.gold,
    required this.onTap,
  });

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
                Icons.shopping_basket_rounded,
                color: Colors.white,
                size: 19,
              ),
              onPressed: onTap,
              padding: const EdgeInsets.all(8),
              constraints: const BoxConstraints(),
            ),
          ),
          if (points > 0)
            Positioned(
              top: -4,
              left: -4,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                constraints: const BoxConstraints(minWidth: 18),
                decoration: BoxDecoration(
                  color: gold,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFF0F3D2E), width: 1.5),
                ),
                child: Text(
                  points > 99 ? '99+' : '$points',
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
// كارت الكاروسيل الأفقي "شخص مقترح" — صورة كبيرة فوق تاخد أغلب
// الكارت، تدرج غامق أسفلها للنص، بدل الكارت الصغير المربع القديم
// ============================================================
class _SuggestedCarouselCard extends StatelessWidget {
  final _NearbyPerson person;
  final Color darkGreen;
  final Color gold;
  final bool isLiked;
  final VoidCallback onLikeTap;
  final VoidCallback onViewProfile;

  const _SuggestedCarouselCard({
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
        width: 148,
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: darkGreen.withValues(alpha: 0.9),
          borderRadius: BorderRadius.circular(22),
          boxShadow: [
            BoxShadow(
              color: darkGreen.withValues(alpha: 0.2),
              blurRadius: 16,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Stack(
          fit: StackFit.expand,
          children: [
            _HomeScreenState.buildAvatar(
              source: person.avatarAsset,
              size: 148,
              fallbackColor: Colors.white70,
            ),
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.transparent,
                      darkGreen.withValues(alpha: 0.85),
                      darkGreen.withValues(alpha: 0.96),
                    ],
                    stops: const [0.0, 0.45, 0.8, 1.0],
                  ),
                ),
              ),
            ),
            Positioned(
              top: 10,
              right: 10,
              child: GestureDetector(
                onTap: onLikeTap,
                child: Container(
                  padding: const EdgeInsets.all(7),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.9),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    isLiked
                        ? Icons.favorite_rounded
                        : Icons.favorite_border_rounded,
                    size: 15,
                    color: isLiked ? Colors.red.shade400 : darkGreen,
                  ),
                ),
              ),
            ),
            if (person.isOnline)
              Positioned(
                top: 12,
                left: 10,
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
              left: 12,
              right: 12,
              bottom: 12,
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
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      fontSize: 13.5,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Row(
                    children: [
                      Icon(Icons.location_on_rounded, size: 11, color: gold),
                      const SizedBox(width: 2),
                      Expanded(
                        child: Text(
                          person.city,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 10.5,
                            color: Colors.white.withValues(alpha: 0.75),
                          ),
                        ),
                      ),
                    ],
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
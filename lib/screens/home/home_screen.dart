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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
        body: Center(child: CircularProgressIndicator(color: darkGreen)),
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
                  padding: const EdgeInsets.all(20),
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
                const SizedBox(height: 18),
                Text(
                  _errorMessage!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Color(0xFFDE3B40),
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 22),
                SizedBox(
                  height: 50,
                  child: ElevatedButton.icon(
                    onPressed: _loadUserData,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: darkGreen,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                    ),
                    icon: const Icon(
                      Icons.refresh_rounded,
                      color: Colors.white,
                    ),
                    label: const Text(
                      'إعادة المحاولة',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
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
      bottomNavigationBar: _buildWowBottomNav(),
    );
  }

  // ============================================================
  // محتوى تبويب "الرئيسية"
  // ============================================================
  Widget _buildHomeTab() {
    return RefreshIndicator(
      color: darkGreen,
      onRefresh: _loadUserData,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 12),
            _buildHeader(),
            const SizedBox(height: 24),
            _buildTagline(),
            const SizedBox(height: 18),
            _buildStatsCard(),
            const SizedBox(height: 18),
            _buildSearchBar(),
            const SizedBox(height: 26),
            const Text(
              'أشخاص مقترحون',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w800,
                color: darkGreen,
              ),
            ),
            const SizedBox(height: 14),
            _buildNearbyGrid(),
            const SizedBox(height: 22),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: OutlinedButton.icon(
                onPressed: () => _logout(context),
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: darkGreen.withValues(alpha: 0.18)),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  backgroundColor: Colors.white,
                ),
                icon: const Icon(
                  Icons.logout_rounded,
                  color: darkGreen,
                  size: 19,
                ),
                label: const Text(
                  'تسجيل الخروج',
                  style: TextStyle(
                    color: darkGreen,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 100),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // HEADER: الأفاتار + الترحيب + جرس الإشعارات + الإعدادات
  // ============================================================
  Widget _buildHeader() {
    return Row(
      children: [
        GestureDetector(
          onTap: _openProfile,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: darkGreen.withValues(alpha: 0.08),
                ),
                child: buildAvatar(
                  source: _avatarAsset,
                  size: 60,
                  fallbackColor: darkGreen,
                ),
              ),
              Positioned(
                bottom: 1,
                right: 1,
                child: Container(
                  width: 14,
                  height: 14,
                  decoration: BoxDecoration(
                    color: _isOnline
                        ? Colors.green.shade500
                        : Colors.grey.shade400,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2.5),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'مرحباً بك 👋',
                style: TextStyle(color: Colors.black45, fontSize: 12.5),
              ),
              const SizedBox(height: 2),
              Text(
                _userName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: darkGreen,
                ),
              ),
            ],
          ),
        ),
        _CircleIconButton(
          icon: _isOnline
              ? Icons.visibility_rounded
              : Icons.visibility_off_rounded,
          iconColor: _isOnline ? darkGreen : Colors.grey.shade500,
          onTap: _toggleOnlineStatus,
        ),
        const SizedBox(width: 8),
        _PointsBasketButton(
          points: _points,
          darkGreen: darkGreen,
          gold: gold,
          onTap: () {
            // TODO: فتح صفحة النقاط / المتجر
          },
        ),
        const SizedBox(width: 8),
        _CircleIconButton(
          icon: Icons.settings_outlined,
          iconColor: darkGreen,
          onTap: () {
            // TODO: فتح صفحة الإعدادات (اللغة، الفوترة، إلخ)
          },
        ),
      ],
    );
  }

  Widget _buildTagline() {
    return SizedBox(
      width: double.infinity,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          RichText(
            textAlign: TextAlign.center,
            text: const TextSpan(
              children: [
                TextSpan(
                  text: 'ابحث عن شخص يشاركك الاهتمامات ',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: darkGreen,
                  ),
                ),
                TextSpan(text: '✨', style: TextStyle(fontSize: 18)),
              ],
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'اكتشف أشخاص جدد وتعرّف عليهم',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13.5, color: Colors.grey.shade600),
          ),
        ],
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
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.12),
            blurRadius: 14,
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

  Widget _buildStatsCard() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 22, horizontal: 16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [darkGreen, Color(0xFF1A6B4A)],
        ),
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: darkGreen.withValues(alpha: 0.28),
            blurRadius: 22,
            offset: const Offset(0, 10),
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
    return Container(
      width: 1,
      height: 34,
      color: Colors.white.withValues(alpha: 0.18),
    );
  }

  // ============================================================
  // ✅ شبكة "أشخاص مقترحون" — 3 أعمدة، بنفس شكل الصورة المرجعية
  // ============================================================
  Widget _buildNearbyGrid() {
    if (_isLoadingNearby) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 30),
        child: Center(child: CircularProgressIndicator(color: darkGreen)),
      );
    }
    if (_nearbyPeople.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 30),
        child: Center(
          child: Column(
            children: [
              Icon(
                Icons.people_outline_rounded,
                color: Colors.grey.shade300,
                size: 36,
              ),
              const SizedBox(height: 8),
              Text(
                'ماكاين حتى حد فـ نفس مدينتك دابا',
                style: TextStyle(color: Colors.grey.shade500, fontSize: 13),
              ),
            ],
          ),
        ),
      );
    }

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _nearbyPeople.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 10,
        mainAxisSpacing: 14,
        childAspectRatio: 0.6,
      ),
      itemBuilder: (context, index) {
        final person = _nearbyPeople[index];
        return _SuggestedCard(
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
    );
  }

  // ============================================================
  // ✅ شريط التنقل السفلي — عائم، بحواف مدورة، مع مؤشر متحرك
  // ============================================================
  Widget _buildWowBottomNav() {
    final items = <_NavItemData>[
      _NavItemData(icon: Icons.home_rounded, label: 'الرئيسية'),
      _NavItemData(icon: Icons.favorite_rounded, label: 'الإعجابات'),
      _NavItemData(icon: Icons.chat_bubble_rounded, label: 'الدردشة'),
      _NavItemData(icon: Icons.person_rounded, label: 'ملفي'),
    ];

    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
        child: Container(
          height: 68,
          padding: const EdgeInsets.symmetric(horizontal: 10),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(28),
            boxShadow: [
              BoxShadow(
                color: darkGreen.withValues(alpha: 0.15),
                blurRadius: 24,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final itemWidth = constraints.maxWidth / items.length;
              return Stack(
                alignment: Alignment.centerLeft,
                children: [
                  AnimatedPositioned(
                    duration: const Duration(milliseconds: 280),
                    curve: Curves.easeOutCubic,
                    left: itemWidth * _selectedIndex,
                    top: 8,
                    child: Container(
                      width: itemWidth,
                      height: 52,
                      alignment: Alignment.center,
                      child: Container(
                        width: 52,
                        height: 52,
                        decoration: BoxDecoration(
                          color: darkGreen,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: darkGreen.withValues(alpha: 0.35),
                              blurRadius: 14,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  Row(
                    children: List.generate(items.length, (index) {
                      final selected = _selectedIndex == index;
                      final isProfile = index == 3;
                      return SizedBox(
                        width: itemWidth,
                        child: InkWell(
                          onTap: () => _onNavTap(index),
                          customBorder: const CircleBorder(),
                          child: SizedBox(
                            height: 68,
                            child: Center(
                              child: isProfile
                                  ? _buildProfileNavIcon(selected)
                                  : AnimatedScale(
                                      duration: const Duration(
                                        milliseconds: 200,
                                      ),
                                      scale: selected ? 1.0 : 0.92,
                                      child: Icon(
                                        items[index].icon,
                                        color: selected
                                            ? Colors.white
                                            : Colors.grey.shade400,
                                        size: 24,
                                      ),
                                    ),
                            ),
                          ),
                        ),
                      );
                    }),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildProfileNavIcon(bool selected) {
    return AnimatedScale(
      duration: const Duration(milliseconds: 200),
      scale: selected ? 1.0 : 0.92,
      child: Container(
        width: 30,
        height: 30,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: selected ? Colors.white : gold.withValues(alpha: 0.6),
            width: 2,
          ),
        ),
        child: buildAvatar(
          source: _avatarAsset,
          size: 30,
          fallbackColor: selected ? Colors.white : Colors.grey.shade400,
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: gold, size: 17),
            const SizedBox(width: 6),
            Text(
              value,
              style: const TextStyle(
                fontSize: 19,
                fontWeight: FontWeight.w800,
                color: Colors.white,
              ),
            ),
          ],
        ),
        const SizedBox(height: 5),
        Text(
          label,
          style: TextStyle(
            fontSize: 11.5,
            color: Colors.white.withValues(alpha: 0.75),
          ),
        ),
      ],
    );
  }
}

// ============================================================
// عنصر مساعد: زر أيقونة دائري صغير (إشعارات / إعدادات / Ghost mode)
// ============================================================
class _CircleIconButton extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final VoidCallback onTap;

  const _CircleIconButton({
    required this.icon,
    required this.iconColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.12),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: IconButton(
        icon: Icon(icon, color: iconColor, size: 20),
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
// زر "النقاط" (سلة/basket) — يعوض جرس الإشعارات، وكيبان فوقه عدد
// النقاط الحالي فـ badge صغير لون ذهبي
// ============================================================
class _PointsBasketButton extends StatelessWidget {
  final int points;
  final Color darkGreen;
  final Color gold;
  final VoidCallback onTap;

  const _PointsBasketButton({
    required this.points,
    required this.darkGreen,
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
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withValues(alpha: 0.12),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: IconButton(
              icon: Icon(
                Icons.shopping_basket_rounded,
                color: darkGreen,
                size: 20,
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
                  border: Border.all(color: Colors.white, width: 1.5),
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
// كارت "شخص مقترح" — بنفس تصميم الصورة المرجعية: قلب فوق، أفاتار
// دائري بنقطة أونلاين، اسم، عمر، مدينة، وزر "عرض الملف"
// ============================================================
class _SuggestedCard extends StatelessWidget {
  final _NearbyPerson person;
  final Color darkGreen;
  final Color gold;
  final bool isLiked;
  final VoidCallback onLikeTap;
  final VoidCallback onViewProfile;

  const _SuggestedCard({
    required this.person,
    required this.darkGreen,
    required this.gold,
    required this.isLiked,
    required this.onLikeTap,
    required this.onViewProfile,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.12),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GestureDetector(
            onTap: onLikeTap,
            child: Icon(
              isLiked ? Icons.favorite_rounded : Icons.favorite_border_rounded,
              size: 18,
              color: isLiked ? Colors.red.shade400 : darkGreen,
            ),
          ),
          const SizedBox(height: 6),
          Center(
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: darkGreen.withValues(alpha: 0.08),
                  ),
                  child: _HomeScreenState.buildAvatar(
                    source: person.avatarAsset,
                    size: 56,
                    fallbackColor: darkGreen,
                  ),
                ),
                if (person.isOnline)
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: Colors.green.shade500,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            person.name,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontWeight: FontWeight.w800,
              color: darkGreen,
              fontSize: 13.5,
            ),
          ),
          if (person.age != null) ...[
            const SizedBox(height: 2),
            Text(
              '${person.age} سنة',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: gold,
                fontWeight: FontWeight.w700,
                fontSize: 11.5,
              ),
            ),
          ],
          const SizedBox(height: 2),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.location_on_rounded,
                size: 11,
                color: Colors.grey.shade400,
              ),
              const SizedBox(width: 2),
              Expanded(
                child: Text(
                  person.city,
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 10.5, color: Colors.grey.shade500),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            height: 30,
            child: ElevatedButton(
              onPressed: onViewProfile,
              style: ElevatedButton.styleFrom(
                backgroundColor: darkGreen,
                elevation: 0,
                padding: EdgeInsets.zero,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
              child: const Text(
                'عرض الملف',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 10.5,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

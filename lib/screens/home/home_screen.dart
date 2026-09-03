// screens/home/home_screen.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../auth/login_screen.dart';
import '../profile/profile_edit_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _NearbyPerson {
  final String uid;
  final String name;
  final String city;
  final String? avatarAsset;
  final bool isOnline;

  const _NearbyPerson({
    required this.uid,
    required this.name,
    required this.city,
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

  // ✅ 0 = الرئيسية | 1 = الإعجابات | 2 = الدردشة | 3 = الملف الشخصي
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

  // ✅ حالة "متصل الآن" اليدوية (Ghost mode)
  bool _isOnline = true;
  bool _isTogglingOnline = false;

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
        _avatarAsset = data['avatarAsset'] as String?;
        _myCity = data['city'] as String?;
        _isOnline = data['isOnline'] as bool? ?? true;
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
              avatarAsset: data['avatarAsset'] as String?,
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

  // ============================================================
  // ✅ Toggle يدوي لحالة "متصل" — تقدر تخبي روحك (Ghost mode) حتى
  // وأنتَ فاتح التطبيق
  // ============================================================
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
  // Schema: 'likes' {fromUserId, toUserId, timestamp}
  //         'matches' {users: [uid1, uid2], timestamp}
  //         'messages' {fromUserId, toUserId, text, timestamp}
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
  // ✅ دورة حياة التطبيق — كانت مكسورة (ناقصها التوقيع)، تصلحت هنا
  // ============================================================
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // إذا المستخدم مفعّل Ghost mode بيدو، ما نبدلوش الحالة تلقائياً
    // كي التطبيق يخرج للخلفية ويرجع — نحترمو اختياره اليدوي فـ الـ resume
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
    _setOnlineStatus(true); // ✅ "متصل الآن" كي يفتح الهوم
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _setOnlineStatus(false); // ✅ "غير متصل" كي يسكر/يخرج
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
  // ✅ الأفاتار الحقيقي (صورة PNG/JPG) بدل الإيموجي
  // ============================================================
  Widget _buildAvatarImage({required double size}) {
    if (_avatarAsset == null || _avatarAsset!.isEmpty) {
      return Icon(Icons.person, size: size * 0.6, color: darkGreen);
    }
    return ClipOval(
      child: Image.asset(
        _avatarAsset!,
        width: size,
        height: size,
        fit: BoxFit.cover,
        alignment: Alignment.topCenter,
        errorBuilder: (context, error, stack) {
          debugPrint('❌ Home avatar load failed: $_avatarAsset -> $error');
          return Icon(Icons.person, size: size * 0.6, color: darkGreen);
        },
      ),
    );
  }

  // ============================================================
  // ✅ يفتح شاشة تعديل الملف الشخصي، وكي يرجع منها يعاود يقرا الداتا
  // (الاسم، المدينة، وخاصة الأفاتار) باش تتبدل مباشرة فـ الهوم
  // وفـ أيقونة "ملفي" فـ الـ bottom nav بلا ما يحتاج المستخدم يعاود
  // يفتح التطبيق
  // ============================================================
  Future<void> _openProfile() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const ProfileEditScreen()),
    );
    if (!mounted) return;
    _loadUserData();
  }

  // ============================================================
  // ✅ نقرة على شريط التنقل السفلي
  // "الملف الشخصي" يفتح شاشة كاملة (push)، الباقي IndexedStack داخلي
  // ============================================================
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
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, color: Colors.red, size: 48),
              const SizedBox(height: 16),
              Text(
                _errorMessage!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.red),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _loadUserData,
                style: ElevatedButton.styleFrom(backgroundColor: darkGreen),
                child: const Text('إعادة المحاولة'),
              ),
            ],
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
            _buildPlaceholderTab(
              icon: Icons.favorite_rounded,
              title: 'الإعجابات',
              subtitle: 'الأشخاص لي عجبوك رح يبانو هنا قريباً 💛',
            ),
            _buildPlaceholderTab(
              icon: Icons.chat_bubble_rounded,
              title: 'الدردشة',
              subtitle: 'محادثاتك مع المتوافقين رح تبان هنا قريباً 💬',
            ),
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
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 12),
          _buildHeader(),
          const SizedBox(height: 24),
          _buildStatsCard(),
          const SizedBox(height: 28),
          const Text(
            'الخيارات السريعة',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: darkGreen,
            ),
          ),
          const SizedBox(height: 14),
          _buildQuickActionsGrid(),
          const SizedBox(height: 28),
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
                style: TextButton.styleFrom(foregroundColor: gold),
                child: const Text('عرض الكل'),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildNearbyList(),
          const SizedBox(height: 20),
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
              icon: Icon(Icons.logout_rounded, color: darkGreen, size: 20),
              label: const Text(
                'تسجيل الخروج',
                style: TextStyle(color: darkGreen, fontWeight: FontWeight.w600),
              ),
            ),
          ),
          const SizedBox(height: 100), // مساحة فوق الـ bottom nav العائم
        ],
      ),
    );
  }

  // ============================================================
  // HEADER: الأفاتار + الترحيب + زر Ghost mode + الإعدادات
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
                child: Padding(
                  padding: const EdgeInsets.all(2),
                  child: CircleAvatar(
                    radius: 32,
                    backgroundColor: darkGreen.withValues(alpha: 0.1),
                    child: ClipOval(
                      child: SizedBox(
                        width: 64,
                        height: 64,
                        child: _buildAvatarImage(size: 64),
                      ),
                    ),
                  ),
                ),
              ),
              // ✅ نقطة صغيرة تعكس الحالة الحقيقية (أخضر=متصل / رمادي=مخفي)
              Positioned(
                bottom: 2,
                right: 2,
                child: Container(
                  width: 16,
                  height: 16,
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
                style: TextStyle(color: Colors.grey, fontSize: 13),
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
        // ✅ زر Ghost mode اليدوي (متصل / مخفي)
        _CircleIconButton(
          icon: _isOnline
              ? Icons.visibility_rounded
              : Icons.visibility_off_rounded,
          iconColor: _isOnline ? darkGreen : Colors.grey.shade500,
          onTap: _toggleOnlineStatus,
        ),
        const SizedBox(width: 4),
        _CircleIconButton(
          icon: Icons.notifications_outlined,
          iconColor: darkGreen,
          onTap: () {
            // TODO: فتح صفحة الإشعارات
          },
        ),
        const SizedBox(width: 4),
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

  Widget _buildStatsCard() {
    return Container(
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
          _buildStatItem('المتوافقين', '$_matches', Icons.people_rounded),
          _buildStatItem('الرسائل', '$_messages', Icons.chat_rounded),
          _buildStatItem('الإعجابات', '$_likes', Icons.favorite_rounded),
        ],
      ),
    );
  }

  Widget _buildQuickActionsGrid() {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 4,
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 0.78,
      children: [
        _buildQuickAction(
          icon: Icons.person_outline_rounded,
          label: 'الملف الشخصي',
          color: Colors.blue.shade700,
          onTap: _openProfile,
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
          onTap: () => _onNavTap(2),
        ),
        _buildQuickAction(
          icon: Icons.favorite_outline_rounded,
          label: 'المفضلة',
          color: Colors.red.shade400,
          onTap: () => _onNavTap(1),
        ),
      ],
    );
  }

  Widget _buildNearbyList() {
    return SizedBox(
      height: 190,
      child: _isLoadingNearby
          ? const Center(child: CircularProgressIndicator(color: darkGreen))
          : _nearbyPeople.isEmpty
          ? Center(
              child: Text(
                'ماكاين حتى حد فـ نفس مدينتك دابا',
                style: TextStyle(color: Colors.grey.shade500, fontSize: 13),
              ),
            )
          : ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _nearbyPeople.length,
              itemBuilder: (context, index) {
                final person = _nearbyPeople[index];
                return _NearbyCard(
                  person: person,
                  darkGreen: darkGreen,
                  gold: gold,
                );
              },
            ),
    );
  }

  // ============================================================
  // ✅ تبويبات مؤقتة (الإعجابات / الدردشة) لحد ما تتخلق شاشاتهم
  // ============================================================
  Widget _buildPlaceholderTab({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: darkGreen.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 48, color: darkGreen),
            ),
            const SizedBox(height: 20),
            Text(
              title,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: darkGreen,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: Colors.grey.shade500),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // ✅ شريط التنقل السفلي الجديد — عائم، بحواف مدورة، مع مؤشر
  // متحرك (pill) تحت العنصر المختار + أفاتار حقيقي فـ تبويب الملف
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
                  // ✅ المؤشر (pill) المتحرك خلف العنصر المختار
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

  // ✅ تبويب "ملفي" يعرض الأفاتار الحقيقي متاع المستخدم بدل أيقونة عامة
  Widget _buildProfileNavIcon(bool selected) {
    final hasAvatar = _avatarAsset != null && _avatarAsset!.isEmpty == false;
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
        child: ClipOval(
          child: hasAvatar
              ? Image.asset(
                  _avatarAsset!,
                  fit: BoxFit.cover,
                  alignment: Alignment.topCenter,
                  errorBuilder: (context, error, stack) => Icon(
                    Icons.person,
                    size: 16,
                    color: selected ? Colors.white : Colors.grey.shade400,
                  ),
                )
              : Icon(
                  Icons.person,
                  size: 16,
                  color: selected ? Colors.white : Colors.grey.shade400,
                ),
        ),
      ),
    );
  }

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
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: Colors.black87,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
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
            color: Colors.grey.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: IconButton(
        icon: Icon(icon, color: iconColor),
        onPressed: onTap,
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
// كارت شخص قريب (نفس المدينة) — بيانات حقيقية من Firestore
// ============================================================
class _NearbyCard extends StatelessWidget {
  final _NearbyPerson person;
  final Color darkGreen;
  final Color gold;

  const _NearbyCard({
    required this.person,
    required this.darkGreen,
    required this.gold,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 130,
      margin: const EdgeInsets.only(right: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.12),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: Stack(
          fit: StackFit.expand,
          children: [
            person.avatarAsset == null || person.avatarAsset!.isEmpty
                ? Container(
                    color: darkGreen.withValues(alpha: 0.08),
                    child: Icon(Icons.person, size: 44, color: darkGreen),
                  )
                : Image.asset(
                    person.avatarAsset!,
                    fit: BoxFit.cover,
                    alignment: Alignment.topCenter,
                    errorBuilder: (context, error, stack) {
                      debugPrint(
                        '❌ Nearby avatar failed: ${person.avatarAsset} -> $error',
                      );
                      return Container(
                        color: darkGreen.withValues(alpha: 0.08),
                        child: Icon(Icons.person, size: 44, color: darkGreen),
                      );
                    },
                  ),
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: Container(
                padding: const EdgeInsets.fromLTRB(10, 24, 10, 10),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withValues(alpha: 0),
                      Colors.black.withValues(alpha: 0.75),
                    ],
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      person.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Icon(Icons.location_on_rounded, size: 11, color: gold),
                        const SizedBox(width: 2),
                        Text(
                          person.city,
                          style: const TextStyle(
                            fontSize: 11,
                            color: Colors.white70,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            if (person.isOnline)
              Positioned(
                top: 8,
                right: 8,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.green.shade600,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.circle, size: 6, color: Colors.white),
                      SizedBox(width: 4),
                      Text(
                        'متصل الآن',
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
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
}

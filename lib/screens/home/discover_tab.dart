// screens/home/discover_tab.dart
//
// ✅ Onglet "اكتشف" — تجيب بروفايلات حقيقية من Firestore (collection 'users')
// بدل البيانات الوهمية اللي كانت hardcodée. نفس منطق _loadNearbyPeople فـ
// home_screen.dart: name/fullName, city, avatarAsset.
//
// ✅ عند الإعجاب: نسجل الإعجاب فـ collection 'likes' (fromUserId, toUserId,
// timestamp) وبعدها نفتح شاشة الدردشة الحقيقية معاه.
//
// ⚠️ TODO:
// - فلتر "جديد" محتاج composite index (gender + createdAt) — شوف التعليق
//   فوق _loadDiscoverProfiles لتفاصيل أكثر.
// - فلتر "جديد" يخدم غير إذا كاين حقل createdAt (Timestamp) فـ document ديال
//   المستخدم عند التسجيل — إذا ماكاينش، الفلتر يرجع فارغ (طبيعي، ماشي bug).
//
// ⚠️ N'oublie pas de garder l'asset image utilisé dans l'état "intro" :
//    assets/discover/discover_people.png

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../chat/chat_conversation_screen.dart';

class _DiscoverProfile {
  final String uid;
  final String name;
  final int? age;
  final String city;
  final String? avatarAsset;

  const _DiscoverProfile({
    required this.uid,
    required this.name,
    required this.age,
    required this.city,
    required this.avatarAsset,
  });
}

class DiscoverTab extends StatefulWidget {
  const DiscoverTab({super.key});

  @override
  State<DiscoverTab> createState() => _DiscoverTabState();
}

class _DiscoverTabState extends State<DiscoverTab>
    with SingleTickerProviderStateMixin {
  static const Color darkGreen = Color(0xFF0F3D2E);
  static const Color darkGreenLight = Color(0xFF1A6B4A);
  static const Color gold = Color(0xFFC9A24B);
  static const Color discoverCardBg = Color(0xFFEFEAE2);
  static const Color bg = Color(0xFFFAF7F2);

  // ============================================================
  // ✅ بروفايلات حقيقية من Firestore
  // ============================================================
  List<_DiscoverProfile> _discoverProfiles = [];
  bool _isLoadingProfiles = true;
  String? _loadError;

  // ✅ نخزنو الجنس والمدينة ديالنا مرة وحدة باش ما نعاودوش نجيبهم كي يتبدل الفلتر
  String? _myGender;
  String? _myCity;
  bool _myProfileLoaded = false;

  bool _hasStartedDiscovering = false;
  int _discoverIndex = 0;
  String _discoverFilter = 'الجميع';
  bool _isDiscoverActing = false;
  late final AnimationController _discoverFade = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 260),
  )..forward();
  late final Animation<double> _cardScale = CurvedAnimation(
    parent: _discoverFade,
    curve: Curves.easeOutCubic,
  ).drive(Tween(begin: 0.94, end: 1.0));

  @override
  void initState() {
    super.initState();
    _loadDiscoverProfiles();
  }

  @override
  void dispose() {
    _discoverFade.dispose();
    super.dispose();
  }

  // ============================================================
  // ✅ يجيب مستخدمين حقيقيين من Firestore حسب الفلتر المختار:
  // - "الجميع"    : الجنس المعاكس فقط
  // - "قريب منك"  : الجنس المعاكس + نفس المدينة (city)
  // - "جديد"      : الجنس المعاكس، مرتبين حسب تاريخ الإنشاء (createdAt) الأحدث
  //
  // ⚠️ فلتر "جديد" محتاج composite index فـ Firestore (gender + createdAt).
  // أول مرة تجرب، Firebase غادي يعطيك فـ الـ console/logcat رابط مباشر
  // "Create the index" — دوس عليه وسير، Firestore يصاوبها وحدو.
  // إذا document ماعندوش createdAt، ما غاديش يبان فـ فلتر "جديد" (طبيعي).
  // ============================================================
  Future<void> _loadDiscoverProfiles() async {
    setState(() {
      _isLoadingProfiles = true;
      _loadError = null;
    });
    try {
      final myUid = FirebaseAuth.instance.currentUser?.uid;
      if (myUid == null) {
        setState(() {
          _loadError = 'المستخدم غير مسجل';
          _isLoadingProfiles = false;
        });
        return;
      }

      // ✅ نجيب الجنس والمدينة ديالي مرة وحدة فقط
      if (!_myProfileLoaded) {
        final myDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(myUid)
            .get();
        _myGender = myDoc.data()?['gender'] as String?;
        _myCity = myDoc.data()?['city'] as String?;
        _myProfileLoaded = true;
      }

      final String? oppositeGender = _myGender == 'male'
          ? 'female'
          : _myGender == 'female'
          ? 'male'
          : null;

      Query<Map<String, dynamic>> query = FirebaseFirestore.instance.collection(
        'users',
      );

      if (oppositeGender != null) {
        query = query.where('gender', isEqualTo: oppositeGender);
      } else {
        debugPrint(
          '⚠️ Discover: جنس المستخدم الحالي غير معروف (gender=$_myGender) — ماعندهاش فلترة',
        );
      }

      switch (_discoverFilter) {
        case 'قريب منك':
          if (_myCity != null && _myCity!.isNotEmpty) {
            query = query.where('city', isEqualTo: _myCity);
          } else {
            debugPrint(
              '⚠️ Discover: مدينتك غير معروفة — فلتر "قريب منك" اتلغى',
            );
          }
          break;
        case 'جديد':
          query = query.orderBy('createdAt', descending: true);
          break;
        case 'الجميع':
        default:
          break;
      }

      final snapshot = await query.limit(30).get();

      final profiles = snapshot.docs.where((d) => d.id != myUid).map((d) {
        final data = d.data();
        final rawAge = data['age'];
        return _DiscoverProfile(
          uid: d.id,
          name:
              (data['fullName'] as String?) ??
              (data['name'] as String?) ??
              'مستخدم',
          age: rawAge is int ? rawAge : int.tryParse('$rawAge'),
          city: (data['city'] as String?) ?? '',
          avatarAsset: data['avatarAsset'] as String?,
        );
      }).toList();

      if (!mounted) return;
      setState(() {
        _discoverProfiles = profiles;
        _discoverIndex = 0;
        _isLoadingProfiles = false;
      });
    } catch (e) {
      debugPrint('❌ Discover profiles load failed: $e');
      if (!mounted) return;
      setState(() {
        _loadError = 'تعذر تحميل البروفايلات';
        _isLoadingProfiles = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 260),
      child: _hasStartedDiscovering
          ? _buildDiscoverSwipeContent()
          : _buildDiscoverIntro(),
    );
  }

  // ------------------------------------------------------------
  // الحالة 1: "اكتشف الأشخاص" (intro) — صورة واحدة + زر بدء
  // ------------------------------------------------------------
  Widget _buildDiscoverIntro() {
    return Center(
      key: const ValueKey('discover_intro'),
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 96,
              height: 96,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    darkGreen.withValues(alpha: 0.10),
                    darkGreen.withValues(alpha: 0.02),
                  ],
                ),
                border: Border.all(
                  color: darkGreen.withValues(alpha: 0.18),
                  width: 1.6,
                ),
              ),
              child: const Icon(
                Icons.people_alt_rounded,
                color: darkGreen,
                size: 38,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'اكتشف الأشخاص',
              style: TextStyle(
                fontSize: 25,
                fontWeight: FontWeight.w800,
                color: darkGreen,
                letterSpacing: -0.3,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'ابحث عن شريك يشاركك نفس\nالقيم والاهتمامات',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade600,
                height: 1.6,
              ),
            ),
            const SizedBox(height: 30),
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(22),
                boxShadow: [
                  BoxShadow(
                    color: darkGreen.withValues(alpha: 0.10),
                    blurRadius: 24,
                    offset: const Offset(0, 12),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(22),
                child: Image.asset(
                  'assets/discover/discover_people.png',
                  width: 320,
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stack) => Container(
                    width: 280,
                    height: 200,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: darkGreen.withValues(alpha: 0.06),
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Icon(
                      Icons.image_not_supported_rounded,
                      color: darkGreen.withValues(alpha: 0.4),
                      size: 40,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: () => setState(() => _hasStartedDiscovering = true),
                style:
                    ElevatedButton.styleFrom(
                      backgroundColor: darkGreen,
                      elevation: 0,
                      shadowColor: Colors.transparent,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ).copyWith(
                      overlayColor: WidgetStateProperty.all(
                        Colors.white.withValues(alpha: 0.08),
                      ),
                    ),
                child: Ink(
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [darkGreen, darkGreenLight],
                    ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: darkGreen.withValues(alpha: 0.32),
                        blurRadius: 18,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Container(
                    alignment: Alignment.center,
                    child: const Text(
                      'ابدأ الاكتشاف',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ------------------------------------------------------------
  // الحالة 2: فلاتر + عداد التقدم + كارت السحب (X / قلب)
  // ------------------------------------------------------------
  Widget _buildDiscoverSwipeContent() {
    final hasProfile = _discoverIndex < _discoverProfiles.length;
    return Column(
      key: const ValueKey('discover_swipe'),
      children: [
        const SizedBox(height: 8),
        _buildDiscoverFilterChips(),
        const SizedBox(height: 14),
        if (!_isLoadingProfiles && _loadError == null && hasProfile)
          _buildProgressDots(),
        const SizedBox(height: 14),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: _isLoadingProfiles
                ? const Center(
                    child: CircularProgressIndicator(color: darkGreen),
                  )
                : _loadError != null
                ? _buildErrorState()
                : hasProfile
                ? _buildCardStack()
                : _buildDiscoverEmptyState(),
          ),
        ),
        const SizedBox(height: 100), // مساحة فوق الـ bottom nav العائم
      ],
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline_rounded,
            color: Colors.grey.shade400,
            size: 40,
          ),
          const SizedBox(height: 12),
          Text(
            _loadError!,
            style: TextStyle(color: Colors.grey.shade500, fontSize: 13.5),
          ),
          const SizedBox(height: 16),
          TextButton.icon(
            onPressed: _loadDiscoverProfiles,
            style: TextButton.styleFrom(foregroundColor: darkGreen),
            icon: const Icon(Icons.refresh_rounded, size: 18),
            label: const Text(
              'إعادة المحاولة',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressDots() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(_discoverProfiles.length, (i) {
        final active = i == _discoverIndex;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          margin: const EdgeInsets.symmetric(horizontal: 3),
          width: active ? 20 : 6,
          height: 6,
          decoration: BoxDecoration(
            color: active ? darkGreen : darkGreen.withValues(alpha: 0.16),
            borderRadius: BorderRadius.circular(4),
          ),
        );
      }),
    );
  }

  Widget _buildDiscoverFilterChips() {
    final filters = <_FilterChipData>[
      _FilterChipData('جديد', Icons.auto_awesome_rounded),
      _FilterChipData('قريب منك', Icons.location_on_rounded),
      _FilterChipData('الجميع', Icons.groups_rounded),
    ];
    return Row(
      children: [
        Expanded(
          child: SizedBox(
            height: 44,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              itemCount: filters.length,
              separatorBuilder: (_, __) => const SizedBox(width: 10),
              itemBuilder: (context, index) {
                final data = filters[index];
                final selected = data.label == _discoverFilter;
                return GestureDetector(
                  onTap: () {
                    if (_discoverFilter == data.label) return;
                    setState(() => _discoverFilter = data.label);
                    _loadDiscoverProfiles();
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    padding: const EdgeInsets.symmetric(horizontal: 18),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: selected ? darkGreen : Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: selected
                          ? [
                              BoxShadow(
                                color: darkGreen.withValues(alpha: 0.24),
                                blurRadius: 12,
                                offset: const Offset(0, 5),
                              ),
                            ]
                          : [
                              BoxShadow(
                                color: Colors.grey.withValues(alpha: 0.10),
                                blurRadius: 8,
                                offset: const Offset(0, 3),
                              ),
                            ],
                      border: selected
                          ? null
                          : Border.all(
                              color: darkGreen.withValues(alpha: 0.08),
                            ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          data.icon,
                          size: 15,
                          color: selected
                              ? gold
                              : darkGreen.withValues(alpha: 0.55),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          data.label,
                          style: TextStyle(
                            color: selected ? Colors.white : darkGreen,
                            fontWeight: FontWeight.w700,
                            fontSize: 13.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ),
        GestureDetector(
          onTap: _isLoadingProfiles ? null : _loadDiscoverProfiles,
          child: Container(
            margin: const EdgeInsets.only(right: 20),
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withValues(alpha: 0.12),
                  blurRadius: 8,
                ),
              ],
            ),
            child: Icon(Icons.refresh_rounded, color: darkGreen, size: 19),
          ),
        ),
      ],
    );
  }

  // ------------------------------------------------------------
  // ✅ Stack: كارت خلفي (Peek) وراء الكارت النشط لإحساس عمق
  // ------------------------------------------------------------
  Widget _buildCardStack() {
    final hasNext = _discoverIndex + 1 < _discoverProfiles.length;
    return Stack(
      alignment: Alignment.topCenter,
      children: [
        if (hasNext)
          Positioned(
            top: 14,
            left: 10,
            right: 10,
            bottom: 0,
            child: Transform.scale(
              scale: 0.95,
              child: Opacity(
                opacity: 0.55,
                child: Container(
                  decoration: BoxDecoration(
                    color: discoverCardBg,
                    borderRadius: BorderRadius.circular(28),
                  ),
                ),
              ),
            ),
          ),
        AnimatedBuilder(
          animation: _discoverFade,
          builder: (context, child) => Opacity(
            opacity: _discoverFade.value,
            child: Transform.scale(scale: _cardScale.value, child: child),
          ),
          child: _buildDiscoverCard(_discoverProfiles[_discoverIndex]),
        ),
      ],
    );
  }

  Widget _buildDiscoverCard(_DiscoverProfile profile) {
    final displayName = profile.age != null
        ? '${profile.name}، ${profile.age}'
        : profile.name;
    return SizedBox(
      width: double.infinity,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 26),
        decoration: BoxDecoration(
          color: discoverCardBg,
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: Colors.white.withValues(alpha: 0.6)),
          boxShadow: [
            BoxShadow(
              color: darkGreen.withValues(alpha: 0.12),
              blurRadius: 26,
              offset: const Offset(0, 14),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildDiscoverCircleTag(
                  icon: Icons.location_on_rounded,
                  onTap: () {},
                ),
                _buildDiscoverCircleTag(
                  icon: Icons.more_horiz_rounded,
                  onTap: () {
                    // TODO: بلاغ / حظر
                  },
                ),
              ],
            ),
            const SizedBox(height: 10),
            Container(
              width: 216,
              height: 216,
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    gold.withValues(alpha: 0.85),
                    gold.withValues(alpha: 0.25),
                  ],
                ),
                boxShadow: [
                  BoxShadow(
                    color: darkGreen.withValues(alpha: 0.14),
                    blurRadius: 24,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white,
                ),
                child: ClipOval(
                  child:
                      profile.avatarAsset == null ||
                          profile.avatarAsset!.isEmpty
                      ? Container(
                          color: darkGreen.withValues(alpha: 0.06),
                          child: Icon(Icons.person, size: 74, color: darkGreen),
                        )
                      : Image.asset(
                          profile.avatarAsset!,
                          fit: BoxFit.cover,
                          errorBuilder: (c, e, s) {
                            debugPrint(
                              '❌ Discover avatar failed: ${profile.avatarAsset} -> $e',
                            );
                            return Container(
                              color: darkGreen.withValues(alpha: 0.06),
                              child: Icon(
                                Icons.person,
                                size: 74,
                                color: darkGreen,
                              ),
                            );
                          },
                        ),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              displayName,
              style: const TextStyle(
                fontSize: 25,
                fontWeight: FontWeight.w800,
                color: darkGreen,
                letterSpacing: -0.3,
              ),
            ),
            if (profile.city.isNotEmpty) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: darkGreen.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.location_on_rounded, size: 13, color: gold),
                    const SizedBox(width: 4),
                    Text(
                      profile.city,
                      style: TextStyle(
                        fontSize: 12.5,
                        color: Colors.grey.shade700,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 26),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _BounceIconButton(
                  icon: Icons.close_rounded,
                  iconColor: Colors.grey.shade700,
                  background: Colors.white,
                  onTap: _handleDiscoverSkip,
                ),
                const SizedBox(width: 30),
                _BounceIconButton(
                  icon: Icons.favorite_rounded,
                  iconColor: Colors.white,
                  size: 72,
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [darkGreen, darkGreenLight],
                  ),
                  shadowColor: darkGreen.withValues(alpha: 0.38),
                  onTap: _handleDiscoverLike,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDiscoverCircleTag({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withValues(alpha: 0.15),
              blurRadius: 8,
            ),
          ],
        ),
        child: Icon(icon, color: darkGreen, size: 20),
      ),
    );
  }

  Widget _buildDiscoverEmptyState() {
    return Center(
      key: const ValueKey('discover_empty'),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: darkGreen.withValues(alpha: 0.06),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.people_outline_rounded,
              color: darkGreen.withValues(alpha: 0.45),
              size: 42,
            ),
          ),
          const SizedBox(height: 18),
          Text(
            'ماكاين حتى بروفايل آخر دابا',
            style: TextStyle(
              color: Colors.grey.shade600,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'رجع مرة أخرى بعد شوية، غادي يبانو أشخاص جدد',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey.shade400, fontSize: 12.5),
          ),
          const SizedBox(height: 22),
          TextButton.icon(
            onPressed: _loadDiscoverProfiles,
            style: TextButton.styleFrom(foregroundColor: darkGreen),
            icon: const Icon(Icons.refresh_rounded, size: 18),
            label: const Text(
              'إعادة التحميل',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }

  void _handleDiscoverSkip() => _goToNextDiscoverProfile();

  // ============================================================
  // ✅ عند الإعجاب: نسجل الإعجاب فـ Firestore بحال حقيقي، من بعد
  // نفتحو شاشة الدردشة الحقيقية معاه (مربوطة بـ Firestore دابا)
  // Schema: collection('likes') {fromUserId, toUserId, timestamp}
  // (نفس الـ schema اللي كتقرا منها _loadRealStats فـ home_screen.dart)
  // ============================================================
  Future<void> _handleDiscoverLike() async {
    if (_isDiscoverActing) return;
    final profile = _discoverProfiles[_discoverIndex];
    final myUid = FirebaseAuth.instance.currentUser?.uid;

    if (myUid != null) {
      try {
        await FirebaseFirestore.instance.collection('likes').add({
          'fromUserId': myUid,
          'toUserId': profile.uid,
          'timestamp': FieldValue.serverTimestamp(),
        });
      } catch (e) {
        debugPrint('❌ Like save failed: $e');
      }
    }

    // ✅ يفتح مباشرة شاشة الدردشة الحقيقية مع هاد الشخص
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ChatConversationScreen(
          personId: profile.uid,
          personName: profile.name,
          personCity: profile.city,
          personAvatarAsset: profile.avatarAsset,
        ),
      ),
    );
    if (!mounted) return;
    _goToNextDiscoverProfile();
  }

  Future<void> _goToNextDiscoverProfile() async {
    if (_isDiscoverActing) return;
    setState(() => _isDiscoverActing = true);
    await _discoverFade.reverse();
    if (!mounted) return;
    setState(() {
      if (_discoverIndex < _discoverProfiles.length - 1) {
        _discoverIndex++;
      } else {
        _discoverIndex = _discoverProfiles.length;
      }
      _isDiscoverActing = false;
    });
    _discoverFade.forward();
  }
}

class _FilterChipData {
  final String label;
  final IconData icon;
  const _FilterChipData(this.label, this.icon);
}

// ============================================================
// ✅ زر أيقونة دائري بتأثير لمسي (ينكمش شوية كي يتضغط)
// ============================================================
class _BounceIconButton extends StatefulWidget {
  final IconData icon;
  final Color iconColor;
  final Color? background;
  final Gradient? gradient;
  final Color shadowColor;
  final double size;
  final VoidCallback onTap;

  const _BounceIconButton({
    required this.icon,
    required this.iconColor,
    required this.onTap,
    this.background,
    this.gradient,
    this.shadowColor = const Color(0x1F000000),
    this.size = 62,
  });

  @override
  State<_BounceIconButton> createState() => _BounceIconButtonState();
}

class _BounceIconButtonState extends State<_BounceIconButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapCancel: () => setState(() => _pressed = false),
      onTapUp: (_) => setState(() => _pressed = false),
      onTap: widget.onTap,
      child: AnimatedScale(
        duration: const Duration(milliseconds: 110),
        scale: _pressed ? 0.90 : 1.0,
        child: Container(
          width: widget.size,
          height: widget.size,
          decoration: BoxDecoration(
            color: widget.gradient == null ? widget.background : null,
            gradient: widget.gradient,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: widget.shadowColor,
                blurRadius: 14,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Icon(
            widget.icon,
            color: widget.iconColor,
            size: widget.size * 0.4,
          ),
        ),
      ),
    );
  }
}
// screens/home/home_screen.dart
import 'dart:async';
import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../auth/login_screen.dart';
import '../profile/profile_edit_screen.dart';
import '../chat/chat_list_tab.dart';
import '../likes/likes_tab.dart';
import '../../services/likes_service.dart';

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

class _HomeScreenState extends State<HomeScreen>
    with WidgetsBindingObserver, TickerProviderStateMixin {
  static const Color darkGreen = Color(0xFF0F3D2E);
  static const Color darkGreenLight = Color(0xFF1A6B4A);
  static const Color gold = Color(0xFFC9A24B);
  static const Color bg = Color(0xFFFAF7F2);
  static const Color cream = Color(0xFFF3EDE1);

  // بيانات المستخدم
  List<_NearbyPerson> _nearbyPeople = [];
  bool _isLoadingNearby = true;

  int _selectedIndex = 0;
  bool _isLoading = true;
  String? _errorMessage;

  String _userName = '';
  String? _avatarAsset;
  String? _myCity;
  String? _myGender;
  int _matches = 0;
  int _messages = 0;
  int _likes = 0;

  // ============================================================
  // 🔔 إشعارات حية (Live) — عدد الدعوات المعلّقة + عدد الرسائل غير
  // المقروءة، تتحدّث تلقائياً بلا Refresh يدوي (بوابتها LikesService
  // و collection('messages') مباشرة، بنفس الـarchitecture الموجود).
  // ============================================================
  int _pendingInvitationsCount = 0;
  int _unreadMessagesCount = 0;
  StreamSubscription<List<LikeInvitation>>? _invitationsSub;
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _unreadMsgsSub;
  int _points = 0;

  bool _isOnline = true;
  bool _isTogglingOnline = false;

  final Set<String> _likedUids = {};
  Set<String> _hiddenUids = {};

  // ============================================================
  // 🎯 DISSOLVE / APPEAR ANIMATION STATE
  // ============================================================
  late AnimationController _dissolveController;
  late AnimationController _appearController;
  double _dissolveValue = 0.0;
  double _appearValue = 0.0;
  bool _isDissolving = false;
  bool _isAppearing = false;
  _NearbyPerson? _likedPerson; // person we liked (for message after dissolve)
  bool _isMessageSheetOpen = false; // prevent double dissolve

  // Particles
  List<_Particle> _particles = [];

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
        _myGender = data['gender'] as String?;
        _isOnline = data['isOnline'] as bool? ?? true;
        _points = (data['points'] as num?)?.toInt() ?? 0;
        _hiddenUids = (data['hiddenUserIds'] as List<dynamic>?)
                ?.cast<String>()
                .toSet() ??
            {};
        _isLoading = false;
      });

      _loadRealStats(user.uid);

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
      // ✅ نفس منطق الجنس المستعمل فـ DiscoverTab: نعرض فقط الجنس
      // المعاكس (أو Preference الحقيقي إذا كان موجوداً فـ المشروع)،
      // ولا نعمل Hardcode إذا كان الجنس غير معروف (البند 10)
      final String? oppositeGender = _myGender == 'male'
          ? 'female'
          : _myGender == 'female'
              ? 'male'
              : null;

      Query<Map<String, dynamic>> query = FirebaseFirestore.instance
          .collection('users')
          .where('city', isEqualTo: city);

      if (oppositeGender != null) {
        query = query.where('gender', isEqualTo: oppositeGender);
      }

      final snapshot = await query.limit(15).get();

      // ✅ نحيدو أي شخص عندي معاه علاقة إعجاب حالية (بعثت ليه، بعث
      // ليا، أو Match) — ما يعاودش يبان ليا للـ swipe مرة ثانية
      // (بحال Facebook: شخص عندك معاه دعوة معلّقة ما يبانش لك تاني
      // فـ "أشخاص تعرفهم").
      final interactedIds = await LikesService.instance.myInteractedUserIds();

      final List<_NearbyPerson> people = snapshot.docs
          .where((d) =>
              d.id != myUid &&
              !_hiddenUids.contains(d.id) &&
              !interactedIds.contains(d.id))
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
          if (_nearbyPeople.isNotEmpty) {
            _currentCardIndex = 0;
            // Reset animation states
            _dissolveValue = 0.0;
            _appearValue = 0.0;
            _isDissolving = false;
            _isAppearing = false;
            _particles.clear();
          }
        });
      }
    } catch (e) {
      debugPrint('❌ Nearby people load failed: $e');
      if (mounted) setState(() => _isLoadingNearby = false);
    }
  }

  // ============================================================
  // ✅ يكتب isOnline + lastSeen فـ Firestore
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
    _dissolveController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..addListener(() {
        if (mounted) {
          setState(() {
            _dissolveValue = _dissolveController.value;
          });
        }
      });

    _appearController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    )..addListener(() {
        if (mounted) {
          setState(() {
            _appearValue = _appearController.value;
          });
        }
      });

    WidgetsBinding.instance.addObserver(this);
    _loadUserData();
    _setOnlineStatus(true);
    _attachLiveBadges();
  }

  // ============================================================
  // 🔔 ربط الإشعارات الحية بالبادجات (bell + bottom nav)
  // ============================================================
  void _attachLiveBadges() {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    _invitationsSub = LikesService.instance.receivedInvitationsStream().listen(
      (list) {
        if (!mounted) return;
        setState(() => _pendingInvitationsCount = list.length);
      },
      onError: (e) => debugPrint('❌ Invitations badge stream failed: $e'),
    );

    _unreadMsgsSub = FirebaseFirestore.instance
        .collection('messages')
        .where('toUserId', isEqualTo: uid)
        .where('read', isEqualTo: false)
        .snapshots()
        .listen(
      (snap) {
        if (!mounted) return;
        setState(() => _unreadMessagesCount = snap.docs.length);
      },
      onError: (e) => debugPrint('❌ Unread messages badge stream failed: $e'),
    );
  }

  @override
  void dispose() {
    _dissolveController.dispose();
    _appearController.dispose();
    WidgetsBinding.instance.removeObserver(this);
    _invitationsSub?.cancel();
    _unreadMsgsSub?.cancel();
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
  // ✅ صورة الأفاتار
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

    final image = isNetwork
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

    if (borderRadius != null) {
      return ClipRRect(borderRadius: borderRadius, child: image);
    }
    return ClipOval(child: SizedBox(width: size, height: size, child: image));
  }

  // ============================================================
  // ✅ يفتح شاشة تعديل الملف الشخصي
  // ============================================================
  Future<void> _openProfile() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const ProfileEditScreen()),
    );
    if (!mounted) return;
    _loadUserData();
    // ✅ إذا رجع من صفحة "حسابي" بالضغط على تبويب آخر (نفس شريط
    // الرئيسية بالضبط)، نبدّل التبويب هنا فعلياً — بلا ماشي ديكور فارغ.
    if (result is int && result >= 0 && result <= 2) {
      setState(() => _selectedIndex = result);
    }
  }

  void _onNavTap(int index) {
    if (index == 3) {
      _openProfile();
      return;
    }
    setState(() => _selectedIndex = index);
  }

  // ============================================================
  // 🚫 EXCLUDE USER FROM HOME DISCOVERY (local + Firestore)
  // ============================================================
  /// Removes the user from the local list and returns the new index.
  /// Does NOT call setState – caller should handle UI update.
  int _removePersonFromLocalList(String uid) {
    final index = _nearbyPeople.indexWhere((p) => p.uid == uid);
    if (index == -1) return _currentCardIndex;

    _nearbyPeople.removeAt(index);
    if (_currentCardIndex > index) {
      return _currentCardIndex - 1;
    } else if (_currentCardIndex == index) {
      if (_currentCardIndex >= _nearbyPeople.length) {
        return _nearbyPeople.length - 1;
      }
      return _currentCardIndex;
    }
    return _currentCardIndex;
  }

  Future<void> _addHiddenUser(String uid) async {
    if (_hiddenUids.contains(uid)) return;
    _hiddenUids.add(uid);
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .update({
          'hiddenUserIds': FieldValue.arrayUnion([uid]),
        });
      }
    } catch (e) {
      debugPrint('❌ Failed to update hidden users: $e');
    }
  }

  // ============================================================
  // 🎯 CARD INDEX & SWIPE
  // ============================================================
  int _currentCardIndex = 0;
  double _dragOffset = 0.0;
  double _dragAngle = 0.0;

  /// Starts the dissolve animation for a specific person.
  void _startDissolve({required _NearbyPerson person, required bool isLike}) {
    if (_isDissolving || _isAppearing) return;
    // Find the person's current index
    final index = _nearbyPeople.indexWhere((p) => p.uid == person.uid);
    if (index == -1) {
      // Person already removed – just show next if available
      _showNextAfterDissolve();
      return;
    }

    // Generate particles only for like
    if (isLike) {
      _particles = _generateParticles();
    } else {
      _particles.clear();
    }

    // Temporarily store the person for dissolving card
    _likedPerson = person;

    setState(() {
      _isDissolving = true;
      _dissolveValue = 0.0;
    });

    _dissolveController.forward(from: 0.0).then((_) {
      if (!mounted) return;
      // Dissolve complete – remove the person from local list
      final newIndex = _removePersonFromLocalList(person.uid);
      // Add to hidden list (Firestore)
      _addHiddenUser(person.uid);

      setState(() {
        _currentCardIndex = newIndex;
        _isDissolving = false;
        _dissolveValue = 0.0;
        _particles.clear();
        _likedPerson = null;
      });

      // Show next person or empty state
      _showNextAfterDissolve();
    });
  }

  /// Shows the next person with appear animation, or empty state.
  void _showNextAfterDissolve() {
    if (_nearbyPeople.isEmpty) {
      setState(() {
        _isAppearing = false;
        _appearValue = 0.0;
      });
      return;
    }

    if (_currentCardIndex >= _nearbyPeople.length) {
      _currentCardIndex = _nearbyPeople.length - 1;
    }

    setState(() {
      _isAppearing = true;
      _appearValue = 0.0;
    });
    _appearController.forward(from: 0.0).then((_) {
      if (!mounted) return;
      setState(() {
        _isAppearing = false;
        _appearValue = 0.0;
      });
    });
  }

  // ============================================================
  // 👇 Heart Like – ينشئ إعجاب/دعوة (Invitation) فقط، بلا فتح Chat.
  // الشخص المعجب به سيرى الدعوة فـ "الإعجابات"، ولا تصبح المحادثة
  // متاحة إلا إذا هو قَبِل (راجع LikesService + likes_tab.dart).
  // ============================================================
  bool _isSendingLike = false;

  Future<void> _heartLike() async {
    if (_isDissolving || _isAppearing || _isSendingLike) return;
    if (_currentCardIndex >= _nearbyPeople.length) return;

    final person = _nearbyPeople[_currentCardIndex];
    setState(() => _isSendingLike = true);

    try {
      final created = await LikesService.instance.sendLike(person.uid);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              created
                  ? 'تم إرسال إعجابك إلى ${person.name} ❤️'
                  : 'سبق أن أرسلت إعجاباً لهذا الشخص',
            ),
            backgroundColor: darkGreen,
          ),
        );
      }
    } on LikeActionException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message)),
        );
      }
    } catch (e) {
      debugPrint('❌ Send like failed: $e');
    } finally {
      if (mounted) setState(() => _isSendingLike = false);
    }

    if (!mounted) return;
    // بعد إرسال الإعجاب، نُبعد البطاقة من الاكتشاف الحالي (تأثير بصري فقط،
    // لا علاقة له بمنطق الإعجاب نفسه الذي تم تسجيله فـ Firestore فوق)
    _startDissolve(person: person, isLike: true);
  }

  // 👇 X / Pass – dissolve immediately (no message)
  void _swipePass() {
    if (_isDissolving || _isAppearing) return;
    if (_currentCardIndex >= _nearbyPeople.length) return;
    final person = _nearbyPeople[_currentCardIndex];
    _startDissolve(person: person, isLike: false);
  }

  // ============================================================
  // 🧪 PARTICLE GENERATION
  // ============================================================
  List<_Particle> _generateParticles() {
    final random = Random();
    final particles = <_Particle>[];
    final int count = 30;
    for (int i = 0; i < count; i++) {
      final angle = random.nextDouble() * 2 * pi;
      final distance = 40 + random.nextDouble() * 120;
      final size = 3 + random.nextDouble() * 8;
      final speed = 0.5 + random.nextDouble() * 0.5;
      final startX = (random.nextDouble() - 0.5) * 40;
      final startY = (random.nextDouble() - 0.5) * 40;
      particles.add(_Particle(
        startOffset: Offset(startX, startY),
        angle: angle,
        distance: distance,
        size: size,
        speed: speed,
        opacity: 0.5 + random.nextDouble() * 0.5,
        color: random.nextBool() ? gold : Colors.white,
      ));
    }
    return particles;
  }

  // ============================================================
  // 🏗️ BUILD
  // ============================================================
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
                    color: const Color(0xFFDE3B40).withOpacity(0.08),
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
                      shadowColor: darkGreen.withOpacity(0.4),
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

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: bg,
        body: SafeArea(
          top: false,
          bottom: false,
          child: IndexedStack(
            index: _selectedIndex,
            children: [
              _buildHomeTab(),
              LikesTab(),
              const ChatsListTab(),
            ],
          ),
        ),
        bottomNavigationBar: SafeArea(top: false, child: _buildBottomNav()),
      ),
    );
  }

  // ============================================================
  // 🏠 HOME TAB
  // ============================================================
  Widget _buildHomeTab() {
    return RefreshIndicator(
      color: darkGreen,
      onRefresh: _loadUserData,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        child: Directionality(
          textDirection: TextDirection.rtl,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(),
              const SizedBox(height: 16),
              _buildSearchBar(),
              const SizedBox(height: 22),
              _buildMainProfileCard(),
              const SizedBox(height: 20),
              _buildNearbySection(),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  // ============================================================
  // 1️⃣ HEADER (unchanged)
  // ============================================================
  Widget _buildHeader() {
    return Row(
      children: [
        Stack(
          children: [
            Container(
              width: 56,
              height: 56,
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: gold, width: 2),
              ),
              child: Container(
                padding: const EdgeInsets.all(2),
                decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                child: ClipOval(
                  child: _HomeScreenState.buildAvatar(
                    source: _avatarAsset,
                    size: 50,
                    fallbackColor: gold,
                  ),
                ),
              ),
            ),
            Positioned(
              bottom: 2,
              right: 2,
              child: Container(
                width: 14,
                height: 14,
                decoration: BoxDecoration(
                  color: _isOnline ? Colors.green.shade400 : Colors.grey.shade400,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _userName,
                style: const TextStyle(
                  fontSize: 19,
                  fontWeight: FontWeight.w800,
                  color: darkGreen,
                  letterSpacing: -0.4,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
              Text(
                'مرحبا بك مجدداً ♡',
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey.shade500,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
        Row(
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: _pendingInvitationsCount > 0
                        ? gold.withOpacity(0.14)
                        : Colors.white,
                    shape: BoxShape.circle,
                    border: _pendingInvitationsCount > 0
                        ? Border.all(color: gold.withOpacity(0.35), width: 1.4)
                        : null,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.10),
                        blurRadius: 10,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: IconButton(
                    icon: Icon(
                      _pendingInvitationsCount > 0
                          ? Icons.notifications_active_rounded
                          : Icons.notifications_none_rounded,
                      color: darkGreen,
                      size: 22,
                    ),
                    // ✅ الجرس أصبح فعلياً يشتغل: يودّي مباشرة لصفحة
                    // "الإعجابات" (وين كاينين الدعوات الجديدة الفعلية)
                    onPressed: () => _onNavTap(1),
                    padding: EdgeInsets.zero,
                    splashRadius: 20,
                  ),
                ),
                if (_pendingInvitationsCount > 0)
                  Positioned(
                    top: -2,
                    right: -2,
                    child: AnimatedScale(
                      scale: 1,
                      duration: const Duration(milliseconds: 220),
                      curve: Curves.elasticOut,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 5),
                        constraints: const BoxConstraints(minWidth: 19, minHeight: 19),
                        decoration: BoxDecoration(
                          color: const Color(0xFFDE3B40),
                          shape: _pendingInvitationsCount > 9
                              ? BoxShape.rectangle
                              : BoxShape.circle,
                          borderRadius: _pendingInvitationsCount > 9
                              ? BorderRadius.circular(10)
                              : null,
                          border: Border.all(color: cream, width: 2),
                        ),
                        child: Center(
                          child: Text(
                            _pendingInvitationsCount > 9 ? '9+' : '$_pendingInvitationsCount',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              height: 1.3,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ],
    );
  }

  // ============================================================
  // 2️⃣ SEARCH BAR (unchanged)
  // ============================================================
  Widget _buildSearchBar() {
    return Container(
      height: 58,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: Colors.black.withOpacity(0.03)),
        boxShadow: [
          BoxShadow(
            color: darkGreen.withOpacity(0.06),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          const SizedBox(width: 18),
          Icon(Icons.search_rounded, color: darkGreen.withOpacity(0.55), size: 22),
          const SizedBox(width: 10),
          Expanded(
            child: TextField(
              decoration: InputDecoration(
                hintText: 'ابحث عن أصدقاء، أشخاص قريبين...',
                hintStyle: TextStyle(
                  color: Colors.grey.shade400,
                  fontSize: 14,
                ),
                border: InputBorder.none,
                isDense: true,
              ),
              textDirection: TextDirection.rtl,
            ),
          ),
          Container(
            margin: const EdgeInsets.all(6),
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: gold.withOpacity(0.12),
              shape: BoxShape.circle,
            ),
            child: IconButton(
              icon: const Icon(Icons.tune_rounded, color: darkGreen, size: 20),
              onPressed: () {},
              padding: EdgeInsets.zero,
              splashRadius: 22,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // 4️⃣ MAIN PROFILE CARD (with dissolve + appear animation)
  // ============================================================
  Widget _buildMainProfileCard() {
    if (_nearbyPeople.isEmpty && !_isDissolving && !_isAppearing) {
      return _buildEmptyCard();
    }

    _NearbyPerson? currentPerson;
    if (_currentCardIndex < _nearbyPeople.length) {
      currentPerson = _nearbyPeople[_currentCardIndex];
    }

    Widget cardContent;
    if (_isDissolving && _likedPerson != null) {
      cardContent = _buildDissolvingCard(_likedPerson!);
    } else if (_isAppearing && currentPerson != null) {
      cardContent = _buildAppearingCard(currentPerson!);
    } else if (currentPerson != null) {
      cardContent = _buildNormalCard(currentPerson);
    } else {
      return _buildEmptyCard();
    }

    return GestureDetector(
      onPanUpdate: (details) {
        if (_isDissolving || _isAppearing) return;
        setState(() {
          _dragOffset += details.delta.dx;
          _dragAngle = _dragOffset * 0.02;
        });
      },
      onPanEnd: (details) {
        if (_isDissolving || _isAppearing) return;
        if (_dragOffset > 80 || _dragOffset < -80) {
          _swipePass();
        } else {
          setState(() {
            _dragOffset = 0.0;
            _dragAngle = 0.0;
          });
        }
      },
      child: Transform.rotate(
        angle: _dragAngle,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          transform: Matrix4.translationValues(_dragOffset, 0, 0),
          child: cardContent,
        ),
      ),
    );
  }

  // Build normal card (idle)
  Widget _buildNormalCard(_NearbyPerson person) {
    final isLiked = _likedUids.contains(person.uid);
    return _buildProfileCardContent(
      person: person,
      isLiked: isLiked,
      showButtons: true,
    );
  }

  // Build dissolving card (scale + fade + particles)
  Widget _buildDissolvingCard(_NearbyPerson person) {
    final isLiked = _likedUids.contains(person.uid);
    return Stack(
      children: [
        Transform.scale(
          scale: 1.0 - _dissolveValue * 0.3,
          child: Opacity(
            opacity: 1.0 - _dissolveValue,
            child: _buildProfileCardContent(
              person: person,
              isLiked: isLiked,
              showButtons: false,
            ),
          ),
        ),
        if (_particles.isNotEmpty && _dissolveValue > 0)
          CustomPaint(
            painter: _ParticlePainter(
              particles: _particles,
              progress: _dissolveValue,
              cardSize: Size(MediaQuery.of(context).size.width - 40, 400),
            ),
            size: Size(MediaQuery.of(context).size.width - 40, 400),
          ),
      ],
    );
  }

  // Build appearing card (fade + scale in)
  Widget _buildAppearingCard(_NearbyPerson person) {
    final isLiked = _likedUids.contains(person.uid);
    return Transform.scale(
      scale: 0.7 + _appearValue * 0.3,
      child: Opacity(
        opacity: _appearValue,
        child: _buildProfileCardContent(
          person: person,
          isLiked: isLiked,
          showButtons: true,
        ),
      ),
    );
  }

  // Helper to build card content (shared)
  Widget _buildProfileCardContent({
    required _NearbyPerson person,
    required bool isLiked,
    required bool showButtons,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(32),
        child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Stack(
            children: [
              SizedBox(
                height: 320,
                width: double.infinity,
                child: _HomeScreenState.buildAvatar(
                  source: person.avatarAsset,
                  size: 320,
                  fallbackColor: darkGreen,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(32),
                    topRight: Radius.circular(32),
                  ),
                ),
              ),
              // Online pill
              Positioned(
                top: 16,
                left: 16,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: person.isOnline ? Colors.green.shade500 : Colors.grey.shade500,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.18),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      if (person.isOnline)
                        Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                          ),
                        ),
                      if (person.isOnline) const SizedBox(width: 6),
                      Text(
                        person.isOnline ? 'متصل الآن' : 'غير متصل',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              // Image counter
              Positioned(
                top: 16,
                right: 16,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.38),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.white.withOpacity(0.25)),
                  ),
                  child: const Text(
                    '1/1',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              // Gradient overlay — تدرّج بثلاث درجات لعمق أكثر
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Container(
                  height: 170,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.black.withOpacity(0.35),
                        Colors.black.withOpacity(0.72),
                      ],
                    ),
                  ),
                ),
              ),
              // Info overlay
              Positioned(
                bottom: 16,
                left: 16,
                right: 16,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          person.name,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 23,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.3,
                            shadows: [
                              Shadow(
                                offset: Offset(0, 2),
                                blurRadius: 6,
                                color: Colors.black38,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.all(3),
                          decoration: BoxDecoration(
                            color: gold,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(color: gold.withOpacity(0.5), blurRadius: 6),
                            ],
                          ),
                          child: const Icon(
                            Icons.verified,
                            color: Colors.white,
                            size: 14,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 5),
                    Row(
                      children: [
                        if (person.age != null)
                          Text(
                            '${person.age} سنة',
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 15,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        if (person.age != null && person.city.isNotEmpty)
                          const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 6),
                            child: Text('•', style: TextStyle(color: Colors.white54)),
                          ),
                        if (person.city.isNotEmpty)
                          Row(
                            children: [
                              const Icon(Icons.location_on_rounded, color: Colors.white70, size: 16),
                              const SizedBox(width: 4),
                              Text(
                                person.city,
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 15,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.18),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.white.withOpacity(0.2)),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.school_rounded, color: Colors.white70, size: 14),
                          SizedBox(width: 4),
                          Text(
                            'طالب جامعي',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 9),
                    Text(
                      'ثق بنفسك دائماً.. لأنك تستحق الأفضل',
                      style: TextStyle(
                        fontSize: 13.5,
                        fontStyle: FontStyle.italic,
                        color: Colors.white.withOpacity(0.9),
                        fontWeight: FontWeight.w500,
                        shadows: const [
                          Shadow(
                            offset: Offset(0, 1),
                            blurRadius: 4,
                            color: Colors.black26,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (showButtons)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _actionButton(
                    icon: Icons.close_rounded,
                    color: Colors.grey.shade500,
                    onTap: _swipePass,
                    size: 62,
                  ),
                  _actionButton(
                    icon: Icons.favorite_rounded,
                    color: isLiked ? darkGreen : gold,
                    onTap: _heartLike,
                    size: 62,
                    hasGlow: true,
                    isLiked: isLiked,
                    isPrimary: true,
                  ),
                ],
              ),
            ),
          if (!showButtons) const SizedBox(height: 20),
        ],
        ),
      ),
    );
  }

  Widget _actionButton({
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
    double size = 56,
    bool hasGlow = false,
    bool isLiked = false,
    bool isPrimary = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: isPrimary ? (isLiked ? darkGreen : gold) : Colors.white,
          shape: BoxShape.circle,
          border: isPrimary
              ? null
              : Border.all(color: Colors.grey.shade200, width: 1.5),
          boxShadow: hasGlow
              ? [
                  BoxShadow(
                    color: color.withOpacity(0.35),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ]
              : [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.12),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
        ),
        child: Icon(
          icon,
          color: isPrimary ? Colors.white : color,
          size: size * 0.42,
        ),
      ),
    );
  }

  // Empty state card
  Widget _buildEmptyCard() {
    return Container(
      height: 420,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.people_outline, size: 60, color: Colors.grey.shade300),
            const SizedBox(height: 16),
            Text(
              'لا يوجد أشخاص جدد حالياً',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: darkGreen,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'سنخبرك عندما نجد أشخاصاً مناسبين لك.',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade500,
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: _loadUserData,
              style: ElevatedButton.styleFrom(
                backgroundColor: gold,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
              icon: const Icon(Icons.refresh),
              label: const Text('تحديث'),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // 5️⃣ NEARBY PEOPLE (unchanged)
  // ============================================================
  Widget _buildNearbySection() {
    if (_isLoadingNearby) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 20),
          child: CircularProgressIndicator(color: darkGreen, strokeWidth: 2),
        ),
      );
    }
    final nearby = _nearbyPeople.skip(1).toList();
    if (nearby.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Icon(Icons.location_on, color: gold, size: 20),
                const SizedBox(width: 6),
                const Text(
                  'أشخاص قريبون',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: darkGreen,
                  ),
                ),
              ],
            ),
            GestureDetector(
              onTap: () {},
              child: Text(
                'عرض الكل >',
                style: TextStyle(
                  fontSize: 14,
                  color: gold,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 120,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: nearby.length,
            separatorBuilder: (_, __) => const SizedBox(width: 14),
            itemBuilder: (context, index) {
              final p = nearby[index];
              return _NearbyPersonCard(
                person: p,
                darkGreen: darkGreen,
                gold: gold,
              );
            },
          ),
        ),
      ],
    );
  }

  // ============================================================
  // 🧭 BOTTOM NAVIGATION (removed "اكتشف")
  // ============================================================
  Widget _buildBottomNav() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      padding: const EdgeInsets.symmetric(vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(40),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.15),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _navItem(Icons.home, 'الرئيسية', _selectedIndex == 0, () => _onNavTap(0)),
          _navItem(Icons.favorite, 'الإعجابات', _selectedIndex == 1, () => _onNavTap(1),
              badgeCount: _pendingInvitationsCount),
          _navItem(Icons.chat, 'المحادثات', _selectedIndex == 2, () => _onNavTap(2),
              badgeCount: _unreadMessagesCount),
          _navItem(Icons.person, 'حسابي', false, () => _onNavTap(3), isProfile: true),
        ],
      ),
    );
  }

  Widget _navItem(
    IconData icon,
    String label,
    bool selected,
    VoidCallback onTap, {
    bool isProfile = false,
    int badgeCount = 0,
  }) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              isProfile
                  ? Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: selected ? gold : Colors.grey.shade300, width: 2),
                      ),
                      child: ClipOval(
                        child: _HomeScreenState.buildAvatar(
                          source: _avatarAsset,
                          size: 28,
                          fallbackColor: darkGreen,
                        ),
                      ),
                    )
                  : Icon(
                      icon,
                      color: selected ? darkGreen : Colors.grey.shade400,
                      size: 24,
                    ),
              // ✅ بادج حي لعدد الدعوات/الرسائل غير المقروءة على أيقونة
              // "الإعجابات" و"المحادثات" فـ الشريط السفلي
              if (badgeCount > 0)
                Positioned(
                  top: -6,
                  right: -8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 5),
                    constraints: const BoxConstraints(minWidth: 17, minHeight: 17),
                    decoration: BoxDecoration(
                      color: const Color(0xFFDE3B40),
                      shape: badgeCount > 9 ? BoxShape.rectangle : BoxShape.circle,
                      borderRadius: badgeCount > 9 ? BorderRadius.circular(9) : null,
                      border: Border.all(color: Colors.white, width: 1.6),
                    ),
                    child: Center(
                      child: Text(
                        badgeCount > 9 ? '9+' : '$badgeCount',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 9,
                          fontWeight: FontWeight.w800,
                          height: 1.3,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: selected ? FontWeight.w800 : FontWeight.w500,
              color: selected ? darkGreen : Colors.grey.shade400,
            ),
          ),
          if (selected && !isProfile)
            Container(
              margin: const EdgeInsets.only(top: 2),
              width: 6,
              height: 6,
              decoration: BoxDecoration(
                color: gold,
                shape: BoxShape.circle,
              ),
            ),
        ],
      ),
    );
  }
}

// ============================================================
// 🧩 PARTICLE DATA
// ============================================================
class _Particle {
  final Offset startOffset;
  final double angle;
  final double distance;
  final double size;
  final double speed;
  final double opacity;
  final Color color;

  _Particle({
    required this.startOffset,
    required this.angle,
    required this.distance,
    required this.size,
    required this.speed,
    required this.opacity,
    required this.color,
  });
}

// ============================================================
// 🎨 PARTICLE PAINTER
// ============================================================
class _ParticlePainter extends CustomPainter {
  final List<_Particle> particles;
  final double progress;
  final Size cardSize;

  _ParticlePainter({
    required this.particles,
    required this.progress,
    required this.cardSize,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;
    final center = Offset(size.width / 2, size.height / 2);

    for (final p in particles) {
      final dx = p.startOffset.dx + cos(p.angle) * p.distance * progress * p.speed;
      final dy = p.startOffset.dy + sin(p.angle) * p.distance * progress * p.speed;
      final currentOffset = center + Offset(dx, dy);

      final opacity = p.opacity * (1 - progress);
      if (opacity <= 0) continue;

      paint.color = p.color.withOpacity(opacity);
      final radius = p.size * (1 - progress * 0.5);
      canvas.drawCircle(currentOffset, radius, paint);
    }
  }

  @override
  bool shouldRepaint(_ParticlePainter oldDelegate) => true;
}

// ============================================================
// 🧩 NEARBY PERSON CARD (unchanged)
// ============================================================
class _NearbyPersonCard extends StatelessWidget {
  final _NearbyPerson person;
  final Color darkGreen;
  final Color gold;

  const _NearbyPersonCard({
    required this.person,
    required this.darkGreen,
    required this.gold,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 86,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: darkGreen.withOpacity(0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Stack(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: gold.withOpacity(0.3), width: 1.5),
                ),
                child: ClipOval(
                  child: _HomeScreenState.buildAvatar(
                    source: person.avatarAsset,
                    size: 52,
                    fallbackColor: darkGreen,
                  ),
                ),
              ),
              if (person.isOnline)
                Positioned(
                  bottom: 2,
                  right: 2,
                  child: Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: Colors.green.shade400,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            person.name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: darkGreen,
            ),
          ),
          const SizedBox(height: 2),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.location_on, size: 10, color: gold),
              const SizedBox(width: 2),
              Text(
                '1.2 كم',
                style: TextStyle(
                  fontSize: 10,
                  color: Colors.grey.shade500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
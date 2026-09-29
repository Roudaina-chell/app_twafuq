// screens/chat/chat_list_tab.dart
//
// ✅ قائمة المحادثات (Inbox) — نفس التصميم لي فـ الصورة المرجعية
// (عنوان "الدردشات" + شريط بحث + ليستة مسطحة بخطوط فاصلة)، لكن
// دابا مربوطة بـ Firestore حقيقي (ماشي بيانات ثابتة).
//
// كتجمع آخر رسالة فـ كل محادثة (chatId) لي أنت طرف فيها
// (fromUserId == me أو toUserId == me)، كتجيب معلومات الطرف الآخر
// (name/avatar/city) من collection('users')، وكتفتح
// ChatConversationScreen الحقيقي كي تدوس على واحد.
//
// عداد الرسائل غير المقروءة (badge) لكل محادثة مبني على حقل "read"
// فـ كل document من collection('messages').

import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'chat_conversation_screen.dart';
import '../../services/likes_service.dart';

class _ConversationPreview {
  final String chatId;
  final String otherUid;
  final String lastMessage;
  final Timestamp? lastTimestamp;
  final bool lastFromMe;
  final int unreadCount;

  _ConversationPreview({
    required this.chatId,
    required this.otherUid,
    required this.lastMessage,
    required this.lastTimestamp,
    required this.lastFromMe,
    required this.unreadCount,
  });
}

// ============================================================
// ✅ صورة الأفاتار الحقيقية — تدعم asset محلي و رابط شبكة، مع
// fallback لحرف اسم الشخص فـ دائرة ملونة (بحال التصميم المرجعي)
// إلا ماكانتش الصورة موجودة أو فشلت.
// ============================================================
Widget buildAvatarImage({
  required String? source,
  required String name,
  required double size,
  required Color fallbackColor,
}) {
  Widget letterFallback() {
    final letter = name.trim().isNotEmpty ? name.trim()[0] : '؟';
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: fallbackColor.withValues(alpha: 0.12),
      ),
      child: Text(
        letter,
        style: TextStyle(
          fontSize: size * 0.4,
          fontWeight: FontWeight.w800,
          color: fallbackColor,
        ),
      ),
    );
  }

  if (source == null || source.trim().isEmpty) {
    return letterFallback();
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
              errorBuilder: (context, error, stack) {
                debugPrint('❌ Avatar (network) load failed: $source -> $error');
                return letterFallback();
              },
            )
          : Image.asset(
              source,
              fit: BoxFit.cover,
              alignment: Alignment.topCenter,
              errorBuilder: (context, error, stack) {
                debugPrint('❌ Avatar (asset) load failed: $source -> $error');
                return letterFallback();
              },
            ),
    ),
  );
}

class ChatsListTab extends StatefulWidget {
  const ChatsListTab({super.key});

  @override
  State<ChatsListTab> createState() => _ChatsListTabState();
}

class _ChatsListTabState extends State<ChatsListTab> {
  static const Color darkGreen = Color(0xFF0F3D2E);
  static const Color darkGreenLight = Color(0xFF1A6B4A);
  static const Color gold = Color(0xFFC9A24B);
  static const Color bg = Color(0xFFFAF7F2);

  List<QueryDocumentSnapshot<Map<String, dynamic>>> _sentDocs = [];
  List<QueryDocumentSnapshot<Map<String, dynamic>>> _receivedDocs = [];
  bool _sentLoaded = false;
  bool _receivedLoaded = false;
  bool _hasError = false;

  // ✅ لا تظهر أي محادثة إلا لشخص يوجد بيني وبينه Match فعلي (البند 8+7):
  // لا Invitation معلّقة، لا Invitation مرفوضة، بل Match مقبول فقط.
  Set<String> _matchedUids = {};
  bool _matchesLoaded = false;

  // 🗂️ الأرشيف + علامة "غير مقروء" اليدوية — مبنيين على otherUid باش
  // يخدمو حتى مع محادثات Match بلا رسائل بعد (chatId فارغ).
  Set<String> _archivedUids = {};
  Set<String> _manualUnreadUids = {};
  bool _archivedLoaded = false;
  bool _manualUnreadLoaded = false;

  // 📌 المحادثات المثبّتة — كتبان فـ رأس القائمة دايماً
  Set<String> _pinnedUids = {};
  bool _pinnedLoaded = false;

  // 🚫 المستخدمين المحظورين (فـ أي اتجاه) — نخبيوهم كاملين من قائمة
  // المحادثات، حيت ما بقاش كاين معنى نبينو محادثة معاهم
  Set<String> _blockedUids = {};
  bool _blockedLoaded = false;

  // 📂 فلتر القائمة الحالي: all (عادي، بلا أرشيف) / archived / unread
  String _filterMode = 'all';

  StreamSubscription? _sentSub;
  StreamSubscription? _receivedSub;
  StreamSubscription<User?>? _authSub;
  StreamSubscription<List<String>>? _matchesSub;
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _archivedSub;
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _manualUnreadSub;
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _pinnedSub;
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _blockedSub;

  final Map<String, Map<String, dynamic>?> _userCache = {};
  final Map<String, bool> _blockedByOtherCache = {};
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  String? get _myUid => FirebaseAuth.instance.currentUser?.uid;

  @override
  void initState() {
    super.initState();
    // ✅ نستنو المستخدم يكون جاهز (auth state) قبل ما نربطو الـ streams،
    // باش ما تبقاش الليستة "معلقة" إلا كانت initState تلقات قبل ما
    // يكمل تسجيل الدخول.
    _authSub = FirebaseAuth.instance.authStateChanges().listen((user) {
      if (user != null) {
        _attachStreams(user.uid);
      }
    });
    if (_myUid != null) {
      _attachStreams(_myUid!);
    }
    _searchController.addListener(() {
      setState(() => _searchQuery = _searchController.text.trim());
    });
  }

  void _attachStreams(String me) {
    _sentSub?.cancel();
    _receivedSub?.cancel();
    _matchesSub?.cancel();
    _archivedSub?.cancel();
    _manualUnreadSub?.cancel();
    _blockedSub?.cancel();
    _pinnedSub?.cancel();

    _blockedSub = FirebaseFirestore.instance
        .collection('users')
        .doc(me)
        .collection('blocked')
        .snapshots()
        .listen(
          (snap) {
            if (!mounted) return;
            setState(() {
              _blockedUids = snap.docs.map((d) => d.id).toSet();
              _blockedLoaded = true;
            });
          },
          onError: (e) {
            debugPrint('❌ Chats list (blocked) stream failed: $e');
            if (!mounted) return;
            setState(() => _blockedLoaded = true);
          },
        );

    _archivedSub = FirebaseFirestore.instance
        .collection('users')
        .doc(me)
        .collection('archivedChats')
        .snapshots()
        .listen(
          (snap) {
            if (!mounted) return;
            setState(() {
              _archivedUids = snap.docs.map((d) => d.id).toSet();
              _archivedLoaded = true;
            });
          },
          onError: (e) {
            debugPrint('❌ Chats list (archived) stream failed: $e');
            if (!mounted) return;
            setState(() => _archivedLoaded = true);
          },
        );

    _manualUnreadSub = FirebaseFirestore.instance
        .collection('users')
        .doc(me)
        .collection('manualUnread')
        .snapshots()
        .listen(
          (snap) {
            if (!mounted) return;
            setState(() {
              _manualUnreadUids = snap.docs.map((d) => d.id).toSet();
              _manualUnreadLoaded = true;
            });
          },
          onError: (e) {
            debugPrint('❌ Chats list (manual unread) stream failed: $e');
            if (!mounted) return;
            setState(() => _manualUnreadLoaded = true);
          },
        );

    _pinnedSub = FirebaseFirestore.instance
        .collection('users')
        .doc(me)
        .collection('pinnedChats')
        .snapshots()
        .listen(
          (snap) {
            if (!mounted) return;
            setState(() {
              _pinnedUids = snap.docs.map((d) => d.id).toSet();
              _pinnedLoaded = true;
            });
          },
          onError: (e) {
            debugPrint('❌ Chats list (pinned) stream failed: $e');
            if (!mounted) return;
            setState(() => _pinnedLoaded = true);
          },
        );

    _matchesSub = LikesService.instance.myMatchedUserIdsStream().listen(
      (uids) {
        if (!mounted) return;
        setState(() {
          _matchedUids = uids.toSet();
          _matchesLoaded = true;
        });
      },
      onError: (e) {
        debugPrint('❌ Chats list (matches) stream failed: $e');
        if (!mounted) return;
        setState(() => _matchesLoaded = true);
      },
    );

    _sentSub = FirebaseFirestore.instance
        .collection('messages')
        .where('fromUserId', isEqualTo: me)
        .snapshots()
        .listen(
          (snap) {
            if (!mounted) return;
            setState(() {
              _sentDocs = snap.docs;
              _sentLoaded = true;
            });
          },
          onError: (e) {
            debugPrint('❌ Chats list (sent) stream failed: $e');
            if (!mounted) return;
            setState(() {
              _hasError = true;
              _sentLoaded = true;
            });
          },
        );

    _receivedSub = FirebaseFirestore.instance
        .collection('messages')
        .where('toUserId', isEqualTo: me)
        .snapshots()
        .listen(
          (snap) {
            if (!mounted) return;
            setState(() {
              _receivedDocs = snap.docs;
              _receivedLoaded = true;
            });
          },
          onError: (e) {
            debugPrint('❌ Chats list (received) stream failed: $e');
            if (!mounted) return;
            setState(() {
              _hasError = true;
              _receivedLoaded = true;
            });
          },
        );
  }

  @override
  void dispose() {
    _sentSub?.cancel();
    _receivedSub?.cancel();
    _matchesSub?.cancel();
    _archivedSub?.cancel();
    _manualUnreadSub?.cancel();
    _blockedSub?.cancel();
    _pinnedSub?.cancel();
    _authSub?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  Future<Map<String, dynamic>?> _getUserInfo(String uid) async {
    if (_userCache.containsKey(uid)) return _userCache[uid];
    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .get();
      final data = doc.data();
      _userCache[uid] = data;
      return data;
    } catch (e) {
      debugPrint('❌ Chats list: user info fetch failed for $uid -> $e');
      _userCache[uid] = null;
      return null;
    }
  }

  // 🚫 واش هو حظرني (أنا الطرف المحظور عندو)؟ — كنتحقق من
  // users/{otherUid}/blocked/{myUid}. لازم Firestore rule تسمح
  // بـ "get" لهاذ الدوكيومنت بالضبط (حيت الـ id يطابق طلبي أنا).
  Future<bool> _amIBlockedBy(String otherUid) async {
    final me = _myUid;
    if (me == null) return false;
    if (_blockedByOtherCache.containsKey(otherUid)) {
      return _blockedByOtherCache[otherUid]!;
    }
    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(otherUid)
          .collection('blocked')
          .doc(me)
          .get();
      _blockedByOtherCache[otherUid] = doc.exists;
      return doc.exists;
    } catch (e) {
      debugPrint('❌ Chats list: blocked-by check failed for $otherUid -> $e');
      _blockedByOtherCache[otherUid] = false;
      return false;
    }
  }

  List<_ConversationPreview> _buildConversations() {
    final me = _myUid;
    if (me == null) return [];

    final Map<String, _ConversationPreview> latestByChat = {};
    final Map<String, int> unreadByChat = {};

    void process(QueryDocumentSnapshot<Map<String, dynamic>> doc) {
      final data = doc.data();
      final chatId = data['chatId'] as String?;
      if (chatId == null) return;
      final fromUserId = data['fromUserId'] as String?;
      final toUserId = data['toUserId'] as String?;
      final otherUid = fromUserId == me ? toUserId : fromUserId;
      if (otherUid == null) return;
      final ts = data['timestamp'] as Timestamp?;
      final text = (data['text'] as String?) ?? '';

      final existing = latestByChat[chatId];
      final bool isNewer =
          existing == null ||
          existing.lastTimestamp == null ||
          (ts != null && ts.compareTo(existing.lastTimestamp!) > 0);

      if (isNewer) {
        latestByChat[chatId] = _ConversationPreview(
          chatId: chatId,
          otherUid: otherUid,
          lastMessage: text,
          lastTimestamp: ts,
          lastFromMe: fromUserId == me,
          unreadCount: unreadByChat[chatId] ?? 0,
        );
      }
    }

    for (final d in _receivedDocs) {
      final data = d.data();
      final chatId = data['chatId'] as String?;
      if (chatId == null) continue;
      final bool isRead = data['read'] == true;
      if (!isRead) {
        unreadByChat[chatId] = (unreadByChat[chatId] ?? 0) + 1;
      }
    }

    for (final d in _sentDocs) {
      process(d);
    }
    for (final d in _receivedDocs) {
      process(d);
    }

    final list = latestByChat.entries.map((entry) {
      final p = entry.value;
      return _ConversationPreview(
        chatId: p.chatId,
        otherUid: p.otherUid,
        lastMessage: p.lastMessage,
        lastTimestamp: p.lastTimestamp,
        lastFromMe: p.lastFromMe,
        unreadCount: unreadByChat[entry.key] ?? 0,
      );
    }).toList();

    // ✅ فلترة صارمة: لا تظهر أي محادثة إلا لشخص عندي معه Match فعلي.
    // هذا يمنع ظهور محادثات لأشخاص Invitation معهم ما زالت pending أو
    // تم رفضها (البند 8).
    final matched = list.where((c) => _matchedUids.contains(c.otherUid)).toList();

    // ✅ بعد Accept مباشرة، يجب أن تظهر المحادثة فـ "المحادثات" حتى لو
    // ما تبادلش الطرفان أي رسالة بعد (البند 18) — نضيف صفوف فارغة
    // للـ Matches التي لا رسائل لها بعد.
    final existingOtherUids = matched.map((c) => c.otherUid).toSet();
    for (final uid in _matchedUids) {
      if (!existingOtherUids.contains(uid)) {
        matched.add(
          _ConversationPreview(
            chatId: '',
            otherUid: uid,
            lastMessage: '',
            lastTimestamp: null,
            lastFromMe: false,
            unreadCount: 0,
          ),
        );
      }
    }

    // ✅ ترتيب: المثبّتة (📌) أولاً دايماً، بعدها الأحدث فالأحدث
    matched.sort((a, b) {
      final aPinned = _pinnedUids.contains(a.otherUid);
      final bPinned = _pinnedUids.contains(b.otherUid);
      if (aPinned != bPinned) return aPinned ? -1 : 1;

      if (a.lastTimestamp == null && b.lastTimestamp == null) return 0;
      if (a.lastTimestamp == null) return 1;
      if (b.lastTimestamp == null) return -1;
      return b.lastTimestamp!.compareTo(a.lastTimestamp!);
    });
    return matched;
  }

  // 🔵 العداد الفعلي: رسائل حقيقية غير مقروءة، أو 1 إلا كانت العلامة
  // اليدوية "غير مقروء" مفعّلة بلا رسائل حقيقية.
  int _effectiveUnread(_ConversationPreview c) {
    if (c.unreadCount > 0) return c.unreadCount;
    return _manualUnreadUids.contains(c.otherUid) ? 1 : 0;
  }

  String _formatTimestamp(Timestamp? ts) {
    if (ts == null) return '';
    final now = DateTime.now();
    final date = ts.toDate();
    final diff = now.difference(date);

    if (diff.inMinutes < 1) return 'الآن';
    if (diff.inHours < 1) return 'منذ ${diff.inMinutes} د';
    if (diff.inHours < 24 && now.day == date.day) {
      final hour = date.hour % 12 == 0 ? 12 : date.hour % 12;
      final minute = date.minute.toString().padLeft(2, '0');
      final period = date.hour >= 12 ? 'م' : 'ص';
      return '$hour:$minute $period';
    }
    if (diff.inDays < 7) {
      const days = [
        'الإثنين',
        'الثلاثاء',
        'الأربعاء',
        'الخميس',
        'الجمعة',
        'السبت',
        'الأحد',
      ];
      return days[date.weekday - 1];
    }
    return '${date.day}/${date.month}';
  }

  @override
  Widget build(BuildContext context) {
    final me = _myUid;

    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            const SizedBox(height: 16),
            _buildSearchBar(),
            const SizedBox(height: 6),
            _buildFilterChip(),
            Expanded(child: _buildBody(me)),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // 🔝 الهيدر: "المحادثات" بتدرّج لوني (نفس لغة صفحة الإعجابات) +
  // بادج حي لعدد المحادثات غير المقروءة
  // ============================================================
  Widget _buildHeader() {
    final conversations = (_sentLoaded && _receivedLoaded && _matchesLoaded)
        ? _buildConversations()
        : const <_ConversationPreview>[];
    final int unreadTotal = conversations
        .where((c) => !_archivedUids.contains(c.otherUid) && !_blockedUids.contains(c.otherUid))
        .fold(0, (sum, c) => sum + _effectiveUnread(c));

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'المحادثات',
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                    color: darkGreen,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'تواصل بسهولة مع الجميع',
                  style: TextStyle(
                    fontSize: 12.5,
                    color: Colors.grey.shade600,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          if (unreadTotal > 0)
            Container(
              margin: const EdgeInsets.only(left: 10),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: darkGreen,
                borderRadius: BorderRadius.circular(18),
                boxShadow: [
                  BoxShadow(
                    color: darkGreen.withValues(alpha: 0.22),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    unreadTotal > 99 ? '99+' : '$unreadTotal',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      height: 1,
                    ),
                  ),
                  const SizedBox(height: 1),
                  Text(
                    'غير مقروء',
                    style: TextStyle(
                      color: gold.withValues(alpha: 0.95),
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          Container(
            decoration: BoxDecoration(
              color: _filterMode != 'all' ? darkGreen : Colors.white,
              shape: BoxShape.circle,
              border: Border.all(
                color: _filterMode != 'all' ? darkGreen : Colors.grey.shade100,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withValues(alpha: 0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: IconButton(
              icon: Icon(
                Icons.more_vert_rounded,
                color: _filterMode != 'all' ? Colors.white : darkGreen,
                size: 20,
              ),
              onPressed: () => _openListMenu(context),
              padding: const EdgeInsets.all(8),
              constraints: const BoxConstraints(),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // 🔍 شريط البحث
  // ============================================================
  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        height: 50,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.grey.shade100),
          boxShadow: [
            BoxShadow(
              color: darkGreen.withValues(alpha: 0.05),
              blurRadius: 14,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(5),
              decoration: BoxDecoration(
                color: darkGreen.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.search_rounded, color: darkGreen, size: 16),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: TextField(
                controller: _searchController,
                textAlign: TextAlign.right,
                decoration: InputDecoration(
                  border: InputBorder.none,
                  isDense: true,
                  hintText: 'ابحث عن محادثة...',
                  hintStyle: TextStyle(
                    color: Colors.grey.shade400,
                    fontSize: 13.5,
                  ),
                ),
                style: const TextStyle(fontSize: 13.5, color: darkGreen),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // 🏷️ شيبة الفلتر النشط (أرشيف / غير مقروءة) — تبان تحت شريط
  // البحث وفيها زر "X" باش ترجع للقائمة العادية
  // ============================================================
  Widget _buildFilterChip() {
    if (_filterMode == 'all') return const SizedBox(height: 6);

    final bool isArchive = _filterMode == 'archived';
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
      child: Align(
        alignment: Alignment.centerRight,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          decoration: BoxDecoration(
            color: darkGreen.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(30),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              GestureDetector(
                onTap: () => setState(() => _filterMode = 'all'),
                child: Icon(Icons.close_rounded, size: 15, color: darkGreen.withValues(alpha: 0.7)),
              ),
              const SizedBox(width: 6),
              Text(
                isArchive ? 'الأرشيف' : 'غير المقروءة',
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: darkGreen),
              ),
              const SizedBox(width: 6),
              Icon(
                isArchive ? Icons.archive_rounded : Icons.mark_email_unread_rounded,
                size: 14,
                color: darkGreen.withValues(alpha: 0.7),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ============================================================
  // ⋮ قائمة "الأرشيف / غير مقروءة" اللي كتفتح من زر الثلاث نقط
  // فـ الهيدر — كي تختار وحدة، القائمة كتتفلتر على حساب الرسائل
  // ============================================================
  void _openListMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (ctx) {
        Widget row({
          required IconData icon,
          required Color color,
          required String label,
          required String value,
        }) {
          final bool active = _filterMode == value;
          return InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () {
              setState(() => _filterMode = active ? 'all' : value);
              Navigator.pop(ctx);
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
              decoration: BoxDecoration(
                color: active ? color.withValues(alpha: 0.08) : Colors.transparent,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(icon, color: color, size: 19),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      label,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: darkGreen,
                      ),
                    ),
                  ),
                  if (active) Icon(Icons.check_circle_rounded, color: color, size: 19),
                ],
              ),
            ),
          );
        }

        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(18, 12, 18, 18),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildSheetHandle(),
                const SizedBox(height: 16),
                row(
                  icon: Icons.archive_rounded,
                  color: gold,
                  label: 'الأرشيف',
                  value: 'archived',
                ),
                const SizedBox(height: 4),
                row(
                  icon: Icons.mark_email_unread_rounded,
                  color: darkGreen,
                  label: 'غير المقروءة',
                  value: 'unread',
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSheetHandle() {
    return Container(
      width: 42,
      height: 4,
      decoration: BoxDecoration(
        color: Colors.grey.shade300,
        borderRadius: BorderRadius.circular(4),
      ),
    );
  }

  // ============================================================
  // 🍔 قائمة الإجراءات السريعة كي تدوس مطوّل على محادثة: حذف،
  // أرشفة، تثبيت، تحديد كغير مقروء — شكل modern بإيموجي/أيقونات دائرية
  // ============================================================
  void _showConversationActions({
    required _ConversationPreview convo,
    required String name,
  }) {
    final bool isArchived = _archivedUids.contains(convo.otherUid);
    final bool isPinned = _pinnedUids.contains(convo.otherUid);
    final bool hasUnread = _effectiveUnread(convo) > 0;

    Widget action({
      required IconData icon,
      required Color color,
      required String label,
      required VoidCallback onTap,
    }) {
      return GestureDetector(
        onTap: onTap,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 54,
              height: 54,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 23),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: darkGreen),
            ),
          ],
        ),
      );
    }

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(18, 12, 18, 22),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildSheetHandle(),
                const SizedBox(height: 14),
                Text(
                  name,
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: darkGreen),
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    action(
                      icon: Icons.delete_rounded,
                      color: Colors.red.shade600,
                      label: 'حذف',
                      onTap: () {
                        Navigator.pop(ctx);
                        _confirmDeleteConversation(convo);
                      },
                    ),
                    action(
                      icon: isArchived ? Icons.unarchive_rounded : Icons.archive_rounded,
                      color: gold,
                      label: isArchived ? 'إلغاء الأرشفة' : 'أرشفة',
                      onTap: () {
                        Navigator.pop(ctx);
                        _toggleArchive(convo);
                      },
                    ),
                    action(
                      icon: Icons.push_pin_rounded,
                      color: darkGreenLight,
                      label: isPinned ? 'إلغاء التثبيت' : 'تثبيت',
                      onTap: () {
                        Navigator.pop(ctx);
                        _togglePin(convo);
                      },
                    ),
                    action(
                      icon: hasUnread ? Icons.mark_email_read_rounded : Icons.mark_email_unread_rounded,
                      color: darkGreen,
                      label: hasUnread ? 'تحديد كمقروء' : 'تحديد كغير مقروء',
                      onTap: () {
                        Navigator.pop(ctx);
                        _toggleUnread(convo, currentlyUnread: hasUnread);
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _confirmDeleteConversation(_ConversationPreview convo) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        title: const Text('حذف المحادثة', style: TextStyle(color: darkGreen, fontWeight: FontWeight.bold)),
        content: const Text(
          'غادي تتحذف كل الرسائل بيناتكم نهائياً. هاذ الشي ما يتراجعش.',
          style: TextStyle(fontSize: 13),
        ),
        actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('إلغاء', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
            child: const Text('حذف', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    if (confirm != true) return;

    final me = _myUid;
    try {
      if (convo.chatId.isNotEmpty) {
        final snap = await FirebaseFirestore.instance
            .collection('messages')
            .where('chatId', isEqualTo: convo.chatId)
            .get();
        final batch = FirebaseFirestore.instance.batch();
        for (final doc in snap.docs) {
          batch.delete(doc.reference);
        }
        await batch.commit();
      }
      if (me != null) {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(me)
            .collection('archivedChats')
            .doc(convo.otherUid)
            .delete()
            .catchError((_) {});
        await FirebaseFirestore.instance
            .collection('users')
            .doc(me)
            .collection('manualUnread')
            .doc(convo.otherUid)
            .delete()
            .catchError((_) {});
        await FirebaseFirestore.instance
            .collection('users')
            .doc(me)
            .collection('pinnedChats')
            .doc(convo.otherUid)
            .delete()
            .catchError((_) {});
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('🗑️ تم حذف المحادثة')),
      );
    } catch (e) {
      debugPrint('❌ Delete conversation (list) failed: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('❌ فشل الحذف: $e')),
      );
    }
  }

  Future<void> _toggleArchive(_ConversationPreview convo) async {
    final me = _myUid;
    if (me == null) return;
    final ref = FirebaseFirestore.instance
        .collection('users')
        .doc(me)
        .collection('archivedChats')
        .doc(convo.otherUid);
    try {
      if (_archivedUids.contains(convo.otherUid)) {
        await ref.delete();
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('↩️ تم إلغاء الأرشفة')),
        );
      } else {
        await ref.set({'chatId': convo.chatId, 'at': FieldValue.serverTimestamp()});
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('📥 تم نقل المحادثة للأرشيف')),
        );
      }
    } catch (e) {
      debugPrint('❌ Toggle archive failed: $e');
    }
  }

  // 📌 تثبيت/إلغاء تثبيت محادثة — المحادثات المثبّتة كتبان فـ رأس
  // القائمة دايماً (_buildConversations كترتبهم قبل الباقي)
  Future<void> _togglePin(_ConversationPreview convo) async {
    final me = _myUid;
    if (me == null) return;
    final ref = FirebaseFirestore.instance
        .collection('users')
        .doc(me)
        .collection('pinnedChats')
        .doc(convo.otherUid);
    try {
      if (_pinnedUids.contains(convo.otherUid)) {
        await ref.delete();
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('📌 تم إلغاء التثبيت')),
        );
      } else {
        await ref.set({'chatId': convo.chatId, 'at': FieldValue.serverTimestamp()});
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('📌 تم تثبيت المحادثة')),
        );
      }
    } catch (e) {
      debugPrint('❌ Toggle pin failed: $e');
    }
  }

  Future<void> _toggleUnread(_ConversationPreview convo, {required bool currentlyUnread}) async {
    final me = _myUid;
    if (me == null) return;
    final flagRef = FirebaseFirestore.instance
        .collection('users')
        .doc(me)
        .collection('manualUnread')
        .doc(convo.otherUid);
    try {
      if (currentlyUnread) {
        // ✅ تحديد كمقروء: نحيّدو العلامة اليدوية + نعلّمو الرسائل
        // الحقيقية الغير مقروءة كـ "مقروءة" (إلا كانت موجودة)
        await flagRef.delete().catchError((_) {});
        if (convo.unreadCount > 0 && convo.chatId.isNotEmpty) {
          final snap = await FirebaseFirestore.instance
              .collection('messages')
              .where('chatId', isEqualTo: convo.chatId)
              .where('toUserId', isEqualTo: me)
              .where('read', isEqualTo: false)
              .get();
          final batch = FirebaseFirestore.instance.batch();
          for (final doc in snap.docs) {
            batch.update(doc.reference, {'read': true});
          }
          await batch.commit();
        }
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('✅ تم تحديدها كمقروءة')),
        );
      } else {
        await flagRef.set({'at': FieldValue.serverTimestamp()});
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('🔵 تم تحديدها كغير مقروءة')),
        );
      }
    } catch (e) {
      debugPrint('❌ Toggle unread failed: $e');
    }
  }

  Widget _buildBody(String? me) {
    if (me == null) {
      return _buildInfoState(
        icon: Icons.person_off_rounded,
        title: 'خاصك تسجل الدخول',
        subtitle: 'باش تشوف رسائلك خاصك تكون مسجل الدخول',
      );
    }

    if (_hasError) {
      return _buildInfoState(
        icon: Icons.error_outline_rounded,
        title: 'تعذر تحميل الرسائل',
        subtitle: 'تأكد من الاتصال وعاود المحاولة',
      );
    }

    if (!_sentLoaded || !_receivedLoaded || !_matchesLoaded || !_archivedLoaded || !_manualUnreadLoaded || !_blockedLoaded || !_pinnedLoaded) {
      return const Center(
        child: CircularProgressIndicator(color: darkGreen, strokeWidth: 2.4),
      );
    }

    var conversations = _buildConversations();

    // 🚫 نحيّدو المستخدمين المحظورين كاملين — ما يبانوش فـ حتى فلتر
    conversations = conversations.where((c) => !_blockedUids.contains(c.otherUid)).toList();

    // 📂 تطبيق الفلتر الحالي: عادي (بلا أرشيف) / أرشيف فقط / غير مقروءة فقط
    if (_filterMode == 'archived') {
      conversations = conversations.where((c) => _archivedUids.contains(c.otherUid)).toList();
    } else if (_filterMode == 'unread') {
      conversations = conversations.where((c) => _effectiveUnread(c) > 0).toList();
    } else {
      conversations = conversations.where((c) => !_archivedUids.contains(c.otherUid)).toList();
    }

    if (conversations.isEmpty) {
      if (_filterMode == 'archived') {
        return _buildInfoState(
          icon: Icons.archive_outlined,
          title: 'الأرشيف فارغ',
          subtitle: 'المحادثات اللي تؤرشفها غادي تبان هنا',
        );
      }
      if (_filterMode == 'unread') {
        return _buildInfoState(
          icon: Icons.mark_email_read_outlined,
          title: 'ماكاين حتى محادثة غير مقروءة',
          subtitle: 'كل رسائلك مقروءة، برافو 👌',
        );
      }
      return _buildInfoState(
        icon: Icons.chat_bubble_outline_rounded,
        title: 'ماكاين حتى محادثة',
        subtitle: 'كي يقبل حد الإعجاب معاك (Match)، المحادثة رح تبان هنا',
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(14, 6, 14, 100),
      itemCount: conversations.length,
      itemBuilder: (context, index) {
        final convo = conversations[index];
        return FutureBuilder<Map<String, dynamic>?>(
          future: _getUserInfo(convo.otherUid),
          builder: (context, snap) {
            final userData = snap.data;
            final name =
                (userData?['fullName'] as String?) ??
                (userData?['name'] as String?) ??
                'مستخدم';

            // ✅ فلترة البحث بالاسم
            if (_searchQuery.isNotEmpty &&
                !name.toLowerCase().contains(_searchQuery.toLowerCase())) {
              return const SizedBox.shrink();
            }

            final avatarAsset =
                (userData?['avatarAsset'] as String?) ??
                (userData?['avatarPath'] as String?);
            final bool isOnline = userData?['isOnline'] == true;

            // ✅ Match بدون أي رسالة بعد (chatId فارغ = تمت إضافته هنا
            // فقط لأن Match موجود) — نعرض دعوة لطيفة لبدء الحديث بدل
            // إيحاء "📎 رسالة" الخاص برسالة فعلية غير موجودة.
            final bool isMatchOnly = convo.chatId.isEmpty;
            final String lastMessageDisplay =
                isMatchOnly ? 'تم التوافق — ابدأ المحادثة الآن 👋' : convo.lastMessage;

            final bool isArchived = _archivedUids.contains(convo.otherUid);
            final bool isPinned = _pinnedUids.contains(convo.otherUid);
            final bool hasUnread = _effectiveUnread(convo) > 0;

            // 🚫 نتحقّقو واش هو حظرني — إلا كان الجواب "إيه"، نبدّلو
            // الصف باش يبين "غير متاح" ويفهم بلي رانا حظرينو
            return FutureBuilder<bool>(
              future: _amIBlockedBy(convo.otherUid),
              builder: (context, blockedSnap) {
                final bool blockedByOther = blockedSnap.data == true;
                final String finalLastMessage =
                    blockedByOther ? '🚫 غير متاح' : lastMessageDisplay;
                final bool finalIsOnline = blockedByOther ? false : isOnline;

                return _SwipeableConversationRow(
                  isArchived: isArchived,
                  isPinned: isPinned,
                  onDelete: () => _confirmDeleteConversation(convo),
                  onArchive: () => _toggleArchive(convo),
                  onPin: () => _togglePin(convo),
                  onToggleUnread: () => _toggleUnread(convo, currentlyUnread: hasUnread),
                  hasUnread: hasUnread,
                  child: _ConversationRow(
                    name: name,
                    avatarAsset: avatarAsset,
                    isOnline: finalIsOnline,
                    isMatchOnly: isMatchOnly,
                    isPinned: isPinned,
                    isBlockedByOther: blockedByOther,
                    lastMessage: finalLastMessage,
                    unreadCount: _effectiveUnread(convo),
                    timeLabel: _formatTimestamp(convo.lastTimestamp),
                    darkGreen: darkGreen,
                    darkGreenLight: darkGreenLight,
                    gold: gold,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ChatConversationScreen(
                            personId: convo.otherUid,
                            personName: name,
                            personCity: userData?['city'] as String?,
                            personAvatarAsset: avatarAsset,
                          ),
                        ),
                      );
                    },
                    onLongPress: () => _showConversationActions(convo: convo, name: name),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _buildInfoState({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 36),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: darkGreen.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 40, color: darkGreen),
            ),
            const SizedBox(height: 20),
            Text(
              title,
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w800,
                color: darkGreen,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey.shade500,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================
// 👉 غلاف "اسحب لليسار" بحال Facebook Messenger بالضبط: كي تسحب
// صف المحادثة لليسار، كتخرج 4 أزرار دائرية ملوّنة بجانبها (تثبيت،
// تحديد كغير مقروء، أرشفة، حذف) بحركة سلسة (AnimatedContainer) —
// بلا أي مكتبة خارجية.
// ============================================================
class _SwipeableConversationRow extends StatefulWidget {
  final Widget child;
  final bool isArchived;
  final bool isPinned;
  final bool hasUnread;
  final VoidCallback onDelete;
  final VoidCallback onArchive;
  final VoidCallback onPin;
  final VoidCallback onToggleUnread;

  const _SwipeableConversationRow({
    required this.child,
    required this.isArchived,
    required this.isPinned,
    required this.hasUnread,
    required this.onDelete,
    required this.onArchive,
    required this.onPin,
    required this.onToggleUnread,
  });

  @override
  State<_SwipeableConversationRow> createState() => _SwipeableConversationRowState();
}

class _SwipeableConversationRowState extends State<_SwipeableConversationRow> {
  static const Color darkGreen = Color(0xFF0F3D2E);
  static const Color darkGreenLight = Color(0xFF1A6B4A);
  static const Color gold = Color(0xFFC9A24B);
  static const double _actionWidth = 60;
  static const int _actionCount = 4;
  static const double _maxExtent = _actionWidth * _actionCount;

  double _dragExtent = 0;
  bool _animating = false;

  void _animateTo(double target) {
    setState(() {
      _animating = true;
      _dragExtent = target;
    });
  }

  void _open() => _animateTo(-_maxExtent);
  void _close() => _animateTo(0);

  @override
  Widget build(BuildContext context) {
    return ClipRect(
      child: Stack(
        children: [
          // 🎬 لوحة الأزرار الدائرية فـ الخلفية — بحال Messenger بالضبط:
          // كل زر دائرة ملوّنة منفصلة (بلا خلفية متصلة)، تبان تدريجياً
          // كي نسحبو الصف لليسار
          Positioned(
            top: 0,
            bottom: 12,
            right: 0,
            width: _maxExtent,
            child: Directionality(
              // ✅ نضمنو ترتيب فيزيائي ثابت (يسار->يمين) بغض النظر عن
              // اتجاه التطبيق العام (RTL)
              textDirection: TextDirection.ltr,
              child: Container(
                alignment: Alignment.center,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _circleAction(
                      icon: widget.isPinned ? Icons.push_pin : Icons.push_pin_outlined,
                      color: darkGreenLight,
                      onTap: () {
                        _close();
                        widget.onPin();
                      },
                    ),
                    _circleAction(
                      icon: widget.hasUnread
                          ? Icons.mark_email_read_rounded
                          : Icons.mark_email_unread_rounded,
                      color: darkGreen,
                      onTap: () {
                        _close();
                        widget.onToggleUnread();
                      },
                    ),
                    _circleAction(
                      icon: widget.isArchived ? Icons.unarchive_rounded : Icons.archive_rounded,
                      color: gold,
                      onTap: () {
                        _close();
                        widget.onArchive();
                      },
                    ),
                    _circleAction(
                      icon: Icons.delete_rounded,
                      color: Colors.red.shade600,
                      onTap: () {
                        _close();
                        widget.onDelete();
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
          // 📇 محتوى الصف — كيتزحلق لليسار كي نسحبو (بحركة ناعمة)
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onHorizontalDragStart: (_) => _animating = false,
            onHorizontalDragUpdate: (details) {
              setState(() {
                _dragExtent = (_dragExtent + details.delta.dx).clamp(-_maxExtent, 0.0);
              });
            },
            onHorizontalDragEnd: (details) {
              final velocity = details.primaryVelocity ?? 0;
              if (velocity < -250 || _dragExtent < -_maxExtent / 2) {
                _open();
              } else {
                _close();
              }
            },
            onTap: _dragExtent != 0 ? _close : null,
            child: AnimatedContainer(
              duration: _animating
                  ? const Duration(milliseconds: 220)
                  : Duration.zero,
              curve: Curves.easeOutCubic,
              transform: Matrix4.translationValues(_dragExtent, 0, 0),
              child: widget.child,
            ),
          ),
        ],
      ),
    );
  }

  Widget _circleAction({
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 46,
        height: 46,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.35),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        alignment: Alignment.center,
        child: Icon(icon, color: Colors.white, size: 20),
      ),
    );
  }
}

class _ConversationRow extends StatelessWidget {
  final String name;
  final String? avatarAsset;
  final bool isOnline;
  final bool isMatchOnly;
  final bool isPinned;
  final bool isBlockedByOther;
  final String lastMessage;
  final int unreadCount;
  final String timeLabel;
  final Color darkGreen;
  final Color darkGreenLight;
  final Color gold;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;

  const _ConversationRow({
    required this.name,
    required this.avatarAsset,
    required this.isOnline,
    required this.isMatchOnly,
    this.isPinned = false,
    this.isBlockedByOther = false,
    required this.lastMessage,
    required this.unreadCount,
    required this.timeLabel,
    required this.darkGreen,
    required this.darkGreenLight,
    required this.gold,
    required this.onTap,
    this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    final bool hasUnread = unreadCount > 0;
    final bool highlight = !isBlockedByOther && (hasUnread || isMatchOnly);

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        child: InkWell(
          onTap: onTap,
          onLongPress: onLongPress,
          borderRadius: BorderRadius.circular(22),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(22),
              border: Border.all(
                color: isBlockedByOther
                    ? Colors.grey.shade200
                    : isMatchOnly
                        ? gold.withValues(alpha: 0.35)
                        : hasUnread
                            ? darkGreen.withValues(alpha: 0.14)
                            : Colors.black.withValues(alpha: 0.03),
                width: isMatchOnly && !isBlockedByOther ? 1.3 : 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: darkGreen.withValues(alpha: highlight ? 0.10 : 0.05),
                  blurRadius: 18,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // ⏰ الوقت + عداد الغير مقروء (يسار)
                SizedBox(
                  width: 54,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (isMatchOnly)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                          decoration: BoxDecoration(
                            color: gold,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Text(
                            'جديد',
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                            ),
                          ),
                        )
                      else
                        Text(
                          timeLabel,
                          style: TextStyle(
                            fontSize: 11.5,
                            color: hasUnread ? darkGreen : Colors.grey.shade400,
                            fontWeight: hasUnread
                                ? FontWeight.w700
                                : FontWeight.normal,
                          ),
                        ),
                      if (hasUnread) ...[
                        const SizedBox(height: 6),
                        Container(
                          width: 21,
                          height: 21,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: darkGreen,
                            shape: BoxShape.circle,
                          ),
                          child: Text(
                            unreadCount > 9 ? '9+' : '$unreadCount',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 6),
                // 📝 الاسم + آخر رسالة (محاذاة يمين)
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          if (isPinned) ...[
                            Icon(Icons.push_pin, size: 13, color: gold),
                            const SizedBox(width: 4),
                          ],
                          Flexible(
                            child: Text(
                              name,
                              textAlign: TextAlign.right,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontWeight: FontWeight.w800,
                                fontSize: 15.5,
                                color: darkGreen,
                                letterSpacing: -0.2,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        lastMessage.isEmpty ? '📎 رسالة' : lastMessage,
                        textAlign: TextAlign.right,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 12.5,
                          fontStyle: isBlockedByOther ? FontStyle.italic : FontStyle.normal,
                          color: isBlockedByOther
                              ? Colors.grey.shade400
                              : isMatchOnly
                                  ? gold.withValues(alpha: 0.95)
                                  : hasUnread
                                      ? Colors.grey.shade700
                                      : Colors.grey.shade500,
                          fontWeight: highlight
                              ? FontWeight.w600
                              : FontWeight.normal,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 14),
                // 🖼️ الأفاتار (يمين) بحلقة تدرّج دائمة — نفس هوية التطبيق
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(2.4),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: highlight ? gold : Colors.grey.shade200,
                          width: 2,
                        ),
                      ),
                      child: Container(
                        padding: const EdgeInsets.all(2),
                        decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                        child: isBlockedByOther
                            ? CircleAvatar(
                                radius: 24,
                                backgroundColor: Colors.grey.shade200,
                                child: Icon(Icons.person, color: Colors.grey.shade400, size: 26),
                              )
                            : buildAvatarImage(
                                source: avatarAsset,
                                name: name,
                                size: 48,
                                fallbackColor: darkGreen,
                              ),
                      ),
                    ),
                    if (isOnline)
                      Positioned(
                        bottom: 1,
                        right: 1,
                        child: Container(
                          width: 13,
                          height: 13,
                          decoration: BoxDecoration(
                            color: Colors.green.shade500,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2.2),
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
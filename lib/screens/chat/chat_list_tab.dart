// screens/chat/chat_list_tab.dart
import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'chat_conversation_screen.dart';
import '../../services/likes_service.dart';

// ------------------------------------------------------------
// لوحة الألوان: تتبدل تلقائياً حسب المظهر (نهاري / ليلي)
// (نفس ألوان صفحة المحادثة)
// ------------------------------------------------------------
const Color _kDarkGreen = Color(0xFF0F3D2E);
const Color _kMidGreen = Color(0xFF1A6B4A);
const Color _kGold = Color(0xFFC9A24B);
const Color _kCream = Color(0xFFE6D5A8);

class _LP {
  final bool isDark;
  final Color bg;
  final Color card;
  final Color title; // العناوين والأسماء
  final Color icon;
  final Color accent; // خلفية الشارات (عدد غير المقروء)
  final Color subtitle; // النصوص الثانوية
  final Color muted; // hint / وقت عادي
  final Color lastMsg; // آخر رسالة (مقروءة)
  final Color lastMsgUnread; // آخر رسالة (غير مقروءة)
  final Color border; // حدود خفيفة
  final Color ringIdle; // إطار الصورة بدون إشعار
  final Color rowBorder; // حدود بطاقة المحادثة العادية
  final Color shadow;

  const _LP({
    required this.isDark,
    required this.bg,
    required this.card,
    required this.title,
    required this.icon,
    required this.accent,
    required this.subtitle,
    required this.muted,
    required this.lastMsg,
    required this.lastMsgUnread,
    required this.border,
    required this.ringIdle,
    required this.rowBorder,
    required this.shadow,
  });

  static const _LP light = _LP(
    isDark: false,
    bg: Color(0xFFFAF7F2),
    card: Colors.white,
    title: _kDarkGreen,
    icon: _kDarkGreen,
    accent: _kDarkGreen,
    subtitle: Color(0xFF757575),
    muted: Color(0xFFBDBDBD),
    lastMsg: Color(0xFF9E9E9E),
    lastMsgUnread: Color(0xFF616161),
    border: Color(0xFFF5F5F5),
    ringIdle: Color(0xFFEEEEEE),
    rowBorder: Color(0x08000000),
    shadow: Color(0x1A9E9E9E),
  );

  static const _LP dark = _LP(
    isDark: true,
    bg: Color(0xFF0E1512),
    card: Color(0xFF17221D),
    title: _kGold,
    icon: _kGold,
    accent: _kMidGreen,
    subtitle: Color(0xFF8FA198),
    muted: Color(0xFF5E7068),
    lastMsg: Color(0xFF8FA198),
    lastMsgUnread: _kCream,
    border: Color(0xFF2A3A33),
    ringIdle: Color(0xFF2A3A33),
    rowBorder: Color(0xFF2A3A33),
    shadow: Color(0x66000000),
  );

  static _LP of(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark ? dark : light;
}

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
  static const Color gold = Color(0xFFC9A24B);

  List<QueryDocumentSnapshot<Map<String, dynamic>>> _sentDocs = [];
  List<QueryDocumentSnapshot<Map<String, dynamic>>> _receivedDocs = [];
  bool _sentLoaded = false;
  bool _receivedLoaded = false;
  bool _hasError = false;

  Set<String> _matchedUids = {};
  bool _matchesLoaded = false;

  StreamSubscription? _sentSub;
  StreamSubscription? _receivedSub;
  StreamSubscription<User?>? _authSub;
  StreamSubscription<List<String>>? _matchesSub;

  final Map<String, Map<String, dynamic>?> _userCache = {};
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  _LP get _p => _LP.of(context);

  String? get _myUid => FirebaseAuth.instance.currentUser?.uid;

  @override
  void initState() {
    super.initState();
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

    final matched = list
        .where((c) => _matchedUids.contains(c.otherUid))
        .toList();

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

    matched.sort((a, b) {
      if (a.lastTimestamp == null && b.lastTimestamp == null) return 0;
      if (a.lastTimestamp == null) return 1;
      if (b.lastTimestamp == null) return -1;
      return b.lastTimestamp!.compareTo(a.lastTimestamp!);
    });
    return matched;
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
    final p = _p;

    return Scaffold(
      backgroundColor: p.bg,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            const SizedBox(height: 16),
            _buildSearchBar(),
            const SizedBox(height: 6),
            Expanded(child: _buildBody(me)),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    final p = _p;
    final conversations = (_sentLoaded && _receivedLoaded && _matchesLoaded)
        ? _buildConversations()
        : const <_ConversationPreview>[];
    final int unreadTotal = conversations.fold(
      0,
      (sum, c) => sum + c.unreadCount,
    );

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'المحادثات',
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                    color: p.title,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'تواصل بسهولة مع الجميع',
                  style: TextStyle(
                    fontSize: 12.5,
                    color: p.subtitle,
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
                color: p.accent,
                borderRadius: BorderRadius.circular(18),
                border: p.isDark ? Border.all(color: p.border) : null,
                boxShadow: [
                  BoxShadow(
                    color: p.isDark
                        ? p.shadow
                        : _kDarkGreen.withValues(alpha: 0.22),
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
              color: p.card,
              shape: BoxShape.circle,
              border: Border.all(color: p.border),
              boxShadow: [
                BoxShadow(
                  color: p.isDark
                      ? p.shadow
                      : Colors.grey.withValues(alpha: 0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: IconButton(
              icon: Icon(Icons.more_vert_rounded, color: p.icon, size: 20),
              onPressed: () {},
              padding: const EdgeInsets.all(8),
              constraints: const BoxConstraints(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    final p = _p;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        height: 50,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          color: p.card,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: p.border),
          boxShadow: [
            BoxShadow(
              color: p.isDark ? p.shadow : _kDarkGreen.withValues(alpha: 0.05),
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
                color: p.icon.withValues(alpha: 0.10),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.search_rounded, color: p.icon, size: 16),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: TextField(
                controller: _searchController,
                textAlign: TextAlign.right,
                cursorColor: p.icon,
                decoration: InputDecoration(
                  border: InputBorder.none,
                  isDense: true,
                  hintText: 'ابحث عن محادثة...',
                  hintStyle: TextStyle(color: p.muted, fontSize: 13.5),
                ),
                style: TextStyle(
                  fontSize: 13.5,
                  color: p.isDark ? _kCream : _kDarkGreen,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBody(String? me) {
    final p = _p;
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

    if (!_sentLoaded || !_receivedLoaded || !_matchesLoaded) {
      return Center(
        child: CircularProgressIndicator(color: p.icon, strokeWidth: 2.4),
      );
    }

    final conversations = _buildConversations();

    if (conversations.isEmpty) {
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

            if (_searchQuery.isNotEmpty &&
                !name.toLowerCase().contains(_searchQuery.toLowerCase())) {
              return const SizedBox.shrink();
            }

            final avatarAsset =
                (userData?['avatarAsset'] as String?) ??
                (userData?['avatarPath'] as String?);
            final bool isOnline = userData?['isOnline'] == true;

            final bool isMatchOnly = convo.chatId.isEmpty;
            final String lastMessageDisplay = isMatchOnly
                ? 'تم التوافق — ابدأ المحادثة الآن 👋'
                : convo.lastMessage;

            return _ConversationRow(
              name: name,
              avatarAsset: avatarAsset,
              isOnline: isOnline,
              isMatchOnly: isMatchOnly,
              lastMessage: lastMessageDisplay,
              unreadCount: convo.unreadCount,
              timeLabel: _formatTimestamp(convo.lastTimestamp),
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
    final p = _p;
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 36),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: p.icon.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 40, color: p.icon),
            ),
            const SizedBox(height: 20),
            Text(
              title,
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w800,
                color: p.title,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: p.subtitle, height: 1.5),
            ),
          ],
        ),
      ),
    );
  }
}

class _ConversationRow extends StatelessWidget {
  static const Color gold = Color(0xFFC9A24B);

  final String name;
  final String? avatarAsset;
  final bool isOnline;
  final bool isMatchOnly;
  final String lastMessage;
  final int unreadCount;
  final String timeLabel;
  final VoidCallback onTap;

  const _ConversationRow({
    required this.name,
    required this.avatarAsset,
    required this.isOnline,
    required this.isMatchOnly,
    required this.lastMessage,
    required this.unreadCount,
    required this.timeLabel,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final p = _LP.of(context);
    final bool hasUnread = unreadCount > 0;
    final bool highlight = hasUnread || isMatchOnly;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: p.card,
        borderRadius: BorderRadius.circular(22),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(22),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(22),
              border: Border.all(
                color: isMatchOnly
                    ? gold.withValues(alpha: 0.35)
                    : hasUnread
                    ? p.icon.withValues(alpha: p.isDark ? 0.35 : 0.14)
                    : p.rowBorder,
                width: isMatchOnly ? 1.3 : 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: p.isDark
                      ? Colors.black.withValues(alpha: highlight ? 0.40 : 0.30)
                      : _kDarkGreen.withValues(alpha: highlight ? 0.10 : 0.05),
                  blurRadius: 18,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                SizedBox(
                  width: 54,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (isMatchOnly)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 7,
                            vertical: 3,
                          ),
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
                            color: hasUnread ? p.title : p.muted,
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
                            color: p.accent,
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
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        name,
                        textAlign: TextAlign.right,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 15.5,
                          color: p.title,
                          letterSpacing: -0.2,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        lastMessage.isEmpty ? '📎 رسالة' : lastMessage,
                        textAlign: TextAlign.right,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 12.5,
                          color: isMatchOnly
                              ? gold.withValues(alpha: 0.95)
                              : hasUnread
                              ? p.lastMsgUnread
                              : p.lastMsg,
                          fontWeight: highlight
                              ? FontWeight.w600
                              : FontWeight.normal,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 14),
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(2.4),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: highlight ? gold : p.ringIdle,
                          width: 2,
                        ),
                      ),
                      child: Container(
                        padding: const EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          color: p.card,
                          shape: BoxShape.circle,
                        ),
                        child: buildAvatarImage(
                          source: avatarAsset,
                          name: name,
                          size: 48,
                          fallbackColor: p.icon,
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
                            border: Border.all(color: p.card, width: 2.2),
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

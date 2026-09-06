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
        gradient: LinearGradient(
          colors: [
            fallbackColor.withValues(alpha: 0.18),
            fallbackColor.withValues(alpha: 0.08),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
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
  static const Color gold = Color(0xFFC9A24B);
  static const Color bg = Color(0xFFFAF7F2);

  List<QueryDocumentSnapshot<Map<String, dynamic>>> _sentDocs = [];
  List<QueryDocumentSnapshot<Map<String, dynamic>>> _receivedDocs = [];
  bool _sentLoaded = false;
  bool _receivedLoaded = false;
  bool _hasError = false;

  StreamSubscription? _sentSub;
  StreamSubscription? _receivedSub;
  StreamSubscription<User?>? _authSub;

  final Map<String, Map<String, dynamic>?> _userCache = {};
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

    list.sort((a, b) {
      if (a.lastTimestamp == null && b.lastTimestamp == null) return 0;
      if (a.lastTimestamp == null) return 1;
      if (b.lastTimestamp == null) return -1;
      return b.lastTimestamp!.compareTo(a.lastTimestamp!);
    });
    return list;
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
            Expanded(child: _buildBody(me)),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // 🔝 الهيدر: "الدردشات" + وصف + زر خيارات
  // ============================================================
  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 4,
                      height: 20,
                      decoration: BoxDecoration(
                        color: gold,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'الدردشات',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                        color: darkGreen,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 5),
                Text(
                  'تواصل بسهولة مع الجميع',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey.shade500,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.grey.shade100),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withValues(alpha: 0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: IconButton(
              icon: Icon(Icons.more_vert_rounded, color: darkGreen, size: 20),
              onPressed: () {},
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

    if (!_sentLoaded || !_receivedLoaded) {
      return const Center(
        child: CircularProgressIndicator(color: darkGreen, strokeWidth: 2.4),
      );
    }

    final conversations = _buildConversations();

    if (conversations.isEmpty) {
      return _buildInfoState(
        icon: Icons.chat_bubble_outline_rounded,
        title: 'ماكاين حتى رسالة',
        subtitle: 'كي تعجبك واحد(ة) فـ الاكتشاف، المحادثة رح تبان هنا',
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

            return _ConversationRow(
              name: name,
              avatarAsset: avatarAsset,
              isOnline: isOnline,
              lastMessage: convo.lastMessage,
              unreadCount: convo.unreadCount,
              timeLabel: _formatTimestamp(convo.lastTimestamp),
              darkGreen: darkGreen,
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
// عنصر واحد فـ الليستة — تصميم بطاقة (card) عصري: أفاتار بنقطة
// أونلاين، اسم + آخر رسالة بمحاذاة يمين، الوقت + عداد الغير مقروء
// على اليسار، ظل ناعم وحواف مدورة بدل الخط الفاصل المسطح.
// ============================================================
class _ConversationRow extends StatelessWidget {
  final String name;
  final String? avatarAsset;
  final bool isOnline;
  final String lastMessage;
  final int unreadCount;
  final String timeLabel;
  final Color darkGreen;
  final Color gold;
  final VoidCallback onTap;

  const _ConversationRow({
    required this.name,
    required this.avatarAsset,
    required this.isOnline,
    required this.lastMessage,
    required this.unreadCount,
    required this.timeLabel,
    required this.darkGreen,
    required this.gold,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final bool hasUnread = unreadCount > 0;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(18),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: hasUnread
                    ? darkGreen.withValues(alpha: 0.14)
                    : Colors.grey.shade100,
              ),
              boxShadow: [
                BoxShadow(
                  color: darkGreen.withValues(alpha: hasUnread ? 0.07 : 0.04),
                  blurRadius: 12,
                  offset: const Offset(0, 5),
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
                          width: 20,
                          height: 20,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                darkGreen,
                                darkGreen.withValues(alpha: 0.8),
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: darkGreen.withValues(alpha: 0.35),
                                blurRadius: 6,
                                offset: const Offset(0, 2),
                              ),
                            ],
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
                      Text(
                        name,
                        textAlign: TextAlign.right,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 15,
                          color: darkGreen,
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
                          color: hasUnread
                              ? Colors.grey.shade700
                              : Colors.grey.shade500,
                          fontWeight: hasUnread
                              ? FontWeight.w600
                              : FontWeight.normal,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                // 🖼️ الأفاتار (يمين) + نقطة أونلاين
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Container(
                      padding: EdgeInsets.all(hasUnread ? 2 : 0),
                      decoration: hasUnread
                          ? BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: LinearGradient(
                                colors: [
                                  gold.withValues(alpha: 0.8),
                                  darkGreen.withValues(alpha: 0.5),
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                            )
                          : null,
                      child: buildAvatarImage(
                        source: avatarAsset,
                        name: name,
                        size: 50,
                        fallbackColor: darkGreen,
                      ),
                    ),
                    if (isOnline)
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
              ],
            ),
          ),
        ),
      ),
    );
  }
}
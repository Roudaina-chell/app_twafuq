import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:tawafuq/screens/chat/profile_view_screen.dart';

class ChatConversationScreen extends StatefulWidget {
  final String? personId;
  final String personName;
  final String? personCity;
  final String? personAvatarAsset;

  const ChatConversationScreen({
    super.key,
    this.personId,
    required this.personName,
    this.personCity,
    this.personAvatarAsset,
  });

  @override
  State<ChatConversationScreen> createState() => _ChatConversationScreenState();
}

class _ChatConversationScreenState extends State<ChatConversationScreen> {
  static const Color darkGreen = Color(0xFF0F3D2E);
  static const Color gold = Color(0xFFC9A24B);
  static const Color bg = Color(0xFFFAF7F2);

  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _focusNode = FocusNode();

  bool _isSending = false;
  bool _isBlocked = false;
  bool _checkingBlock = true;

  // متغيرات للرد المعلق
  String? _replyToId;
  String? _replyToText;

  // MethodChannel لمنع الشاشة
  static const MethodChannel _channel = MethodChannel('screen_security');

  // ============================================================
  // 🛡️ قائمة الكلمات المحظورة
  // ============================================================
  static const Set<String> _blockedWords = {
    'انستا',
    'انستغرام',
    'انستقرام',
    'فيسبوك',
    'فايسبوك',
    'فايس',
    'فيس',
    'فيبر',
    'فايبر',
    'واتساب',
    'واتس',
    'تليغرام',
    'تيليغرام',
    'تليجرام',
    'سناب',
    'سنابشات',
    'insta',
    'instagram',
    'ig',
    'fb',
    'facebook',
    'viber',
    'whatsapp',
    'whats',
    'telegram',
    'tg',
    'snap',
    'snapchat',
    'tik',
    'tiktok',
    'موبيليس',
    'جيزي',
    'أوريدو',
    'نجمة',
    'بريديموب',
    'ديديكاس',
    'mobilis',
    'djezzy',
    'ooredoo',
    'nedjma',
    'baridimob',
    'رقمي',
    'نيميرو',
    'النيميرو',
    'كونط',
    'كونتي',
    'بروفيلي',
    'ابوني',
    'ارسلي',
    'ابعثلي',
    'ضيفني',
    'ضيفيني',
    'اجوتيني',
    'اجوتي',
    'السيرفيس',
    'فوطو',
    'فوطوات',
    'num',
    'numero',
    'mon num',
    'mon numero',
    'compte',
    'fb mte3i',
    'mon fb',
    'add me',
    'addini',
    'ajoute',
    'ajoutini',
    'خا',
    'خه',
    'كس',
    'كسي',
    'كسك',
    'قحب',
    'قحبة',
    'مخنوق',
    'طيز',
    'شرمطة',
    'زبي',
    'زب',
    'نياك',
    'ناك',
    'بعبص',
    'حمار',
  };

  static const Set<String> _blockedEmojis = {
    '📞',
    '📱',
    '👻',
  };

  String? get _myUid => FirebaseAuth.instance.currentUser?.uid;
  String? get _chatId {
    final me = _myUid;
    final other = widget.personId;
    if (me == null || other == null) return null;
    final ids = [me, other]..sort();
    return ids.join('_');
  }

  // ============================================================
  // 🔒 تفعيل منع لقطة الشاشة
  // ============================================================
  Future<void> _enableScreenSecurity() async {
    try {
      await _channel.invokeMethod('enableSecureFlag');
      debugPrint('🔒 Screen security enabled');
    } catch (e) {
      debugPrint('⚠️ Failed to enable secure flag: $e');
    }
  }

  Future<void> _disableScreenSecurity() async {
    try {
      await _channel.invokeMethod('disableSecureFlag');
      debugPrint('🔓 Screen security disabled');
    } catch (e) {
      debugPrint('⚠️ Failed to disable secure flag: $e');
    }
  }

  @override
  void initState() {
    super.initState();
    _enableScreenSecurity();
    _checkIfBlocked();
  }

  @override
  void dispose() {
    _disableScreenSecurity();
    _controller.dispose();
    _scrollController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });
  }

  // ============================================================
  // 🔒 التحقق من الحظر
  // ============================================================
  Future<void> _checkIfBlocked() async {
    final myUid = _myUid;
    final otherId = widget.personId;
    if (myUid == null || otherId == null) {
      setState(() => _checkingBlock = false);
      return;
    }
    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(myUid)
          .collection('blocked')
          .doc(otherId)
          .get();
      setState(() {
        _isBlocked = doc.exists;
        _checkingBlock = false;
      });
    } catch (e) {
      debugPrint('❌ Check blocked failed: $e');
      setState(() => _checkingBlock = false);
    }
  }

  // ============================================================
  // 🛡️ فحص المحتوى المحظور
  // ============================================================
  bool _containsBlockedContent(String text) {
    final lowerText = text.toLowerCase();
    for (final word in _blockedWords) {
      if (lowerText.contains(word.toLowerCase())) return true;
    }
    for (final emoji in _blockedEmojis) {
      if (text.contains(emoji)) return true;
    }
    final RegExp phoneRegex = RegExp(r'(0[567]\d{8,9}|\+213\d{9,10}|00213\d{9,10})');
    if (phoneRegex.hasMatch(text)) return true;
    final RegExp anyNumberRegex = RegExp(r'\b\d{9,10}\b');
    if (anyNumberRegex.hasMatch(text)) return true;
    return false;
  }

  // ============================================================
  // ✅ إرسال الرسالة مع دعم الرد
  // ============================================================
  Future<void> _sendMessage({String? replyToId, String? replyToText}) async {
    final text = _controller.text.trim();
    final me = _myUid;
    final other = widget.personId;
    final chatId = _chatId;

    if (text.isEmpty || _isSending) return;

    if (_containsBlockedContent(text)) {
      _controller.clear();
      _clearReplyState();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.red.shade700,
          duration: const Duration(seconds: 4),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          content: const Row(
            children: [
              Icon(Icons.warning_rounded, color: Colors.white),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  '⚠️ يرجى إرسال الرسالة بطريقة أخرى',
                  style: TextStyle(color: Colors.white, fontSize: 14),
                ),
              ),
            ],
          ),
        ),
      );
      FocusScope.of(context).requestFocus(FocusNode());
      return;
    }

    if (me == null || other == null || chatId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تعذر إرسال الرسالة، عاود المحاولة')),
      );
      return;
    }

    setState(() => _isSending = true);
    _controller.clear();

    try {
      await FirebaseFirestore.instance.collection('messages').add({
        'chatId': chatId,
        'fromUserId': me,
        'toUserId': other,
        'text': text,
        'timestamp': FieldValue.serverTimestamp(),
        'replyToId': replyToId,
        'replyToText': replyToText,
        'reactions': {},
      });
      _clearReplyState();
      _scrollToBottom();
    } catch (e) {
      debugPrint('❌ Send message failed: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('خطأ: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  // ============================================================
  // 🧹 إلغاء الرد المعلق
  // ============================================================
  void _clearReplyState() {
    setState(() {
      _replyToId = null;
      _replyToText = null;
    });
  }

  // ============================================================
  // ✏️ تعديل رسالة (خاصة بك فقط)
  // ============================================================
  Future<void> _editMessage(String docId, String currentText) async {
    final controller = TextEditingController(text: currentText);
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('تعديل الرسالة'),
        content: TextField(
          controller: controller,
          maxLines: 3,
          decoration: const InputDecoration(
            hintText: 'اكتب النص الجديد...',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('إلغاء', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, controller.text.trim()),
            child: const Text('حفظ'),
          ),
        ],
      ),
    );

    if (result != null && result.isNotEmpty && result != currentText) {
      try {
        await FirebaseFirestore.instance
            .collection('messages')
            .doc(docId)
            .update({'text': result});
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('✅ تم تعديل الرسالة')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('❌ فشل التعديل: $e')),
          );
        }
      }
    }
  }

  // ============================================================
  // 🗑️ حذف رسالة (خاصة بك فقط)
  // ============================================================
  Future<void> _deleteMessage(String docId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('حذف الرسالة'),
        content: const Text('هل أنت متأكد من حذف هذه الرسالة؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('إلغاء', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('حذف', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await FirebaseFirestore.instance
            .collection('messages')
            .doc(docId)
            .delete();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('🗑️ تم حذف الرسالة')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('❌ فشل الحذف: $e')),
          );
        }
      }
    }
  }

  // ============================================================
  // ↩️ بدء الرد على رسالة (أي رسالة)
  // ============================================================
  void _replyToMessage(String replyToId, String replyToText) {
    setState(() {
      _replyToId = replyToId;
      _replyToText = replyToText;
    });
    _focusNode.requestFocus();
  }

  // ============================================================
  // ❤️ إضافة/إزالة تفاعل (أي رسالة)
  // ============================================================
  Future<void> _toggleReaction(String messageId, String emoji) async {
    final me = _myUid;
    if (me == null) return;
    final docRef = FirebaseFirestore.instance.collection('messages').doc(messageId);
    try {
      await FirebaseFirestore.instance.runTransaction((transaction) async {
        final doc = await transaction.get(docRef);
        if (!doc.exists) return;
        Map<String, dynamic> reactions = Map.from(doc.data()?['reactions'] ?? {});
        List<dynamic> users = reactions[emoji] ?? [];
        if (users.contains(me)) {
          users.remove(me);
        } else {
          users.add(me);
        }
        if (users.isEmpty) {
          reactions.remove(emoji);
        } else {
          reactions[emoji] = users;
        }
        transaction.update(docRef, {'reactions': reactions});
      });
    } catch (e) {
      debugPrint('❌ Reaction error: $e');
    }
  }

  // ============================================================
  // 🖼️ بناء الأفاتار
  // ============================================================
  Widget _buildAvatar({double size = 40}) {
    if (widget.personAvatarAsset == null || widget.personAvatarAsset!.isEmpty) {
      return CircleAvatar(
        radius: size / 2,
        backgroundColor: darkGreen.withValues(alpha: 0.08),
        child: Icon(Icons.person, color: darkGreen, size: size * 0.55),
      );
    }
    return ClipOval(
      child: SizedBox(
        width: size,
        height: size,
        child: Image.asset(
          widget.personAvatarAsset!,
          fit: BoxFit.cover,
          alignment: Alignment.topCenter,
          errorBuilder: (context, error, stack) => CircleAvatar(
            radius: size / 2,
            backgroundColor: darkGreen.withValues(alpha: 0.08),
            child: Icon(Icons.person, color: darkGreen, size: size * 0.55),
          ),
        ),
      ),
    );
  }

  // ============================================================
  // 🏗️ الواجهة الرئيسية
  // ============================================================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        titleSpacing: 0,
        title: GestureDetector(
          onTap: () {
            if (widget.personId != null) {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ProfileViewScreen(
                    userId: widget.personId!,
                    userName: widget.personName,
                  ),
                ),
              );
            }
          },
          child: Row(
            children: [
              _buildAvatar(size: 38),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      widget.personName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 15.5,
                        fontWeight: FontWeight.w800,
                        color: darkGreen,
                      ),
                    ),
                    if (widget.personCity != null && widget.personCity!.isNotEmpty)
                      Text(
                        widget.personCity!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 11.5,
                          color: Colors.grey.shade500,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
        iconTheme: const IconThemeData(color: darkGreen),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(child: _buildMessagesArea()),
            if (_replyToId != null) _buildReplyBanner(),
            _buildInputBar(),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // 📌 شريط الرد المعلق
  // ============================================================
  Widget _buildReplyBanner() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: Colors.grey.shade100,
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  '↩️ رد على:',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                ),
                Text(
                  _replyToText ?? '',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close, size: 18),
            onPressed: _clearReplyState,
            tooltip: 'إلغاء الرد',
          ),
        ],
      ),
    );
  }

  // ============================================================
  // 💬 منطقة الرسائل
  // ============================================================
  Widget _buildMessagesArea() {
    final me = _myUid;
    final chatId = _chatId;

    if (_checkingBlock) {
      return const Center(child: CircularProgressIndicator(color: darkGreen));
    }

    if (me == null || chatId == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 40),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline_rounded, color: Colors.grey.shade400, size: 36),
              const SizedBox(height: 12),
              Text(
                'ماقدرناش نحددو المحادثة، عاود المحاولة',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
              ),
            ],
          ),
        ),
      );
    }

    if (_isBlocked) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 40),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.block_rounded, color: Colors.red.shade400, size: 48),
              const SizedBox(height: 16),
              Text(
                'لقد قمت بحظر هذا المستخدم',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey.shade700,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'لن تظهر لك رسائله، ويمكنك إلغاء الحظر من ملفه الشخصي',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey.shade500,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('messages')
          .where('chatId', isEqualTo: chatId)
          .orderBy('timestamp')
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, color: Colors.red, size: 48),
                  const SizedBox(height: 16),
                  Text(
                    'خطأ في تحميل الرسائل:',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${snapshot.error}',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.red, fontSize: 13),
                  ),
                ],
              ),
            ),
          );
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(color: darkGreen),
                SizedBox(height: 12),
                Text('جاري تحميل الرسائل...'),
              ],
            ),
          );
        }

        final docs = snapshot.data?.docs ?? [];

        if (docs.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.favorite_rounded, color: gold, size: 40),
                  const SizedBox(height: 14),
                  Text(
                    'عجبتكم بعضاكم! ابدأ الحوار مع ${widget.personName} 👋',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 13.5,
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        _scrollToBottom();

        return ListView.builder(
          controller: _scrollController,
          padding: const EdgeInsets.all(16),
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final doc = docs[index];
            final data = doc.data();
            final bool fromMe = data['fromUserId'] == me;
            final String text = (data['text'] as String?) ?? '';
            final Timestamp? ts = data['timestamp'] as Timestamp?;
            final String docId = doc.id;
            final String? replyToId = data['replyToId'];
            final String? replyToText = data['replyToText'];
            final Map<String, dynamic> reactions = Map.from(data['reactions'] ?? {});

            return GestureDetector(
              onLongPress: () {
                _showMessageOptions(docId, text, fromMe);
              },
              child: Column(
                crossAxisAlignment: fromMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                children: [
                  if (replyToId != null && replyToText != null)
                    Container(
                      margin: const EdgeInsets.only(bottom: 4),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade200,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '↩️ رد على:',
                            style: TextStyle(fontSize: 10, color: Colors.grey.shade600),
                          ),
                          Text(
                            replyToText,
                            style: const TextStyle(fontSize: 13, color: Colors.black87),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  Container(
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    constraints: BoxConstraints(
                      maxWidth: MediaQuery.of(context).size.width * 0.72,
                    ),
                    decoration: BoxDecoration(
                      color: fromMe ? darkGreen : Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withValues(alpha: 0.1),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          text,
                          style: TextStyle(
                            color: fromMe ? Colors.white : Colors.black87,
                            fontSize: 14,
                          ),
                        ),
                        if (ts != null) ...[
                          const SizedBox(height: 4),
                          Text(
                            _formatTime(ts.toDate()),
                            style: TextStyle(
                              fontSize: 10,
                              color: fromMe
                                  ? Colors.white.withValues(alpha: 0.65)
                                  : Colors.grey.shade500,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  if (reactions.isNotEmpty)
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      children: reactions.entries.map((entry) {
                        final emoji = entry.key;
                        final users = List<String>.from(entry.value);
                        final bool isReacted = users.contains(me);
                        return GestureDetector(
                          onTap: () => _toggleReaction(docId, emoji),
                          child: Chip(
                            label: Text('$emoji ${users.length}'),
                            padding: const EdgeInsets.symmetric(horizontal: 6),
                            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            backgroundColor: isReacted ? Colors.blue.shade50 : Colors.grey.shade100,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                              side: BorderSide(
                                color: isReacted ? Colors.blue : Colors.transparent,
                                width: 1,
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  // ============================================================
  // 📋 القائمة المنبثقة (تدعم الجميع)
  // ============================================================
  void _showMessageOptions(String docId, String text, bool isMyMessage) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: ['❤️', '😂', '👍', '😮', '😢', '😡'].map((emoji) {
                    return GestureDetector(
                      onTap: () {
                        Navigator.pop(ctx);
                        _toggleReaction(docId, emoji);
                      },
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white,
                        ),
                        child: Text(emoji, style: const TextStyle(fontSize: 26)),
                      ),
                    );
                  }).toList(),
                ),
              ),
              const Divider(height: 1, thickness: 1, indent: 16, endIndent: 16),
              ListTile(
                leading: const Icon(Icons.reply, color: Colors.blue),
                title: const Text('رد على الرسالة'),
                onTap: () {
                  Navigator.pop(ctx);
                  _replyToMessage(docId, text);
                },
              ),
              if (isMyMessage) ...[
                ListTile(
                  leading: const Icon(Icons.edit, color: darkGreen),
                  title: const Text('تعديل الرسالة'),
                  onTap: () {
                    Navigator.pop(ctx);
                    _editMessage(docId, text);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.delete_outline, color: Colors.red),
                  title: const Text('حذف الرسالة'),
                  onTap: () {
                    Navigator.pop(ctx);
                    _deleteMessage(docId);
                  },
                ),
              ],
              const SizedBox(height: 10),
            ],
          ),
        );
      },
    );
  }

  String _formatTime(DateTime time) {
    final hour = time.hour % 12 == 0 ? 12 : time.hour % 12;
    final minute = time.minute.toString().padLeft(2, '0');
    final period = time.hour >= 12 ? 'م' : 'ص';
    return '$hour:$minute $period';
  }

  // ============================================================
  // 📝 شريط إدخال النص
  // ============================================================
  Widget _buildInputBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.12),
            blurRadius: 10,
            offset: const Offset(0, -3),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: bg,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: darkGreen.withValues(alpha: 0.12)),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: TextField(
                controller: _controller,
                focusNode: _focusNode,
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => _sendMessage(
                  replyToId: _replyToId,
                  replyToText: _replyToText,
                ),
                decoration: const InputDecoration(
                  hintText: 'اكتب رسالة...',
                  border: InputBorder.none,
                  isDense: true,
                  contentPadding: EdgeInsets.symmetric(vertical: 12),
                ),
                style: const TextStyle(fontSize: 14),
              ),
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: _isSending
                ? null
                : () => _sendMessage(
                      replyToId: _replyToId,
                      replyToText: _replyToText,
                    ),
            child: Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: darkGreen.withValues(alpha: _isSending ? 0.6 : 1),
                shape: BoxShape.circle,
              ),
              child: _isSending
                  ? const Padding(
                      padding: EdgeInsets.all(13),
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : const Icon(
                      Icons.send_rounded,
                      color: Colors.white,
                      size: 20,
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
// screens/chat/chat_conversation_screen.dart
import 'dart:async';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:record/record.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:path_provider/path_provider.dart';
import 'package:tawafuq/screens/chat/profile_view_screen.dart';
import 'package:tawafuq/screens/chat/report_user_screen.dart';

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
  static const Color seenBlue = Color(0xFF53BDEB);

  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _focusNode = FocusNode();

  bool _isSending = false;
  bool _isBlocked = false;
  bool _checkingBlock = true;
  bool _isMarkingRead = false;
  bool _isTogglingBlock = false;

  // 🎤 تسجيل صوتي
  final AudioRecorder _audioRecorder = AudioRecorder();
  bool _isRecording = false;
  int _recordSeconds = 0;
  Timer? _recordTimer;
  bool _isUploadingVoice = false;

  // ▶️ تشغيل الرسائل الصوتية
  final AudioPlayer _audioPlayer = AudioPlayer();
  String? _playingMessageId;

  static const List<String> _quickEmojis = [
    '😀',
    '😂',
    '😍',
    '😊',
    '😉',
    '😢',
    '😮',
    '😡',
    '👍',
    '👎',
    '🙏',
    '👏',
    '💪',
    '🎉',
    '🔥',
    '✨',
    '❤️',
    '💚',
    '💛',
    '💔',
    '😴',
    '🤔',
    '😅',
    '😎',
    '🥰',
    '😘',
    '🤗',
    '😇',
    '🙂',
    '☺️',
    '😁',
    '🤩',
  ];

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

  static const Set<String> _blockedEmojis = {'📞', '📱', '👻'};

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
    _recordTimer?.cancel();
    _audioRecorder.dispose();
    _audioPlayer.dispose();
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
  // 🔒 حظر/إلغاء حظر مباشرة من قائمة (⋮) المحادثة — كنبقاو فـ نفس
  // الشاشة، والواجهة كتبدل وحدها (بحال WhatsApp) بلا ما نديرو Navigator
  // ============================================================
  Future<void> _toggleBlockFromMenu() async {
    final myUid = _myUid;
    final otherId = widget.personId;
    if (myUid == null || otherId == null || _isTogglingBlock) return;

    if (!_isBlocked) {
      final confirm = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(22),
          ),
          title: const Text(
            'حظر المستخدم',
            style: TextStyle(color: darkGreen, fontWeight: FontWeight.bold),
          ),
          content: const Text(
            'لن يتمكن هذا المستخدم من مراسلتك أو رؤية معلوماتك. متأكد؟',
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
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: const Text('حظر', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      );
      if (confirm != true) return;
    }

    setState(() => _isTogglingBlock = true);
    try {
      final ref = FirebaseFirestore.instance
          .collection('users')
          .doc(myUid)
          .collection('blocked')
          .doc(otherId);
      if (_isBlocked) {
        await ref.delete();
      } else {
        await ref.set({
          'blockedUserId': otherId,
          'blockedAt': FieldValue.serverTimestamp(),
        });
      }
      if (!mounted) return;
      setState(() => _isBlocked = !_isBlocked);
      _showFloatingSnack(_isBlocked ? 'تم حظر المستخدم' : 'تم إلغاء الحظر');
    } catch (e) {
      debugPrint('❌ Toggle block failed: $e');
    } finally {
      if (mounted) setState(() => _isTogglingBlock = false);
    }
  }

  // ============================================================
  // 🗑️ حذف المحادثة كاملة من قائمة (⋮) المحادثة — كنرجعو لقائمة
  // المحادثات (pop وحدة) حيت المحادثة ماعادش كاينة
  // ============================================================
  Future<void> _deleteConversationFromMenu() async {
    final chatId = _chatId;
    if (chatId == null) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        title: const Text(
          'حذف المحادثة',
          style: TextStyle(color: darkGreen, fontWeight: FontWeight.bold),
        ),
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
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            child: const Text('حذف', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    if (confirm != true) return;

    try {
      final snap = await FirebaseFirestore.instance
          .collection('messages')
          .where('chatId', isEqualTo: chatId)
          .get();
      final batch = FirebaseFirestore.instance.batch();
      for (final doc in snap.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();
      if (mounted) {
        _showFloatingSnack('🗑️ تم حذف المحادثة');
        Navigator.pop(context); // ✅ pop وحدة برك — كنرجعو لقائمة المحادثات
      }
    } catch (e) {
      debugPrint('❌ Delete conversation failed: $e');
      if (mounted) {
        _showFloatingSnack('❌ فشل الحذف: $e', isError: true);
      }
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
    final RegExp phoneRegex = RegExp(
      r'(0[567]\d{8,9}|\+213\d{9,10}|00213\d{9,10})',
    );
    if (phoneRegex.hasMatch(text)) return true;
    final RegExp anyNumberRegex = RegExp(r'\b\d{9,10}\b');
    if (anyNumberRegex.hasMatch(text)) return true;
    return false;
  }

  // ============================================================
  // 🔔 Snackbar موحد وأنيق
  // ============================================================
  void _showFloatingSnack(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: isError ? Colors.red.shade700 : darkGreen,
        duration: const Duration(seconds: 3),
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
        content: Text(
          message,
          style: const TextStyle(color: Colors.white, fontSize: 13.5),
        ),
      ),
    );
  }

  // ============================================================
  // ✅ إرسال الرسالة مع دعم الرد + حقل "read" (لعلامة الاطلاع)
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
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
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
      _showFloatingSnack('تعذر إرسال الرسالة، عاود المحاولة', isError: true);
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
        'read': false, // ✅ الرسالة الجديدة دايما تبدا "غير مقروءة"
      });
      _clearReplyState();
      _scrollToBottom();
    } catch (e) {
      debugPrint('❌ Send message failed: $e');
      if (mounted) {
        _showFloatingSnack('خطأ: $e', isError: true);
      }
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  // ============================================================
  // ✅ نعلمو الرسائل الموجهة لينا كـ "مقروءة" كي نفتحو المحادثة أو
  // كي توصل رسائل جداد ونحن حاطين فـ الشاشة. كنستعملو نفس الـ docs
  // اللي جايين من الـ StreamBuilder، بلا query إضافية.
  // ============================================================
  Future<void> _markMessagesAsRead(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> unreadIncoming,
  ) async {
    if (_isMarkingRead || unreadIncoming.isEmpty) return;
    _isMarkingRead = true;
    try {
      final batch = FirebaseFirestore.instance.batch();
      for (final doc in unreadIncoming) {
        batch.update(doc.reference, {'read': true});
      }
      await batch.commit();
    } catch (e) {
      debugPrint('❌ Mark as read failed: $e');
    } finally {
      _isMarkingRead = false;
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
  // 😊 اختيار Emoji — bottom sheet بسيط، كيدخل الـ emoji فـ الـ TextField
  // ============================================================
  void _openEmojiPicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildSheetHandle(),
                const SizedBox(height: 12),
                GridView.builder(
                  shrinkWrap: true,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 8,
                    mainAxisSpacing: 6,
                    crossAxisSpacing: 6,
                  ),
                  itemCount: _quickEmojis.length,
                  itemBuilder: (context, index) {
                    final emoji = _quickEmojis[index];
                    return GestureDetector(
                      onTap: () {
                        final text = _controller.text;
                        final selection = _controller.selection;
                        final cursor = selection.start >= 0
                            ? selection.start
                            : text.length;
                        final newText = text.replaceRange(cursor, cursor, emoji);
                        _controller.text = newText;
                        _controller.selection = TextSelection.collapsed(
                          offset: cursor + emoji.length,
                        );
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(10),
                          color: bg,
                        ),
                        child: Center(
                          child: Text(emoji, style: const TextStyle(fontSize: 24)),
                        ),
                      ),
                    );
                  },
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
        borderRadius: BorderRadius.circular(10),
      ),
    );
  }

  // ============================================================
  // 🎤 تسجيل رسالة صوتية — تبدا بضغطة، تسالي بضغطة أخرى وكتصيفط
  // ============================================================
  Future<void> _toggleRecording() async {
    if (_isRecording) {
      await _stopRecordingAndSend();
      return;
    }

    try {
      final hasPermission = await _audioRecorder.hasPermission();
      if (!hasPermission) {
        if (mounted) {
          _showFloatingSnack('خاصك تعطي صلاحية الميكروفون باش تبعت رسالة صوتية');
        }
        return;
      }

      final dir = await getTemporaryDirectory();
      final path =
          '${dir.path}/voice_${DateTime.now().millisecondsSinceEpoch}.m4a';

      await _audioRecorder.start(const RecordConfig(), path: path);

      setState(() {
        _isRecording = true;
        _recordSeconds = 0;
      });

      _recordTimer = Timer.periodic(const Duration(seconds: 1), (_) {
        if (!mounted) return;
        setState(() => _recordSeconds++);
      });
    } catch (e) {
      debugPrint('❌ Start recording failed: $e');
    }
  }

  Future<void> _stopRecordingAndSend() async {
    _recordTimer?.cancel();
    final durationSeconds = _recordSeconds;
    setState(() {
      _isRecording = false;
      _recordSeconds = 0;
    });

    try {
      final path = await _audioRecorder.stop();
      if (path == null || durationSeconds < 1)
        return; // ✅ تسجيل قصير بزاف، تجاهله

      final me = _myUid;
      final other = widget.personId;
      final chatId = _chatId;
      if (me == null || other == null || chatId == null) return;

      setState(() => _isUploadingVoice = true);

      final fileName = 'voice_${DateTime.now().millisecondsSinceEpoch}.m4a';
      final storageRef = FirebaseStorage.instance.ref(
        'voice_messages/$chatId/$fileName',
      );
      await storageRef.putFile(File(path));
      final url = await storageRef.getDownloadURL();

      await FirebaseFirestore.instance.collection('messages').add({
        'chatId': chatId,
        'fromUserId': me,
        'toUserId': other,
        'text': '',
        'audioUrl': url,
        'audioDuration': durationSeconds,
        'timestamp': FieldValue.serverTimestamp(),
        'replyToId': null,
        'replyToText': null,
        'reactions': {},
        'read': false,
      });
      _scrollToBottom();
    } catch (e) {
      debugPrint('❌ Voice message send failed: $e');
      if (mounted) {
        _showFloatingSnack('❌ فشل إرسال الرسالة الصوتية', isError: true);
      }
    } finally {
      if (mounted) setState(() => _isUploadingVoice = false);
    }
  }

  Future<void> _togglePlayVoice(String messageId, String url) async {
    try {
      if (_playingMessageId == messageId) {
        await _audioPlayer.stop();
        setState(() => _playingMessageId = null);
        return;
      }
      await _audioPlayer.stop();
      setState(() => _playingMessageId = messageId);
      await _audioPlayer.play(UrlSource(url));
      _audioPlayer.onPlayerComplete.first.then((_) {
        if (mounted && _playingMessageId == messageId) {
          setState(() => _playingMessageId = null);
        }
      });
    } catch (e) {
      debugPrint('❌ Play voice failed: $e');
    }
  }

  String _formatDuration(int seconds) {
    final m = (seconds ~/ 60).toString().padLeft(1, '0');
    final s = (seconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  // ============================================================
  // ✏️ تعديل رسالة (خاصة بك فقط)
  // ============================================================
  Future<void> _editMessage(String docId, String currentText) async {
    final controller = TextEditingController(text: currentText);
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('تعديل الرسالة',
            style: TextStyle(color: darkGreen, fontWeight: FontWeight.bold)),
        content: TextField(
          controller: controller,
          maxLines: 3,
          decoration: InputDecoration(
            hintText: 'اكتب النص الجديد...',
            filled: true,
            fillColor: bg,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
          ),
        ),
        actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('إلغاء', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, controller.text.trim()),
            style: ElevatedButton.styleFrom(
              backgroundColor: darkGreen,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('حفظ', style: TextStyle(color: Colors.white)),
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
          _showFloatingSnack('✅ تم تعديل الرسالة');
        }
      } catch (e) {
        if (mounted) {
          _showFloatingSnack('❌ فشل التعديل: $e', isError: true);
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('حذف الرسالة',
            style: TextStyle(color: darkGreen, fontWeight: FontWeight.bold)),
        content: const Text('هل أنت متأكد من حذف هذه الرسالة؟',
            style: TextStyle(fontSize: 13)),
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
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
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
          _showFloatingSnack('🗑️ تم حذف الرسالة');
        }
      } catch (e) {
        if (mounted) {
          _showFloatingSnack('❌ فشل الحذف: $e', isError: true);
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
    final docRef = FirebaseFirestore.instance
        .collection('messages')
        .doc(messageId);
    try {
      await FirebaseFirestore.instance.runTransaction((transaction) async {
        final doc = await transaction.get(docRef);
        if (!doc.exists) return;
        Map<String, dynamic> reactions = Map.from(
          doc.data()?['reactions'] ?? {},
        );
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
  // 🖼️ بناء الأفاتار (الصورة الحقيقية: male_1.png, female_2.png...)
  // مع حلقة ذهبية رفيعة ونقطة الحالة (متصل/غير متصل)
  // ============================================================
  Widget _buildAvatar({double size = 40, bool withRing = true}) {
    Widget avatarCore;
    if (widget.personAvatarAsset == null || widget.personAvatarAsset!.isEmpty) {
      avatarCore = CircleAvatar(
        radius: size / 2,
        backgroundColor: darkGreen.withValues(alpha: 0.08),
        child: Icon(Icons.person, color: darkGreen, size: size * 0.55),
      );
    } else {
      final source = widget.personAvatarAsset!;
      final isNetwork =
          source.startsWith('http://') || source.startsWith('https://');
      avatarCore = ClipOval(
        child: SizedBox(
          width: size,
          height: size,
          child: isNetwork
              ? Image.network(
                  source,
                  fit: BoxFit.cover,
                  alignment: Alignment.topCenter,
                  errorBuilder: (context, error, stack) => CircleAvatar(
                    radius: size / 2,
                    backgroundColor: darkGreen.withValues(alpha: 0.08),
                    child: Icon(
                      Icons.person,
                      color: darkGreen,
                      size: size * 0.55,
                    ),
                  ),
                )
              : Image.asset(
                  source,
                  fit: BoxFit.cover,
                  alignment: Alignment.topCenter,
                  errorBuilder: (context, error, stack) => CircleAvatar(
                    radius: size / 2,
                    backgroundColor: darkGreen.withValues(alpha: 0.08),
                    child: Icon(
                      Icons.person,
                      color: darkGreen,
                      size: size * 0.55,
                    ),
                  ),
                ),
        ),
      );
    }

    if (!withRing) return avatarCore;

    return Container(
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          colors: [gold.withValues(alpha: 0.9), darkGreen.withValues(alpha: 0.6)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: avatarCore,
    );
  }

  // ============================================================
  // 🏗️ الواجهة الرئيسية
  // ============================================================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bg,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(64),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: darkGreen.withValues(alpha: 0.06),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: AppBar(
            backgroundColor: Colors.white,
            elevation: 0,
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
                  _buildAvatar(size: 40),
                  const SizedBox(width: 12),
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
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: darkGreen,
                            letterSpacing: 0.1,
                          ),
                        ),
                        const SizedBox(height: 3),
                        _buildOnlineStatus(),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            iconTheme: const IconThemeData(color: darkGreen),
            actions: [
              PopupMenuButton<String>(
                icon: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: bg,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.more_vert_rounded,
                      color: darkGreen, size: 20),
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 6,
                onSelected: (value) {
                  if (value == 'report') {
                    if (widget.personId != null) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ReportUserScreen(
                            userId: widget.personId!,
                            userName: widget.personName,
                          ),
                        ),
                      );
                    }
                  } else if (value == 'block') {
                    _toggleBlockFromMenu();
                  } else if (value == 'delete') {
                    _deleteConversationFromMenu();
                  }
                },
                itemBuilder: (ctx) => [
                  const PopupMenuItem(
                    value: 'report',
                    child: Row(
                      children: [
                        Icon(Icons.flag_rounded, color: Colors.orange, size: 20),
                        SizedBox(width: 10),
                        Text('الإبلاغ عن المستخدم'),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: 'block',
                    child: Row(
                      children: [
                        Icon(
                          _isBlocked
                              ? Icons.check_circle_rounded
                              : Icons.block_rounded,
                          color: Colors.red,
                          size: 20,
                        ),
                        const SizedBox(width: 10),
                        Text(_isBlocked ? 'إلغاء حظر المستخدم' : 'حظر المستخدم'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        Icon(
                          Icons.delete_outline_rounded,
                          color: Colors.red,
                          size: 20,
                        ),
                        SizedBox(width: 10),
                        Text('حذف المحادثة'),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 6),
            ],
          ),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(child: _buildMessagesArea()),
            AnimatedSize(
              duration: const Duration(milliseconds: 180),
              child: _replyToId != null ? _buildReplyBanner() : const SizedBox.shrink(),
            ),
            _buildInputBar(),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // 🟢 حالة "متصل الآن" الحية — StreamBuilder على document المستخدم
  // الآخر باش تتبدل مباشرة كي يدخل/يخرج من التطبيق
  // ============================================================
  Widget _buildOnlineStatus() {
    final otherId = widget.personId;
    if (otherId == null) {
      return const SizedBox.shrink();
    }
    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(otherId)
          .snapshots(),
      builder: (context, snap) {
        final data = snap.data?.data();
        final bool isOnline = data?['isOnline'] == true;
        if (isOnline) {
          return Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 7,
                height: 7,
                decoration: BoxDecoration(
                  color: Colors.green,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.green.withValues(alpha: 0.5),
                      blurRadius: 4,
                      spreadRadius: 1,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 6),
              Text(
                'متصل الآن',
                style: TextStyle(
                  fontSize: 11.5,
                  color: Colors.green.shade700,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          );
        }
        // ✅ غير متصل — نبينو المدينة إلا كانت موجودة، وإلا "غير متصل"
        final label =
            (widget.personCity != null && widget.personCity!.isNotEmpty)
            ? widget.personCity!
            : 'غير متصل';
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.circle, size: 6, color: Colors.grey.shade400),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 11.5, color: Colors.grey.shade500),
              ),
            ),
          ],
        );
      },
    );
  }

  // ============================================================
  // 📌 شريط الرد المعلق
  // ============================================================
  Widget _buildReplyBanner() {
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 8, 12, 0),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border(left: BorderSide(color: gold, width: 3)),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.08),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Icon(Icons.reply_rounded, size: 18, color: gold),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'رد على رسالة',
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                    color: darkGreen,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _replyToText ?? '',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: _clearReplyState,
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: bg,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.close_rounded, size: 16, color: Colors.grey),
            ),
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
      return const Center(
        child: CircularProgressIndicator(color: darkGreen, strokeWidth: 2.4),
      );
    }

    if (me == null || chatId == null) {
      return _buildInfoState(
        icon: Icons.error_outline_rounded,
        iconColor: Colors.grey.shade400,
        title: 'ماقدرناش نحددو المحادثة',
        subtitle: 'عاود المحاولة من فضلك',
      );
    }

    if (_isBlocked) {
      return _buildInfoState(
        icon: Icons.block_rounded,
        iconColor: Colors.red.shade400,
        title: 'لقد قمت بحظر هذا المستخدم',
        subtitle: 'لن تظهر لك رسائله، ويمكنك إلغاء الحظر من ملفه الشخصي',
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
          return _buildInfoState(
            icon: Icons.error_outline_rounded,
            iconColor: Colors.red,
            title: 'خطأ في تحميل الرسائل',
            subtitle: '${snapshot.error}',
            titleColor: Colors.red,
          );
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(color: darkGreen, strokeWidth: 2.4),
                SizedBox(height: 14),
                Text(
                  'جاري تحميل الرسائل...',
                  style: TextStyle(color: Colors.grey, fontSize: 12.5),
                ),
              ],
            ),
          );
        }

        final docs = snapshot.data?.docs ?? [];

        // ✅ نعلمو الرسائل الموجهة لينا وماكانتش مقروءة، بلا query زايدة
        final unreadIncoming = docs.where((d) {
          final data = d.data();
          return data['toUserId'] == me && data['read'] != true;
        }).toList();
        if (unreadIncoming.isNotEmpty) {
          // fire-and-forget، ما خاصناش ننتظرو الـ batch باش نبنيو الواجهة
          _markMessagesAsRead(unreadIncoming);
        }

        if (docs.isEmpty) {
          return _buildInfoState(
            icon: Icons.favorite_rounded,
            iconColor: gold,
            title: 'عجبتكم بعضاكم! 👋',
            subtitle: 'ابدأ الحوار مع ${widget.personName}',
            big: true,
          );
        }

        _scrollToBottom();

        return ListView.builder(
          controller: _scrollController,
          padding: const EdgeInsets.fromLTRB(14, 16, 14, 10),
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
            final Map<String, dynamic> reactions = Map.from(
              data['reactions'] ?? {},
            );
            final bool isRead = data['read'] == true;
            final String? audioUrl = data['audioUrl'] as String?;
            final int audioDuration =
                (data['audioDuration'] as num?)?.toInt() ?? 0;

            return GestureDetector(
              onLongPress: () {
                HapticFeedback.selectionClick();
                _showMessageOptions(docId, text, fromMe);
              },
              child: Padding(
                padding: const EdgeInsets.only(bottom: 2),
                child: Column(
                  crossAxisAlignment: fromMe
                      ? CrossAxisAlignment.end
                      : CrossAxisAlignment.start,
                  children: [
                    Container(
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 10,
                      ),
                      constraints: BoxConstraints(
                        maxWidth: MediaQuery.of(context).size.width * 0.75,
                      ),
                      decoration: BoxDecoration(
                        gradient: fromMe
                            ? LinearGradient(
                                colors: [
                                  darkGreen,
                                  darkGreen.withValues(alpha: 0.88),
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              )
                            : null,
                        color: fromMe ? null : Colors.white,
                        borderRadius: BorderRadius.only(
                          topLeft: const Radius.circular(18),
                          topRight: const Radius.circular(18),
                          bottomLeft: Radius.circular(fromMe ? 18 : 4),
                          bottomRight: Radius.circular(fromMe ? 4 : 18),
                        ),
                        border: fromMe
                            ? null
                            : Border.all(color: Colors.grey.shade200, width: 1),
                        boxShadow: [
                          BoxShadow(
                            color: (fromMe ? darkGreen : Colors.grey)
                                .withValues(alpha: fromMe ? 0.18 : 0.08),
                            blurRadius: 10,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (replyToId != null && replyToText != null)
                            Container(
                              margin: const EdgeInsets.only(bottom: 6),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: fromMe
                                    ? Colors.white.withValues(alpha: 0.12)
                                    : bg,
                                borderRadius: BorderRadius.circular(10),
                                border: Border(
                                  left: BorderSide(
                                    color: fromMe
                                        ? Colors.white.withValues(alpha: 0.5)
                                        : gold,
                                    width: 2.5,
                                  ),
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    'رد على',
                                    style: TextStyle(
                                      fontSize: 9.5,
                                      fontWeight: FontWeight.w700,
                                      color: fromMe
                                          ? Colors.white.withValues(alpha: 0.75)
                                          : Colors.grey.shade600,
                                    ),
                                  ),
                                  const SizedBox(height: 1),
                                  Text(
                                    replyToText,
                                    style: TextStyle(
                                      fontSize: 12.5,
                                      color: fromMe
                                          ? Colors.white.withValues(alpha: 0.9)
                                          : Colors.black87,
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                          if (audioUrl != null)
                            _VoiceMessageRow(
                              isPlaying: _playingMessageId == docId,
                              durationSeconds: audioDuration,
                              fromMe: fromMe,
                              onTap: () => _togglePlayVoice(docId, audioUrl),
                            )
                          else
                            Text(
                              text,
                              style: TextStyle(
                                color: fromMe ? Colors.white : Colors.black87,
                                fontSize: 14.5,
                                height: 1.35,
                              ),
                            ),
                          if (ts != null) ...[
                            const SizedBox(height: 5),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  _formatTime(ts.toDate()),
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: fromMe
                                        ? Colors.white.withValues(alpha: 0.65)
                                        : Colors.grey.shade500,
                                  ),
                                ),
                                // ✅ علامة الاطلاع (بحال واتساب): ✓✓ رمادية
                                // = توصلت، ✓✓ زرقاء = تشافت من الطرف الآخر
                                if (fromMe) ...[
                                  const SizedBox(width: 4),
                                  Icon(
                                    Icons.done_all_rounded,
                                    size: 14,
                                    color: isRead
                                        ? seenBlue
                                        : Colors.white.withValues(alpha: 0.65),
                                  ),
                                ],
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                    if (reactions.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Wrap(
                          spacing: 6,
                          runSpacing: 4,
                          children: reactions.entries.map((entry) {
                            final emoji = entry.key;
                            final users = List<String>.from(entry.value);
                            final bool isReacted = users.contains(me);
                            return GestureDetector(
                              onTap: () => _toggleReaction(docId, emoji),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 9,
                                  vertical: 5,
                                ),
                                decoration: BoxDecoration(
                                  color: isReacted
                                      ? darkGreen.withValues(alpha: 0.1)
                                      : Colors.white,
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(
                                    color: isReacted
                                        ? darkGreen.withValues(alpha: 0.4)
                                        : Colors.grey.shade200,
                                    width: 1,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.grey.withValues(alpha: 0.06),
                                      blurRadius: 4,
                                      offset: const Offset(0, 1),
                                    ),
                                  ],
                                ),
                                child: Text(
                                  '$emoji ${users.length}',
                                  style: const TextStyle(fontSize: 12),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  // ============================================================
  // 🧊 حالة معلوماتية موحدة (فارغ / محظور / خطأ)
  // ============================================================
  Widget _buildInfoState({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    Color titleColor = Colors.black87,
    bool big = false,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 36),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: EdgeInsets.all(big ? 22 : 18),
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: iconColor, size: big ? 38 : 34),
            ),
            const SizedBox(height: 18),
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: big ? 15.5 : 15,
                fontWeight: FontWeight.w700,
                color: titleColor == Colors.black87 ? darkGreen : titleColor,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12.5,
                color: Colors.grey.shade500,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // 📋 القائمة المنبثقة (تدعم الجميع)
  // ============================================================
  void _showMessageOptions(String docId, String text, bool isMyMessage) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 10),
              _buildSheetHandle(),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
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
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: bg,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.grey.withValues(alpha: 0.08),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Text(
                          emoji,
                          style: const TextStyle(fontSize: 24),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
              const Divider(height: 1, thickness: 1, indent: 20, endIndent: 20),
              const SizedBox(height: 6),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.blue.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.reply_rounded, color: Colors.blue, size: 18),
                ),
                title: const Text('رد على الرسالة',
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                onTap: () {
                  Navigator.pop(ctx);
                  _replyToMessage(docId, text);
                },
              ),
              if (isMyMessage) ...[
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: darkGreen.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.edit_rounded, color: darkGreen, size: 18),
                  ),
                  title: const Text('تعديل الرسالة',
                      style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                  onTap: () {
                    Navigator.pop(ctx);
                    _editMessage(docId, text);
                  },
                ),
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.red.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.delete_outline_rounded,
                        color: Colors.red, size: 18),
                  ),
                  title: const Text('حذف الرسالة',
                      style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                  onTap: () {
                    Navigator.pop(ctx);
                    _deleteMessage(docId);
                  },
                ),
              ],
              const SizedBox(height: 14),
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
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.12),
            blurRadius: 12,
            offset: const Offset(0, -3),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: bg,
                borderRadius: BorderRadius.circular(26),
                border: Border.all(color: darkGreen.withValues(alpha: 0.1)),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 6),
              child: Row(
                children: [
                  // 😊 زر الـ emoji
                  IconButton(
                    icon: const Icon(
                      Icons.emoji_emotions_outlined,
                      color: darkGreen,
                      size: 22,
                    ),
                    onPressed: _isRecording ? null : _openEmojiPicker,
                    visualDensity: VisualDensity.compact,
                  ),
                  Expanded(
                    child: _isRecording
                        ? Row(
                            children: [
                              Container(
                                width: 9,
                                height: 9,
                                decoration: BoxDecoration(
                                  color: Colors.red.shade400,
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.red.withValues(alpha: 0.4),
                                      blurRadius: 5,
                                      spreadRadius: 1,
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 10),
                              Text(
                                _formatDuration(_recordSeconds),
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: darkGreen,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Text(
                                'جاري التسجيل...',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey.shade500,
                                ),
                              ),
                            ],
                          )
                        : TextField(
                            controller: _controller,
                            focusNode: _focusNode,
                            textInputAction: TextInputAction.send,
                            minLines: 1,
                            maxLines: 4,
                            onSubmitted: (_) => _sendMessage(
                              replyToId: _replyToId,
                              replyToText: _replyToText,
                            ),
                            decoration: const InputDecoration(
                              hintText: 'اكتب رسالة...',
                              hintStyle: TextStyle(color: Colors.grey),
                              border: InputBorder.none,
                              isDense: true,
                              contentPadding: EdgeInsets.symmetric(
                                vertical: 13,
                              ),
                            ),
                            style: const TextStyle(fontSize: 14.5),
                          ),
                  ),
                  // 🎤 زر التسجيل الصوتي
                  IconButton(
                    icon: _isUploadingVoice
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: darkGreen,
                            ),
                          )
                        : Icon(
                            _isRecording
                                ? Icons.stop_circle_rounded
                                : Icons.mic_none_rounded,
                            color: _isRecording ? Colors.red : darkGreen,
                            size: 22,
                          ),
                    onPressed: _isUploadingVoice ? null : _toggleRecording,
                    visualDensity: VisualDensity.compact,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: _isSending || _isRecording
                ? null
                : () => _sendMessage(
                    replyToId: _replyToId,
                    replyToText: _replyToText,
                  ),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    darkGreen.withValues(
                      alpha: (_isSending || _isRecording) ? 0.55 : 1,
                    ),
                    darkGreen.withValues(
                      alpha: (_isSending || _isRecording) ? 0.4 : 0.82,
                    ),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                shape: BoxShape.circle,
                boxShadow: (_isSending || _isRecording)
                    ? []
                    : [
                        BoxShadow(
                          color: darkGreen.withValues(alpha: 0.35),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
              ),
              child: _isSending
                  ? const Padding(
                      padding: EdgeInsets.all(14),
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

// ============================================================
// 🎤 صف عرض الرسالة الصوتية داخل الفقاعة: زر تشغيل/إيقاف + موجة + مدة
// ============================================================
class _VoiceMessageRow extends StatelessWidget {
  final bool isPlaying;
  final int durationSeconds;
  final bool fromMe;
  final VoidCallback onTap;

  const _VoiceMessageRow({
    required this.isPlaying,
    required this.durationSeconds,
    required this.fromMe,
    required this.onTap,
  });

  String _format(int seconds) {
    final m = (seconds ~/ 60).toString();
    final s = (seconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  // ارتفاعات ثابتة لأعمدة الموجة الصوتية (شكل ديكوري بسيط، بلا مكتبات إضافية)
  static const List<double> _bars = [
    6, 11, 8, 14, 9, 16, 7, 13, 10, 6, 12, 8, 15, 9, 6,
  ];

  @override
  Widget build(BuildContext context) {
    final Color color = fromMe ? Colors.white : const Color(0xFF0F3D2E);
    return SizedBox(
      width: 190,
      child: Row(
        children: [
          GestureDetector(
            onTap: onTap,
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: fromMe
                    ? Colors.white.withValues(alpha: 0.2)
                    : color.withValues(alpha: 0.08),
              ),
              child: Icon(
                isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                color: color,
                size: 20,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: SizedBox(
              height: 18,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: _bars
                    .map(
                      (h) => Expanded(
                        child: Container(
                          margin: const EdgeInsets.symmetric(horizontal: 1),
                          height: h,
                          decoration: BoxDecoration(
                            color: color.withValues(alpha: isPlaying ? 0.9 : 0.4),
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                    )
                    .toList(),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            _format(durationSeconds),
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: color.withValues(alpha: 0.85),
            ),
          ),
        ],
      ),
    );
  }
}
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
import '../../services/likes_service.dart';

// ------------------------------------------------------------
// النصوص
// ------------------------------------------------------------
class _Strings {
  const _Strings._();

  // عام
  static const cancel = 'إلغاء';
  static const save = 'حفظ';
  static const delete = 'حذف';
  static const genericError = '❌ حدث خطأ، أعد المحاولة';

  // الحظر
  static const block = 'حظر المستخدم';
  static const unblock = 'إلغاء حظر المستخدم';
  static const blockConfirm = 'حظر';
  static const blockMessage =
      'لن يتمكن هذا المستخدم من مراسلتك أو رؤية معلوماتك. هل أنت متأكد؟';
  static const unblocked = 'تم إلغاء الحظر';
  static const youBlocked = 'لقد قمت بحظر هذا المستخدم';
  static const youBlockedPerson = 'لقد قمت بحظر هذا الشخص';

  // حذف المحادثة / الرسائل
  static const deleteConversation = 'حذف المحادثة';
  static const deleteConversationMessage =
      'سيتم حذف جميع الرسائل بينكما نهائياً. لا يمكن التراجع عن هذا الإجراء.';
  static const conversationDeleted = '🗑️ تم حذف المحادثة';
  static const deleteFailed = '❌ فشل الحذف';
  static const deleteMessage = 'حذف الرسالة';
  static const deleteMessageConfirm = 'هل أنت متأكد من حذف هذه الرسالة؟';
  static const messageDeleted = '🗑️ تم حذف الرسالة';
  static const editMessage = 'تعديل الرسالة';
  static const editHint = 'اكتب النص الجديد...';
  static const messageEdited = '✅ تم تعديل الرسالة';
  static const editFailed = '❌ فشل التعديل';

  // الإرسال
  static const typeMessage = 'اكتب رسالة...';
  static const sendFailed = 'تعذّر إرسال الرسالة، أعد المحاولة';
  static const sendDenied = 'لا يمكنك إرسال رسالة لهذا المستخدم';
  static const rephrase = '⚠️ يرجى إرسال الرسالة بطريقة أخرى';
  static const rephraseEdit = '⚠️ يرجى كتابة الرسالة بطريقة أخرى';
  static const matchRequiredSnack =
      'لا يمكنك المراسلة قبل أن يقبل الطرف الآخر إعجابك';

  // الصوت
  static const micPermission =
      'يجب السماح بالوصول إلى الميكروفون لإرسال رسالة صوتية';
  static const voiceFailed = '❌ فشل إرسال الرسالة الصوتية';
  static const recording = 'جارٍ التسجيل...';
  static const voiceMessage = '🎤 رسالة صوتية';

  // القائمة
  static const changeTheme = 'تغيير شكل المحادثة';
  static const nickname = 'اسم مستعار';
  static const nicknameHelper = 'اتركه فارغاً لاستعادة الاسم الأصلي';
  static const report = 'الإبلاغ عن المستخدم';

  // الثيم
  static const themeTitle = 'شكل المحادثة';
  static const themeSubtitle =
      'اختر الثيم الذي يعجبك — سيظهر لك وللطرف الآخر معاً';

  // الحالة
  static const online = 'متصل الآن';
  static const offline = 'غير متصل';

  // الرد والتفاعل
  static const replyingTo = 'رد على رسالة';
  static const replyLabel = 'رد على';
  static const replyAction = 'رد على الرسالة';

  // حالات الشاشة
  static const loadingMessages = 'جارٍ تحميل الرسائل...';
  static const loadError = 'خطأ في تحميل الرسائل';
  static const noChatYet = 'لا توجد محادثة بعد';
  static const noChatYetSubtitle =
      'يجب أن يقبل الطرفان الإعجاب أولاً (Match) قبل إمكانية المراسلة';
  static const chatNotFound = 'تعذّر تحديد المحادثة';
  static const tryAgain = 'أعد المحاولة من فضلك';
  static const noMessages = 'لا توجد رسائل';
  static const noMessagesSubtitle = 'لم يتم تبادل أي رسائل بعد';
  static const matchTitle = 'لقد أُعجب كل منكما بالآخر! 👋';
  static String startChat(String name) => 'ابدأ المحادثة مع $name';

  // التاريخ والوقت
  static const today = 'اليوم';
  static const yesterday = 'أمس';
  static const am = 'ص';
  static const pm = 'م';
  static const monthNames = [
    'يناير',
    'فبراير',
    'مارس',
    'أبريل',
    'مايو',
    'يونيو',
    'يوليو',
    'أغسطس',
    'سبتمبر',
    'أكتوبر',
    'نوفمبر',
    'ديسمبر',
  ];
}

// ------------------------------------------------------------
// لوحة الألوان: تتبدل تلقائياً حسب المظهر (نهاري / ليلي)
// ------------------------------------------------------------
const Color _kDarkGreen = Color(0xFF0F3D2E);
const Color _kMidGreen = Color(0xFF1A6B4A);
const Color _kGold = Color(0xFFC9A24B);
const Color _kCream = Color(0xFFE6D5A8);
const Color _kSeenBlue = Color(0xFF53BDEB);

class _Palette {
  final bool isDark;
  final Color bg;
  final Color appBar;
  final Color card;
  final Color sheet;
  final Color title;
  final Color text;
  final Color subtitle;
  final Color icon;
  final Color iconBg;
  final Color border;
  final Color fieldBorder;
  final Color handle;
  final Color shadow;
  final Color error;

  const _Palette({
    required this.isDark,
    required this.bg,
    required this.appBar,
    required this.card,
    required this.sheet,
    required this.title,
    required this.text,
    required this.subtitle,
    required this.icon,
    required this.iconBg,
    required this.border,
    required this.fieldBorder,
    required this.handle,
    required this.shadow,
    required this.error,
  });

  static const light = _Palette(
    isDark: false,
    bg: Color(0xFFFAF7F2),
    appBar: Colors.white,
    card: Colors.white,
    sheet: Colors.white,
    title: _kDarkGreen,
    text: Color(0xDD000000),
    subtitle: Color(0xFF8A8A8A),
    icon: _kDarkGreen,
    iconBg: Color(0x140F3D2E),
    border: Color(0xFFEEEEEE),
    fieldBorder: Color(0xFFBDBDBD),
    handle: Color(0xFFE0E0E0),
    shadow: Color(0x14000000),
    error: Color(0xFFD32F2F),
  );

  static const dark = _Palette(
    isDark: true,
    bg: Color(0xFF0E1512),
    appBar: Color(0xFF121C17),
    card: Color(0xFF17221D),
    sheet: Color(0xFF17221D),
    title: _kGold,
    text: _kCream,
    subtitle: Color(0xFF8FA198),
    icon: _kGold,
    iconBg: Color(0x1AC9A24B),
    border: Color(0xFF2A3A33),
    fieldBorder: Color(0xFF2A3A33),
    handle: Color(0xFF3A4A43),
    shadow: Color(0x66000000),
    error: Color(0xFFFF8A80),
  );

  static _Palette of(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark ? dark : light;

  Color get primaryButton => isDark ? _kMidGreen : _kDarkGreen;
}

// ------------------------------------------------------------
// ثيمات المحادثة
// ------------------------------------------------------------
class ChatThemeOption {
  final String id;
  final String label;
  final Color background;
  final Color swatch;

  const ChatThemeOption({
    required this.id,
    required this.label,
    required this.background,
    required this.swatch,
  });
}

const List<ChatThemeOption> kChatThemes = [
  ChatThemeOption(
    id: 'classic',
    label: 'أنيق',
    background: Color(0xFFF7F3ED),
    swatch: Color(0xFF22333B),
  ),
  ChatThemeOption(
    id: 'rose',
    label: 'خمري',
    background: Color(0xFFFBF1F3),
    swatch: Color(0xFF9D3F5E),
  ),
  ChatThemeOption(
    id: 'gold',
    label: 'ذهبي فاخر',
    background: Color(0xFFFBF7EC),
    swatch: Color(0xFF8A6A2F),
  ),
  ChatThemeOption(
    id: 'ocean',
    label: 'تركوازي',
    background: Color(0xFFEFF7F7),
    swatch: Color(0xFF0E5C64),
  ),
  ChatThemeOption(
    id: 'sunset',
    label: 'غروب',
    background: Color(0xFFFFF3EC),
    swatch: Color(0xFFC1592E),
  ),
  ChatThemeOption(
    id: 'night',
    label: 'ليلي',
    background: Color(0xFF14141C),
    swatch: Color(0xFF7C5CFC),
  ),
];

ChatThemeOption chatThemeById(String id) =>
    kChatThemes.firstWhere((t) => t.id == id, orElse: () => kChatThemes.first);

// ------------------------------------------------------------
// دوال مساعدة عامة
// ------------------------------------------------------------
String _formatDuration(int seconds) {
  final m = (seconds ~/ 60).toString();
  final s = (seconds % 60).toString().padLeft(2, '0');
  return '$m:$s';
}

String _formatTime(DateTime time) {
  final hour = time.hour % 12 == 0 ? 12 : time.hour % 12;
  final minute = time.minute.toString().padLeft(2, '0');
  final period = time.hour >= 12 ? _Strings.pm : _Strings.am;
  return '$hour:$minute $period';
}

bool _isSameDay(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;

String _dayLabel(DateTime date) {
  final now = DateTime.now();
  // UTC لتفادي أي مشكل مع تغيير التوقيت الصيفي
  final today = DateTime.utc(now.year, now.month, now.day);
  final day = DateTime.utc(date.year, date.month, date.day);
  final diff = today.difference(day).inDays;

  if (diff == 0) return _Strings.today;
  if (diff == 1) return _Strings.yesterday;

  final month = _Strings.monthNames[date.month - 1];
  if (date.year == now.year) return '${date.day} $month';
  return '${date.day} $month ${date.year}';
}

/// يحوّل الأرقام العربية/الفارسية إلى لاتينية
String _normalizeDigits(String input) {
  const arabic = '٠١٢٣٤٥٦٧٨٩';
  const persian = '۰۱۲۳۴۵۶۷۸۹';
  final buffer = StringBuffer();
  for (final rune in input.runes) {
    final ch = String.fromCharCode(rune);
    var idx = arabic.indexOf(ch);
    if (idx < 0) idx = persian.indexOf(ch);
    buffer.write(idx >= 0 ? '$idx' : ch);
  }
  return buffer.toString();
}

// ------------------------------------------------------------
// فلتر المحتوى (منع تبادل وسائل التواصل والأرقام)
// ------------------------------------------------------------
const Set<String> _blockedWords = {
  // وسائل التواصل
  'انستا', 'انستغرام', 'انستقرام', 'فيسبوك', 'فايسبوك', 'فايس', 'فيس',
  'فيبر', 'فايبر', 'واتساب', 'واتس', 'تليغرام', 'تيليغرام', 'تليجرام',
  'سناب', 'سنابشات', 'insta', 'instagram', 'ig', 'fb', 'facebook', 'viber',
  'whatsapp', 'whats', 'telegram', 'tg', 'snap', 'snapchat', 'tik', 'tiktok',
  // متعاملو الهاتف والدفع
  'موبيليس', 'جيزي', 'أوريدو', 'نجمة', 'بريديموب', 'ديديكاس', 'mobilis',
  'djezzy', 'ooredoo', 'nedjma', 'baridimob',
  // طلب معلومات الاتصال
  'رقمي', 'نيميرو', 'النيميرو', 'كونط', 'كونتي', 'بروفيلي', 'ابوني',
  'ارسلي', 'ابعثلي', 'ضيفني', 'ضيفيني', 'اجوتيني', 'اجوتي', 'السيرفيس',
  'فوطو', 'فوطوات', 'num', 'numero', 'mon num', 'mon numero', 'compte',
  'fb mte3i', 'mon fb', 'add me', 'addini', 'ajoute', 'ajoutini',
  // ألفاظ نابية
  'خا', 'خه', 'كس', 'كسي', 'كسك', 'قحب', 'قحبة', 'مخنوق', 'طيز', 'شرمطة',
  'زبي', 'زب', 'نياك', 'ناك', 'بعبص', 'حمار',
};

const Set<String> _blockedEmojis = {'📞', '📱', '👻'};

/// يفصل النص إلى كلمات (حروف، علامات تشكيل، أرقام)
final RegExp _tokenSplit = RegExp(r'[^\p{L}\p{M}\p{N}]+', unicode: true);

bool _containsBlockedContent(String text) {
  final normalized = _normalizeDigits(text).toLowerCase();

  // الكلمات القصيرة (≤ 4 أحرف) يجب أن تطابق كلمة كاملة
  // لتفادي الإيجابيات الخاطئة (مثل "ig" في "right" أو "زب" في "زبون").
  final tokens = normalized
      .split(_tokenSplit)
      .where((t) => t.isNotEmpty)
      .toSet();

  for (final raw in _blockedWords) {
    final word = raw.toLowerCase();
    if (word.contains(' ')) {
      if (normalized.contains(word)) return true;
    } else if (word.length <= 4) {
      if (tokens.contains(word)) return true;
    } else {
      if (normalized.contains(word)) return true;
    }
  }

  for (final emoji in _blockedEmojis) {
    if (text.contains(emoji)) return true;
  }

  // أرقام الهاتف، حتى مع مسافات / نقاط / شرطات
  final compact = normalized.replaceAll(RegExp(r'[\s\.\-_/()]'), '');
  if (RegExp(r'(0[567]\d{8}|\+213\d{9}|00213\d{9})').hasMatch(compact)) {
    return true;
  }
  if (RegExp(r'\d{9,}').hasMatch(compact)) return true;

  return false;
}

// ------------------------------------------------------------
// الشاشة
// ------------------------------------------------------------
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
  static const int _batchLimit = 400; // الحد الأقصى في Firestore هو 500
  static const MethodChannel _channel = MethodChannel('screen_security');

  static const List<String> _quickEmojis = [
    // 😀 وجوه
    '😀', '😂', '🥹', '😍', '🥰', '😘', '😊',
    '😉', '😅', '😢', '😭', '😮', '😡', '🤔',
    '😴', '😎', '🤩', '😇', '🙈', '🙊', '😏',
    // ❤️ قلوب
    '❤️', '🧡', '💛', '💚', '💙', '💜', '🖤',
    // 👍 إيمات/حركات
    '👍', '👎', '🙏', '👏', '💪', '👌', '🤝',
    // ✨ احتفال / إضافات
    '🔥', '✨', '🎉', '🥳', '🌹', '💍', '💯',
  ];

  static const List<String> _reactionEmojis = [
    '❤️',
    '😂',
    '👍',
    '😮',
    '😢',
    '😡',
  ];

  final _firestore = FirebaseFirestore.instance;

  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _focusNode = FocusNode();

  bool _isSending = false;
  bool _isBlocked = false;
  bool _checkingBlock = true;
  bool _isMarkingRead = false;
  bool _isTogglingBlock = false;
  bool _blockedSheetOpen = false;

  String _chatThemeId = 'classic';

  String? _nickname;
  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>? _settingsSub;

  bool _hasMatch = false;
  bool _checkingMatch = true;

  final AudioRecorder _audioRecorder = AudioRecorder();
  bool _isRecording = false;
  int _recordSeconds = 0;
  Timer? _recordTimer;
  bool _isUploadingVoice = false;

  final AudioPlayer _audioPlayer = AudioPlayer();
  String? _playingMessageId;

  /// للتمرير إلى الأسفل فقط عند وصول رسالة جديدة
  int _lastMessageCount = 0;

  String? _replyToId;
  String? _replyToText;

  _Palette get _p => _Palette.of(context);

  /// لون الفقاعات/الأيقونات حسب الثيم (الكلاسيكي يتفتح قليلاً في الليلي)
  Color _swatchOf(ChatThemeOption t) =>
      (_p.isDark && t.id == 'classic') ? _kMidGreen : t.swatch;

  /// خلفية المحادثة: في الليلي كل الثيمات تصبح داكنة
  Color _bgOf(ChatThemeOption t) =>
      _p.isDark ? (t.id == 'night' ? t.background : _p.bg) : t.background;

  String? get _myUid => FirebaseAuth.instance.currentUser?.uid;

  String? get _chatId {
    final me = _myUid;
    final other = widget.personId;
    if (me == null || other == null) return null;
    final ids = [me, other]..sort();
    return ids.join('_');
  }

  void _safeSetState(VoidCallback fn) {
    if (!mounted) return;
    setState(fn);
  }

  // ------------------------------------------------------------
  // دورة الحياة
  // ------------------------------------------------------------
  @override
  void initState() {
    super.initState();
    _setScreenSecurity(true);
    _checkIfBlocked();
    _checkMatch();
    _listenChatSettings();
  }

  @override
  void dispose() {
    _setScreenSecurity(false);
    _settingsSub?.cancel();
    _controller.dispose();
    _scrollController.dispose();
    _focusNode.dispose();
    _recordTimer?.cancel();
    _audioRecorder.dispose();
    _audioPlayer.dispose();
    super.dispose();
  }

  Future<void> _setScreenSecurity(bool enabled) async {
    try {
      await _channel.invokeMethod(
        enabled ? 'enableSecureFlag' : 'disableSecureFlag',
      );
    } catch (e) {
      debugPrint('⚠️ Screen security toggle failed: $e');
    }
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

  // ------------------------------------------------------------
  // الثيم + الاسم المستعار: من نفس المكان (chatSettings/{chatId})
  // عبر stream ليظهر أي تغيير (من الملف الشخصي أو من هنا) فوراً
  // ------------------------------------------------------------
  DocumentReference<Map<String, dynamic>>? get _chatSettingsDoc {
    final chatId = _chatId;
    return chatId == null
        ? null
        : _firestore.collection('chatSettings').doc(chatId);
  }

  void _listenChatSettings() {
    final doc = _chatSettingsDoc;
    final otherId = widget.personId;
    if (doc == null || otherId == null) return;

    _settingsSub = doc.snapshots().listen((snap) {
      final data = snap.data();
      final theme = data?['theme'] as String?;
      final raw = data?['nicknames'];
      String? nick;
      if (raw is Map) {
        final v = raw[otherId];
        if (v is String && v.trim().isNotEmpty) nick = v.trim();
      }
      _safeSetState(() {
        _chatThemeId = theme ?? 'classic';
        _nickname = nick;
      });
    }, onError: (e) => debugPrint('❌ Chat settings stream failed: $e'));
  }

  Future<void> _changeChatTheme(String themeId) async {
    _safeSetState(() => _chatThemeId = themeId);
    try {
      await _chatSettingsDoc?.set({'theme': themeId}, SetOptions(merge: true));
    } catch (e) {
      debugPrint('❌ Save chat theme failed: $e');
    }
  }

  Future<void> _openNicknameDialog() async {
    final otherId = widget.personId;
    final doc = _chatSettingsDoc;
    if (otherId == null || doc == null) return;

    final result = await showDialog<String>(
      context: context,
      builder: (_) => _TextInputDialog(
        title: _Strings.nickname,
        hint: widget.personName,
        initial: _nickname ?? '',
        maxLength: 30,
        helper: _Strings.nicknameHelper,
      ),
    );

    // null = ألغى المستخدم العملية
    if (result == null) return;
    try {
      await doc.set({
        'nicknames': {otherId: result.isEmpty ? FieldValue.delete() : result},
      }, SetOptions(merge: true));
    } catch (e) {
      debugPrint('❌ Save nickname failed: $e');
      _showFloatingSnack(_Strings.genericError, isError: true);
    }
  }

  // ------------------------------------------------------------
  // المطابقة
  // ------------------------------------------------------------
  Future<void> _checkMatch() async {
    final otherId = widget.personId;
    if (otherId == null) {
      _checkingMatch = false;
      return;
    }
    try {
      final matched = await LikesService.instance.hasMatch(otherId);
      _safeSetState(() {
        _hasMatch = matched;
        _checkingMatch = false;
      });
    } catch (e) {
      debugPrint('❌ Check match failed: $e');
      _safeSetState(() => _checkingMatch = false);
    }
  }

  // ------------------------------------------------------------
  // الحظر — collection واحدة: users/{uid}/blockedUsers
  // (نفسها المستعملة في blocked_list_screen.dart وشاشة الملف الشخصي)
  // ------------------------------------------------------------
  CollectionReference<Map<String, dynamic>> _blockedCol(String myUid) =>
      _firestore.collection('users').doc(myUid).collection('blockedUsers');

  Future<void> _checkIfBlocked() async {
    final myUid = _myUid;
    final otherId = widget.personId;
    if (myUid == null || otherId == null) {
      _checkingBlock = false;
      return;
    }
    try {
      final snap = await _blockedCol(
        myUid,
      ).where('blockedUid', isEqualTo: otherId).limit(1).get();
      _safeSetState(() {
        _isBlocked = snap.docs.isNotEmpty;
        _checkingBlock = false;
      });
    } catch (e) {
      debugPrint('❌ Check blocked failed: $e');
      _safeSetState(() => _checkingBlock = false);
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

    // التأكيد مطلوب عند الحظر فقط (لا عند إلغاء الحظر)
    if (!_isBlocked) {
      final confirm = await _confirmDialog(
        title: _Strings.block,
        message: _Strings.blockMessage,
        confirmLabel: _Strings.blockConfirm,
      );
      if (confirm != true) return;
    }

    setState(() => _isTogglingBlock = true);
    try {
      final col = _blockedCol(myUid);
      final wasBlocked = _isBlocked;

      if (wasBlocked) {
        // يحذف كل وثيقة تشير إلى هذا المستخدم مهما كان معرّفها
        final existing = await col
            .where('blockedUid', isEqualTo: otherId)
            .get();
        for (final d in existing.docs) {
          await d.reference.delete();
        }
      } else {
        final avatar = widget.personAvatarAsset;
        await col.doc(otherId).set({
          'blockedUid': otherId,
          'name': widget.personName,
          'avatarUrl': (avatar != null && avatar.startsWith('http'))
              ? avatar
              : null,
          'blockedAt': FieldValue.serverTimestamp(),
        });
        await _stopMediaAfterBlock();
      }

      if (!mounted) return;
      setState(() {
        _isBlocked = !wasBlocked;
        _lastMessageCount = 0; // لإعادة التمرير للأسفل بعد إلغاء الحظر
      });
      if (_isBlocked) {
        _showBlockedSheet();
      } else {
        _showFloatingSnack(_Strings.unblocked);
      }
    } catch (e) {
      debugPrint('❌ Toggle block failed: $e');
      _showFloatingSnack(_Strings.genericError, isError: true);
    } finally {
      if (mounted) setState(() => _isTogglingBlock = false);
    }
  }

  /// يوقف التشغيل الصوتي والتسجيل ويفرّغ حالة الكتابة عند الحظر
  Future<void> _stopMediaAfterBlock() async {
    await _audioPlayer.stop();
    if (_isRecording) {
      _recordTimer?.cancel();
      try {
        await _audioRecorder.cancel();
      } catch (_) {}
      _isRecording = false;
      _recordSeconds = 0;
    }
    _playingMessageId = null;
    _replyToId = null;
    _replyToText = null;
    _controller.clear();
  }

  /// لوحة "لقد قمت بحظر هذا الشخص" (مشتركة مع شاشة الملف الشخصي)
  Future<void> _showBlockedSheet() async {
    if (_blockedSheetOpen || !mounted) return;
    _blockedSheetOpen = true;

    final action = await showBlockedSheet(context);

    _blockedSheetOpen = false;
    if (!mounted) return;
    if (action == BlockedSheetAction.unblock) {
      await _toggleBlockFromMenu();
    } else if (action == BlockedSheetAction.delete) {
      await _deleteConversationFromMenu();
    }
  }

  // ------------------------------------------------------------
  // حذف المحادثة (على دفعات)
  // ------------------------------------------------------------
  Future<void> _deleteConversationFromMenu() async {
    final chatId = _chatId;
    if (chatId == null) return;

    final confirm = await _confirmDialog(
      title: _Strings.deleteConversation,
      message: _Strings.deleteConversationMessage,
      confirmLabel: _Strings.delete,
    );
    if (confirm != true) return;

    try {
      final snap = await _firestore
          .collection('messages')
          .where('chatId', isEqualTo: chatId)
          .get();
      final docs = snap.docs;

      for (var i = 0; i < docs.length; i += _batchLimit) {
        final end = (i + _batchLimit < docs.length)
            ? i + _batchLimit
            : docs.length;
        final batch = _firestore.batch();
        for (final doc in docs.sublist(i, end)) {
          batch.delete(doc.reference);
        }
        await batch.commit();
      }

      if (!mounted) return;
      _showFloatingSnack(_Strings.conversationDeleted);
      Navigator.pop(context);
    } catch (e) {
      debugPrint('❌ Delete conversation failed: $e');
      _showFloatingSnack(_Strings.deleteFailed, isError: true);
    }
  }

  // ------------------------------------------------------------
  // أدوات الواجهة
  // ------------------------------------------------------------
  void _showFloatingSnack(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: isError ? Colors.red.shade700 : _p.primaryButton,
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

  Future<bool?> _confirmDialog({
    required String title,
    required String message,
    required String confirmLabel,
  }) {
    final p = _p;
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: p.card,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        title: Text(
          title,
          style: TextStyle(color: p.title, fontWeight: FontWeight.bold),
        ),
        content: Text(message, style: TextStyle(fontSize: 13, color: p.text)),
        actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(_Strings.cancel, style: TextStyle(color: p.subtitle)),
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
            child: Text(
              confirmLabel,
              style: const TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSheetHandle(_Palette p) => Container(
    width: 42,
    height: 4,
    decoration: BoxDecoration(
      color: p.handle,
      borderRadius: BorderRadius.circular(10),
    ),
  );

  // ------------------------------------------------------------
  // الإرسال
  // ------------------------------------------------------------
  Future<void> _sendMessage() async {
    final text = _controller.text.trim();
    final me = _myUid;
    final other = widget.personId;
    final chatId = _chatId;

    if (text.isEmpty || _isSending) return;

    if (_isBlocked) {
      _showFloatingSnack(_Strings.youBlocked, isError: true);
      return;
    }

    if (_containsBlockedContent(text)) {
      _controller.clear();
      _clearReplyState();
      _showFloatingSnack(_Strings.rephrase, isError: true);
      FocusScope.of(context).unfocus();
      return;
    }

    if (me == null || other == null || chatId == null) {
      _showFloatingSnack(_Strings.sendFailed, isError: true);
      return;
    }

    // ✅ بوابة Match: لا رسالة بلا توافق متبادل (البند 7 + 14)
    if (!_hasMatch) {
      _showFloatingSnack(_Strings.matchRequiredSnack, isError: true);
      return;
    }

    final replyToId = _replyToId;
    final replyToText = _replyToText;

    setState(() => _isSending = true);
    _controller.clear();

    try {
      await _firestore.collection('messages').add({
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
    } on FirebaseException catch (e) {
      debugPrint('❌ Send message failed: $e');
      // نعيد النص حتى لا يفقده المستخدم
      if (mounted && _controller.text.isEmpty) _controller.text = text;
      _showFloatingSnack(
        e.code == 'permission-denied'
            ? _Strings.sendDenied
            : _Strings.sendFailed,
        isError: true,
      );
    } catch (e) {
      debugPrint('❌ Send message failed: $e');
      if (mounted && _controller.text.isEmpty) _controller.text = text;
      _showFloatingSnack(_Strings.sendFailed, isError: true);
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
      for (var i = 0; i < unreadIncoming.length; i += _batchLimit) {
        final end = (i + _batchLimit < unreadIncoming.length)
            ? i + _batchLimit
            : unreadIncoming.length;
        final batch = _firestore.batch();
        for (final doc in unreadIncoming.sublist(i, end)) {
          batch.update(doc.reference, {'read': true});
        }
        await batch.commit();
      }
    } catch (e) {
      debugPrint('❌ Mark as read failed: $e');
    } finally {
      _isMarkingRead = false;
    }
  }

  void _clearReplyState() => _safeSetState(() {
    _replyToId = null;
    _replyToText = null;
  });

  void _replyToMessage(String replyToId, String replyToText) {
    if (_isBlocked) return;
    setState(() {
      _replyToId = replyToId;
      _replyToText = replyToText;
    });
    _focusNode.requestFocus();
  }

  // ------------------------------------------------------------
  // الرسائل الصوتية
  // ------------------------------------------------------------
  Future<void> _toggleRecording() async {
    if (_isRecording) {
      await _stopRecordingAndSend();
      return;
    }

    if (_isBlocked) {
      _showFloatingSnack(_Strings.youBlocked, isError: true);
      return;
    }

    if (!_hasMatch) {
      _showFloatingSnack(_Strings.matchRequiredSnack, isError: true);
      return;
    }

    try {
      if (!await _audioRecorder.hasPermission()) {
        _showFloatingSnack(_Strings.micPermission);
        return;
      }

      final dir = await getTemporaryDirectory();
      final path =
          '${dir.path}/voice_${DateTime.now().millisecondsSinceEpoch}.m4a';

      await _audioRecorder.start(const RecordConfig(), path: path);

      _safeSetState(() {
        _isRecording = true;
        _recordSeconds = 0;
      });

      _recordTimer?.cancel();
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
    _safeSetState(() {
      _isRecording = false;
      _recordSeconds = 0;
    });

    try {
      final path = await _audioRecorder.stop();
      if (path == null || durationSeconds < 1) return;

      final me = _myUid;
      final other = widget.personId;
      final chatId = _chatId;
      if (me == null || other == null || chatId == null) return;
      if (!_hasMatch || _isBlocked) return;

      _safeSetState(() => _isUploadingVoice = true);

      final fileName = 'voice_${DateTime.now().millisecondsSinceEpoch}.m4a';
      final storageRef = FirebaseStorage.instance.ref(
        'voice_messages/$chatId/$fileName',
      );
      await storageRef.putFile(File(path));
      final url = await storageRef.getDownloadURL();

      await _firestore.collection('messages').add({
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
      _showFloatingSnack(_Strings.voiceFailed, isError: true);
    } finally {
      _safeSetState(() => _isUploadingVoice = false);
    }
  }

  Future<void> _togglePlayVoice(String messageId, String url) async {
    try {
      if (_playingMessageId == messageId) {
        await _audioPlayer.stop();
        _safeSetState(() => _playingMessageId = null);
        return;
      }
      await _audioPlayer.stop();
      _safeSetState(() => _playingMessageId = messageId);
      await _audioPlayer.play(UrlSource(url));
      _audioPlayer.onPlayerComplete.first.then((_) {
        if (mounted && _playingMessageId == messageId) {
          setState(() => _playingMessageId = null);
        }
      });
    } catch (e) {
      debugPrint('❌ Play voice failed: $e');
      _safeSetState(() => _playingMessageId = null);
    }
  }

  // ------------------------------------------------------------
  // تعديل / حذف / تفاعل
  // ------------------------------------------------------------
  Future<void> _editMessage(String docId, String currentText) async {
    final result = await showDialog<String>(
      context: context,
      builder: (_) => _TextInputDialog(
        title: _Strings.editMessage,
        hint: _Strings.editHint,
        initial: currentText,
        maxLines: 3,
        filled: true,
      ),
    );

    if (result == null || result.isEmpty || result == currentText) return;

    // نفس فلتر الإرسال حتى لا تُتجاوز الحماية بالتعديل
    if (_containsBlockedContent(result)) {
      _showFloatingSnack(_Strings.rephraseEdit, isError: true);
      return;
    }

    try {
      await _firestore.collection('messages').doc(docId).update({
        'text': result,
      });
      _showFloatingSnack(_Strings.messageEdited);
    } catch (e) {
      debugPrint('❌ Edit message failed: $e');
      _showFloatingSnack(_Strings.editFailed, isError: true);
    }
  }

  Future<void> _deleteMessage(String docId) async {
    final confirm = await _confirmDialog(
      title: _Strings.deleteMessage,
      message: _Strings.deleteMessageConfirm,
      confirmLabel: _Strings.delete,
    );
    if (confirm != true) return;

    try {
      await _firestore.collection('messages').doc(docId).delete();
      _showFloatingSnack(_Strings.messageDeleted);
    } catch (e) {
      debugPrint('❌ Delete message failed: $e');
      _showFloatingSnack(_Strings.deleteFailed, isError: true);
    }
  }

  Future<void> _toggleReaction(String messageId, String emoji) async {
    final me = _myUid;
    if (me == null || _isBlocked) return;
    final docRef = _firestore.collection('messages').doc(messageId);
    try {
      await _firestore.runTransaction((transaction) async {
        final doc = await transaction.get(docRef);
        if (!doc.exists) return;
        final reactions = Map<String, dynamic>.from(
          doc.data()?['reactions'] ?? {},
        );
        final users = List<dynamic>.from(reactions[emoji] ?? []);
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

  // ------------------------------------------------------------
  // التنقل
  // ------------------------------------------------------------
  Future<void> _openProfile() async {
    final id = widget.personId;
    if (id == null) return;

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) =>
            ProfileViewScreen(userId: id, userName: widget.personName),
      ),
    );
    if (!mounted) return;

    // قد يكون المستخدم حُظر أو رُفع عنه الحظر من الملف الشخصي
    await _checkIfBlocked();
    _lastMessageCount = 0;
  }

  void _openReport() {
    final id = widget.personId;
    if (id == null) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) =>
            ReportUserScreen(userId: id, userName: widget.personName),
      ),
    );
  }

  // ------------------------------------------------------------
  // النوافذ السفلية
  // ------------------------------------------------------------
  void _openThemePicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: _p.sheet,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
      ),
      builder: (ctx) {
        final p = _Palette.of(ctx);
        return Padding(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: p.handle,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
              Text(
                _Strings.themeTitle,
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  color: p.title,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                _Strings.themeSubtitle,
                style: TextStyle(fontSize: 12.5, color: p.subtitle),
              ),
              const SizedBox(height: 20),
              Wrap(
                spacing: 14,
                runSpacing: 16,
                children: kChatThemes
                    .map((theme) => _buildThemeOption(ctx, p, theme))
                    .toList(),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildThemeOption(
    BuildContext ctx,
    _Palette p,
    ChatThemeOption theme,
  ) {
    final selected = theme.id == _chatThemeId;
    final bool dark = theme.id == 'night';

    Widget bar({required double width, required Color color, Border? border}) =>
        Container(
          width: width,
          height: 10,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(6),
            border: border,
          ),
        );

    return GestureDetector(
      onTap: () {
        _changeChatTheme(theme.id);
        Navigator.pop(ctx);
      },
      child: Column(
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            width: 78,
            height: 96,
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: theme.background,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: selected
                    ? _kGold
                    : (p.isDark
                          ? p.border
                          : Colors.black.withValues(alpha: 0.05)),
                width: selected ? 2.5 : 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: theme.swatch.withValues(alpha: selected ? 0.28 : 0.12),
                  blurRadius: selected ? 14 : 8,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Align(
                  alignment: Alignment.topLeft,
                  child: bar(
                    width: 34,
                    color: dark
                        ? Colors.white.withValues(alpha: 0.14)
                        : Colors.white,
                    border: dark
                        ? null
                        : Border.all(
                            color: Colors.black.withValues(alpha: 0.05),
                          ),
                  ),
                ),
                Positioned(
                  top: 16,
                  right: 0,
                  child: bar(width: 26, color: theme.swatch),
                ),
                Positioned(
                  bottom: 0,
                  left: 0,
                  child: bar(width: 44, color: theme.swatch),
                ),
                if (selected)
                  Positioned(
                    bottom: -2,
                    right: -2,
                    child: Container(
                      padding: const EdgeInsets.all(3),
                      decoration: const BoxDecoration(
                        color: _kGold,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.check_rounded,
                        color: Colors.white,
                        size: 12,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 7),
          Text(
            theme.label,
            style: TextStyle(
              fontSize: 11.5,
              fontWeight: selected ? FontWeight.w800 : FontWeight.w500,
              color: p.title,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // 😊 اختيار Emoji — bottom sheet بسيط، كيدخل الـ emoji فـ الـ TextField
  // ============================================================
  void _openEmojiPicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: _p.sheet,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (ctx) {
        final p = _Palette.of(ctx);
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(18, 12, 18, 18),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildSheetHandle(p),
                const SizedBox(height: 12),
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 6,
                    mainAxisSpacing: 8,
                    crossAxisSpacing: 8,
                    childAspectRatio: 1,
                  ),
                  itemCount: _quickEmojis.length,
                  itemBuilder: (_, index) {
                    final emoji = _quickEmojis[index];
                    return GestureDetector(
                      onTap: () => _insertEmoji(emoji),
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(10),
                          color: p.bg,
                        ),
                        child: Center(
                          child: Text(emoji, style: const TextStyle(fontSize: 26)),
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

  void _insertEmoji(String emoji) {
    final text = _controller.text;
    final selection = _controller.selection;
    final cursor = selection.start >= 0 ? selection.start : text.length;
    _controller.text = text.replaceRange(cursor, cursor, emoji);
    _controller.selection = TextSelection.collapsed(
      offset: cursor + emoji.length,
    );
  }

  void _showMessageOptions(
    String docId,
    String text,
    bool isMyMessage, {
    bool isAudio = false,
  }) {
    showModalBottomSheet(
      context: context,
      backgroundColor: _p.sheet,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        final p = _Palette.of(ctx);

        Widget option({
          required IconData icon,
          required Color color,
          required String label,
          required VoidCallback onTap,
        }) => ListTile(
          leading: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          title: Text(
            label,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 14,
              color: p.text,
            ),
          ),
          onTap: () {
            Navigator.pop(ctx);
            onTap();
          },
        );

        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 10),
              _buildSheetHandle(p),
              // لا تفاعل ولا رد عندما يكون المستخدم محظوراً
              if (!_isBlocked) ...[
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: _reactionEmojis.map((emoji) {
                      return GestureDetector(
                        onTap: () {
                          Navigator.pop(ctx);
                          _toggleReaction(docId, emoji);
                        },
                        child: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: p.bg,
                            boxShadow: [
                              BoxShadow(
                                color: p.isDark
                                    ? Colors.black.withValues(alpha: 0.3)
                                    : Colors.grey.withValues(alpha: 0.08),
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
                Divider(
                  height: 1,
                  thickness: 1,
                  indent: 20,
                  endIndent: 20,
                  color: p.isDark ? p.border : null,
                ),
                const SizedBox(height: 6),
                option(
                  icon: Icons.reply_rounded,
                  color: Colors.blue,
                  label: _Strings.replyAction,
                  onTap: () => _replyToMessage(
                    docId,
                    text.isEmpty && isAudio ? _Strings.voiceMessage : text,
                  ),
                ),
              ] else
                const SizedBox(height: 10),
              if (isMyMessage) ...[
                // لا يمكن تعديل الرسالة الصوتية (ولا عند الحظر)
                if (!isAudio && !_isBlocked)
                  option(
                    icon: Icons.edit_rounded,
                    color: p.icon,
                    label: _Strings.editMessage,
                    onTap: () => _editMessage(docId, text),
                  ),
                option(
                  icon: Icons.delete_outline_rounded,
                  color: p.isDark ? p.error : Colors.red,
                  label: _Strings.deleteMessage,
                  onTap: () => _deleteMessage(docId),
                ),
              ],
              const SizedBox(height: 14),
            ],
          ),
        );
      },
    );
  }

  // ------------------------------------------------------------
  // البناء
  // ------------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    final theme = chatThemeById(_chatThemeId);
    final bool canWrite = !_checkingMatch && _hasMatch && !_isBlocked;

    return Scaffold(
      backgroundColor: _bgOf(theme),
      appBar: _buildAppBar(theme),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(child: _buildMessagesArea()),
            AnimatedSize(
              duration: const Duration(milliseconds: 180),
              child: (_replyToId != null && canWrite)
                  ? _buildReplyBanner()
                  : const SizedBox.shrink(),
            ),
            if (canWrite)
              _buildInputBar()
            else if (_isBlocked)
              _buildInputBar(disabled: true),
          ],
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(ChatThemeOption theme) {
    final p = _p;
    final swatch = _swatchOf(theme);

    return PreferredSize(
      preferredSize: const Size.fromHeight(72),
      child: Container(
        decoration: BoxDecoration(
          color: p.appBar,
          boxShadow: [
            BoxShadow(
              color: p.isDark ? p.shadow : swatch.withValues(alpha: 0.08),
              blurRadius: 12,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: SafeArea(
          bottom: false,
          child: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            titleSpacing: 0,
            iconTheme: IconThemeData(color: p.icon),
            title: GestureDetector(
              onTap: _openProfile,
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
                          _nickname ?? widget.personName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: p.title,
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
            actions: [_buildPopupMenu(), const SizedBox(width: 6)],
          ),
        ),
      ),
    );
  }

  Widget _buildPopupMenu() {
    final p = _p;

    PopupMenuItem<String> item(
      String value,
      IconData icon,
      Color color,
      String label, {
      bool destructive = false,
    }) => PopupMenuItem(
      value: value,
      height: 46,
      child: _buildMenuRow(
        icon: icon,
        color: color,
        label: label,
        destructive: destructive,
      ),
    );

    return PopupMenuButton<String>(
      icon: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: p.isDark ? p.card : p.bg,
          shape: BoxShape.circle,
          border: p.isDark ? Border.all(color: p.border) : null,
        ),
        child: Icon(Icons.more_vert_rounded, color: p.icon, size: 20),
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      color: p.card,
      elevation: 8,
      offset: const Offset(0, 8),
      itemBuilder: (_) => [
        item('theme', Icons.palette_rounded, _kGold, _Strings.changeTheme),
        item('nickname', Icons.badge_rounded, p.icon, _Strings.nickname),
        const PopupMenuDivider(height: 10),
        item(
          'report',
          Icons.flag_rounded,
          Colors.orange.shade700,
          _Strings.report,
        ),
        item(
          'block',
          _isBlocked ? Icons.check_circle_rounded : Icons.block_rounded,
          _isBlocked ? (p.isDark ? p.icon : _kMidGreen) : Colors.red.shade600,
          _isBlocked ? _Strings.unblock : _Strings.block,
          destructive: !_isBlocked,
        ),
        item(
          'delete',
          Icons.delete_rounded,
          Colors.red.shade600,
          _Strings.deleteConversation,
          destructive: true,
        ),
      ],
      onSelected: (value) {
        switch (value) {
          case 'report':
            _openReport();
          case 'block':
            _toggleBlockFromMenu();
          case 'delete':
            _deleteConversationFromMenu();
          case 'theme':
            _openThemePicker();
          case 'nickname':
            _openNicknameDialog();
        }
      },
    );
  }

  // ============================================================
  // 🍔 صف موحّد لعناصر قائمة (⋮): أيقونة داخل شيبة ملوّنة + نص —
  // شكل modern بدل الأيقونة العارية القديمة.
  // ============================================================
  Widget _buildMenuRow({
    required IconData icon,
    required Color color,
    required String label,
    bool destructive = false,
  }) {
    final p = _p;
    return Row(
      children: [
        Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(11),
          ),
          child: Icon(icon, color: color, size: 18),
        ),
        const SizedBox(width: 12),
        Text(
          label,
          style: TextStyle(
            fontSize: 13.5,
            fontWeight: FontWeight.w600,
            color: destructive ? p.error : p.text,
          ),
        ),
      ],
    );
  }

  // الصورة الشخصية تبقى كما هي حتى عند الحظر
  Widget _buildAvatar({double size = 40}) {
    final p = _p;
    Widget fallback() => CircleAvatar(
      radius: size / 2,
      backgroundColor: p.icon.withValues(alpha: 0.08),
      child: Icon(Icons.person, color: p.icon, size: size * 0.55),
    );

    final source = widget.personAvatarAsset;
    Widget core;
    if (source == null || source.isEmpty) {
      core = fallback();
    } else {
      final isNetwork =
          source.startsWith('http://') || source.startsWith('https://');
      errorBuilder(BuildContext _, Object __, StackTrace? ___) => fallback();
      core = ClipOval(
        child: SizedBox(
          width: size,
          height: size,
          child: isNetwork
              ? Image.network(
                  source,
                  fit: BoxFit.cover,
                  alignment: Alignment.topCenter,
                  errorBuilder: errorBuilder,
                )
              : Image.asset(
                  source,
                  fit: BoxFit.cover,
                  alignment: Alignment.topCenter,
                  errorBuilder: errorBuilder,
                ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: _kGold, width: 2),
      ),
      child: core,
    );
  }

  // ============================================================
  // 🟢 حالة "متصل الآن" الحية — StreamBuilder على document المستخدم
  // الآخر باش تتبدل مباشرة كي يدخل/يخرج من التطبيق
  // ============================================================
  Widget _buildOnlineStatus() {
    final otherId = widget.personId;
    if (otherId == null) return const SizedBox.shrink();
    final p = _p;

    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: _firestore.collection('users').doc(otherId).snapshots(),
      builder: (context, snap) {
        final data = snap.data?.data();
        // عند حظر الشخص لا نعرض "متصل الآن"
        final bool isOnline = !_isBlocked && data?['isOnline'] == true;

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
                _Strings.online,
                style: TextStyle(
                  fontSize: 11.5,
                  color: p.isDark
                      ? Colors.green.shade400
                      : Colors.green.shade700,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          );
        }

        final city = widget.personCity;
        final label = (city != null && city.isNotEmpty)
            ? city
            : _Strings.offline;
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.circle, size: 6, color: p.subtitle),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 11.5, color: p.subtitle),
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
    final p = _p;
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 8, 12, 0),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: p.card,
        borderRadius: BorderRadius.circular(14),
        border: const Border(left: BorderSide(color: _kGold, width: 3)),
        boxShadow: [
          BoxShadow(
            color: p.isDark ? p.shadow : Colors.grey.withValues(alpha: 0.08),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          const Icon(Icons.reply_rounded, size: 18, color: _kGold),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _Strings.replyingTo,
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                    color: p.title,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _replyToText ?? '',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 13, color: p.subtitle),
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: _clearReplyState,
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(color: p.bg, shape: BoxShape.circle),
              child: Icon(Icons.close_rounded, size: 16, color: p.subtitle),
            ),
          ),
        ],
      ),
    );
  }

  // ------------------------------------------------------------
  // فواصل التاريخ
  // ------------------------------------------------------------
  Widget _buildDateSeparator(DateTime date) {
    final p = _p;
    final lineColor = p.isDark
        ? p.border
        : Colors.black.withValues(alpha: 0.08);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          Expanded(child: Container(height: 1, color: lineColor)),
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 12),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
            decoration: BoxDecoration(
              color: p.isDark ? p.card : Colors.black.withValues(alpha: 0.04),
              borderRadius: BorderRadius.circular(20),
              border: p.isDark ? Border.all(color: p.border) : null,
            ),
            child: Text(
              _dayLabel(date),
              style: TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w700,
                color: p.subtitle,
              ),
            ),
          ),
          Expanded(child: Container(height: 1, color: lineColor)),
        ],
      ),
    );
  }

  // ------------------------------------------------------------
  // منطقة الرسائل
  // ------------------------------------------------------------
  Widget _buildMessagesArea() {
    final p = _p;
    final me = _myUid;
    final chatId = _chatId;

    if (_checkingBlock || _checkingMatch) {
      return Center(
        child: CircularProgressIndicator(color: p.icon, strokeWidth: 2.4),
      );
    }

    // عند الحظر يبقى السجل ظاهراً، وتُستبدل خانة الكتابة فقط
    if (!_hasMatch && !_isBlocked) {
      return _buildInfoState(
        icon: Icons.favorite_border_rounded,
        iconColor: _kGold,
        title: _Strings.noChatYet,
        subtitle: _Strings.noChatYetSubtitle,
      );
    }

    if (me == null || chatId == null) {
      return _buildInfoState(
        icon: Icons.error_outline_rounded,
        iconColor: p.subtitle,
        title: _Strings.chatNotFound,
        subtitle: _Strings.tryAgain,
      );
    }

    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: _firestore
          .collection('messages')
          .where('chatId', isEqualTo: chatId)
          .orderBy('timestamp')
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          debugPrint('❌ Messages stream error: ${snapshot.error}');
          return _buildInfoState(
            icon: Icons.error_outline_rounded,
            iconColor: p.error,
            title: _Strings.loadError,
            subtitle: _Strings.tryAgain,
            titleColor: p.error,
          );
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(color: p.icon, strokeWidth: 2.4),
                const SizedBox(height: 14),
                Text(
                  _Strings.loadingMessages,
                  style: TextStyle(color: p.subtitle, fontSize: 12.5),
                ),
              ],
            ),
          );
        }

        final docs = snapshot.data?.docs ?? [];

        // لا نعلّم الرسائل كمقروءة أثناء الحظر
        if (!_isBlocked) {
          final unreadIncoming = docs.where((d) {
            final data = d.data();
            return data['toUserId'] == me && data['read'] != true;
          }).toList();
          if (unreadIncoming.isNotEmpty) _markMessagesAsRead(unreadIncoming);
        }

        if (docs.isEmpty) {
          if (_isBlocked) {
            return _buildInfoState(
              icon: Icons.chat_bubble_outline_rounded,
              iconColor: p.subtitle,
              title: _Strings.noMessages,
              subtitle: _Strings.noMessagesSubtitle,
            );
          }
          return _buildInfoState(
            icon: Icons.favorite_rounded,
            iconColor: _kGold,
            title: _Strings.matchTitle,
            subtitle: _Strings.startChat(widget.personName),
            big: true,
          );
        }

        // نمرّر للأسفل فقط إذا تغيّر عدد الرسائل
        // (وليس عند كل تفاعل / تعديل / "مقروءة")
        if (docs.length != _lastMessageCount) {
          _lastMessageCount = docs.length;
          _scrollToBottom();
        }

        final swatch = _swatchOf(chatThemeById(_chatThemeId));

        return ListView.builder(
          controller: _scrollController,
          padding: const EdgeInsets.fromLTRB(14, 16, 14, 10),
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final data = docs[index].data();
            final Timestamp? ts = data['timestamp'] as Timestamp?;

            // رسالة أُرسلت للتو (timestamp = null) تُعتبر "اليوم"
            final DateTime msgDate = ts?.toDate() ?? DateTime.now();
            bool showSeparator = index == 0;
            if (index > 0) {
              final prevTs = docs[index - 1].data()['timestamp'] as Timestamp?;
              showSeparator = !_isSameDay(
                prevTs?.toDate() ?? DateTime.now(),
                msgDate,
              );
            }

            final item = _buildMessageItem(docs[index], me, swatch);
            if (!showSeparator) return item;

            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [_buildDateSeparator(msgDate), item],
            );
          },
        );
      },
    );
  }

  Widget _buildMessageItem(
    QueryDocumentSnapshot<Map<String, dynamic>> doc,
    String me,
    Color swatch,
  ) {
    final p = _p;
    final data = doc.data();
    final bool fromMe = data['fromUserId'] == me;
    final String text = (data['text'] as String?) ?? '';
    final Timestamp? ts = data['timestamp'] as Timestamp?;
    final String docId = doc.id;
    final String? replyToId = data['replyToId'];
    final String? replyToText = data['replyToText'];
    final Map<String, dynamic> reactions = Map<String, dynamic>.from(
      data['reactions'] ?? {},
    );
    final bool isRead = data['read'] == true;
    final String? audioUrl = data['audioUrl'] as String?;
    final int audioDuration = (data['audioDuration'] as num?)?.toInt() ?? 0;

    return GestureDetector(
      onLongPress: () {
        HapticFeedback.selectionClick();
        _showMessageOptions(docId, text, fromMe, isAudio: audioUrl != null);
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
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.75,
              ),
              decoration: BoxDecoration(
                color: fromMe ? swatch : p.card,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(18),
                  topRight: const Radius.circular(18),
                  bottomLeft: Radius.circular(fromMe ? 18 : 4),
                  bottomRight: Radius.circular(fromMe ? 4 : 18),
                ),
                border: fromMe
                    ? null
                    : Border.all(
                        color: p.isDark ? p.border : Colors.grey.shade200,
                      ),
                boxShadow: [
                  BoxShadow(
                    color: p.isDark
                        ? Colors.black.withValues(alpha: 0.3)
                        : (fromMe ? swatch : Colors.grey).withValues(
                            alpha: fromMe ? 0.18 : 0.08,
                          ),
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
                    _buildReplyPreview(replyToText, fromMe),
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
                        color: fromMe ? Colors.white : p.text,
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
                                : p.subtitle,
                          ),
                        ),
                        if (fromMe) ...[
                          const SizedBox(width: 4),
                          Icon(
                            Icons.done_all_rounded,
                            size: 14,
                            color: isRead
                                ? _kSeenBlue
                                : Colors.white.withValues(alpha: 0.65),
                          ),
                        ],
                      ],
                    ),
                  ],
                ],
              ),
            ),
            if (reactions.isNotEmpty) _buildReactions(docId, reactions, me),
          ],
        ),
      ),
    );
  }

  Widget _buildReplyPreview(String replyToText, bool fromMe) {
    final p = _p;
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: fromMe ? Colors.white.withValues(alpha: 0.12) : p.bg,
        borderRadius: BorderRadius.circular(10),
        border: Border(
          left: BorderSide(
            color: fromMe ? Colors.white.withValues(alpha: 0.5) : _kGold,
            width: 2.5,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            _Strings.replyLabel,
            style: TextStyle(
              fontSize: 9.5,
              fontWeight: FontWeight.w700,
              color: fromMe ? Colors.white.withValues(alpha: 0.75) : p.subtitle,
            ),
          ),
          const SizedBox(height: 1),
          Text(
            replyToText,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 12.5,
              color: fromMe ? Colors.white.withValues(alpha: 0.9) : p.text,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReactions(
    String docId,
    Map<String, dynamic> reactions,
    String me,
  ) {
    final p = _p;
    return Padding(
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
              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
              decoration: BoxDecoration(
                color: isReacted ? p.icon.withValues(alpha: 0.14) : p.card,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: isReacted
                      ? p.icon.withValues(alpha: 0.5)
                      : (p.isDark ? p.border : Colors.grey.shade200),
                ),
                boxShadow: [
                  BoxShadow(
                    color: p.isDark
                        ? Colors.black.withValues(alpha: 0.25)
                        : Colors.grey.withValues(alpha: 0.06),
                    blurRadius: 4,
                    offset: const Offset(0, 1),
                  ),
                ],
              ),
              child: Text(
                '$emoji ${users.length}',
                style: TextStyle(fontSize: 12, color: p.text),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildInfoState({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    Color? titleColor,
    bool big = false,
  }) {
    final p = _p;
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
                color: titleColor ?? p.title,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12.5, color: p.subtitle, height: 1.5),
            ),
          ],
        ),
      ),
    );
  }

  // ------------------------------------------------------------
  // شريط الإدخال
  // ------------------------------------------------------------
  Widget _buildRoundChipButton({
    required Widget icon,
    required VoidCallback? onTap,
    required Color background,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: background,
          shape: BoxShape.circle,
        ),
        alignment: Alignment.center,
        child: icon,
      ),
    );
  }

  Widget _buildRecordingIndicator() {
    final p = _p;
    return Row(
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
          style: TextStyle(
            fontSize: 14,
            color: p.title,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(width: 10),
        Text(
          _Strings.recording,
          style: TextStyle(fontSize: 12, color: p.subtitle),
        ),
      ],
    );
  }

  Widget _buildInputBar({bool disabled = false}) {
    final p = _p;
    final swatch = _swatchOf(chatThemeById(_chatThemeId));
    final bool busy = _isSending || _isRecording;

    final bar = Container(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: p.card,
                borderRadius: BorderRadius.circular(28),
                border: Border.all(
                  color: p.isDark ? p.border : swatch.withValues(alpha: 0.08),
                ),
                boxShadow: [
                  BoxShadow(
                    color: p.isDark
                        ? Colors.black.withValues(alpha: 0.35)
                        : swatch.withValues(alpha: 0.16),
                    blurRadius: 22,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 5),
              child: Row(
                children: [
                  // 😊 زر الـ emoji — شكل دائرة معبأة بدل أيقونة عارية
                  _buildRoundChipButton(
                    icon: Icon(
                      Icons.emoji_emotions_rounded,
                      color: _isRecording ? p.handle : swatch,
                      size: 21,
                    ),
                    background: swatch.withValues(alpha: 0.12),
                    onTap: _isRecording ? null : _openEmojiPicker,
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: _isRecording
                        ? _buildRecordingIndicator()
                        : TextField(
                            controller: _controller,
                            focusNode: _focusNode,
                            textInputAction: TextInputAction.send,
                            minLines: 1,
                            maxLines: 4,
                            cursorColor: p.icon,
                            onSubmitted: (_) => _sendMessage(),
                            decoration: InputDecoration(
                              hintText: disabled
                                  ? _Strings.youBlockedPerson
                                  : _Strings.typeMessage,
                              hintStyle: TextStyle(color: p.subtitle),
                              border: InputBorder.none,
                              isDense: true,
                              contentPadding: const EdgeInsets.symmetric(
                                vertical: 13,
                              ),
                            ),
                            style: TextStyle(fontSize: 14.5, color: p.text),
                          ),
                  ),
                  const SizedBox(width: 4),
                  // 🎤 زر التسجيل الصوتي — دائرة تتلوّن بالأحمر أثناء التسجيل
                  _buildRoundChipButton(
                    icon: _isUploadingVoice
                        ? SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: p.icon,
                            ),
                          )
                        : Icon(
                            _isRecording
                                ? Icons.stop_rounded
                                : Icons.mic_rounded,
                            color: _isRecording ? Colors.white : swatch,
                            size: 20,
                          ),
                    background: _isRecording
                        ? Colors.red.shade400
                        : swatch.withValues(alpha: 0.12),
                    onTap: _isUploadingVoice ? null : _toggleRecording,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: busy ? null : _sendMessage,
            child: AnimatedScale(
              duration: const Duration(milliseconds: 150),
              scale: busy ? 0.94 : 1,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      swatch.withValues(alpha: busy ? 0.5 : 1),
                      p.primaryButton.withValues(alpha: busy ? 0.5 : 1),
                    ],
                  ),
                  shape: BoxShape.circle,
                  boxShadow: busy
                      ? []
                      : [
                          BoxShadow(
                            color: swatch.withValues(alpha: 0.38),
                            blurRadius: 12,
                            offset: const Offset(0, 5),
                          ),
                        ],
                ),
                child: _isSending
                    ? const Padding(
                        padding: EdgeInsets.all(15),
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Icon(
                        Icons.send_rounded,
                        color: Colors.white,
                        size: 21,
                      ),
              ),
            ),
          ),
        ],
      ),
    );

    if (!disabled) return bar;

    // الخانة معطّلة: أي ضغطة تفتح لوحة الحظر
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: _showBlockedSheet,
      child: AbsorbPointer(child: bar),
    );
  }
}

// ------------------------------------------------------------
// Dialog إدخال نص (اسم مستعار / تعديل رسالة):
// يملك الـ controller ويتخلص منه بأمان → لا خطأ عند "إلغاء"
// ------------------------------------------------------------
class _TextInputDialog extends StatefulWidget {
  final String title;
  final String hint;
  final String initial;
  final int maxLines;
  final int? maxLength;
  final String? helper;
  final bool filled;

  const _TextInputDialog({
    required this.title,
    required this.hint,
    required this.initial,
    this.maxLines = 1,
    this.maxLength,
    this.helper,
    this.filled = false,
  });

  @override
  State<_TextInputDialog> createState() => _TextInputDialogState();
}

class _TextInputDialogState extends State<_TextInputDialog> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initial);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = _Palette.of(context);
    final radius = BorderRadius.circular(widget.filled ? 12 : 14);
    final OutlineInputBorder normal = widget.filled
        ? OutlineInputBorder(borderRadius: radius, borderSide: BorderSide.none)
        : OutlineInputBorder(
            borderRadius: radius,
            borderSide: BorderSide(color: p.fieldBorder),
          );

    return AlertDialog(
      backgroundColor: p.card,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Text(
        widget.title,
        style: TextStyle(color: p.title, fontWeight: FontWeight.w800),
      ),
      content: TextField(
        controller: _controller,
        autofocus: true,
        maxLines: widget.maxLines,
        maxLength: widget.maxLength,
        textDirection: TextDirection.rtl,
        cursorColor: p.icon,
        style: TextStyle(color: p.text),
        decoration: InputDecoration(
          hintText: widget.hint,
          hintStyle: TextStyle(color: p.subtitle),
          helperText: widget.helper,
          helperStyle: TextStyle(color: p.subtitle),
          counterStyle: TextStyle(color: p.subtitle),
          filled: widget.filled,
          fillColor: p.bg,
          border: normal,
          enabledBorder: normal,
          focusedBorder: OutlineInputBorder(
            borderRadius: radius,
            borderSide: BorderSide(color: p.icon),
          ),
        ),
      ),
      actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(_Strings.cancel, style: TextStyle(color: p.subtitle)),
        ),
        ElevatedButton(
          onPressed: () => Navigator.pop(context, _controller.text.trim()),
          style: ElevatedButton.styleFrom(
            backgroundColor: p.primaryButton,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: const Text(
            _Strings.save,
            style: TextStyle(color: Colors.white),
          ),
        ),
      ],
    );
  }
}

// ------------------------------------------------------------
// صف الرسالة الصوتية
// ------------------------------------------------------------
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

  static const List<double> _bars = [
    6, 11, 8, 14, 9, 16, 7, 13, 10, 6, 12, 8, 15, 9, 6,
  ];

  @override
  Widget build(BuildContext context) {
    final p = _Palette.of(context);
    final Color color = fromMe ? Colors.white : p.title;

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
                    : color.withValues(alpha: 0.12),
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
            _formatDuration(durationSeconds),
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
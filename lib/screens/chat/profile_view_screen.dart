// screens/chat/profile_view_screen.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'report_user_screen.dart';
import '../../services/likes_service.dart';

// ------------------------------------------------------------
// النصوص
// ------------------------------------------------------------
class _Strings {
  const _Strings._();

  // عام
  static const cancel = 'إلغاء';
  static const save = 'حفظ';
  static const retry = 'إعادة المحاولة';
  static const genericError = 'حدث خطأ، أعد المحاولة';
  static const loadError = 'حدث خطأ أثناء التحميل';
  static const profileNotFound = 'الملف الشخصي غير موجود';
  static const noData = 'لا توجد بيانات';
  static const defaultUserName = 'مستخدم';
  static const online = 'متصل الآن';

  // المطابقة
  static const matchRequired = 'ستتمكن من المراسلة بعد أن يقبل الطرفان الإعجاب';

  // إعدادات المحادثة
  static const chatSettings = 'إعدادات المحادثة';
  static const searchTitle = 'البحث في المحادثة';
  static const searchSubtitle = 'ابحث في الرسائل';
  static const tapToEdit = 'اضغط للتعديل';
  static const tapToChangeName = 'اضغط لتغيير الاسم';
  static const myNameInChat = 'اسمي في هذه المحادثة';
  static const originalName = 'الاسم الأصلي';
  static const newNameHint = 'اكتب الاسم الجديد';
  static const myNewNameHint = 'اكتب اسمك الجديد';
  static const nicknameHelper = 'اتركه فارغاً لاستعادة الاسم الأصلي';
  static const nicknameSaved = '✅ تم حفظ الاسم';
  static String nameOf(String name) => 'اسم $name';
  static String editNameOf(String name) => 'تعديل اسم $name';

  // حذف المحادثة
  static const deleteConversation = 'حذف المحادثة';
  static const deleteConversationMessage =
      'سيتم حذف جميع الرسائل بينكما نهائياً. لا يمكن التراجع عن هذا الإجراء.';
  static const delete = 'حذف';
  static const conversationDeleted = '🗑️ تم حذف المحادثة';
  static const deleteFailed = '❌ فشل الحذف';

  // الحظر والإبلاغ
  static const report = 'الإبلاغ عن المستخدم';
  static const block = 'حظر المستخدم';
  static const unblock = 'إلغاء حظر المستخدم';
  static const blockMessage =
      'لن يتمكن هذا المستخدم من مراسلتك أو رؤية معلوماتك. هل أنت متأكد؟';
  static const blockConfirm = 'حظر';
  static const unblocked = 'تم إلغاء الحظر';
  static const blockNotice =
      'لن يتمكن هذا المستخدم من مراسلتك أو رؤية معلوماتك.';

  // البحث
  static const searchLoadFailed = 'تعذّر تحميل الرسائل';
  static const searchHint = 'ابحث في المحادثة...';
  static const searchStart = 'ابدأ الكتابة للبحث';
  static const noResults = 'لا توجد نتائج';
}

// ------------------------------------------------------------
// لوحة الألوان: تتبدل تلقائياً حسب المظهر (نهاري / ليلي)
// ------------------------------------------------------------
const Color _kDarkGreen = Color(0xFF0F3D2E);
const Color _kMidGreen = Color(0xFF1A6B4A);
const Color _kGold = Color(0xFFC9A24B);
const Color _kCream = Color(0xFFE6D5A8);

class _Palette {
  final bool isDark;
  final Color bg;
  final Color appBar;
  final Color card;
  final Color title;
  final Color text;
  final Color subtitle;
  final Color icon;
  final Color iconBg;
  final Color border;
  final Color shadow;
  final Color error;
  final Color online;

  const _Palette({
    required this.isDark,
    required this.bg,
    required this.appBar,
    required this.card,
    required this.title,
    required this.text,
    required this.subtitle,
    required this.icon,
    required this.iconBg,
    required this.border,
    required this.shadow,
    required this.error,
    required this.online,
  });

  static const light = _Palette(
    isDark: false,
    bg: Color(0xFFFAF7F2),
    appBar: Colors.white,
    card: Colors.white,
    title: _kDarkGreen,
    text: _kDarkGreen,
    subtitle: Color(0xFF757575),
    icon: _kDarkGreen,
    iconBg: Color(0x140F3D2E),
    border: Color(0x00000000),
    shadow: Color(0x0F0F3D2E),
    error: Color(0xFFD32F2F),
    online: Color(0xFF4CAF50),
  );

  static const dark = _Palette(
    isDark: true,
    bg: Color(0xFF0E1512),
    appBar: Color(0xFF121C17),
    card: Color(0xFF17221D),
    title: _kGold,
    text: _kCream,
    subtitle: Color(0xFF8FA198),
    icon: _kGold,
    iconBg: Color(0x1AC9A24B),
    border: Color(0xFF2A3A33),
    shadow: Color(0x66000000),
    error: Color(0xFFFF8A80),
    online: Color(0xFF4CAF50),
  );

  static _Palette of(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark ? dark : light;

  /// لون الأزرار الرئيسية
  Color get primaryButton => isDark ? _kMidGreen : _kDarkGreen;
}

// ------------------------------------------------------------
// دوال مساعدة
// ------------------------------------------------------------

/// يتجاهل حالة الأحرف، التشكيل، التطويل، وأشكال الألف والياء والتاء المربوطة
String _normalizeArabic(String s) => s
    .toLowerCase()
    .replaceAll(RegExp(r'[\u064B-\u065F\u0670\u0640]'), '')
    .replaceAll(RegExp(r'[أإآ]'), 'ا')
    .replaceAll('ى', 'ي')
    .replaceAll('ة', 'ه');

String _formatDate(Timestamp ts) {
  final d = ts.toDate();
  return '${d.day}/${d.month}/${d.year}';
}

// ------------------------------------------------------------
// الشاشة الرئيسية
// ------------------------------------------------------------
class ProfileViewScreen extends StatefulWidget {
  final String userId;
  final String userName;

  const ProfileViewScreen({
    super.key,
    required this.userId,
    required this.userName,
  });

  @override
  State<ProfileViewScreen> createState() => _ProfileViewScreenState();
}

class _ProfileViewScreenState extends State<ProfileViewScreen> {
  static const int _batchLimit = 400; // الحد الأقصى في Firestore هو 500

  final _firestore = FirebaseFirestore.instance;

  bool _isLoading = true;
  bool _isBlocked = false;
  bool _isSubmitting = false;
  bool _hasMatch = false;
  bool _checkingMatch = true;
  String? _errorMessage;

  Map<String, dynamic>? _userData;
  Map<String, String> _nicknames = {};

  _Palette get _p => _Palette.of(context);

  String get _myUid => FirebaseAuth.instance.currentUser?.uid ?? '';

  String get _chatId {
    final ids = [_myUid, widget.userId]..sort();
    return ids.join('_');
  }

  String? _nickOf(String uid) {
    final v = _nicknames[uid];
    return (v == null || v.trim().isEmpty) ? null : v;
  }

  String? get _otherNick => _nickOf(widget.userId);
  String? get _myNick => _nickOf(_myUid);

  String get _realName =>
      _userData?['fullName'] as String? ??
      _userData?['name'] as String? ??
      _Strings.defaultUserName;

  String? get _avatarSource =>
      (_userData?['avatarAsset'] as String?) ??
      (_userData?['avatarPath'] as String?);

  DocumentReference<Map<String, dynamic>> get _userDoc =>
      _firestore.collection('users').doc(widget.userId);

  /// نفس الـ collection المستعملة في شاشة المحادثة وقائمة المحظورين
  CollectionReference<Map<String, dynamic>> get _blockedCol =>
      _firestore.collection('users').doc(_myUid).collection('blockedUsers');

  DocumentReference<Map<String, dynamic>> get _chatSettingsDoc =>
      _firestore.collection('chatSettings').doc(_chatId);

  Query<Map<String, dynamic>> get _chatMessagesQuery =>
      _firestore.collection('messages').where('chatId', isEqualTo: _chatId);

  @override
  void initState() {
    super.initState();
    _loadAll();
  }

  // ------------------------------------------------------------
  // تحميل البيانات
  // ------------------------------------------------------------
  Future<void> _loadAll() => Future.wait([
    _loadProfile(),
    _checkIfBlocked(),
    _loadChatSettings(),
    _checkMatch(),
  ]);

  Future<void> _checkMatch() async {
    try {
      final matched = await LikesService.instance.hasMatch(widget.userId);
      if (!mounted) return;
      setState(() {
        _hasMatch = matched;
        _checkingMatch = false;
      });
    } catch (e) {
      debugPrint('❌ Check match failed: $e');
      if (mounted) setState(() => _checkingMatch = false);
    }
  }

  Future<void> _loadProfile() async {
    try {
      final doc = await _userDoc.get();
      if (!mounted) return;

      setState(() {
        if (doc.exists) {
          _userData = doc.data();
        } else {
          _errorMessage = _Strings.profileNotFound;
        }
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('❌ Load profile failed: $e');
      if (!mounted) return;
      setState(() {
        _errorMessage = _Strings.loadError;
        _isLoading = false;
      });
    }
  }

  Future<void> _checkIfBlocked() async {
    try {
      final snap = await _blockedCol
          .where('blockedUid', isEqualTo: widget.userId)
          .limit(1)
          .get();
      if (mounted && snap.docs.isNotEmpty) setState(() => _isBlocked = true);
    } catch (e) {
      debugPrint('❌ Check blocked failed: $e');
    }
  }

  Future<void> _loadChatSettings() async {
    try {
      final doc = await _chatSettingsDoc.get();
      if (!mounted || !doc.exists) return;

      final raw = doc.data()?['nicknames'];
      if (raw is Map) {
        setState(() {
          _nicknames = raw.map((k, v) => MapEntry(k.toString(), v.toString()));
        });
      }
    } catch (e) {
      debugPrint('❌ Load chat settings failed: $e');
    }
  }

  // ------------------------------------------------------------
  // الأسماء المستعارة
  // (الـ controller يُدار داخل الـ dialog نفسه لتفادي خطأ disposed)
  // ------------------------------------------------------------
  Future<void> _editNickname({
    required String uid,
    required String title,
    required String hint,
  }) async {
    final result = await showDialog<String>(
      context: context,
      builder: (_) => _NicknameDialog(
        title: title,
        hint: hint,
        initial: _nicknames[uid] ?? '',
      ),
    );

    // null = ألغى المستخدم العملية
    if (result == null) return;
    await _saveNickname(uid, result);
  }

  Future<void> _saveNickname(String uid, String value) async {
    try {
      await _chatSettingsDoc.set({
        'nicknames': {uid: value.isEmpty ? FieldValue.delete() : value},
      }, SetOptions(merge: true));
      if (!mounted) return;
      setState(() {
        if (value.isEmpty) {
          _nicknames.remove(uid);
        } else {
          _nicknames[uid] = value;
        }
      });
      _showSnack(_Strings.nicknameSaved);
    } catch (e) {
      debugPrint('❌ Save nickname failed: $e');
      if (mounted) _showSnack(_Strings.genericError, color: Colors.red);
    }
  }

  // ------------------------------------------------------------
  // الحظر
  // ------------------------------------------------------------
  Future<void> _toggleBlock() async {
    if (_isSubmitting) return;
    setState(() => _isSubmitting = true);

    var blockedNow = false;
    try {
      if (_isBlocked) {
        await _removeBlock();
        if (!mounted) return;
        setState(() => _isBlocked = false);
        _showSnack(_Strings.unblocked, color: Colors.green);
        return;
      }

      final confirm = await _confirmDialog(
        title: _Strings.block,
        message: _Strings.blockMessage,
        confirmLabel: _Strings.blockConfirm,
        confirmColor: Colors.red,
      );
      if (confirm != true) return;

      await _addBlock();
      if (!mounted) return;
      setState(() => _isBlocked = true);
      blockedNow = true;
    } catch (e) {
      debugPrint('❌ Block toggle failed: $e');
      if (mounted) _showSnack(_Strings.genericError, color: Colors.red);
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }

    // بدل الإشعار: نعرض لوحة "لقد قمت بحظر هذا الشخص"
    if (blockedNow && mounted) await _showBlockedPanel();
  }

  /// نفس صيغة الوثيقة التي تكتبها شاشة المحادثة
  Future<void> _addBlock() {
    final avatar = _avatarSource;
    return _blockedCol.doc(widget.userId).set({
      'blockedUid': widget.userId,
      'name': _realName,
      'avatarUrl': (avatar != null && avatar.startsWith('http'))
          ? avatar
          : null,
      'blockedAt': FieldValue.serverTimestamp(),
    });
  }

  /// يحذف كل وثيقة تشير إلى هذا المستخدم مهما كان معرّفها
  Future<void> _removeBlock() async {
    final existing = await _blockedCol
        .where('blockedUid', isEqualTo: widget.userId)
        .get();
    for (final d in existing.docs) {
      await d.reference.delete();
    }
  }

  Future<void> _showBlockedPanel() async {
    final action = await showBlockedSheet(context);
    if (!mounted) return;

    if (action == BlockedSheetAction.unblock) {
      await _toggleBlock(); // _isBlocked = true → يلغي الحظر مباشرة
    } else if (action == BlockedSheetAction.delete) {
      await _deleteConversation();
    }
  }

  // ------------------------------------------------------------
  // حذف المحادثة (على دفعات لتفادي حد الـ 500 عملية)
  // ------------------------------------------------------------
  Future<void> _deleteConversation() async {
    final confirm = await _confirmDialog(
      title: _Strings.deleteConversation,
      message: _Strings.deleteConversationMessage,
      confirmLabel: _Strings.delete,
      confirmColor: Colors.red,
    );
    if (confirm != true) return;

    try {
      final snap = await _chatMessagesQuery.get();
      final docs = snap.docs;

      for (var i = 0; i < docs.length; i += _batchLimit) {
        final batch = _firestore.batch();
        final end = (i + _batchLimit < docs.length)
            ? i + _batchLimit
            : docs.length;
        for (final doc in docs.sublist(i, end)) {
          batch.delete(doc.reference);
        }
        await batch.commit();
      }

      if (!mounted) return;
      _showSnack(_Strings.conversationDeleted);
      // إغلاق شاشة الملف الشخصي ثم شاشة المحادثة
      Navigator.pop(context);
      Navigator.pop(context);
    } catch (e) {
      debugPrint('❌ Delete conversation failed: $e');
      if (mounted) _showSnack(_Strings.deleteFailed, color: Colors.red);
    }
  }

  // ------------------------------------------------------------
  // البحث: بدون orderBy (لتفادي الحاجة إلى composite index) والترتيب محلياً
  // ------------------------------------------------------------
  Future<void> _openSearch() async {
    final List<QueryDocumentSnapshot<Map<String, dynamic>>> docs;
    try {
      final snap = await _chatMessagesQuery.get();
      docs = snap.docs.toList()
        ..sort((a, b) {
          final ta = a.data()['timestamp'] as Timestamp?;
          final tb = b.data()['timestamp'] as Timestamp?;
          if (ta == null && tb == null) return 0;
          if (ta == null) return -1; // رسالة جديدة لم تُسجَّل بعد
          if (tb == null) return 1;
          return tb.compareTo(ta); // الأحدث أولاً
        });
    } catch (e) {
      debugPrint('❌ Search load failed: $e');
      if (mounted) _showSnack(_Strings.searchLoadFailed, color: Colors.red);
      return;
    }
    if (!mounted) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: _p.card,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _SearchSheet(docs: docs),
    );
  }

  // ------------------------------------------------------------
  // أدوات واجهة
  // ------------------------------------------------------------
  void _showSnack(String message, {Color? color}) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message), backgroundColor: color));
  }

  Future<bool?> _confirmDialog({
    required String title,
    required String message,
    required String confirmLabel,
    required Color confirmColor,
  }) {
    final p = _p;
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: p.card,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          title,
          style: TextStyle(color: p.title, fontWeight: FontWeight.bold),
        ),
        content: Text(message, style: TextStyle(fontSize: 13, color: p.text)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(_Strings.cancel, style: TextStyle(color: p.subtitle)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: confirmColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
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

  // ------------------------------------------------------------
  // البناء
  // ------------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    final p = _p;
    return Scaffold(
      backgroundColor: p.bg,
      appBar: AppBar(
        backgroundColor: p.appBar,
        elevation: 0.5,
        iconTheme: IconThemeData(color: p.icon),
        actions: [if (_hasMatch) _buildMenu()],
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: p.icon))
          : _errorMessage != null
          ? _buildErrorState()
          : _buildProfileContent(),
    );
  }

  Widget _buildMenu() {
    final p = _p;
    return PopupMenuButton<String>(
      icon: Icon(Icons.more_vert_rounded, color: p.icon),
      color: p.card,
      onSelected: (value) {
        if (value == 'delete') _deleteConversation();
      },
      itemBuilder: (_) => [
        PopupMenuItem(
          value: 'delete',
          child: Row(
            children: [
              Icon(Icons.delete_outline_rounded, color: p.error, size: 20),
              const SizedBox(width: 10),
              Text(
                _Strings.deleteConversation,
                style: TextStyle(color: p.text),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildErrorState() {
    final p = _p;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, color: p.error, size: 48),
            const SizedBox(height: 16),
            Text(
              _errorMessage!,
              textAlign: TextAlign.center,
              style: TextStyle(color: p.subtitle),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadProfile,
              style: ElevatedButton.styleFrom(
                backgroundColor: p.primaryButton,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: const Text(
                _Strings.retry,
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAvatarImage(String? source, double size) {
    final fallback = Icon(Icons.person, size: size * 0.55, color: _p.icon);
    if (source == null || source.trim().isEmpty) return fallback;

    final isNetwork =
        source.startsWith('http://') || source.startsWith('https://');
    errorBuilder(BuildContext _, Object __, StackTrace? ___) => fallback;

    return isNetwork
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
          );
  }

  Widget _buildProfileContent() {
    final data = _userData;
    if (data == null) {
      return Center(
        child: Text(_Strings.noData, style: TextStyle(color: _p.text)),
      );
    }

    final String name =
        data['fullName'] as String? ??
        data['name'] as String? ??
        _Strings.defaultUserName;
    final String? avatar =
        (data['avatarAsset'] as String?) ?? (data['avatarPath'] as String?);
    final bool isOnline = data['isOnline'] == true;
    final String displayName = _otherNick ?? name;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 30),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildHeader(
            displayName: displayName,
            realName: name,
            avatar: avatar,
            isOnline: isOnline,
          ),
          const SizedBox(height: 22),
          if (!_hasMatch && !_checkingMatch) ...[
            _buildMatchNotice(),
            const SizedBox(height: 22),
          ],
          if (_hasMatch) ...[
            _buildChatSettings(displayName: displayName, realName: name),
            const SizedBox(height: 22),
          ],
          _buildActions(name),
        ],
      ),
    );
  }

  Widget _buildHeader({
    required String displayName,
    required String realName,
    required String? avatar,
    required bool isOnline,
  }) {
    final p = _p;
    return Center(
      child: Column(
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                width: 96,
                height: 96,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: p.icon.withValues(alpha: 0.08),
                  border: Border.all(color: _kGold, width: 2.5),
                ),
                child: ClipOval(child: _buildAvatarImage(avatar, 96)),
              ),
              if (isOnline)
                Positioned(
                  bottom: 2,
                  right: 2,
                  child: Container(
                    width: 18,
                    height: 18,
                    decoration: BoxDecoration(
                      color: p.online,
                      shape: BoxShape.circle,
                      border: Border.all(color: p.bg, width: 2.5),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            displayName,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: p.title,
            ),
          ),
          if (_otherNick != null) ...[
            const SizedBox(height: 2),
            Text(realName, style: TextStyle(fontSize: 12, color: p.subtitle)),
          ],
          const SizedBox(height: 4),
          if (isOnline)
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 7,
                  height: 7,
                  decoration: BoxDecoration(
                    color: p.online,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 5),
                Text(
                  _Strings.online,
                  style: TextStyle(fontSize: 12.5, color: p.subtitle),
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildMatchNotice() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _kGold.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          const Icon(Icons.favorite_border_rounded, color: _kGold, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              _Strings.matchRequired,
              style: TextStyle(fontSize: 12.5, color: _p.subtitle),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChatSettings({
    required String displayName,
    required String realName,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const _SectionLabel(_Strings.chatSettings),
        const SizedBox(height: 8),
        _InfoCard(
          icon: Icons.search_rounded,
          title: _Strings.searchTitle,
          value: _Strings.searchSubtitle,
          onTap: _openSearch,
        ),
        const SizedBox(height: 10),
        _InfoCard(
          icon: Icons.edit_rounded,
          title: _Strings.nameOf(displayName),
          value: _otherNick != null
              ? _Strings.tapToEdit
              : _Strings.tapToChangeName,
          onTap: () => _editNickname(
            uid: widget.userId,
            title: _Strings.editNameOf(realName),
            hint: _Strings.newNameHint,
          ),
        ),
        const SizedBox(height: 10),
        _InfoCard(
          icon: Icons.person_outline_rounded,
          title: _Strings.myNameInChat,
          value: _myNick ?? _Strings.originalName,
          onTap: () => _editNickname(
            uid: _myUid,
            title: _Strings.myNameInChat,
            hint: _Strings.myNewNameHint,
          ),
        ),
      ],
    );
  }

  Widget _buildActions(String name) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _ActionRow(
          icon: Icons.flag_rounded,
          label: _Strings.report,
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) =>
                  ReportUserScreen(userId: widget.userId, userName: name),
            ),
          ),
        ),
        const SizedBox(height: 10),
        _ActionRow(
          icon: _isBlocked ? Icons.check_circle_rounded : Icons.block_rounded,
          label: _isBlocked ? _Strings.unblock : _Strings.block,
          onTap: _isSubmitting ? null : _toggleBlock,
        ),
        const SizedBox(height: 16),
        Center(
          child: Text(
            _Strings.blockNotice,
            textAlign: TextAlign.center,
            style: TextStyle(color: _p.subtitle, fontSize: 11),
          ),
        ),
      ],
    );
  }
}

// ------------------------------------------------------------
// Dialog تعديل الاسم: يملك الـ controller ويتخلص منه بأمان
// ------------------------------------------------------------
class _NicknameDialog extends StatefulWidget {
  final String title;
  final String hint;
  final String initial;

  const _NicknameDialog({
    required this.title,
    required this.hint,
    required this.initial,
  });

  @override
  State<_NicknameDialog> createState() => _NicknameDialogState();
}

class _NicknameDialogState extends State<_NicknameDialog> {
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
    return AlertDialog(
      backgroundColor: p.card,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Text(
        widget.title,
        style: TextStyle(color: p.title, fontWeight: FontWeight.bold),
      ),
      content: TextField(
        controller: _controller,
        autofocus: true,
        maxLength: 30,
        textAlign: TextAlign.right,
        cursorColor: p.icon,
        style: TextStyle(color: p.text),
        decoration: InputDecoration(
          hintText: widget.hint,
          hintStyle: TextStyle(color: p.subtitle),
          helperText: _Strings.nicknameHelper,
          helperStyle: TextStyle(color: p.subtitle),
          counterStyle: TextStyle(color: p.subtitle),
          enabledBorder: UnderlineInputBorder(
            borderSide: BorderSide(color: p.isDark ? p.border : Colors.grey),
          ),
          focusedBorder: UnderlineInputBorder(
            borderSide: BorderSide(color: p.icon),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(_Strings.cancel, style: TextStyle(color: p.subtitle)),
        ),
        ElevatedButton(
          onPressed: () => Navigator.pop(context, _controller.text.trim()),
          style: ElevatedButton.styleFrom(
            backgroundColor: p.primaryButton,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
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
// Bottom sheet: البحث في المحادثة
// ------------------------------------------------------------
class _SearchSheet extends StatefulWidget {
  final List<QueryDocumentSnapshot<Map<String, dynamic>>> docs;
  const _SearchSheet({required this.docs});

  @override
  State<_SearchSheet> createState() => _SearchSheetState();
}

class _SearchSheetState extends State<_SearchSheet> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  List<QueryDocumentSnapshot<Map<String, dynamic>>> _search(String query) {
    if (query.isEmpty) return const [];
    return widget.docs.where((d) {
      final text = (d.data()['text'] as String?) ?? '';
      return text.isNotEmpty && _normalizeArabic(text).contains(query);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final p = _Palette.of(context);
    final query = _normalizeArabic(_controller.text.trim());
    final results = _search(query);

    return Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
      ),
      child: SizedBox(
        height: MediaQuery.of(context).size.height * 0.6,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(Icons.search_rounded, color: p.icon),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: _controller,
                    autofocus: true,
                    textAlign: TextAlign.right,
                    cursorColor: p.icon,
                    style: TextStyle(color: p.text),
                    decoration: InputDecoration(
                      hintText: _Strings.searchHint,
                      hintStyle: TextStyle(color: p.subtitle),
                      border: InputBorder.none,
                    ),
                    onChanged: (_) => setState(() {}),
                  ),
                ),
              ],
            ),
            Divider(color: p.isDark ? p.border : null),
            Expanded(child: _buildBody(p, query, results)),
          ],
        ),
      ),
    );
  }

  Widget _buildBody(
    _Palette p,
    String query,
    List<QueryDocumentSnapshot<Map<String, dynamic>>> results,
  ) {
    if (query.isEmpty) {
      return _centerText(_Strings.searchStart, p);
    }
    if (results.isEmpty) {
      return _centerText(_Strings.noResults, p);
    }

    return ListView.builder(
      itemCount: results.length,
      itemBuilder: (_, index) {
        final data = results[index].data();
        final text = (data['text'] as String?) ?? '';
        final ts = data['timestamp'] as Timestamp?;
        return ListTile(
          leading: Icon(Icons.chat_bubble_outline_rounded, color: p.icon),
          title: Text(
            text,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(color: p.text),
          ),
          subtitle: ts != null
              ? Text(
                  _formatDate(ts),
                  style: TextStyle(fontSize: 11, color: p.subtitle),
                )
              : null,
        );
      },
    );
  }

  Widget _centerText(String text, _Palette p) => Center(
    child: Text(text, style: TextStyle(color: p.subtitle)),
  );
}

// ------------------------------------------------------------
// عناصر واجهة صغيرة
// ------------------------------------------------------------
class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    final p = _Palette.of(context);
    return Text(
      text,
      style: TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w800,
        color: p.title,
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;
  final VoidCallback? onTap;

  const _InfoCard({
    required this.icon,
    required this.title,
    required this.value,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final p = _Palette.of(context);
    return Material(
      color: p.card,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: p.isDark ? Border.all(color: p.border) : null,
            boxShadow: [
              BoxShadow(
                color: p.shadow,
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: p.iconBg,
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: p.icon, size: 18),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 13.5,
                        color: p.title,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      value,
                      style: TextStyle(fontSize: 12, color: p.subtitle),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ActionRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onTap;

  const _ActionRow({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final p = _Palette.of(context);
    return Material(
      color: p.error.withValues(alpha: p.isDark ? 0.10 : 0.06),
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Icon(icon, color: p.error, size: 20),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    color: p.error,
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                ),
              ),
              Icon(
                Icons.chevron_left_rounded,
                color: p.error.withValues(alpha: 0.6),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ------------------------------------------------------------
// لوحة "لقد قمت بحظر هذا الشخص" (تُستعمل أيضاً في شاشة المحادثة)
// ------------------------------------------------------------
enum BlockedSheetAction { unblock, delete }

/// تُرجع null إذا أغلقها المستخدم دون اختيار
Future<BlockedSheetAction?> showBlockedSheet(BuildContext context) {
  FocusScope.of(context).unfocus();
  return showModalBottomSheet<BlockedSheetAction>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    barrierColor: Colors.black.withValues(alpha: 0.35),
    builder: (_) => const _BlockedPanel(),
  );
}

class _BlockedPanel extends StatelessWidget {
  const _BlockedPanel();

  @override
  Widget build(BuildContext context) {
    final p = _Palette.of(context);
    final danger = p.isDark ? p.error : Colors.red.shade700;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: p.isDark ? p.card : const Color(0xFFFAF8F5),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          border: p.isDark ? Border.all(color: p.border) : null,
        ),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 38, 20, 44),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    color: Colors.grey.withValues(alpha: 0.14),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.speaker_notes_off_outlined,
                    size: 34,
                    color: p.isDark ? p.subtitle : Colors.grey.shade600,
                  ),
                ),
                const SizedBox(height: 18),
                Text(
                  'لقد قمت بحظر هذا الشخص',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: p.isDark ? p.title : const Color(0xFF1C1C1C),
                    decoration: TextDecoration.none,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'لا يمكنك إرسال رسائل إلى هذا الحساب أو الاتصال به إلا إذا قمت بإلغاء الحظر',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 13,
                    height: 1.5,
                    fontWeight: FontWeight.w400,
                    color: p.subtitle,
                    decoration: TextDecoration.none,
                  ),
                ),
                const SizedBox(height: 26),
                Row(
                  children: [
                    Expanded(
                      child: _PanelButton(
                        label: 'إلغاء الحظر',
                        background: p.isDark
                            ? const Color(0xFF26332D)
                            : const Color(0xFFE9ECEA),
                        foreground: p.icon,
                        onPressed: () =>
                            Navigator.pop(context, BlockedSheetAction.unblock),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _PanelButton(
                        label: 'حذف',
                        background: p.isDark
                            ? const Color(0xFF3A1F1F)
                            : const Color(0xFFFBE4E4),
                        foreground: danger,
                        onPressed: () =>
                            Navigator.pop(context, BlockedSheetAction.delete),
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

class _PanelButton extends StatelessWidget {
  final String label;
  final Color background;
  final Color foreground;
  final VoidCallback onPressed;

  const _PanelButton({
    required this.label,
    required this.background,
    required this.foreground,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 48,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: background,
          foregroundColor: foreground,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        child: Text(
          label,
          style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w800),
        ),
      ),
    );
  }
}

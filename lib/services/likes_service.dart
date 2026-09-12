// services/likes_service.dart
//
// ✅ Service مركزي لمنطق الإعجابات (Likes) + الدعوات (Invitations) + المطابقات (Matches)
//
// هذا هو "الـ Backend" الحقيقي لنظام الإعجابات فـ تطبيق يعتمد على Firebase:
// كل القرارات المصيرية (هل يوجد Match؟ هل يمكن القبول؟ هل يمكن إرسال رسالة؟)
// تعدّى من هنا، وتُفرض مرة ثانية (بشكل غير قابل للالتفاف حوله من طرف
// Frontend) عبر Firestore Security Rules (راجع ملف firestore.rules).
//
// القواعد:
// - LIKE يُنشئ إعجاب بحالة "pending" (أو يعيد استعمال الموجود، بلا تكرار — البند 11)
// - ACCEPT يتحقق أن الإعجاب موجّه فعلاً لي وأنه ما زال pending، ثم ينشئ MATCH
//   (كل هذا داخل Firestore transaction واحدة كي يبقى العمل atomic)
// - REJECT يرفض الإعجاب فقط — بلا Match وبلا Chat
// - hasMatch() هو المرجع الوحيد لمعرفة هل يمكن فتح/استعمال محادثة مع شخص معين
//
// Firestore collections المستعملة:
//   likes:   { fromUserId, toUserId, status: pending|accepted|rejected|cancelled, createdAt, updatedAt }
//   matches: { users: [uid1, uid2], user1Id, user2Id, createdAt }   (id = "uidA_uidB" مرتبة أبجدياً)

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

enum LikeStatus { pending, accepted, rejected, cancelled }

LikeStatus statusFromString(String? s) {
  switch (s) {
    case 'accepted':
      return LikeStatus.accepted;
    case 'rejected':
      return LikeStatus.rejected;
    case 'cancelled':
      return LikeStatus.cancelled;
    case 'pending':
    default:
      return LikeStatus.pending;
  }
}

String statusToString(LikeStatus s) => s.name;

/// دعوة/إعجاب كما تُقرأ من Firestore
class LikeInvitation {
  final String id;
  final String fromUserId;
  final String toUserId;
  final LikeStatus status;
  final Timestamp? createdAt;

  const LikeInvitation({
    required this.id,
    required this.fromUserId,
    required this.toUserId,
    required this.status,
    required this.createdAt,
  });

  factory LikeInvitation.fromDoc(
    QueryDocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data();
    return LikeInvitation(
      id: doc.id,
      fromUserId: data['fromUserId'] as String? ?? '',
      toUserId: data['toUserId'] as String? ?? '',
      status: statusFromString(data['status'] as String?),
      createdAt: data['createdAt'] as Timestamp?,
    );
  }
}

/// استثناء واضح نعرضه للمستخدم (بدل تسريب تفاصيل تقنية غير ضرورية)
class LikeActionException implements Exception {
  final String message;
  LikeActionException(this.message);
  @override
  String toString() => message;
}

class LikesService {
  LikesService._();
  static final LikesService instance = LikesService._();

  final FirebaseFirestore _db = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _likes =>
      _db.collection('likes');
  CollectionReference<Map<String, dynamic>> get _matches =>
      _db.collection('matches');

  String? get _myUid => FirebaseAuth.instance.currentUser?.uid;

  /// معرف ثابت لأي زوج مستخدمين (نفس فكرة chatId الموجودة فـ المشروع)
  String pairKey(String a, String b) {
    final ids = [a, b]..sort();
    return ids.join('_');
  }

  /// ✅ معرف ثابت (وليس auto-id) لكل إعجاب: "fromUserId_toUserId"
  /// (بترتيب الاتجاه، بلا فرز أبجدي، خلافاً لـ pairKey). هذا يسمح لقواعد
  /// أمان Firestore (firestore.rules) بالتحقق من وجود إعجاب مقبول حقيقي
  /// خلف أي Match تُنشأ — بدل الاعتماد الأعمى على الـ Frontend (البند 14).
  String _likeId(String from, String to) => '${from}_$to';

  // ============================================================
  // ❤️ إرسال إعجاب (Like / Invitation) — البند 2 + 11
  // ============================================================
  /// يُرجع true إذا انطلقت دعوة جديدة (أو أعيد تفعيل واحدة مرفوضة سابقاً)،
  /// و false إذا كان هناك بالفعل إعجاب pending/accepted أو Match قائم —
  /// حتى لا يتكرر نفس الإعجاب أبداً لنفس الشخص.
  Future<bool> sendLike(String toUserId) async {
    final me = _myUid;
    if (me == null) throw LikeActionException('يجب تسجيل الدخول أولاً');
    if (me == toUserId) {
      throw LikeActionException('لا يمكنك إرسال إعجاب لنفسك');
    }

    // إذا كان هناك Match مسبق، لا فائدة من إعجاب جديد
    if (await hasMatch(toUserId)) return false;

    final likeRef = _likes.doc(_likeId(me, toUserId));
    final snap = await likeRef.get();

    if (snap.exists) {
      final status = statusFromString(snap.data()?['status'] as String?);
      if (status == LikeStatus.pending || status == LikeStatus.accepted) {
        return false; // موجود بالفعل — لا Row جديد (البند 11)
      }
      // كان مرفوضاً/ملغياً — نعيد تفعيله بدل إنشاء وثيقة مكررة
      await likeRef.update({
        'status': statusToString(LikeStatus.pending),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      return true;
    }

    await likeRef.set({
      'fromUserId': me,
      'toUserId': toUserId,
      'status': statusToString(LikeStatus.pending),
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
    return true;
  }

  // ============================================================
  // 📥 Invitations المستقبلة (pending فقط) — Stream حي — البند 3+4
  // ============================================================
  Stream<List<LikeInvitation>> receivedInvitationsStream() {
    final me = _myUid;
    if (me == null) return const Stream.empty();
    return _likes
        .where('toUserId', isEqualTo: me)
        .where('status', isEqualTo: 'pending')
        .snapshots()
        .map((snap) {
      final list = snap.docs.map(LikeInvitation.fromDoc).toList();
      list.sort((a, b) {
        final at = a.createdAt;
        final bt = b.createdAt;
        if (at == null && bt == null) return 0;
        if (at == null) return 1;
        if (bt == null) return -1;
        return bt.compareTo(at);
      });
      return list;
    });
  }

  // ============================================================
  // ✅ قبول دعوة → إنشاء Match — البند 6
  // ============================================================
  Future<void> acceptInvitation(String likeId) async {
    final me = _myUid;
    if (me == null) throw LikeActionException('يجب تسجيل الدخول أولاً');

    await _db.runTransaction((tx) async {
      final likeRef = _likes.doc(likeId);
      final likeSnap = await tx.get(likeRef);
      if (!likeSnap.exists) {
        throw LikeActionException('هذه الدعوة لم تعد موجودة');
      }
      final data = likeSnap.data()!;
      final fromUserId = data['fromUserId'] as String?;
      final toUserId = data['toUserId'] as String?;
      final status = statusFromString(data['status'] as String?);

      if (toUserId != me) {
        throw LikeActionException('لا يمكنك قبول دعوة ليست موجهة إليك');
      }
      if (fromUserId == null || fromUserId.isEmpty) {
        throw LikeActionException('بيانات الدعوة غير صالحة');
      }
      if (status != LikeStatus.pending) {
        throw LikeActionException('تم التعامل مع هذه الدعوة من قبل');
      }

      final matchRef = _matches.doc(pairKey(fromUserId, me));
      final matchSnap = await tx.get(matchRef);

      tx.update(likeRef, {
        'status': statusToString(LikeStatus.accepted),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      if (!matchSnap.exists) {
        tx.set(matchRef, {
          'users': [fromUserId, me],
          'user1Id': fromUserId,
          'user2Id': me,
          'createdAt': FieldValue.serverTimestamp(),
        });
      }
    });
  }

  // ============================================================
  // ❌ رفض دعوة — البند 9
  // ============================================================
  Future<void> rejectInvitation(String likeId) async {
    final me = _myUid;
    if (me == null) throw LikeActionException('يجب تسجيل الدخول أولاً');

    final likeRef = _likes.doc(likeId);
    final likeSnap = await likeRef.get();
    if (!likeSnap.exists) return;

    final data = likeSnap.data()!;
    final toUserId = data['toUserId'] as String?;
    final status = statusFromString(data['status'] as String?);

    if (toUserId != me) {
      throw LikeActionException('لا يمكنك رفض دعوة ليست موجهة إليك');
    }
    if (status != LikeStatus.pending) return;

    await likeRef.update({
      'status': statusToString(LikeStatus.rejected),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  // ============================================================
  // 🔗 هل يوجد Match بيني وبين شخص معين؟ — بوابة الدردشة (البند 7)
  // ============================================================
  Future<bool> hasMatch(String otherUserId) async {
    final me = _myUid;
    if (me == null) return false;
    final doc = await _matches.doc(pairKey(me, otherUserId)).get();
    return doc.exists;
  }

  Stream<bool> hasMatchStream(String otherUserId) {
    final me = _myUid;
    if (me == null) return Stream.value(false);
    return _matches
        .doc(pairKey(me, otherUserId))
        .snapshots()
        .map((d) => d.exists);
  }

  // ============================================================
  // 💞 كل الـ UIDs التي عندي معها Match — لتغذية "المحادثات" — البند 8
  // ============================================================
  Stream<List<String>> myMatchedUserIdsStream() {
    final me = _myUid;
    if (me == null) return Stream.value(const []);
    return _matches.where('users', arrayContains: me).snapshots().map((
      snap,
    ) {
      return snap.docs
          .map((d) {
            final users =
                (d.data()['users'] as List<dynamic>?)?.cast<String>() ??
                    const <String>[];
            return users.firstWhere((u) => u != me, orElse: () => '');
          })
          .where((u) => u.isNotEmpty)
          .toList();
    });
  }
}
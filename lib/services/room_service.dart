import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/room_model.dart';

class RoomService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // ── Tạo phòng mới ─────────────────────────────
  Future<RoomModel> createRoom({
    required String headId,
    required String headName,
    required String headAvatarUrl,
    required String roomName,
    String? address,
    double? monthlyRent,
    int? rentDueDay,
  }) async {
    final joinCode = _generateJoinCode();
    final roomRef = _db.collection('rooms').doc();
    final now = DateTime.now();

    final room = RoomModel(
      roomId: roomRef.id,
      roomName: roomName,
      address: address,
      joinCode: joinCode,
      headId: headId,
      memberIds: [headId],
      monthlyRent: monthlyRent,
      rentDueDay: rentDueDay,
      createdAt: now,
    );

    final batch = _db.batch();

    // Tạo room doc
    batch.set(roomRef, room.toFirestore());

    // Thêm head vào subcollection members
    final memberRef = roomRef.collection('members').doc(headId);
    batch.set(
      memberRef,
      MemberModel(
        userId: headId,
        fullName: headName,
        avatarUrl: headAvatarUrl,
        role: 'head',
        joinedAt: now,
      ).toFirestore(),
    );

    // Cập nhật currentRoomId + role của head
    batch.update(_db.collection('users').doc(headId), {
      'currentRoomId': roomRef.id,
      'role': 'head',
    });

    await batch.commit();
    return room;
  }

  // ── Tham gia phòng bằng joinCode ──────────────
  Future<RoomModel> joinRoom({
    required String userId,
    required String userName,
    required String? avatarUrl,
    required String joinCode,
  }) async {
    // Tìm phòng theo joinCode
    final query = await _db
        .collection('rooms')
        .where('joinCode', isEqualTo: joinCode.toUpperCase())
        .where('isActive', isEqualTo: true)
        .limit(1)
        .get();

    if (query.docs.isEmpty) throw Exception('Mã phòng không hợp lệ');

    final roomDoc = query.docs.first;
    final room = RoomModel.fromFirestore(roomDoc);

    if (room.memberIds.contains(userId)) {
      throw Exception('Bạn đã là thành viên phòng này');
    }
    if (room.memberIds.length >= room.maxMembers) {
      throw Exception('Phòng đã đầy thành viên');
    }

    final now = DateTime.now();
    final batch = _db.batch();

    // Thêm userId vào memberIds
    batch.update(roomDoc.reference, {
      'memberIds': FieldValue.arrayUnion([userId]),
    });

    // Tạo member doc
    final memberRef = roomDoc.reference.collection('members').doc(userId);
    batch.set(
      memberRef,
      MemberModel(
        userId: userId,
        fullName: userName,
        avatarUrl: avatarUrl,
        role: 'member',
        joinedAt: now,
      ).toFirestore(),
    );

    // Cập nhật user
    batch.update(_db.collection('users').doc(userId), {
      'currentRoomId': room.roomId,
    });

    await batch.commit();
    return room;
  }

  // ── Lấy thông tin phòng (stream) ─────────────
  Stream<RoomModel?> roomStream(String roomId) {
    if (roomId.isEmpty) return Stream.value(null);
    return _db
        .collection('rooms')
        .doc(roomId)
        .snapshots()
        .map((doc) => doc.exists ? RoomModel.fromFirestore(doc) : null);
  }

  // ── Lấy danh sách thành viên (stream) ────────
  Stream<List<MemberModel>> membersStream(String roomId) {
    if (roomId.isEmpty) return Stream.value([]);
    return _db
        .collection('rooms')
        .doc(roomId)
        .collection('members')
        .where('isActive', isEqualTo: true)
        .snapshots()
        .map((snap) => snap.docs.map(MemberModel.fromFirestore).toList());
  }

  // ── Xoá thành viên ────────────────────────────
  Future<void> removeMember({
    required String roomId,
    required String userId,
  }) async {
    final batch = _db.batch();
    final roomRef = _db.collection('rooms').doc(roomId);

    batch.update(roomRef.collection('members').doc(userId), {
      'isActive': false,
      'removedAt': FieldValue.serverTimestamp(),
    });

    batch.update(roomRef, {
      'memberIds': FieldValue.arrayRemove([userId]),
    });

    batch.update(_db.collection('users').doc(userId), {
      'currentRoomId': FieldValue.delete(), // ✅ xoá field thay vì set null
      'role': 'member',
    });

    await batch.commit();
  }

  // ── Cập nhật thông tin phòng ──────────────────
  Future<void> updateRoom({
    required String roomId,
    String? roomName,
    String? address,
    double? monthlyRent,
    int? rentDueDay,
  }) async {
    final updates = <String, dynamic>{};
    if (roomName != null) updates['roomName'] = roomName;
    if (address != null) updates['address'] = address;
    if (monthlyRent != null) updates['monthlyRent'] = monthlyRent;
    if (rentDueDay != null) updates['rentDueDay'] = rentDueDay;
    await _db.collection('rooms').doc(roomId).update(updates);
  }

  // ── Thống kê nhanh cho Dashboard ─────────────
  Future<Map<String, dynamic>> getDashboardStats(String roomId) async {
    final now = DateTime.now();
    final startOfMonth = DateTime(now.year, now.month, 1);

    // Lấy chi tiêu tháng này
    final expenseSnap = await _db
        .collection('rooms')
        .doc(roomId)
        .collection('expenses')
        .where(
          'expenseDate',
          isGreaterThanOrEqualTo: Timestamp.fromDate(startOfMonth),
        )
        .get();

    double totalExpense = 0;
    for (final doc in expenseSnap.docs) {
      totalExpense += (doc.data()['totalAmount'] as num?)?.toDouble() ?? 0;
    }

    // Lấy tổng quỹ
    final fundSnap = await _db
        .collection('rooms')
        .doc(roomId)
        .collection('funds')
        .where('isActive', isEqualTo: true)
        .get();

    double totalFund = 0;
    int unpaidCount = 0;
    for (final doc in fundSnap.docs) {
      totalFund += (doc.data()['currentBalance'] as num?)?.toDouble() ?? 0;
      final memberStatus = Map<String, String>.from(
        doc.data()['memberStatus'] ?? {},
      );
      unpaidCount += memberStatus.values.where((s) => s == 'unpaid').length;
    }

    return {
      'totalExpenseThisMonth': totalExpense,
      'totalFundBalance': totalFund,
      'unpaidMemberCount': unpaidCount,
      'activeFundCount': fundSnap.docs.length,
    };
  }

  // ── Generate join code ─────────────────────────
  String _generateJoinCode() {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final rnd = Random.secure();
    return List.generate(6, (_) => chars[rnd.nextInt(chars.length)]).join();
  }

  // ── Rời phòng ─────────────────────────────────
  Future<void> leaveRoom({
    required String roomId,
    required String userId,
  }) async {
    final batch = _db.batch();
    final roomRef = _db.collection('rooms').doc(roomId);

    // Đánh dấu member không còn active
    batch.update(roomRef.collection('members').doc(userId), {
      'isActive': false,
      'removedAt': FieldValue.serverTimestamp(),
    });

    // Xoá userId khỏi danh sách memberIds của phòng
    batch.update(roomRef, {
      'memberIds': FieldValue.arrayRemove([userId]),
    });

    // Xoá currentRoomId trên user doc
    // ✅ Dùng FieldValue.delete() thay vì null
    // (Firestore không chấp nhận null trong update(), sẽ throw exception)
    batch.update(_db.collection('users').doc(userId), {
      'currentRoomId': FieldValue.delete(),
    });

    await batch.commit();
  }
}
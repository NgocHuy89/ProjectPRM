import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/notification_model.dart';

class NotificationService {
  final FirebaseFirestore _db;

  NotificationService({FirebaseFirestore? db}) : _db = db ?? FirebaseFirestore.instance;

  // Collection reference cho notifications
  // Có thể đặt notifications trong root hoặc sub-collection của users.
  // Ở đây chọn cách lưu root: /users/{userId}/notifications/{notificationId}
  CollectionReference _userNotifications(String userId) {
    return _db.collection('users').doc(userId).collection('notifications');
  }

  // Lắng nghe stream danh sách thông báo của user (real-time)
  Stream<List<NotificationModel>> getNotificationsStream(String userId) {
    return _userNotifications(userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => NotificationModel.fromFirestore(doc))
            .toList());
  }

  // Đếm số lượng thông báo chưa đọc
  Stream<int> getUnreadCountStream(String userId) {
    return _userNotifications(userId)
        .where('isRead', isEqualTo: false)
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }

  // Gửi một thông báo mới
  Future<void> sendNotification({
    required String userId,
    required String title,
    required String body,
    required String type,
    String? referenceId,
    String? roomId,
  }) async {
    final notif = NotificationModel(
      id: '',
      userId: userId,
      title: title,
      body: body,
      type: type,
      createdAt: DateTime.now(),
      referenceId: referenceId,
      roomId: roomId,
    );

    await _userNotifications(userId).add(notif.toMap());
  }

  // Đánh dấu 1 thông báo là đã đọc
  Future<void> markAsRead(String userId, String notificationId) async {
    await _userNotifications(userId).doc(notificationId).update({'isRead': true});
  }

  // Đánh dấu tất cả là đã đọc
  Future<void> markAllAsRead(String userId) async {
    final query = await _userNotifications(userId)
        .where('isRead', isEqualTo: false)
        .get();

    final batch = _db.batch();
    for (var doc in query.docs) {
      batch.update(doc.reference, {'isRead': true});
    }
    await batch.commit();
  }
}

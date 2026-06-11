import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../models/user_model.dart';

class UserService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  // ── Lấy thông tin user ────────────────────────
  Future<UserModel?> getUser(String uid) async {
    final doc = await _db.collection('users').doc(uid).get();
    return doc.exists ? UserModel.fromFirestore(doc) : null;
  }

  // ── Stream user realtime ──────────────────────
  Stream<UserModel?> userStream(String uid) {
    return _db.collection('users').doc(uid).snapshots().map(
          (doc) => doc.exists ? UserModel.fromFirestore(doc) : null,
        );
  }
  

  // ── Cập nhật profile ──────────────────────────
  Future<void> updateProfile({
    required String uid,
    String? fullName,
    String? phone,
    String? avatarUrl,
  }) async {
    final updates = <String, dynamic>{};
    if (fullName != null) updates['fullName'] = fullName;
    if (phone != null) updates['phone'] = phone;
    if (avatarUrl != null) updates['avatarUrl'] = avatarUrl;
    if (updates.isEmpty) return;
    await _db.collection('users').doc(uid).update(updates);
  }

  // ── Upload ảnh đại diện ───────────────────────
  Future<String> uploadAvatar({
    required String uid,
    required File imageFile,
  }) async {
    final ref = _storage.ref().child('avatars/$uid.jpg');
    await ref.putFile(
      imageFile,
      SettableMetadata(contentType: 'image/jpeg'),
    );
    final url = await ref.getDownloadURL();
    // Cập nhật luôn vào Firestore
    await _db.collection('users').doc(uid).update({'avatarUrl': url});
    return url;
  }

  // ── Cập nhật FCM token ────────────────────────
  Future<void> updateFcmToken(String uid, String token) async {
    await _db
        .collection('users')
        .doc(uid)
        .update({'fcmToken': token});
  }
}

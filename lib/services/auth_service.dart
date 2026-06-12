import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Stream trạng thái đăng nhập
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  User? get currentUser => _auth.currentUser;

  // ── Đăng ký ──────────────────────────────────
  Future<UserModel> register({
    required String fullName,
    required String email,
    required String password,
  }) async {
    try {
      debugPrint('📝 Bắt đầu tạo user: $email');
      final cred = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      debugPrint('✅ Firebase Auth tạo user thành công: ${cred.user!.uid}');

      final user = UserModel(
        uid: cred.user!.uid,
        fullName: fullName,
        email: email,
        role: 'member',
        createdAt: DateTime.now(),
      );

      try {
        debugPrint('💾 Lưu user data vào Firestore...');
        await _db.collection('users').doc(user.uid).set(user.toFirestore());
        debugPrint('✅ Firestore lưu user thành công');
      } catch (firestoreError) {
        debugPrint('❌ LỖI FIRESTORE: $firestoreError');
        debugPrint('⚠️ Xóa user từ Firebase Auth do lưu Firestore thất bại');
        // Xóa user từ Firebase Auth nếu Firestore thất bại
        await cred.user?.delete();
        rethrow;
      }

      await _auth.signOut();
      return user;
    } catch (e) {
      debugPrint('❌ Lỗi đăng ký: $e');
      rethrow;
    }
  }

  // ── Đăng nhập ─────────────────────────────────
  Future<UserModel> login({
    required String email,
    required String password,
  }) async {
    final cred = await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
    await _db.collection('users').doc(cred.user!.uid).update({
      'lastLoginAt': FieldValue.serverTimestamp(),
    });
    final doc = await _db.collection('users').doc(cred.user!.uid).get();
    return UserModel.fromFirestore(doc);
  }

  // ── Đăng xuất ─────────────────────────────────
  Future<void> logout() async => _auth.signOut();

  // ── Quên mật khẩu ────────────────────────────
  Future<void> sendPasswordResetEmail(String email) async {
    await _auth.setLanguageCode('vi');
    await _auth.sendPasswordResetEmail(email: email.trim());
  }

  // ── Lấy user hiện tại từ Firestore ───────────
  Future<UserModel?> getCurrentUserModel() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return null;
    final doc = await _db.collection('users').doc(uid).get();
    if (!doc.exists) return null;
    return UserModel.fromFirestore(doc);
  }

  // ── Stream user realtime ──────────────────────
  Stream<UserModel?> userStream(String uid) {
    return _db
        .collection('users')
        .doc(uid)
        .snapshots()
        .map((doc) => doc.exists ? UserModel.fromFirestore(doc) : null);
  }
}

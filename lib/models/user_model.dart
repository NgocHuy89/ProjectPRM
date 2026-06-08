import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String uid;
  final String fullName;
  final String email;
  final String? avatarUrl;
  final String? phone;
  final String? currentRoomId;
  final String role; // head | member
  final DateTime createdAt;
  final DateTime? lastLoginAt;
  final String? fcmToken;

  UserModel({
    required this.uid,
    required this.fullName,
    required this.email,
    this.avatarUrl,
    this.phone,
    this.currentRoomId,
    required this.role,
    required this.createdAt,
    this.lastLoginAt,
    this.fcmToken,
  });

  bool get isHead => role == 'head';
  bool get haRoom => currentRoomId != null;

  factory UserModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return UserModel(
      uid: doc.id,
      fullName: data['fullName'] ?? '',
      email: data['email'] ?? '',
      avatarUrl: data['avatarUrl'],
      phone: data['phone'],
      currentRoomId: data['currentRoomId'],
      role: data['role'] ?? 'member',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      lastLoginAt: (data['lastLoginAt'] as Timestamp?)?.toDate(),
      fcmToken: data['fcmToken'],
    );
  }

  Map<String, dynamic> toFirestore() => {
    'uid': uid,
    'fullName': fullName,
    'email': email,
    'avatarUrl': avatarUrl,
    'phone': phone,
    'currentRoomId': currentRoomId,
    'role': role,
    'createdAt': Timestamp.fromDate(createdAt),
    'lastLoginAt': lastLoginAt != null
        ? Timestamp.fromDate(lastLoginAt!)
        : FieldValue.serverTimestamp(),
    'fcmToken': fcmToken,
  };

  UserModel copyWith({
    String? fullName,
    String? avatarUrl,
    String? phone,
    String? currentRoomId,
    String? role,
    String? fcmToken,
  }) {
    return UserModel(
      uid: uid,
      fullName: fullName ?? this.fullName,
      email: email,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      phone: phone ?? this.phone,
      currentRoomId: currentRoomId ?? this.currentRoomId,
      role: role ?? this.role,
      createdAt: createdAt,
      lastLoginAt: lastLoginAt,
      fcmToken: fcmToken ?? this.fcmToken,
    );
  }
}

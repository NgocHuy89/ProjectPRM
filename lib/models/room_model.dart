import 'package:cloud_firestore/cloud_firestore.dart';

class RoomModel {
  final String roomId;
  final String roomName;
  final String? address;
  final String joinCode;
  final String headId;
  final List<String> memberIds;
  final int maxMembers;
  final double? monthlyRent;
  final int? rentDueDay;
  final DateTime createdAt;
  final bool isActive;

  RoomModel({
    required this.roomId,
    required this.roomName,
    this.address,
    required this.joinCode,
    required this.headId,
    required this.memberIds,
    this.maxMembers = 10,
    this.monthlyRent,
    this.rentDueDay,
    required this.createdAt,
    this.isActive = true,
  });

  int get memberCount => memberIds.length;

  factory RoomModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return RoomModel(
      roomId: doc.id,
      roomName: data['roomName'] ?? '',
      address: data['address'],
      joinCode: data['joinCode'] ?? '',
      headId: data['headId'] ?? '',
      memberIds: List<String>.from(data['memberIds'] ?? []),
      maxMembers: data['maxMembers'] ?? 10,
      monthlyRent: (data['monthlyRent'] as num?)?.toDouble(),
      rentDueDay: data['rentDueDay'],
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      isActive: data['isActive'] ?? true,
    );
  }

  Map<String, dynamic> toFirestore() => {
        'roomName': roomName,
        'address': address,
        'joinCode': joinCode,
        'headId': headId,
        'memberIds': memberIds,
        'maxMembers': maxMembers,
        'monthlyRent': monthlyRent,
        'rentDueDay': rentDueDay,
        'createdAt': Timestamp.fromDate(createdAt),
        'isActive': isActive,
      };
}

class MemberModel {
  final String userId;
  final String fullName;
  final String? avatarUrl;
  final String role;
  final DateTime joinedAt;
  final double totalContributed;
  final double totalOwed;
  final bool isActive;

  MemberModel({
    required this.userId,
    required this.fullName,
    this.avatarUrl,
    required this.role,
    required this.joinedAt,
    this.totalContributed = 0,
    this.totalOwed = 0,
    this.isActive = true,
  });

  bool get isHead => role == 'head';
  double get balance => totalContributed - totalOwed;

  factory MemberModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return MemberModel(
      userId: doc.id,
      fullName: data['fullName'] ?? '',
      avatarUrl: data['avatarUrl'],
      role: data['role'] ?? 'member',
      joinedAt: (data['joinedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      totalContributed: (data['totalContributed'] as num?)?.toDouble() ?? 0,
      totalOwed: (data['totalOwed'] as num?)?.toDouble() ?? 0,
      isActive: data['isActive'] ?? true,
    );
  }

  Map<String, dynamic> toFirestore() => {
        'userId': userId,
        'fullName': fullName,
        'avatarUrl': avatarUrl,
        'role': role,
        'joinedAt': Timestamp.fromDate(joinedAt),
        'totalContributed': totalContributed,
        'totalOwed': totalOwed,
        'isActive': isActive,
      };
}

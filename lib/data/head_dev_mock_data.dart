import '../models/finance_models.dart';
import '../models/room_model.dart';

/// Dữ liệu demo cho Head Dashboard (tài khoản fix cứng dev-uid-001).
class HeadDevMockData {
  HeadDevMockData._();

  static const devUid = 'dev-uid-001';

  static final room = RoomModel(
    roomId: 'dev-room-001',
    roomName: 'Phòng 402 - KTX ĐHQG',
    address: 'Khu B, KTX ĐHQG-HCM, Linh Trung, TP.HCM',
    joinCode: 'RF4K2X',
    headId: devUid,
    memberIds: [devUid, 'dev-m002', 'dev-m003', 'dev-m004'],
    maxMembers: 6,
    monthlyRent: 4500000,
    rentDueDay: 5,
    createdAt: DateTime(2024, 9, 1),
  );

  static final members = [
    MemberModel(
      userId: devUid,
      fullName: 'Huy Nguyen',
      role: 'head',
      joinedAt: DateTime(2024, 9, 1),
      totalContributed: 8500000,
      totalOwed: 0,
    ),
    MemberModel(
      userId: 'dev-m002',
      fullName: 'Minh Trần',
      role: 'member',
      joinedAt: DateTime(2024, 9, 5),
      totalContributed: 6200000,
      totalOwed: 450000,
    ),
    MemberModel(
      userId: 'dev-m003',
      fullName: 'Lan Phạm',
      role: 'member',
      joinedAt: DateTime(2024, 9, 8),
      totalContributed: 5800000,
      totalOwed: 320000,
    ),
    MemberModel(
      userId: 'dev-m004',
      fullName: 'Tuấn Lê',
      role: 'member',
      joinedAt: DateTime(2024, 10, 1),
      totalContributed: 2100000,
      totalOwed: 780000,
    ),
  ];

  static const stats = {
    'totalExpenseThisMonth': 3250000.0,
    'totalFundBalance': 12800000.0,
    'unpaidMemberCount': 2,
    'activeFundCount': 3,
  };

  static final funds = [
    FundModel(
      fundId: 'fund-001',
      name: 'Quỹ tiền thuê tháng 6',
      description: 'Tiền thuê phòng tháng 6/2026',
      targetAmount: 18000000,
      currentBalance: 12800000,
      contributionPerMember: 4500000,
      dueDate: DateTime(2026, 6, 5),
      createdBy: devUid,
      createdAt: DateTime(2026, 5, 20),
      memberStatus: {
        devUid: 'paid',
        'dev-m002': 'paid',
        'dev-m003': 'unpaid',
        'dev-m004': 'unpaid',
      },
    ),
    FundModel(
      fundId: 'fund-002',
      name: 'Quỹ điện nước T5',
      description: 'Hóa đơn điện nước tháng 5',
      targetAmount: 3200000,
      currentBalance: 3200000,
      contributionPerMember: 800000,
      dueDate: DateTime(2026, 5, 15),
      createdBy: devUid,
      createdAt: DateTime(2026, 5, 1),
      memberStatus: {
        devUid: 'paid',
        'dev-m002': 'paid',
        'dev-m003': 'paid',
        'dev-m004': 'paid',
      },
    ),
    FundModel(
      fundId: 'fund-003',
      name: 'Quỹ đồ dùng chung',
      description: 'Nước rửa chén, giấy vệ sinh, dụng cụ bếp',
      targetAmount: 1500000,
      currentBalance: 900000,
      contributionPerMember: 375000,
      dueDate: DateTime(2026, 6, 20),
      createdBy: devUid,
      createdAt: DateTime(2026, 5, 25),
      memberStatus: {
        devUid: 'paid',
        'dev-m002': 'partial',
        'dev-m003': 'unpaid',
        'dev-m004': 'unpaid',
      },
    ),
  ];

  static final expenses = [
    ExpenseModel(
      expenseId: 'exp-001',
      title: 'Tiền điện tháng 5',
      category: 'electricity',
      totalAmount: 850000,
      paidBy: devUid,
      paidByName: 'Huy Nguyen',
      expenseDate: DateTime(2026, 5, 28),
      createdAt: DateTime(2026, 5, 28),
      createdBy: devUid,
    ),
    ExpenseModel(
      expenseId: 'exp-002',
      title: 'Tiền nước tháng 5',
      category: 'water',
      totalAmount: 420000,
      paidBy: 'dev-m002',
      paidByName: 'Minh Trần',
      expenseDate: DateTime(2026, 5, 26),
      createdAt: DateTime(2026, 5, 26),
      createdBy: devUid,
    ),
    ExpenseModel(
      expenseId: 'exp-003',
      title: 'Cước Internet FPT',
      category: 'internet',
      totalAmount: 600000,
      paidBy: devUid,
      paidByName: 'Huy Nguyen',
      expenseDate: DateTime(2026, 5, 20),
      createdAt: DateTime(2026, 5, 20),
      createdBy: devUid,
    ),
    ExpenseModel(
      expenseId: 'exp-004',
      title: 'Đồ dùng vệ sinh chung',
      category: 'supplies',
      totalAmount: 380000,
      paidBy: 'dev-m003',
      paidByName: 'Lan Phạm',
      expenseDate: DateTime(2026, 5, 15),
      createdAt: DateTime(2026, 5, 15),
      createdBy: devUid,
    ),
    ExpenseModel(
      expenseId: 'exp-005',
      title: 'Sửa quạt trần phòng',
      category: 'other',
      totalAmount: 1000000,
      paidBy: 'dev-m004',
      paidByName: 'Tuấn Lê',
      expenseDate: DateTime(2026, 5, 10),
      createdAt: DateTime(2026, 5, 10),
      createdBy: devUid,
    ),
  ];

  static const monthlyReport = {
    'totalExpense': 3250000.0,
    'totalIncome': 4800000.0,
    'balance': 1550000.0,
    'byCategory': {
      'electricity': 850000.0,
      'water': 420000.0,
      'internet': 600000.0,
      'supplies': 380000.0,
      'other': 1000000.0,
    },
    'topCategory': 'electricity',
    'expenseCount': 8,
  };
}

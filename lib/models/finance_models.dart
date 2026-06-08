import 'package:cloud_firestore/cloud_firestore.dart';

// ─── Fund ────────────────────────────────────────────────
class FundModel {
  final String fundId;
  final String name;
  final String? description;
  final double? targetAmount;
  final double currentBalance;
  final double? contributionPerMember;
  final DateTime? dueDate;
  final String createdBy;
  final DateTime createdAt;
  final bool isActive;
  final Map<String, String> memberStatus; // userId -> paid|unpaid|partial

  FundModel({
    required this.fundId,
    required this.name,
    this.description,
    this.targetAmount,
    this.currentBalance = 0,
    this.contributionPerMember,
    this.dueDate,
    required this.createdBy,
    required this.createdAt,
    this.isActive = true,
    this.memberStatus = const {},
  });

  double get progressPercent =>
      targetAmount != null && targetAmount! > 0
          ? (currentBalance / targetAmount!).clamp(0.0, 1.0)
          : 0;

  factory FundModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return FundModel(
      fundId: doc.id,
      name: data['name'] ?? '',
      description: data['description'],
      targetAmount: (data['targetAmount'] as num?)?.toDouble(),
      currentBalance: (data['currentBalance'] as num?)?.toDouble() ?? 0,
      contributionPerMember:
          (data['contributionPerMember'] as num?)?.toDouble(),
      dueDate: (data['dueDate'] as Timestamp?)?.toDate(),
      createdBy: data['createdBy'] ?? '',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      isActive: data['isActive'] ?? true,
      memberStatus:
          Map<String, String>.from(data['memberStatus'] ?? {}),
    );
  }

  Map<String, dynamic> toFirestore() => {
        'name': name,
        'description': description,
        'targetAmount': targetAmount,
        'currentBalance': currentBalance,
        'contributionPerMember': contributionPerMember,
        'dueDate': dueDate != null ? Timestamp.fromDate(dueDate!) : null,
        'createdBy': createdBy,
        'createdAt': Timestamp.fromDate(createdAt),
        'isActive': isActive,
        'memberStatus': memberStatus,
      };
}

// ─── Contribution ────────────────────────────────────────
class ContributionModel {
  final String contributionId;
  final String fundId;
  final String userId;
  final String userName;
  final double amount;
  final String? note;
  final String? proofImageUrl;
  final DateTime contributedAt;
  final String? confirmedBy;
  final String status; // pending | confirmed | rejected

  ContributionModel({
    required this.contributionId,
    required this.fundId,
    required this.userId,
    required this.userName,
    required this.amount,
    this.note,
    this.proofImageUrl,
    required this.contributedAt,
    this.confirmedBy,
    this.status = 'pending',
  });

  factory ContributionModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ContributionModel(
      contributionId: doc.id,
      fundId: data['fundId'] ?? '',
      userId: data['userId'] ?? '',
      userName: data['userName'] ?? '',
      amount: (data['amount'] as num?)?.toDouble() ?? 0,
      note: data['note'],
      proofImageUrl: data['proofImageUrl'],
      contributedAt:
          (data['contributedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      confirmedBy: data['confirmedBy'],
      status: data['status'] ?? 'pending',
    );
  }

  Map<String, dynamic> toFirestore() => {
        'fundId': fundId,
        'userId': userId,
        'userName': userName,
        'amount': amount,
        'note': note,
        'proofImageUrl': proofImageUrl,
        'contributedAt': Timestamp.fromDate(contributedAt),
        'confirmedBy': confirmedBy,
        'status': status,
      };
}

// ─── Expense ─────────────────────────────────────────────
class ExpenseModel {
  final String expenseId;
  final String title;
  final String category; // electricity|water|internet|supplies|other
  final double totalAmount;
  final String paidBy;
  final String paidByName;
  final String splitType; // equal|custom|single
  final Map<String, double>? splitAmounts;
  final String? fundId;
  final String? receiptImageUrl;
  final String? note;
  final DateTime expenseDate;
  final DateTime createdAt;
  final String createdBy;
  final bool isPersonalNote;
  final Map<String, bool> settledStatus;

  ExpenseModel({
    required this.expenseId,
    required this.title,
    required this.category,
    required this.totalAmount,
    required this.paidBy,
    required this.paidByName,
    this.splitType = 'equal',
    this.splitAmounts,
    this.fundId,
    this.receiptImageUrl,
    this.note,
    required this.expenseDate,
    required this.createdAt,
    required this.createdBy,
    this.isPersonalNote = false,
    this.settledStatus = const {},
  });

  factory ExpenseModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ExpenseModel(
      expenseId: doc.id,
      title: data['title'] ?? '',
      category: data['category'] ?? 'other',
      totalAmount: (data['totalAmount'] as num?)?.toDouble() ?? 0,
      paidBy: data['paidBy'] ?? '',
      paidByName: data['paidByName'] ?? '',
      splitType: data['splitType'] ?? 'equal',
      splitAmounts: data['splitAmounts'] != null
          ? Map<String, double>.from(
              (data['splitAmounts'] as Map).map(
                  (k, v) => MapEntry(k.toString(), (v as num).toDouble())))
          : null,
      fundId: data['fundId'],
      receiptImageUrl: data['receiptImageUrl'],
      note: data['note'],
      expenseDate:
          (data['expenseDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
      createdAt:
          (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      createdBy: data['createdBy'] ?? '',
      isPersonalNote: data['isPersonalNote'] ?? false,
      settledStatus:
          Map<String, bool>.from(data['settledStatus'] ?? {}),
    );
  }

  Map<String, dynamic> toFirestore() => {
        'title': title,
        'category': category,
        'totalAmount': totalAmount,
        'paidBy': paidBy,
        'paidByName': paidByName,
        'splitType': splitType,
        'splitAmounts': splitAmounts,
        'fundId': fundId,
        'receiptImageUrl': receiptImageUrl,
        'note': note,
        'expenseDate': Timestamp.fromDate(expenseDate),
        'createdAt': Timestamp.fromDate(createdAt),
        'createdBy': createdBy,
        'isPersonalNote': isPersonalNote,
        'settledStatus': settledStatus,
      };
}

// ─── Report ──────────────────────────────────────────────
class ReportModel {
  final String month; // YYYY-MM
  final double totalIncome;
  final double totalExpense;
  final double balance;
  final String? topCategory;
  final Map<String, dynamic> memberSummary;
  final Map<String, double> expenseByCategory;
  final DateTime generatedAt;

  ReportModel({
    required this.month,
    required this.totalIncome,
    required this.totalExpense,
    required this.balance,
    this.topCategory,
    required this.memberSummary,
    required this.expenseByCategory,
    required this.generatedAt,
  });

  factory ReportModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ReportModel(
      month: data['month'] ?? '',
      totalIncome: (data['totalIncome'] as num?)?.toDouble() ?? 0,
      totalExpense: (data['totalExpense'] as num?)?.toDouble() ?? 0,
      balance: (data['balance'] as num?)?.toDouble() ?? 0,
      topCategory: data['topCategory'],
      memberSummary:
          Map<String, dynamic>.from(data['memberSummary'] ?? {}),
      expenseByCategory: data['expenseByCategory'] != null
          ? Map<String, double>.from(
              (data['expenseByCategory'] as Map).map(
                  (k, v) => MapEntry(k.toString(), (v as num).toDouble())))
          : {},
      generatedAt:
          (data['generatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }
}

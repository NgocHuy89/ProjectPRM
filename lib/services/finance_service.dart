import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/finance_models.dart';

class FinanceService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // ════════════════════════════════════════
  // FUND
  // ════════════════════════════════════════

  /// Stream danh sách quỹ của phòng
  Stream<List<FundModel>> fundsStream(String roomId) {
    return _db
        .collection('rooms')
        .doc(roomId)
        .collection('funds')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map(FundModel.fromFirestore).toList());
  }

  /// Tạo quỹ mới
  Future<FundModel> createFund({
    required String roomId,
    required String name,
    String? description,
    double? targetAmount,
    double? contributionPerMember,
    DateTime? dueDate,
    required String createdBy,
    required List<String> memberIds,
  }) async {
    final ref = _db.collection('rooms').doc(roomId).collection('funds').doc();

    // Khởi tạo memberStatus: tất cả unpaid
    final memberStatus = {for (final id in memberIds) id: 'unpaid'};

    final fund = FundModel(
      fundId: ref.id,
      name: name,
      description: description,
      targetAmount: targetAmount,
      currentBalance: 0,
      contributionPerMember: contributionPerMember,
      dueDate: dueDate,
      createdBy: createdBy,
      createdAt: DateTime.now(),
      isActive: true,
      memberStatus: memberStatus,
    );

    await ref.set(fund.toFirestore());
    return fund;
  }

  /// Cập nhật thông tin quỹ
  Future<void> updateFund({
    required String roomId,
    required String fundId,
    String? name,
    String? description,
    double? targetAmount,
    double? contributionPerMember,
    DateTime? dueDate,
    bool? isActive,
  }) async {
    final updates = <String, dynamic>{};
    if (name != null) updates['name'] = name;
    if (description != null) updates['description'] = description;
    if (targetAmount != null) updates['targetAmount'] = targetAmount;
    if (contributionPerMember != null) {
      updates['contributionPerMember'] = contributionPerMember;
    }
    if (dueDate != null) updates['dueDate'] = Timestamp.fromDate(dueDate);
    if (isActive != null) updates['isActive'] = isActive;

    await _db
        .collection('rooms')
        .doc(roomId)
        .collection('funds')
        .doc(fundId)
        .update(updates);
  }

  // ════════════════════════════════════════
  // CONTRIBUTION
  // ════════════════════════════════════════

  /// Stream lịch sử đóng quỹ
  Stream<List<ContributionModel>> contributionsStream({
    required String roomId,
    required String fundId,
  }) {
    return _db
        .collection('rooms')
        .doc(roomId)
        .collection('funds')
        .doc(fundId)
        .collection('contributions')
        .orderBy('contributedAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map(ContributionModel.fromFirestore).toList());
  }

  /// Stream tất cả contribution của phòng (cho member summary)
  Stream<List<ContributionModel>> allContributionsStream(String roomId) {
    return _db
        .collectionGroup('contributions')
        .where('roomId', isEqualTo: roomId)
        .orderBy('contributedAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map(ContributionModel.fromFirestore).toList());
  }

  /// Thành viên đóng tiền vào quỹ
  Future<void> addContribution({
    required String roomId,
    required String fundId,
    required String userId,
    required String userName,
    required double amount,
    String? note,
    String? proofImageUrl,
  }) async {
    final batch = _db.batch();
    final fundRef = _db
        .collection('rooms')
        .doc(roomId)
        .collection('funds')
        .doc(fundId);

    final contribRef = fundRef.collection('contributions').doc();

    final contribution = ContributionModel(
      contributionId: contribRef.id,
      fundId: fundId,
      userId: userId,
      userName: userName,
      amount: amount,
      note: note,
      proofImageUrl: proofImageUrl,
      contributedAt: DateTime.now(),
      status: 'confirmed', // Tự động xác nhận
    );

    // Lưu contribution
    batch.set(contribRef, {
      ...contribution.toFirestore(),
      'roomId': roomId, // Cho collectionGroup query
    });

    // Cập nhật currentBalance và memberStatus
    batch.update(fundRef, {
      'currentBalance': FieldValue.increment(amount),
      'memberStatus.$userId': 'paid',
    });

    // Cập nhật totalContributed của member
    batch.update(
      _db.collection('rooms').doc(roomId).collection('members').doc(userId),
      {'totalContributed': FieldValue.increment(amount)},
    );

    await batch.commit();
  }

  // ════════════════════════════════════════
  // EXPENSE
  // ════════════════════════════════════════

  /// Stream danh sách chi tiêu
  Stream<List<ExpenseModel>> expensesStream(String roomId) {
    return _db
        .collection('rooms')
        .doc(roomId)
        .collection('expenses')
        .orderBy('expenseDate', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map(ExpenseModel.fromFirestore).toList());
  }

  /// Stream chi tiêu theo tháng (cho reports)
  Stream<List<ExpenseModel>> expensesByMonthStream({
    required String roomId,
    required int year,
    required int month,
  }) {
    final start = DateTime(year, month, 1);
    final end = DateTime(year, month + 1, 1);
    return _db
        .collection('rooms')
        .doc(roomId)
        .collection('expenses')
        .where('expenseDate', isGreaterThanOrEqualTo: Timestamp.fromDate(start))
        .where('expenseDate', isLessThan: Timestamp.fromDate(end))
        .orderBy('expenseDate', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map(ExpenseModel.fromFirestore).toList());
  }

  /// Thêm chi tiêu mới
  Future<ExpenseModel> addExpense({
    required String roomId,
    required String title,
    required String category,
    required double totalAmount,
    required String paidBy,
    required String paidByName,
    String splitType = 'equal',
    Map<String, double>? splitAmounts,
    String? fundId,
    String? note,
    String? receiptImageUrl,
    required DateTime expenseDate,
    required String createdBy,
    bool isPersonalNote = false,
    required List<String> memberIds,
  }) async {
    final ref = _db
        .collection('rooms')
        .doc(roomId)
        .collection('expenses')
        .doc();

    // Khởi tạo settledStatus: paidBy đã settled
    final settledStatus = {for (final id in memberIds) id: id == paidBy};

    final expense = ExpenseModel(
      expenseId: ref.id,
      title: title,
      category: category,
      totalAmount: totalAmount,
      paidBy: paidBy,
      paidByName: paidByName,
      splitType: splitType,
      splitAmounts: splitAmounts,
      fundId: fundId,
      receiptImageUrl: receiptImageUrl,
      note: note,
      expenseDate: expenseDate,
      createdAt: DateTime.now(),
      createdBy: createdBy,
      isPersonalNote: isPersonalNote,
      settledStatus: settledStatus,
    );

    final batch = _db.batch();
    batch.set(ref, expense.toFirestore());

    // Cập nhật totalOwed cho tất cả member (trừ người trả)
    if (splitType == 'equal' && memberIds.isNotEmpty) {
      final perPerson = totalAmount / memberIds.length;
      for (final uid in memberIds) {
        if (uid != paidBy) {
          batch.update(
            _db
                .collection('rooms')
                .doc(roomId)
                .collection('members')
                .doc(uid),
            {'totalOwed': FieldValue.increment(perPerson)},
          );
        }
      }
    }

    await batch.commit();
    return expense;
  }

  /// Đánh dấu member đã thanh toán phần của mình
  Future<void> markSettled({
    required String roomId,
    required String expenseId,
    required String userId,
  }) async {
    await _db
        .collection('rooms')
        .doc(roomId)
        .collection('expenses')
        .doc(expenseId)
        .update({'settledStatus.$userId': true});
  }

  // ════════════════════════════════════════
  // REPORTS – tổng hợp dữ liệu tháng
  // ════════════════════════════════════════

  Future<Map<String, dynamic>> getMonthlyReport({
    required String roomId,
    required int year,
    required int month,
  }) async {
    final start = DateTime(year, month, 1);
    final end = DateTime(year, month + 1, 1);

    // Chi tiêu tháng
    final expSnap = await _db
        .collection('rooms')
        .doc(roomId)
        .collection('expenses')
        .where('expenseDate', isGreaterThanOrEqualTo: Timestamp.fromDate(start))
        .where('expenseDate', isLessThan: Timestamp.fromDate(end))
        .get();

    double totalExpense = 0;
    final Map<String, double> byCategory = {};
    for (final doc in expSnap.docs) {
      final data = doc.data();
      final amount = (data['totalAmount'] as num?)?.toDouble() ?? 0;
      final cat = data['category'] as String? ?? 'other';
      totalExpense += amount;
      byCategory[cat] = (byCategory[cat] ?? 0) + amount;
    }

    // Top category
    String? topCat;
    double topAmt = 0;
    byCategory.forEach((cat, amt) {
      if (amt > topAmt) {
        topAmt = amt;
        topCat = cat;
      }
    });

    // Contribution tháng
    double totalIncome = 0;
    final fundSnap = await _db
        .collection('rooms')
        .doc(roomId)
        .collection('funds')
        .get();

    for (final fundDoc in fundSnap.docs) {
      final contribSnap = await fundDoc.reference
          .collection('contributions')
          .where(
            'contributedAt',
            isGreaterThanOrEqualTo: Timestamp.fromDate(start),
          )
          .where('contributedAt', isLessThan: Timestamp.fromDate(end))
          .get();
      for (final c in contribSnap.docs) {
        totalIncome +=
            (c.data()['amount'] as num?)?.toDouble() ?? 0;
      }
    }

    return {
      'totalExpense': totalExpense,
      'totalIncome': totalIncome,
      'balance': totalIncome - totalExpense,
      'byCategory': byCategory,
      'topCategory': topCat,
      'expenseCount': expSnap.docs.length,
    };
  }
}

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../models/finance_models.dart';
import 'notification_service.dart';

class FinanceService {
  final FirebaseFirestore _db;

  FinanceService({FirebaseFirestore? db}) : _db = db ?? FirebaseFirestore.instance;

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

    // Send notifications to all members except creator
    final notifService = NotificationService(db: _db);
    for (final id in memberIds) {
      if (id != createdBy) {
        notifService.sendNotification(
          userId: id,
          title: 'Quỹ mới được tạo',
          body: 'Quỹ "$name" vừa được tạo. Vui lòng đóng quỹ.',
          type: 'fund',
          referenceId: ref.id,
          roomId: roomId,
        );
      }
    }

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

  /// Xoá quỹ (Chỉ được phép nếu chưa có thành viên nào đóng)
  Future<void> deleteFund({
    required String roomId,
    required String fundId,
  }) async {
    final fundRef = _db.collection('rooms').doc(roomId).collection('funds').doc(fundId);
    final fundSnap = await fundRef.get();
    
    if (!fundSnap.exists) {
      throw Exception('Quỹ không tồn tại');
    }

    final data = fundSnap.data()!;
    final memberStatus = data['memberStatus'] as Map<String, dynamic>? ?? {};
    
    // Kiểm tra xem đã có ai đóng tiền chưa
    final hasPaidMembers = memberStatus.values.any((status) => status == 'paid');
    
    if (hasPaidMembers) {
      throw Exception('Không thể xoá quỹ này vì đã có thành viên đóng tiền. Vui lòng kiểm tra lại!');
    }

    // Xoá quỹ
    await fundRef.delete();
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

    // Lấy thông tin phòng để lấy headId
    final roomDoc = await _db.collection('rooms').doc(roomId).get();
    final headId = roomDoc.data()?['headId'];

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
      status: 'pending', // Chờ duyệt
    );

    // Lưu contribution
    batch.set(contribRef, {
      ...contribution.toFirestore(),
      'roomId': roomId, // Cho collectionGroup query
    });

    await batch.commit();

    // Gửi thông báo cho chủ phòng
    if (headId != null) {
      final notifService = NotificationService(db: _db);
      final formattedAmount = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ').format(amount);
      await notifService.sendNotification(
        userId: headId,
        title: 'Yêu cầu đóng quỹ',
        body: '$userName đã đóng $formattedAmount. Vui lòng xác nhận.',
        type: 'contribution_request',
        referenceId: '$roomId|$fundId|${contribRef.id}',
        roomId: roomId,
      );
    }
  }

  /// Thành viên huỷ yêu cầu đóng tiền đang chờ duyệt
  Future<void> deletePendingContribution({
    required String roomId,
    required String fundId,
    required String contributionId,
  }) async {
    final contribRef = _db
        .collection('rooms')
        .doc(roomId)
        .collection('funds')
        .doc(fundId)
        .collection('contributions')
        .doc(contributionId);
    
    final doc = await contribRef.get();
    if (doc.exists && doc.data()?['status'] == 'pending') {
      await contribRef.delete();
    }
  }

  /// Chủ phòng duyệt đóng tiền
  Future<void> approveContribution({
    required String roomId,
    required String fundId,
    required String contributionId,
    required String headId,
  }) async {
    final contribRef = _db.collection('rooms').doc(roomId).collection('funds').doc(fundId).collection('contributions').doc(contributionId);
    final contribDoc = await contribRef.get();
    if (!contribDoc.exists) {
      throw Exception('Yêu cầu đã bị người dùng huỷ hoặc không tồn tại.');
    }

    final data = contribDoc.data()!;
    if (data['status'] != 'pending') {
      throw Exception('Yêu cầu này đã được xử lý.');
    }

    final amount = (data['amount'] as num).toDouble();
    final userId = data['userId'];

    final batch = _db.batch();
    
    batch.update(contribRef, {
      'status': 'confirmed',
      'confirmedBy': headId,
    });

    final fundRef = _db.collection('rooms').doc(roomId).collection('funds').doc(fundId);
    batch.update(fundRef, {
      'currentBalance': FieldValue.increment(amount),
      'memberStatus.$userId': 'paid',
    });

    batch.update(
      _db.collection('rooms').doc(roomId).collection('members').doc(userId),
      {'totalContributed': FieldValue.increment(amount)},
    );

    await batch.commit();

    final notifService = NotificationService(db: _db);
    final formattedAmount = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ').format(amount);
    await notifService.sendNotification(
      userId: userId,
      title: 'Đóng quỹ thành công',
      body: 'Khoản đóng $formattedAmount của bạn đã được chủ phòng xác nhận.',
      type: 'contribution_approved',
      referenceId: fundId,
      roomId: roomId,
    );
  }

  /// Chủ phòng từ chối đóng tiền
  Future<void> rejectContribution({
    required String roomId,
    required String fundId,
    required String contributionId,
    required String headId,
  }) async {
    final contribRef = _db.collection('rooms').doc(roomId).collection('funds').doc(fundId).collection('contributions').doc(contributionId);
    final contribDoc = await contribRef.get();
    if (!contribDoc.exists) {
      throw Exception('Yêu cầu đã bị người dùng huỷ hoặc không tồn tại.');
    }

    final data = contribDoc.data()!;
    if (data['status'] != 'pending') {
      throw Exception('Yêu cầu này đã được xử lý.');
    }

    final amount = (data['amount'] as num).toDouble();
    final userId = data['userId'];

    await contribRef.update({
      'status': 'rejected',
      'confirmedBy': headId,
    });

    final notifService = NotificationService(db: _db);
    final formattedAmount = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ').format(amount);
    await notifService.sendNotification(
      userId: userId,
      title: 'Đóng quỹ thất bại',
      body: 'Khoản đóng $formattedAmount của bạn đã bị từ chối.',
      type: 'contribution_rejected',
      referenceId: fundId,
      roomId: roomId,
    );
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

    final bool isFromFund = fundId != null && fundId.isNotEmpty;

    // Khởi tạo settledStatus: nếu chi từ quỹ thì tất cả coi như đã thanh toán
    final settledStatus = {for (final id in memberIds) id: isFromFund ? true : id == paidBy};

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

    if (isFromFund) {
      batch.update(
        _db.collection('rooms').doc(roomId).collection('funds').doc(fundId),
        {'currentBalance': FieldValue.increment(-totalAmount)},
      );
      if (isPersonalNote) {
        batch.update(
          _db.collection('rooms').doc(roomId).collection('members').doc(paidBy),
          {'fundDebt': FieldValue.increment(totalAmount)},
        );
      }
    }

    // Cập nhật totalOwed cho tất cả member (trừ người trả)
    // FIX BUG: Nếu chi từ quỹ thì không tính nợ cá nhân nữa
    if (!isFromFund && splitType == 'equal' && memberIds.isNotEmpty) {
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

    // Send notifications to all members except creator
    final notifService = NotificationService(db: _db);
    for (final id in memberIds) {
      if (id != createdBy) {
        notifService.sendNotification(
          userId: id,
          title: 'Khoản chi mới',
          body: '$paidByName vừa thêm khoản chi: $title',
          type: 'expense',
          referenceId: ref.id,
          roomId: roomId,
        );
      }
    }

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

  /// Trả nợ cá nhân cho quỹ
  Future<void> payFundDebt({
    required String roomId,
    required String fundId,
    required String userId,
  }) async {
    final batch = _db.batch();
    final memberRef = _db.collection('rooms').doc(roomId).collection('members').doc(userId);
    final memberSnap = await memberRef.get();
    final currentDebt =
        (memberSnap.data()?['fundDebt'] as num?)?.toDouble() ?? 0;
    
    final expensesSnap = await _db
        .collection('rooms')
        .doc(roomId)
        .collection('expenses')
        .where('fundId', isEqualTo: fundId)
        .get();

    double totalPaid = 0;
    for (var doc in expensesSnap.docs) {
      final data = doc.data();
      if (data['isPersonalNote'] == true &&
          data['paidBy'] == userId &&
          data['isDebtPaid'] != true) {
        totalPaid += (data['totalAmount'] as num?)?.toDouble() ?? 0;
        batch.update(doc.reference, {'isDebtPaid': true});
      }
    }

    if (totalPaid > 0) {
      final remainingDebt =
          (currentDebt - totalPaid).clamp(0.0, double.infinity).toDouble();
      batch.update(
        _db.collection('rooms').doc(roomId).collection('funds').doc(fundId),
        {'currentBalance': FieldValue.increment(totalPaid)},
      );
      batch.update(memberRef, {
        'fundDebt': remainingDebt,
      });
    }

    await batch.commit();
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

  // ════════════════════════════════════════
  // PERSONAL EXPENSE
  // ════════════════════════════════════════

  /// Lấy danh sách chi tiêu cá nhân
  Stream<List<PersonalExpenseModel>> personalExpensesStream(String userId) {
    return _db
        .collection('users')
        .doc(userId)
        .collection('personal_expenses')
        .orderBy('expenseDate', descending: true)
        .snapshots()
        .map((snap) =>
            snap.docs.map(PersonalExpenseModel.fromFirestore).toList());
  }

  /// Lấy danh sách chi tiêu cá nhân theo tháng
  Stream<List<PersonalExpenseModel>> personalExpensesByMonthStream({
    required String userId,
    required int year,
    required int month,
  }) {
    final start = DateTime(year, month, 1);
    final end = DateTime(year, month + 1, 1);
    return _db
        .collection('users')
        .doc(userId)
        .collection('personal_expenses')
        .where('expenseDate', isGreaterThanOrEqualTo: Timestamp.fromDate(start))
        .where('expenseDate', isLessThan: Timestamp.fromDate(end))
        .orderBy('expenseDate', descending: true)
        .snapshots()
        .map((snap) =>
            snap.docs.map(PersonalExpenseModel.fromFirestore).toList());
  }

  /// Thêm chi tiêu cá nhân
  Future<void> addPersonalExpense({
    required String userId,
    required String title,
    required String category,
    required double amount,
    required DateTime expenseDate,
    String? note,
  }) async {
    final ref = _db
        .collection('users')
        .doc(userId)
        .collection('personal_expenses')
        .doc();

    final expense = PersonalExpenseModel(
      expenseId: ref.id,
      userId: userId,
      title: title,
      category: category,
      amount: amount,
      expenseDate: expenseDate,
      note: note,
      createdAt: DateTime.now(),
    );

    await ref.set(expense.toFirestore());
  }

  /// Xoá chi tiêu cá nhân
  Future<void> deletePersonalExpense({
    required String userId,
    required String expenseId,
  }) async {
    await _db
        .collection('users')
        .doc(userId)
        .collection('personal_expenses')
        .doc(expenseId)
        .delete();
  }
}

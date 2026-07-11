import 'package:flutter_test/flutter_test.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:room_finance_app/services/finance_service.dart';

void main() {
  late FakeFirebaseFirestore fakeDb;
  late FinanceService financeService;

  const String roomId = 'test-room-1';
  const String user1 = 'user-1';
  const String user2 = 'user-2';
  const String user3 = 'user-3';
  final List<String> memberIds = [user1, user2, user3];

  setUp(() async {
    fakeDb = FakeFirebaseFirestore();
    financeService = FinanceService(db: fakeDb);

    // Prepare room members
    for (final uid in memberIds) {
      await fakeDb.collection('rooms').doc(roomId).collection('members').doc(uid).set({
        'userId': uid,
        'totalContributed': 0.0,
        'totalOwed': 0.0,
      });
    }
  });

  test('createFund creates a fund correctly', () async {
    final fund = await financeService.createFund(
      roomId: roomId,
      name: 'Test Fund',
      createdBy: user1,
      memberIds: memberIds,
    );

    expect(fund.name, 'Test Fund');
    expect(fund.currentBalance, 0);
    expect(fund.memberStatus.length, 3);
    expect(fund.memberStatus[user1], 'unpaid');
    
    // Verify in db
    final snap = await fakeDb.collection('rooms').doc(roomId).collection('funds').doc(fund.fundId).get();
    expect(snap.exists, true);
    expect(snap.data()?['name'], 'Test Fund');
  });

  test('addExpense with isFromFund = true subtracts from fund and DOES NOT add debt to members', () async {
    // 1. Create fund and add some money to it manually
    final fund = await financeService.createFund(
      roomId: roomId,
      name: 'Test Fund',
      createdBy: user1,
      memberIds: memberIds,
    );
    
    await fakeDb.collection('rooms').doc(roomId).collection('funds').doc(fund.fundId).update({
      'currentBalance': 1000.0,
    });

    // 2. Add an expense from this fund
    final expense = await financeService.addExpense(
      roomId: roomId,
      title: 'Buy snacks',
      category: 'food',
      totalAmount: 300,
      paidBy: user1,
      paidByName: 'User One',
      createdBy: user1,
      expenseDate: DateTime.now(),
      memberIds: memberIds,
      fundId: fund.fundId,
    );

    // 3. Verify fund balance is reduced by 300
    final fundSnap = await fakeDb.collection('rooms').doc(roomId).collection('funds').doc(fund.fundId).get();
    expect(fundSnap.data()?['currentBalance'], 700.0); // 1000 - 300

    // 4. Verify no debt is added to members
    final member2Snap = await fakeDb.collection('rooms').doc(roomId).collection('members').doc(user2).get();
    expect(member2Snap.data()?['totalOwed'], 0.0);
    
    // 5. Verify all members are settled
    expect(expense.settledStatus[user1], true);
    expect(expense.settledStatus[user2], true);
    expect(expense.settledStatus[user3], true);
  });

  test('addExpense with isFromFund = false ADDS debt to members', () async {
    // 1. Add an expense paid by user1 (no fund)
    final expense = await financeService.addExpense(
      roomId: roomId,
      title: 'Buy pizza',
      category: 'food',
      totalAmount: 300,
      paidBy: user1,
      paidByName: 'User One',
      createdBy: user1,
      expenseDate: DateTime.now(),
      memberIds: memberIds,
    );

    // 2. Verify debt is added to members (300 / 3 = 100 each for user2 and user3)
    final member2Snap = await fakeDb.collection('rooms').doc(roomId).collection('members').doc(user2).get();
    expect(member2Snap.data()?['totalOwed'], 100.0);
    
    final member3Snap = await fakeDb.collection('rooms').doc(roomId).collection('members').doc(user3).get();
    expect(member3Snap.data()?['totalOwed'], 100.0);

    // 3. user1 owes nothing extra (paidBy)
    final member1Snap = await fakeDb.collection('rooms').doc(roomId).collection('members').doc(user1).get();
    expect(member1Snap.data()?['totalOwed'], 0.0);
    
    // 4. Verify settledStatus: only user1 is settled
    expect(expense.settledStatus[user1], true);
    expect(expense.settledStatus[user2], false);
    expect(expense.settledStatus[user3], false);
  });
}

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/finance_models.dart';
import '../../models/user_model.dart';
import '../../services/finance_service.dart';
import '../../utils/app_theme.dart';
import '../../widgets/common_widgets.dart';
import 'add_expense_screen.dart';
import 'expense_detail_screen.dart';

class ExpenseListScreen extends StatefulWidget {
  final UserModel user;
  final String roomId;
  final bool isHead;
  final bool showAppBar;

  const ExpenseListScreen({
    super.key,
    required this.user,
    required this.roomId,
    required this.isHead,
    this.showAppBar = true,
  });

  @override
  State<ExpenseListScreen> createState() => _ExpenseListScreenState();
}

class _ExpenseListScreenState extends State<ExpenseListScreen> {
  String _filterCategory = 'all';

  final Map<String, String> _categories = {
    'all': 'Tất cả',
    'electricity': 'Tiền điện',
    'water': 'Tiền nước',
    'internet': 'Internet',
    'supplies': 'Đồ dùng',
    'other': 'Khác',
  };

  @override
  Widget build(BuildContext context) {
    final financeService = FinanceService();

    return Scaffold(
      appBar: widget.showAppBar
          ? AppBar(
              title: const Text('Chi tiêu chung'),
              automaticallyImplyLeading: false,
            )
          : null,
      body: Column(
        children: [
          // Category filter chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Row(
              children: _categories.entries.map((e) {
                final selected = _filterCategory == e.key;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: Text(e.value),
                    selected: selected,
                    onSelected: (_) =>
                        setState(() => _filterCategory = e.key),
                    selectedColor: AppColors.primary.withValues(alpha: 0.15),
                    checkmarkColor: AppColors.primary,
                    labelStyle: TextStyle(
                      color: selected
                          ? AppColors.primary
                          : AppColors.textSecondary,
                      fontWeight:
                          selected ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                );
              }).toList(),
            ),
          ),

          // Expense list
          Expanded(
            child: StreamBuilder<List<ExpenseModel>>(
              stream: financeService.expensesStream(widget.roomId),
              builder: (context, snap) {
                if (snap.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                var expenses = snap.data ?? [];

                // Filter
                if (_filterCategory != 'all') {
                  expenses = expenses
                      .where((e) => e.category == _filterCategory)
                      .toList();
                }

                if (expenses.isEmpty) {
                  return EmptyState(
                    icon: Icons.receipt_long_outlined,
                    title: 'Chưa có chi tiêu nào',
                    subtitle: 'Ấn nút + để thêm khoản chi',
                  );
                }

                // Group by month
                final Map<String, List<ExpenseModel>> grouped = {};
                for (final e in expenses) {
                  final key =
                      DateFormat('MM/yyyy').format(e.expenseDate);
                  grouped.putIfAbsent(key, () => []).add(e);
                }

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: grouped.length,
                  itemBuilder: (ctx, i) {
                    final monthKey = grouped.keys.elementAt(i);
                    final items = grouped[monthKey]!;
                    final monthTotal =
                        items.fold<double>(0, (s, e) => s + e.totalAmount);

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Month header
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: Row(
                            mainAxisAlignment:
                                MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Tháng $monthKey',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                              Text(
                                formatVND(monthTotal),
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                  color: AppColors.danger,
                                ),
                              ),
                            ],
                          ),
                        ),
                        ...items.map(
                          (e) => _ExpenseTile(
                            expense: e,
                            onTap: e.isPersonalNote
                                ? null
                                : () => Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => ExpenseDetailScreen(
                                          expense: e,
                                          roomId: widget.roomId,
                                          currentUserId: widget.user.uid,
                                          isHead: widget.isHead,
                                        ),
                                      ),
                                    ),
                          ),
                        ),
                        const SizedBox(height: 8),
                      ],
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => AddExpenseScreen(
                    roomId: widget.roomId,
                    user: widget.user,
                  ),
                ),
              ),
              icon: const Icon(Icons.add),
              label: const Text('Thêm chi tiêu'),
              backgroundColor: AppColors.danger,
            ),
    );
  }
}

class _ExpenseTile extends StatelessWidget {
  final ExpenseModel expense;
  final VoidCallback? onTap;

  const _ExpenseTile({required this.expense, this.onTap});

  @override
  Widget build(BuildContext context) {
    final catColor = AppConstants.categoryColor(expense.category);
    final catIcon = AppConstants.categoryIcons[expense.category] ??
        Icons.more_horiz;
    final catLabel = AppConstants.categoryLabels[expense.category] ?? expense.category;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              // Category icon
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: catColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(catIcon, color: catColor, size: 22),
              ),
              const SizedBox(width: 12),
              // Title + meta
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      expense.title,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '$catLabel • ${expense.paidByName} trả',
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    Text(
                      DateFormat('dd/MM/yyyy').format(expense.expenseDate),
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              // Amount
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    formatVND(expense.totalAmount),
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                      color: expense.isPersonalNote ? AppColors.danger : AppColors.secondary,
                    ),
                  ),
                  if (expense.isPersonalNote && expense.isDebtPaid)
                    Container(
                      margin: const EdgeInsets.only(top: 4),
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.secondary.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text(
                        'Đã trả',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: AppColors.secondary,
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

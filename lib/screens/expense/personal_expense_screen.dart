import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/finance_models.dart';
import '../../models/user_model.dart';
import '../../services/finance_service.dart';
import '../../utils/app_theme.dart';
import '../../widgets/common_widgets.dart';
import 'add_personal_expense_screen.dart';

class PersonalExpenseScreen extends StatelessWidget {
  final UserModel user;

  const PersonalExpenseScreen({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    final financeService = FinanceService();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Chi tiêu cá nhân'),
      ),
      body: StreamBuilder<List<PersonalExpenseModel>>(
        stream: financeService.personalExpensesStream(user.uid),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final expenses = snap.data ?? [];
          if (expenses.isEmpty) {
            return const EmptyState(
              icon: Icons.account_balance_wallet_outlined,
              title: 'Chưa có chi tiêu cá nhân',
              subtitle: 'Nhấn + để thêm chi tiêu mới',
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: expenses.length,
            itemBuilder: (ctx, i) {
              final exp = expenses[i];
              final catName = AppConstants.categoryLabels[exp.category] ?? exp.category;
              final icon = AppConstants.categoryIcons[exp.category] ?? Icons.more_horiz;
              final color = AppConstants.categoryColor(exp.category);

              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  contentPadding: const EdgeInsets.all(16),
                  leading: Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(icon, color: color),
                  ),
                  title: Text(
                    exp.title,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 4),
                      Text(
                        catName,
                        style: TextStyle(color: color, fontSize: 12),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        DateFormat('dd/MM/yyyy HH:mm').format(exp.expenseDate),
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      if (exp.note != null && exp.note!.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          exp.note!,
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ]
                    ],
                  ),
                  trailing: Text(
                    formatVND(exp.amount),
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                      color: AppColors.danger,
                    ),
                  ),
                  onLongPress: () {
                    showDialog(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        title: const Text('Xoá chi tiêu'),
                        content: const Text('Bạn có chắc muốn xoá khoản chi này?'),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(ctx),
                            child: const Text('Huỷ'),
                          ),
                          TextButton(
                            onPressed: () {
                              financeService.deletePersonalExpense(
                                userId: user.uid,
                                expenseId: exp.expenseId,
                              );
                              Navigator.pop(ctx);
                            },
                            child: const Text('Xoá', style: TextStyle(color: Colors.red)),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => AddPersonalExpenseScreen(user: user),
            ),
          );
        },
        icon: const Icon(Icons.add),
        label: const Text('Thêm chi tiêu'),
      ),
    );
  }
}

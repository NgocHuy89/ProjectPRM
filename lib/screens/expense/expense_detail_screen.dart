import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/finance_models.dart';
import '../../models/room_model.dart';
import '../../services/finance_service.dart';
import '../../services/room_service.dart';
import '../../utils/app_theme.dart';
import '../../widgets/common_widgets.dart';

class ExpenseDetailScreen extends StatelessWidget {
  final ExpenseModel expense;
  final String roomId;
  final String currentUserId;
  final bool isHead;

  const ExpenseDetailScreen({
    super.key,
    required this.expense,
    required this.roomId,
    required this.currentUserId,
    required this.isHead,
  });

  @override
  Widget build(BuildContext context) {
    final roomService = RoomService();
    final financeService = FinanceService();
    final catColor = AppConstants.categoryColor(expense.category);
    final catIcon =
        AppConstants.categoryIcons[expense.category] ?? Icons.more_horiz;
    final catLabel =
        AppConstants.categoryLabels[expense.category] ?? expense.category;

    return Scaffold(
      body: StreamBuilder<List<MemberModel>>(
        stream: roomService.membersStream(roomId),
        builder: (context, memberSnap) {
          final members = memberSnap.data ?? [];

          return CustomScrollView(
            slivers: [
              // ── AppBar ─────────────────────────────────
              SliverAppBar(
                expandedHeight: 180,
                pinned: true,
                backgroundColor: catColor,
                flexibleSpace: FlexibleSpaceBar(
                  background: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          catColor.withValues(alpha: 0.9),
                          catColor.withValues(alpha: 0.7),
                        ],
                      ),
                    ),
                    padding: const EdgeInsets.fromLTRB(20, 80, 20, 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(catIcon,
                                  color: Colors.white, size: 24),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    catLabel,
                                    style: const TextStyle(
                                      color: Colors.white70,
                                      fontSize: 12,
                                    ),
                                  ),
                                  Text(
                                    expense.title,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          formatVND(expense.totalAmount),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              SliverPadding(
                padding: const EdgeInsets.all(16),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    // ── Info card ────────────────────────
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          children: [
                            InfoRow(
                              icon: Icons.person,
                              label: 'Người trả',
                              value: expense.paidByName,
                            ),
                            const Divider(height: 1),
                            InfoRow(
                              icon: Icons.calendar_today,
                              label: 'Ngày chi',
                              value: DateFormat('dd/MM/yyyy')
                                  .format(expense.expenseDate),
                            ),
                            if (expense.note != null) ...[
                              const Divider(height: 1),
                              InfoRow(
                                icon: Icons.notes,
                                label: 'Ghi chú',
                                value: expense.note!,
                              ),
                            ],
                            if (expense.isPersonalNote) ...[
                              const Divider(height: 1),
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 8,
                                ),
                                child: Row(
                                  children: [
                                    const Icon(
                                      Icons.info_outline,
                                      size: 16,
                                      color: AppColors.warning,
                                    ),
                                    const SizedBox(width: 8),
                                    const Expanded(
                                      child: Text(
                                        'Khoản chi chung dùng vào việc cá nhân',
                                        style: TextStyle(
                                          color: AppColors.warning,
                                          fontSize: 13,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // ── Split info ────────────────────────
                    _buildSplitCard(
                      members: members,
                      expense: expense,
                      financeService: financeService,
                      context: context,
                    ),
                    const SizedBox(height: 80),
                  ]),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSplitCard({
    required List<MemberModel> members,
    required ExpenseModel expense,
    required FinanceService financeService,
    required BuildContext context,
  }) {
    final perPerson = members.isNotEmpty
        ? expense.totalAmount / members.length
        : expense.totalAmount;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Phân chia chi tiêu',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
                Text(
                  'Mỗi người: ${formatVND(perPerson)}',
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ...members.map((m) {
              final settled = expense.settledStatus[m.userId] ?? false;
              final isPayer = m.userId == expense.paidBy;

              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Row(
                  children: [
                    UserAvatar(
                      imageUrl: m.avatarUrl,
                      name: m.fullName,
                      radius: 18,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            m.fullName,
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                            ),
                          ),
                          if (isPayer)
                            const Text(
                              'Người trả',
                              style: TextStyle(
                                fontSize: 11,
                                color: AppColors.primary,
                              ),
                            ),
                        ],
                      ),
                    ),
                    if (isPayer)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          '+${formatVND(expense.totalAmount - perPerson * (members.length - 1))}',
                          style: const TextStyle(
                            color: AppColors.primary,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      )
                    else ...[
                      Text(
                        formatVND(perPerson),
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                          color: settled
                              ? AppColors.secondary
                              : AppColors.danger,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: settled
                              ? AppColors.secondary.withValues(alpha: 0.1)
                              : AppColors.warning.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          settled ? 'Đã trả' : 'Chưa trả',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: settled
                                ? AppColors.secondary
                                : AppColors.warning,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/finance_models.dart';
import '../../models/user_model.dart';
import '../../services/finance_service.dart';
import '../../utils/app_theme.dart';
import '../../widgets/common_widgets.dart';
import 'create_fund_screen.dart';
import 'fund_detail_screen.dart';

class FundListScreen extends StatelessWidget {
  final UserModel user;
  final String roomId;
  final bool isHead;
  final bool showAppBar;

  const FundListScreen({
    super.key,
    required this.user,
    required this.roomId,
    required this.isHead,
    this.showAppBar = true,
  });

  @override
  Widget build(BuildContext context) {
    final financeService = FinanceService();

    return Scaffold(
      appBar: showAppBar
          ? AppBar(
              title: const Text('Quản lý quỹ'),
              automaticallyImplyLeading: false,
            )
          : null,
      body: StreamBuilder<List<FundModel>>(
        stream: financeService.fundsStream(roomId),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final funds = snap.data ?? [];
          if (funds.isEmpty) {
            return EmptyState(
              icon: Icons.savings_outlined,
              title: 'Chưa có quỹ nào',
              subtitle: isHead
                  ? 'Ấn nút + để tạo quỹ mới'
                  : 'Trưởng phòng chưa tạo quỹ nào',
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: funds.length,
            itemBuilder: (ctx, i) => _FundCard(
              fund: funds[i],
              userId: user.uid,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => FundDetailScreen(
                    fund: funds[i],
                    roomId: roomId,
                    user: user,
                    isHead: isHead,
                  ),
                ),
              ),
            ),
          );
        },
      ),
      floatingActionButton: isHead
          ? FloatingActionButton.extended(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => CreateFundScreen(
                    roomId: roomId,
                    createdBy: user.uid,
                  ),
                ),
              ),
              icon: const Icon(Icons.add),
              label: const Text('Tạo quỹ'),
              backgroundColor: AppColors.primary,
            )
          : null,
    );
  }
}

class _FundCard extends StatelessWidget {
  final FundModel fund;
  final String userId;
  final VoidCallback onTap;

  const _FundCard({
    required this.fund,
    required this.userId,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final myStatus = fund.memberStatus[userId] ?? 'unpaid';
    final isPaid = myStatus == 'paid';
    final progress = fund.progressPercent;

    return Card(
      margin: const EdgeInsets.only(bottom: 14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Fund name + status badge
              Row(
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.savings,
                      color: AppColors.primary,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          fund.name,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        if (fund.dueDate != null)
                          Text(
                            'Hạn: ${DateFormat('dd/MM/yyyy').format(fund.dueDate!)}',
                            style: const TextStyle(
                              fontSize: 11,
                              color: AppColors.textSecondary,
                            ),
                          ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: isPaid
                          ? AppColors.secondary.withValues(alpha: 0.12)
                          : AppColors.warning.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      isPaid ? 'Đã đóng' : 'Chưa đóng',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: isPaid ? AppColors.secondary : AppColors.warning,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Balance
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Số dư hiện tại',
                        style: TextStyle(
                          fontSize: 11,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      Text(
                        formatVND(fund.currentBalance),
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppColors.secondary,
                        ),
                      ),
                    ],
                  ),
                  if (fund.targetAmount != null)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        const Text(
                          'Mục tiêu',
                          style: TextStyle(
                            fontSize: 11,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        Text(
                          formatVND(fund.targetAmount!),
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                ],
              ),

              // Progress bar
              if (fund.targetAmount != null) ...[
                const SizedBox(height: 10),
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LinearProgressIndicator(
                    value: progress,
                    backgroundColor: AppColors.divider,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      progress >= 1.0 ? AppColors.secondary : AppColors.primary,
                    ),
                    minHeight: 8,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  '${(progress * 100).toStringAsFixed(0)}% đạt mục tiêu',
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],

              // Unpaid count
              const SizedBox(height: 10),
              _buildMemberStatusRow(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMemberStatusRow() {
    final unpaid = fund.memberStatus.values.where((s) => s == 'unpaid').length;
    final paid = fund.memberStatus.values.where((s) => s == 'paid').length;
    return Row(
      children: [
        Icon(Icons.check_circle, size: 14, color: AppColors.secondary),
        const SizedBox(width: 4),
        Text(
          '$paid đã đóng',
          style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
        ),
        const SizedBox(width: 12),
        Icon(Icons.pending, size: 14, color: AppColors.warning),
        const SizedBox(width: 4),
        Text(
          '$unpaid chưa đóng',
          style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
        ),
      ],
    );
  }
}

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/finance_models.dart';
import '../../services/finance_service.dart';
import '../../utils/app_theme.dart';
import '../../widgets/common_widgets.dart';

class ContributionHistoryScreen extends StatelessWidget {
  final String fundId;
  final String roomId;
  final String fundName;

  const ContributionHistoryScreen({
    super.key,
    required this.fundId,
    required this.roomId,
    required this.fundName,
  });

  @override
  Widget build(BuildContext context) {
    final financeService = FinanceService();

    return Scaffold(
      appBar: AppBar(
        title: Text(fundName),
      ),
      body: StreamBuilder<List<ContributionModel>>(
        stream: financeService.contributionsStream(
          roomId: roomId,
          fundId: fundId,
        ),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final contribs = snap.data ?? [];
          if (contribs.isEmpty) {
            return const EmptyState(
              icon: Icons.history,
              title: 'Chưa có đóng góp nào',
              subtitle: 'Lịch sử đóng tiền sẽ hiển thị ở đây',
            );
          }

          // Group by date
          final Map<String, List<ContributionModel>> grouped = {};
          for (final c in contribs) {
            final key = DateFormat('dd/MM/yyyy').format(c.contributedAt);
            grouped.putIfAbsent(key, () => []).add(c);
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: grouped.length,
            itemBuilder: (ctx, i) {
              final dateKey = grouped.keys.elementAt(i);
              final items = grouped[dateKey]!;
              final dayTotal = items.fold<double>(0, (s, c) => s + c.amount);

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Date header
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          dateKey,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        Text(
                          '+${formatVND(dayTotal)}',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                            color: AppColors.secondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  ...items.map((c) => _ContributionTile(contribution: c)),
                  const SizedBox(height: 8),
                ],
              );
            },
          );
        },
      ),
    );
  }
}

class _ContributionTile extends StatelessWidget {
  final ContributionModel contribution;
  const _ContributionTile({required this.contribution});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            // Avatar
            UserAvatar(
              name: contribution.userName,
              radius: 20,
            ),
            const SizedBox(width: 12),
            // Name + note
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    contribution.userName,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  if (contribution.note != null)
                    Text(
                      contribution.note!,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  Text(
                    DateFormat('HH:mm').format(contribution.contributedAt),
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            // Amount + status
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '+${formatVND(contribution.amount)}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                    color: AppColors.secondary,
                  ),
                ),
                Container(
                  margin: const EdgeInsets.only(top: 4),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.secondary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Text(
                    'Đã xác nhận',
                    style: TextStyle(
                      fontSize: 10,
                      color: AppColors.secondary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

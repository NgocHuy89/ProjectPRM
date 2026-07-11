import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/finance_models.dart';
import '../../models/room_model.dart';
import '../../models/user_model.dart';
import '../../services/finance_service.dart';
import '../../services/room_service.dart';
import '../../utils/app_theme.dart';
import '../../widgets/common_widgets.dart';
import '../../services/notification_service.dart';
import 'contribute_screen.dart';
import 'contribution_history_screen.dart';

class FundDetailScreen extends StatelessWidget {
  final FundModel fund;
  final String roomId;
  final UserModel user;
  final bool isHead;

  const FundDetailScreen({
    super.key,
    required this.fund,
    required this.roomId,
    required this.user,
    required this.isHead,
  });

  @override
  Widget build(BuildContext context) {
    final financeService = FinanceService();
    final roomService = RoomService();

    return StreamBuilder<FundModel?>(
      stream: financeService.fundsStream(roomId).map(
            (list) => list.where((f) => f.fundId == fund.fundId).firstOrNull,
          ),
      builder: (context, snap) {
        final currentFund = snap.data ?? fund;
        final myStatus = currentFund.memberStatus[user.uid] ?? 'unpaid';
        final isPaid = myStatus == 'paid';
        final progress = currentFund.progressPercent;

        return Scaffold(
          body: CustomScrollView(
            slivers: [
              // ── AppBar với gradient ─────────────────────
              SliverAppBar(
                expandedHeight: 200,
                pinned: true,
                backgroundColor: AppColors.primaryDark,
                flexibleSpace: FlexibleSpaceBar(
                  background: Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [AppColors.primaryDark, AppColors.primary],
                      ),
                    ),
                    padding: const EdgeInsets.fromLTRB(20, 80, 20, 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Text(
                          currentFund.name,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (currentFund.description != null)
                          Text(
                            currentFund.description!,
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 13,
                            ),
                          ),
                        if (currentFund.dueDate != null) ...[
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              const Icon(
                                Icons.calendar_today,
                                size: 12,
                                color: Colors.white60,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'Hạn: ${DateFormat('dd/MM/yyyy').format(currentFund.dueDate!)}',
                                style: const TextStyle(
                                  color: Colors.white60,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                actions: [
                  IconButton(
                    icon: const Icon(Icons.history, color: Colors.white),
                    tooltip: 'Lịch sử đóng tiền',
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ContributionHistoryScreen(
                          fundId: fund.fundId,
                          roomId: roomId,
                          fundName: currentFund.name,
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              SliverPadding(
                padding: const EdgeInsets.all(16),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    // ── Progress card ────────────────────
                    _ProgressCard(fund: currentFund, progress: progress),
                    const SizedBox(height: 16),

                    // ── Nút đóng tiền ────────────────────
                    if (!isPaid) ...[
                      ElevatedButton.icon(
                        onPressed: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => ContributeScreen(
                              fund: currentFund,
                              roomId: roomId,
                              user: user,
                            ),
                          ),
                        ),
                        icon: const Icon(Icons.payment),
                        label: Text(
                          currentFund.contributionPerMember != null
                              ? 'Đóng ${formatVND(currentFund.contributionPerMember!)}'
                              : 'Đóng tiền vào quỹ',
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.secondary,
                        ),
                      ),
                    ] else ...[
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: AppColors.secondary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: AppColors.secondary.withValues(alpha: 0.3),
                          ),
                        ),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.check_circle,
                              color: AppColors.secondary,
                            ),
                            SizedBox(width: 8),
                            Text(
                              'Bạn đã đóng tiền quỹ này',
                              style: TextStyle(
                                color: AppColors.secondary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    const SizedBox(height: 20),

                    // ── Danh sách thành viên ─────────────
                    const SectionHeader(title: 'Trạng thái thành viên'),
                    const SizedBox(height: 12),

                    StreamBuilder<List<MemberModel>>(
                      stream: roomService.membersStream(roomId),
                      builder: (ctx, memberSnap) {
                        final members = memberSnap.data ?? [];
                        return Column(
                          children: members.map((m) {
                            final status =
                                currentFund.memberStatus[m.userId] ?? 'unpaid';
                            return _MemberStatusTile(
                              member: m,
                              status: status,
                              isHead: isHead,
                              onRemind: () async {
                                final notifService = NotificationService();
                                await notifService.sendNotification(
                                  userId: m.userId,
                                  title: 'Nhắc nhở đóng quỹ',
                                  body: 'Trưởng phòng nhắc bạn đóng quỹ "${currentFund.name}".',
                                  type: 'fund_reminder',
                                  referenceId: currentFund.fundId,
                                  roomId: roomId,
                                );
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text('Đã gửi nhắc nhở tới ${m.fullName}')),
                                  );
                                }
                              },
                            );
                          }).toList(),
                        );
                      },
                    ),
                    const SizedBox(height: 80),
                  ]),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _ProgressCard extends StatelessWidget {
  final FundModel fund;
  final double progress;

  const _ProgressCard({required this.fund, required this.progress});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Số dư hiện tại',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                    Text(
                      formatVND(fund.currentBalance),
                      style: const TextStyle(
                        fontSize: 24,
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
                          color: AppColors.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                      Text(
                        formatVND(fund.targetAmount!),
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
              ],
            ),
            if (fund.targetAmount != null) ...[
              const SizedBox(height: 16),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  value: progress,
                  backgroundColor: AppColors.divider,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    progress >= 1.0 ? AppColors.secondary : AppColors.primary,
                  ),
                  minHeight: 12,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '${(progress * 100).toStringAsFixed(1)}% đạt mục tiêu',
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 13,
                ),
              ),
            ],
            if (fund.contributionPerMember != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.person_outlined,
                      size: 16,
                      color: AppColors.primary,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Mỗi người đóng: ${formatVND(fund.contributionPerMember!)}',
                      style: const TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _MemberStatusTile extends StatelessWidget {
  final MemberModel member;
  final String status;
  final bool isHead;
  final VoidCallback? onRemind;

  const _MemberStatusTile({
    required this.member, 
    required this.status,
    this.isHead = false,
    this.onRemind,
  });

  @override
  Widget build(BuildContext context) {
    final isPaid = status == 'paid';
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: 1,
      child: ListTile(
        leading: UserAvatar(
          imageUrl: member.avatarUrl,
          name: member.fullName,
          radius: 20,
        ),
        title: Text(
          member.fullName,
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
        ),
        subtitle: member.isHead
            ? const Text(
                'Trưởng phòng',
                style: TextStyle(fontSize: 11, color: AppColors.primary),
              )
            : null,
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isHead && !isPaid)
              IconButton(
                icon: const Icon(Icons.notifications_active_outlined),
                color: AppColors.primary,
                tooltip: 'Gửi nhắc nhở',
                onPressed: onRemind,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            if (isHead && !isPaid) const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: isPaid
                    ? AppColors.secondary.withValues(alpha: 0.12)
                    : AppColors.warning.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    isPaid ? Icons.check_circle : Icons.pending,
                    size: 14,
                    color: isPaid ? AppColors.secondary : AppColors.warning,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    isPaid ? 'Đã đóng' : 'Chưa đóng',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: isPaid ? AppColors.secondary : AppColors.warning,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

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

import 'contribution_history_screen.dart';
import 'edit_fund_screen.dart';

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
                  if (isHead)
                    PopupMenuButton<String>(
                      icon: const Icon(Icons.more_vert, color: Colors.white),
                      onSelected: (val) async {
                        if (val == 'edit') {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => EditFundScreen(
                                roomId: roomId,
                                fund: currentFund,
                              ),
                            ),
                          );
                        } else if (val == 'delete') {
                          final confirm = await showDialog<bool>(
                            context: context,
                            builder: (ctx) => AlertDialog(
                              title: const Text('Xoá quỹ?'),
                              content: const Text(
                                  'Bạn có chắc chắn muốn xoá quỹ này không? Chỉ có thể xoá nếu chưa có thành viên nào nộp tiền.'),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(ctx, false),
                                  child: const Text('Huỷ',
                                      style: TextStyle(color: Colors.grey)),
                                ),
                                TextButton(
                                  onPressed: () => Navigator.pop(ctx, true),
                                  child: const Text('Xoá',
                                      style: TextStyle(color: Colors.red)),
                                ),
                              ],
                            ),
                          );
                          if (confirm == true && context.mounted) {
                            try {
                              await financeService.deleteFund(
                                roomId: roomId,
                                fundId: currentFund.fundId,
                              );
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Xoá quỹ thành công')),
                                );
                                Navigator.pop(context); // Quay lại danh sách quỹ
                              }
                            } catch (e) {
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(e.toString().replaceAll('Exception: ', '')),
                                    backgroundColor: Colors.red,
                                  ),
                                );
                              }
                            }
                          }
                        }
                      },
                      itemBuilder: (_) => [
                        const PopupMenuItem(
                          value: 'edit',
                          child: Row(
                            children: [
                              Icon(Icons.edit_outlined, color: Colors.blue),
                              SizedBox(width: 8),
                              Text('Sửa thông tin quỹ', style: TextStyle(color: Colors.blue)),
                            ],
                          ),
                        ),
                        const PopupMenuItem(
                          value: 'delete',
                          child: Row(
                            children: [
                              Icon(Icons.delete_outline, color: Colors.red),
                              SizedBox(width: 8),
                              Text('Xoá quỹ', style: TextStyle(color: Colors.red)),
                            ],
                          ),
                        ),
                      ],
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
                    StreamBuilder<List<ContributionModel>>(
                      stream: financeService.contributionsStream(roomId: roomId, fundId: currentFund.fundId),
                      builder: (context, contribSnap) {
                        final contributions = contribSnap.data ?? [];
                        final myContributions = contributions.where((c) => c.userId == user.uid).toList();
                        final hasPending = myContributions.any((c) => c.status == 'pending');

                        if (isPaid) {
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
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
                                    Icon(Icons.check_circle, color: AppColors.secondary),
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
                              const SizedBox(height: 12),
                              ElevatedButton.icon(
                                onPressed: () => _showPayForOthersDialog(context, currentFund, financeService, roomService, isPaid, hasPending),
                                icon: const Icon(Icons.people),
                                label: const Text('Đóng quỹ hộ người khác'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.primary,
                                  padding: const EdgeInsets.symmetric(vertical: 14),
                                ),
                              ),
                            ],
                          );
                        } else if (hasPending) {
                          final pendingContrib = myContributions.firstWhere((c) => c.status == 'pending');
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              InkWell(
                                onTap: () {
                                  showDialog(
                                    context: context,
                                    builder: (ctx) => AlertDialog(
                                      title: const Text('Huỷ yêu cầu đóng tiền'),
                                      content: const Text('Bạn muốn huỷ yêu cầu đóng tiền đang chờ duyệt này?'),
                                      actions: [
                                        TextButton(
                                          onPressed: () => Navigator.pop(ctx),
                                          child: const Text('Không', style: TextStyle(color: Colors.grey)),
                                        ),
                                        ElevatedButton(
                                          onPressed: () async {
                                            Navigator.pop(ctx);
                                            try {
                                              await financeService.deletePendingContribution(
                                                roomId: roomId,
                                                fundId: currentFund.fundId,
                                                contributionId: pendingContrib.contributionId,
                                              );
                                              if (context.mounted) {
                                                ScaffoldMessenger.of(context).showSnackBar(
                                                  const SnackBar(content: Text('Đã huỷ yêu cầu')),
                                                );
                                              }
                                            } catch (e) {
                                              if (context.mounted) {
                                                ScaffoldMessenger.of(context).showSnackBar(
                                                  SnackBar(content: Text('Lỗi: $e')),
                                                );
                                              }
                                            }
                                          },
                                          style: ElevatedButton.styleFrom(backgroundColor: AppColors.danger),
                                          child: const Text('Huỷ yêu cầu'),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                                borderRadius: BorderRadius.circular(12),
                                child: Container(
                                  padding: const EdgeInsets.all(14),
                                  decoration: BoxDecoration(
                                    color: Colors.orange.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: Colors.orange.withValues(alpha: 0.3),
                                    ),
                                  ),
                                  child: const Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(Icons.access_time, color: Colors.orange),
                                      SizedBox(width: 8),
                                      Text(
                                        'Đang chờ duyệt (Bấm để huỷ)',
                                        style: TextStyle(
                                          color: Colors.orange,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(height: 12),
                              ElevatedButton.icon(
                                onPressed: () => _showPayForOthersDialog(context, currentFund, financeService, roomService, isPaid, hasPending),
                                icon: const Icon(Icons.people),
                                label: const Text('Đóng quỹ hộ người khác'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.primary,
                                  padding: const EdgeInsets.symmetric(vertical: 14),
                                ),
                              ),
                            ],
                          );
                        } else {
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              ElevatedButton.icon(
                                onPressed: () {
                                  _showContributeDialog(context, currentFund, financeService);
                                },
                                icon: const Icon(Icons.payment),
                                label: Text(
                                  currentFund.contributionPerMember != null
                                      ? 'Đóng ${formatVND(currentFund.contributionPerMember!)}'
                                      : 'Đóng tiền vào quỹ',
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.secondary,
                                  padding: const EdgeInsets.symmetric(vertical: 14),
                                ),
                              ),
                              const SizedBox(height: 12),
                              OutlinedButton.icon(
                                onPressed: () => _showPayForOthersDialog(context, currentFund, financeService, roomService, isPaid, hasPending),
                                icon: const Icon(Icons.people, color: AppColors.primary),
                                label: const Text('Đóng quỹ hộ người khác', style: TextStyle(color: AppColors.primary)),
                                style: OutlinedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(vertical: 14),
                                  side: const BorderSide(color: AppColors.primary),
                                ),
                              ),
                            ],
                          );
                        }
                      },
                    ),
                    const SizedBox(height: 20),

                    // ── Danh sách thành viên ─────────────
                    const SectionHeader(title: 'Trạng thái thành viên'),
                    const SizedBox(height: 12),

                    StreamBuilder<List<MemberModel>>(
                      stream: roomService.membersStream(roomId),
                      builder: (ctx, memberSnap) {
                        final members = memberSnap.data ?? [];
                        return StreamBuilder<List<ExpenseModel>>(
                          stream: financeService.expensesStream(roomId),
                          builder: (ctx, expSnap) {
                            final expenses = expSnap.data ?? [];
                            final fundExpenses = expenses.where((e) => e.fundId == currentFund.fundId && e.isPersonalNote).toList();
                            final Map<String, bool> memberHasPaidDebt = {};
                            for (var e in fundExpenses) {
                              if (e.isDebtPaid) {
                                memberHasPaidDebt[e.paidBy] = true;
                              }
                            }
                            
                            return Column(
                              children: members.map((m) {
                                final status =
                                    currentFund.memberStatus[m.userId] ?? 'unpaid';
                                final debt = m.fundDebt;
                                final hasPaidDebt = memberHasPaidDebt[m.userId] ?? false;
                                return _MemberStatusTile(
                                  member: m,
                                  status: status,
                                  debt: debt,
                                  hasPaidDebt: hasPaidDebt,
                                  isCurrentUser: m.userId == user.uid,
                                  isHead: isHead,
                                  onPayDebt: () async {
                                    final confirm = await showDialog<bool>(
                                      context: context,
                                      builder: (ctx) => AlertDialog(
                                        title: const Text('Trả nợ quỹ'),
                                        content: Text('Bạn có chắc chắn muốn trả ${formatVND(debt)} nợ quỹ không?'),
                                        actions: [
                                          TextButton(
                                            onPressed: () => Navigator.pop(ctx, false),
                                            child: const Text('Huỷ', style: TextStyle(color: Colors.grey)),
                                          ),
                                          TextButton(
                                            onPressed: () => Navigator.pop(ctx, true),
                                            child: const Text('Trả nợ', style: TextStyle(color: AppColors.danger)),
                                          ),
                                        ],
                                      ),
                                    );
                                    if (confirm == true && context.mounted) {
                                      try {
                                        await financeService.payFundDebt(
                                          roomId: roomId,
                                          fundId: currentFund.fundId,
                                          userId: user.uid,
                                        );
                                        if (context.mounted) {
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            const SnackBar(content: Text('Đã trả nợ thành công!')),
                                          );
                                        }
                                      } catch (e) {
                                        if (context.mounted) {
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            SnackBar(content: Text('Lỗi: $e'), backgroundColor: Colors.red),
                                          );
                                        }
                                      }
                                    }
                                  },
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

  void _showContributeDialog(BuildContext context, FundModel currentFund, FinanceService financeService) {
    if (currentFund.contributionPerMember != null) {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Xác nhận đóng quỹ'),
          content: Text('Bạn có chắc chắn gửi yêu cầu đóng ${formatVND(currentFund.contributionPerMember!)} cho chủ phòng?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Huỷ', style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(ctx);
                try {
                  await financeService.addContribution(
                    roomId: roomId,
                    fundId: currentFund.fundId,
                    userId: user.uid,
                    userName: user.fullName,
                    amount: currentFund.contributionPerMember!,
                  );
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Đã gửi yêu cầu đóng tiền')),
                    );
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Lỗi: ${e.toString()}'), backgroundColor: Colors.red),
                    );
                  }
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
              child: const Text('Gửi yêu cầu'),
            ),
          ],
        ),
      );
    } else {
      final ctrl = TextEditingController();
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Nhập số tiền đóng'),
          content: TextField(
            controller: ctrl,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Số tiền (VND)',
              border: OutlineInputBorder(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Huỷ', style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              onPressed: () async {
                final val = double.tryParse(ctrl.text.trim()) ?? 0;
                if (val <= 0) {
                  ScaffoldMessenger.of(ctx).showSnackBar(
                    const SnackBar(content: Text('Số tiền không hợp lệ')),
                  );
                  return;
                }
                Navigator.pop(ctx);
                try {
                  await financeService.addContribution(
                    roomId: roomId,
                    fundId: currentFund.fundId,
                    userId: user.uid,
                    userName: user.fullName,
                    amount: val,
                  );
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Đã gửi yêu cầu đóng tiền')),
                    );
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Lỗi: ${e.toString()}'), backgroundColor: Colors.red),
                    );
                  }
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
              child: const Text('Gửi yêu cầu'),
            ),
          ],
        ),
      );
    }
  }

  void _showPayForOthersDialog(
    BuildContext context,
    FundModel currentFund,
    FinanceService financeService,
    RoomService roomService,
    bool isCurrentUserPaid,
    bool hasPending,
  ) {
    if (currentFund.contributionPerMember == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tính năng này chỉ hỗ trợ quỹ có mức đóng cố định')),
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _PayForOthersSheet(
        roomId: roomId,
        currentFund: currentFund,
        financeService: financeService,
        roomService: roomService,
        currentUser: user,
        isCurrentUserPaid: isCurrentUserPaid,
        hasPending: hasPending,
      ),
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
  final double debt;
  final bool hasPaidDebt;
  final bool isCurrentUser;
  final bool isHead;
  final VoidCallback? onRemind;
  final VoidCallback? onPayDebt;

  const _MemberStatusTile({
    required this.member, 
    required this.status,
    this.debt = 0,
    this.hasPaidDebt = false,
    this.isCurrentUser = false,
    this.isHead = false,
    this.onRemind,
    this.onPayDebt,
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
        subtitle: (member.isHead || debt > 0 || hasPaidDebt)
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (member.isHead)
                    const Text(
                      'Trưởng phòng',
                      style: TextStyle(fontSize: 11, color: AppColors.primary),
                    ),
                  if (debt > 0)
                    Text(
                      'Nợ quỹ: ${formatVND(debt)}',
                      style: const TextStyle(fontSize: 12, color: AppColors.danger, fontWeight: FontWeight.w600),
                    )
                  else if (hasPaidDebt)
                    const Text(
                      'Đã trả nợ quỹ',
                      style: TextStyle(fontSize: 12, color: AppColors.secondary, fontWeight: FontWeight.w600),
                    ),
                ],
              )
            : null,
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isCurrentUser && debt > 0)
              TextButton(
                onPressed: onPayDebt,
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: const Text('Trả nợ', style: TextStyle(fontSize: 13, color: AppColors.danger, fontWeight: FontWeight.bold)),
              ),
            if (isCurrentUser && debt > 0) const SizedBox(width: 8),
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

class _PayForOthersSheet extends StatefulWidget {
  final String roomId;
  final FundModel currentFund;
  final FinanceService financeService;
  final RoomService roomService;
  final UserModel currentUser;
  final bool isCurrentUserPaid;
  final bool hasPending;

  const _PayForOthersSheet({
    required this.roomId,
    required this.currentFund,
    required this.financeService,
    required this.roomService,
    required this.currentUser,
    required this.isCurrentUserPaid,
    required this.hasPending,
  });

  @override
  State<_PayForOthersSheet> createState() => _PayForOthersSheetState();
}

class _PayForOthersSheetState extends State<_PayForOthersSheet> {
  final Set<String> _selectedMemberIds = {};
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(
        top: 24,
        left: 24,
        right: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.8,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Đóng quỹ hộ người khác',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Text(
            'Chọn thành viên chưa đóng quỹ để đóng hộ (không bao gồm bạn):',
            style: TextStyle(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: StreamBuilder<List<MemberModel>>(
              stream: widget.roomService.membersStream(widget.roomId),
              builder: (context, snap) {
                if (snap.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                final members = snap.data ?? [];
                final unpaidOthers = members.where((m) {
                  if (m.userId == widget.currentUser.uid) return false; 
                  final status = widget.currentFund.memberStatus[m.userId] ?? 'unpaid';
                  return status != 'paid';
                }).toList();

                if (unpaidOthers.isEmpty) {
                  return const Center(
                    child: Text('Tất cả mọi người đều đã đóng quỹ này.'),
                  );
                }

                return ListView.builder(
                  shrinkWrap: true,
                  itemCount: unpaidOthers.length,
                  itemBuilder: (ctx, index) {
                    final m = unpaidOthers[index];
                    return CheckboxListTile(
                      value: _selectedMemberIds.contains(m.userId),
                      onChanged: (val) {
                        setState(() {
                          if (val == true) {
                            _selectedMemberIds.add(m.userId);
                          } else {
                            _selectedMemberIds.remove(m.userId);
                          }
                        });
                      },
                      title: Text(m.fullName),
                      subtitle: Text(m.role == 'head' ? 'Trưởng phòng' : 'Thành viên'),
                      activeColor: AppColors.primary,
                      contentPadding: EdgeInsets.zero,
                    );
                  },
                );
              },
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: (_selectedMemberIds.isEmpty || _isLoading) ? null : _submitPayment,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: _isLoading 
                ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                : const Text('Yêu cầu đóng tiền', style: TextStyle(fontSize: 16)),
          ),
        ],
      ),
    );
  }

  Future<void> _submitPayment() async {
    setState(() => _isLoading = true);
    try {
      final amount = widget.currentFund.contributionPerMember!;
      
      final membersList = await widget.roomService.membersStream(widget.roomId).first;
      
      int successCount = 0;
      
      // 1. Submit cho những người được chọn
      for (final uid in _selectedMemberIds) {
        final m = membersList.firstWhere((e) => e.userId == uid);
        await widget.financeService.addContribution(
          roomId: widget.roomId,
          fundId: widget.currentFund.fundId,
          userId: m.userId,
          userName: m.fullName,
          amount: amount,
          note: 'Đóng hộ bởi ${widget.currentUser.fullName}',
        );
        successCount++;
      }
      
      // 2. Tự động submit cho bản thân nếu chưa đóng và chưa có pending
      if (!widget.isCurrentUserPaid && !widget.hasPending) {
        await widget.financeService.addContribution(
          roomId: widget.roomId,
          fundId: widget.currentFund.fundId,
          userId: widget.currentUser.uid,
          userName: widget.currentUser.fullName,
          amount: amount,
        );
        successCount++;
      }

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Đã gửi $successCount yêu cầu đóng tiền'),
            backgroundColor: AppColors.secondary,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi: $e'),
            backgroundColor: AppColors.danger,
          ),
        );
      }
    }
  }
}

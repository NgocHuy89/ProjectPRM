import 'package:flutter/material.dart';
import 'package:timeago/timeago.dart' as timeago;

import '../../models/notification_model.dart';
import '../../models/finance_models.dart';
import '../../models/user_model.dart';
import '../../services/notification_service.dart';
import '../../services/finance_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../utils/app_theme.dart';
import '../fund/fund_detail_screen.dart';

class NotificationsScreen extends StatefulWidget {
  final String userId;

  const NotificationsScreen({super.key, required this.userId});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final _notificationService = NotificationService();

  @override
  void initState() {
    super.initState();
    timeago.setLocaleMessages('vi', timeago.ViMessages());
  }

  void _markAllAsRead() async {
    await _notificationService.markAllAsRead(widget.userId);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('?? ??nh d?u t?t c? l? ?? ??c')),
      );
    }
  }

  void _onNotificationTapped(NotificationModel notif) async {
    if (!notif.isRead) {
      await _notificationService.markAsRead(widget.userId, notif.id);
    }
    if (notif.type == 'fund_reminder') {
      await _openFundReminder(notif);
    }
  }

  Future<void> _openFundReminder(NotificationModel notif) async {
    if (notif.roomId == null || notif.referenceId == null) return;

    try {
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.userId)
          .get();
      final fundDoc = await FirebaseFirestore.instance
          .collection('rooms')
          .doc(notif.roomId)
          .collection('funds')
          .doc(notif.referenceId)
          .get();

      if (!mounted) return;
      if (!userDoc.exists || !fundDoc.exists) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Kh?ng t?m th?y qu? c?n ??ng.')),
        );
        return;
      }

      final user = UserModel.fromFirestore(userDoc);
      final fund = FundModel.fromFirestore(fundDoc);
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => FundDetailScreen(
            fund: fund,
            roomId: notif.roomId!,
            user: user,
            isHead: user.isHead,
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Kh?ng th? m? qu?: $e')),
      );
    }
  }

  Future<DocumentSnapshot?> _checkContributionExists(String referenceId) async {
    final parts = referenceId.split('|');
    if (parts.length == 3) {
      try {
        return await FirebaseFirestore.instance
            .collection('rooms')
            .doc(parts[0])
            .collection('funds')
            .doc(parts[1])
            .collection('contributions')
            .doc(parts[2])
            .get();
      } catch (e) {
        return null;
      }
    }
    return null;
  }

  Future<void> _markContributionHandled(
    NotificationModel notif, {
    required String newType,
  }) async {
    await FirebaseFirestore.instance
        .collection('users')
        .doc(widget.userId)
        .collection('notifications')
        .doc(notif.id)
        .update({
          'type': newType,
          'isRead': true,
        });
  }

  void _handleApprove(NotificationModel notif) async {
    if (notif.referenceId == null) return;
    final parts = notif.referenceId!.split('|');
    if (parts.length != 3) return;

    try {
      final financeService = FinanceService();
      await financeService.approveContribution(
        roomId: parts[0],
        fundId: parts[1],
        contributionId: parts[2],
        headId: widget.userId,
      );

      await _markContributionHandled(
        notif,
        newType: 'contribution_request_approved',
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('?? x?c nh?n kho?n ??ng qu?')),
        );
      }
    } catch (e) {
      if (e.toString().contains('b? ng??i d?ng hu?')) {
        await _markContributionHandled(
          notif,
          newType: 'contribution_request_canceled',
        );
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Y?u c?u n?y ?? b? ng??i d?ng hu? tr??c ??.'),
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('L?i: $e')),
          );
        }
      }
    }
  }

  void _handleReject(NotificationModel notif) async {
    if (notif.referenceId == null) return;
    final parts = notif.referenceId!.split('|');
    if (parts.length != 3) return;

    try {
      final financeService = FinanceService();
      await financeService.rejectContribution(
        roomId: parts[0],
        fundId: parts[1],
        contributionId: parts[2],
        headId: widget.userId,
      );

      await _markContributionHandled(
        notif,
        newType: 'contribution_request_rejected',
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('?? t? ch?i kho?n ??ng qu?')),
        );
      }
    } catch (e) {
      if (e.toString().contains('b? ng??i d?ng hu?')) {
        await _markContributionHandled(
          notif,
          newType: 'contribution_request_canceled',
        );
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Y?u c?u n?y ?? b? ng??i d?ng hu? tr??c ??.'),
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('L?i: $e')),
          );
        }
      }
    }
  }

  IconData _getIconForType(String type) {
    switch (type) {
      case 'expense':
        return Icons.receipt_long;
      case 'fund_reminder':
        return Icons.warning_amber_rounded;
      case 'fund':
        return Icons.savings;
      case 'contribution_request':
        return Icons.payments_outlined;
      case 'contribution_request_approved':
        return Icons.check_circle_outline;
      case 'contribution_request_rejected':
        return Icons.cancel_outlined;
      case 'contribution_request_canceled':
        return Icons.cancel;
      default:
        return Icons.notifications;
    }
  }

  Color _getColorForType(String type) {
    switch (type) {
      case 'expense':
        return AppColors.primary;
      case 'fund_reminder':
        return AppColors.danger;
      case 'fund':
        return AppColors.secondary;
      case 'contribution_request':
        return AppColors.primary;
      case 'contribution_request_approved':
        return AppColors.secondary;
      case 'contribution_request_rejected':
        return AppColors.danger;
      case 'contribution_request_canceled':
        return Colors.grey;
      default:
        return Colors.grey;
    }
  }

  Widget? _buildContributionStatus(String type) {
    switch (type) {
      case 'contribution_request_approved':
        return _statusChip('?? x?c nh?n', AppColors.secondary);
      case 'contribution_request_rejected':
        return _statusChip('?? t? ch?i', AppColors.danger);
      case 'contribution_request_canceled':
        return _statusChip(
          'Y?u c?u ?? b? ng??i d?ng hu?.',
          AppColors.danger,
          italic: true,
        );
      default:
        return null;
    }
  }

  Widget _statusChip(String label, Color color, {bool italic = false}) {
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: color,
            fontWeight: FontWeight.w600,
            fontSize: 13,
            fontStyle: italic ? FontStyle.italic : FontStyle.normal,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Th?ng b?o'),
        actions: [
          IconButton(
            icon: const Icon(Icons.done_all),
            tooltip: '??nh d?u t?t c? ?? ??c',
            onPressed: _markAllAsRead,
          ),
        ],
      ),
      body: StreamBuilder<List<NotificationModel>>(
        stream: _notificationService.getNotificationsStream(widget.userId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final notifications = snapshot.data ?? [];

          if (notifications.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.notifications_none,
                    size: 80,
                    color: Colors.grey.withValues(alpha: 0.5),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'B?n ch?a c? th?ng b?o n?o',
                    style: TextStyle(color: Colors.grey, fontSize: 16),
                  ),
                ],
              ),
            );
          }

          return ListView.separated(
            itemCount: notifications.length,
            separatorBuilder: (ctx, i) => const Divider(height: 1, indent: 72),
            itemBuilder: (context, index) {
              final notif = notifications[index];
              final isRead = notif.isRead;
              final iconColor = _getColorForType(notif.type);
              final statusWidget = _buildContributionStatus(notif.type);

              return Material(
                color: isRead ? Colors.transparent : Colors.blue.withOpacity(0.05),
                child: InkWell(
                  onTap: () => _onNotificationTapped(notif),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: iconColor.withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            _getIconForType(notif.type),
                            color: iconColor,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                notif.title,
                                style: TextStyle(
                                  fontWeight: isRead ? FontWeight.normal : FontWeight.bold,
                                  fontSize: 15,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                notif.body,
                                style: TextStyle(
                                  color: AppColors.textSecondary,
                                  fontSize: 14,
                                  fontWeight: isRead ? FontWeight.normal : FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                timeago.format(notif.createdAt, locale: 'vi'),
                                style: TextStyle(
                                  color: Colors.grey.shade500,
                                  fontSize: 12,
                                ),
                              ),
                              if (statusWidget != null) statusWidget,
                              if (notif.type == 'contribution_request' &&
                                  notif.referenceId != null) ...[
                                const SizedBox(height: 8),
                                FutureBuilder<DocumentSnapshot?>(
                                  future: _checkContributionExists(notif.referenceId!),
                                  builder: (context, snapshot) {
                                    if (snapshot.connectionState ==
                                        ConnectionState.waiting) {
                                      return const Align(
                                        alignment: Alignment.centerLeft,
                                        child: SizedBox(
                                          height: 20,
                                          width: 20,
                                          child: CircularProgressIndicator(strokeWidth: 2),
                                        ),
                                      );
                                    }

                                    final doc = snapshot.data;
                                    if (doc == null || !doc.exists) {
                                      FirebaseFirestore.instance
                                          .collection('users')
                                          .doc(widget.userId)
                                          .collection('notifications')
                                          .doc(notif.id)
                                          .update({
                                            'type': 'contribution_request_canceled',
                                          })
                                          .catchError((_) {});

                                      return _statusChip(
                                        'Y?u c?u ?? b? ng??i d?ng hu?.',
                                        AppColors.danger,
                                        italic: true,
                                      );
                                    }

                                    return Row(
                                      children: [
                                        ElevatedButton(
                                          onPressed: () => _handleApprove(notif),
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: AppColors.secondary,
                                            visualDensity: VisualDensity.compact,
                                            minimumSize: Size.zero,
                                          ),
                                          child: const Text('X?c nh?n'),
                                        ),
                                        const SizedBox(width: 8),
                                        TextButton(
                                          onPressed: () => _handleReject(notif),
                                          style: TextButton.styleFrom(
                                            foregroundColor: AppColors.danger,
                                            visualDensity: VisualDensity.compact,
                                          ),
                                          child: const Text('T? ch?i'),
                                        ),
                                      ],
                                    );
                                  },
                                ),
                              ],
                            ],
                          ),
                        ),
                        if (!isRead)
                          Container(
                            width: 10,
                            height: 10,
                            margin: const EdgeInsets.only(top: 8),
                            decoration: const BoxDecoration(
                              color: AppColors.primary,
                              shape: BoxShape.circle,
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

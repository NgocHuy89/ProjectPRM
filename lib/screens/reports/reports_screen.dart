import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/room_model.dart';
import '../../services/finance_service.dart';
import '../../services/room_service.dart';
import '../../utils/app_theme.dart';
import '../../widgets/common_widgets.dart';

class ReportsScreen extends StatefulWidget {
  final String roomId;
  const ReportsScreen({super.key, required this.roomId});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  final _financeService = FinanceService();
  final _roomService = RoomService();

  late int _selectedYear;
  late int _selectedMonth;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _selectedYear = now.year;
    _selectedMonth = now.month;
  }

  void _prevMonth() {
    setState(() {
      if (_selectedMonth == 1) {
        _selectedMonth = 12;
        _selectedYear--;
      } else {
        _selectedMonth--;
      }
    });
  }

  void _nextMonth() {
    final now = DateTime.now();
    if (_selectedYear == now.year && _selectedMonth == now.month) return;
    setState(() {
      if (_selectedMonth == 12) {
        _selectedMonth = 1;
        _selectedYear++;
      } else {
        _selectedMonth++;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Báo cáo & Thống kê'),
        automaticallyImplyLeading: false,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ── Month selector ──────────────────────────────
          _buildMonthSelector(),
          const SizedBox(height: 16),

          // ── Monthly summary ─────────────────────────────
          FutureBuilder<Map<String, dynamic>>(
            future: _financeService.getMonthlyReport(
              roomId: widget.roomId,
              year: _selectedYear,
              month: _selectedMonth,
            ),
            builder: (ctx, snap) {
              if (snap.connectionState == ConnectionState.waiting) {
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.all(32),
                    child: CircularProgressIndicator(),
                  ),
                );
              }

              final data = snap.data ?? {};
              final totalExpense =
                  (data['totalExpense'] as double?) ?? 0;
              final totalIncome =
                  (data['totalIncome'] as double?) ?? 0;
              final balance = (data['balance'] as double?) ?? 0;
              final byCategory =
                  (data['byCategory'] as Map<String, double>?) ?? {};
              final topCategory = data['topCategory'] as String?;
              final expenseCount = (data['expenseCount'] as int?) ?? 0;

              return Column(
                children: [
                  // Summary cards
                  _buildSummaryRow(
                    totalExpense: totalExpense,
                    totalIncome: totalIncome,
                    balance: balance,
                    expenseCount: expenseCount,
                  ),
                  const SizedBox(height: 20),

                  // Bar chart
                  if (byCategory.isNotEmpty) ...[
                    const SectionHeader(title: 'Chi tiêu theo danh mục'),
                    const SizedBox(height: 12),
                    _buildCategoryChart(byCategory, totalExpense),
                    const SizedBox(height: 20),
                  ],

                  // Top category
                  if (topCategory != null) ...[
                    _buildTopCategoryCard(topCategory, byCategory),
                    const SizedBox(height: 20),
                  ],
                ],
              );
            },
          ),

          // ── Member summary ──────────────────────────────
          const SectionHeader(title: 'Tổng hợp thành viên'),
          const SizedBox(height: 12),
          StreamBuilder<List<MemberModel>>(
            stream: _roomService.membersStream(widget.roomId),
            builder: (ctx, snap) {
              final members = snap.data ?? [];
              if (members.isEmpty) {
                return const EmptyState(
                  icon: Icons.group_outlined,
                  title: 'Chưa có thành viên',
                );
              }
              return Column(
                children: members
                    .map((m) => _MemberSummaryCard(member: m))
                    .toList(),
              );
            },
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildMonthSelector() {
    final now = DateTime.now();
    final isCurrentMonth =
        _selectedYear == now.year && _selectedMonth == now.month;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left),
            onPressed: _prevMonth,
            color: AppColors.primary,
          ),
          Text(
            DateFormat('MMMM yyyy', 'vi').format(
              DateTime(_selectedYear, _selectedMonth),
            ),
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          IconButton(
            icon: Icon(
              Icons.chevron_right,
              color:
                  isCurrentMonth ? AppColors.divider : AppColors.primary,
            ),
            onPressed: isCurrentMonth ? null : _nextMonth,
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow({
    required double totalExpense,
    required double totalIncome,
    required double balance,
    required int expenseCount,
  }) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _SummaryCard(
                label: 'Tổng chi',
                value: formatVND(totalExpense),
                icon: Icons.trending_down,
                color: AppColors.danger,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _SummaryCard(
                label: 'Tổng đóng quỹ',
                value: formatVND(totalIncome),
                icon: Icons.trending_up,
                color: AppColors.secondary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _SummaryCard(
                label: 'Số dư (quỹ-chi)',
                value: formatVND(balance),
                icon: Icons.account_balance,
                color: balance >= 0 ? AppColors.secondary : AppColors.danger,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _SummaryCard(
                label: 'Số khoản chi',
                value: '$expenseCount khoản',
                icon: Icons.receipt_long,
                color: AppColors.primary,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildCategoryChart(
      Map<String, double> byCategory, double totalExpense) {
    final sorted = byCategory.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: sorted.map((entry) {
            final pct =
                totalExpense > 0 ? entry.value / totalExpense : 0.0;
            final color = AppConstants.categoryColor(entry.key);
            final label =
                AppConstants.categoryLabels[entry.key] ?? 'Khác';
            final icon =
                AppConstants.categoryIcons[entry.key] ?? Icons.more_horiz;

            return Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(icon, size: 16, color: color),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          label,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      Text(
                        formatVND(entry.value),
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: color,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '${(pct * 100).toStringAsFixed(1)}%',
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: LinearProgressIndicator(
                      value: pct.toDouble(),
                      backgroundColor: color.withValues(alpha: 0.1),
                      valueColor: AlwaysStoppedAnimation<Color>(color),
                      minHeight: 10,
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildTopCategoryCard(
      String topCat, Map<String, double> byCategory) {
    final color = AppConstants.categoryColor(topCat);
    final label = AppConstants.categoryLabels[topCat] ?? 'Khác';
    final icon = AppConstants.categoryIcons[topCat] ?? Icons.more_horiz;
    final amount = byCategory[topCat] ?? 0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color.withValues(alpha: 0.8), color],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: Colors.white, size: 28),
          ),
          const SizedBox(width: 14),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Chi nhiều nhất tháng này',
                style: TextStyle(color: Colors.white70, fontSize: 12),
              ),
              Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                formatVND(amount),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _SummaryCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(height: 10),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

class _MemberSummaryCard extends StatelessWidget {
  final MemberModel member;

  const _MemberSummaryCard({required this.member});

  @override
  Widget build(BuildContext context) {
    final balance = member.balance;
    final isPositive = balance >= 0;

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            UserAvatar(
              imageUrl: member.avatarUrl,
              name: member.fullName,
              radius: 22,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        member.fullName,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      if (member.isHead) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Text(
                            'Trưởng phòng',
                            style: TextStyle(
                              fontSize: 9,
                              color: AppColors.primary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text(
                        'Đã đóng: ${formatVND(member.totalContributed)}',
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.secondary,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Còn nợ: ${formatVND(member.totalOwed)}',
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.danger,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  isPositive
                      ? '+${formatVND(balance)}'
                      : formatVND(balance),
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: isPositive ? AppColors.secondary : AppColors.danger,
                  ),
                ),
                Text(
                  isPositive ? 'Dư' : 'Thiếu',
                  style: TextStyle(
                    fontSize: 11,
                    color: isPositive ? AppColors.secondary : AppColors.danger,
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

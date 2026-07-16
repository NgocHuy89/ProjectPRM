import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../../models/finance_models.dart';
import '../../models/room_model.dart';
import '../../models/user_model.dart';
import '../../services/finance_service.dart';
import '../../services/room_service.dart';
import '../../utils/app_theme.dart';
import '../../widgets/common_widgets.dart';

class ReportsScreen extends StatefulWidget {
  final String roomId;
  final UserModel user;

  const ReportsScreen({super.key, required this.roomId, required this.user});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  final _financeService = FinanceService();
  final _roomService = RoomService();

  DateTime _selectedDate = DateTime.now();

  @override
  Widget build(BuildContext context) {
    final start = DateTime(_selectedDate.year, _selectedDate.month, 1);
    final end = DateTime(_selectedDate.year, _selectedDate.month + 1, 1);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Báo cáo & Thống kê'),
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_month, color: Colors.white),
            onPressed: () async {
              final picked = await showDatePicker(
                context: context,
                initialDate: _selectedDate,
                firstDate: DateTime(2020),
                lastDate: DateTime.now(),
              );
              if (picked != null) {
                setState(() => _selectedDate = picked);
              }
            },
          ),
        ],
      ),
      body: StreamBuilder<List<ExpenseModel>>(
        stream: _financeService.expensesStream(widget.roomId),
        builder: (context, expSnap) {
          if (expSnap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final allExpenses = expSnap.data ?? [];
          final monthlyExpenses = allExpenses.where((e) =>
              e.expenseDate.isAfter(start.subtract(const Duration(milliseconds: 1))) &&
              e.expenseDate.isBefore(end)).toList();

          return StreamBuilder<List<FundModel>>(
            stream: _financeService.fundsStream(widget.roomId),
            builder: (context, fundSnap) {
              if (fundSnap.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              final allFunds = fundSnap.data ?? [];
              final monthlyFunds = allFunds.where((f) =>
                  f.createdAt.isAfter(start.subtract(const Duration(milliseconds: 1))) &&
                  f.createdAt.isBefore(end)).toList();

              return StreamBuilder<List<MemberModel>>(
                stream: _roomService.membersStream(widget.roomId),
                builder: (context, memSnap) {
                  if (memSnap.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final members = memSnap.data ?? [];
                  return _buildContent(monthlyExpenses, monthlyFunds, members);
                },
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildContent(
    List<ExpenseModel> expenses,
    List<FundModel> funds,
    List<MemberModel> members,
  ) {
    double totalExpense = 0;
    Map<String, double> byCategory = {};

    for (var exp in expenses) {
      totalExpense += exp.totalAmount;
      byCategory[exp.category] = (byCategory[exp.category] ?? 0) + exp.totalAmount;
    }

    double totalIncome = 0;
    for (var fund in funds) {
      totalIncome += fund.currentBalance;
    }

    final balance = totalIncome - totalExpense;

    String topCategory = '';
    double maxCatAmount = 0;
    byCategory.forEach((key, value) {
      if (value > maxCatAmount) {
        maxCatAmount = value;
        topCategory = key;
      }
    });

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Container(
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
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                DateFormat('MMMM yyyy', 'vi').format(
                  DateTime(_selectedDate.year, _selectedDate.month),
                ),
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        _buildReportSummaryRow(
          totalExpense: totalExpense,
          totalIncome: totalIncome,
          balance: balance,
          expenseCount: expenses.length,
        ),
        const SizedBox(height: 20),
        if (totalExpense > 0) ...[
          const SectionHeader(title: 'Chi tiêu theo danh mục'),
          const SizedBox(height: 12),
          _buildCategoryChart(byCategory, totalExpense),
          const SizedBox(height: 20),
          if (topCategory.isNotEmpty)
            _buildTopCategoryCard(topCategory, byCategory),
          const SizedBox(height: 20),
        ],
        const SectionHeader(title: 'Tổng hợp thành viên'),
        const SizedBox(height: 12),
        ...members.map((e) => _buildMemberReportCard(e)),
        const SizedBox(height: 32),
      ],
    );
  }

  Widget _buildReportSummaryRow({
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
              child: _reportSummaryCard(
                label: 'Tổng chi',
                value: formatVND(totalExpense),
                icon: Icons.trending_down,
                color: AppColors.danger,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _reportSummaryCard(
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
              child: _reportSummaryCard(
                label: 'Số dư (quỹ-chi)',
                value: formatVND(balance),
                icon: Icons.account_balance,
                color: balance >= 0 ? AppColors.secondary : AppColors.danger,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _reportSummaryCard(
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

  Widget _reportSummaryCard({
    required String label,
    required String value,
    required IconData icon,
    required Color color,
  }) {
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
          Icon(icon, color: color, size: 22),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: color,
            ),
            overflow: TextOverflow.ellipsis,
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

  Widget _buildCategoryChart(Map<String, double> byCategory, double total) {
    final sorted = byCategory.entries.where((e) => e.value > 0).toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    
    if (sorted.isEmpty) return const SizedBox();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            SizedBox(
              height: 200,
              child: PieChart(
                PieChartData(
                  sectionsSpace: 0,
                  centerSpaceRadius: 40,
                  sections: sorted.map((entry) {
                    final pct = (entry.value / total) * 100;
                    return PieChartSectionData(
                      color: AppConstants.categoryColor(entry.key),
                      value: entry.value,
                      title: '${pct.toStringAsFixed(1)}%',
                      radius: 50,
                      titleStyle: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
            const SizedBox(height: 16),
            ...sorted.map((entry) {
              final pct = total > 0 ? entry.value / total : 0.0;
              final color = AppConstants.categoryColor(entry.key);
              final label =
                  AppConstants.categoryLabels[entry.key] ?? entry.key;

              return Padding(
                padding: const EdgeInsets.only(bottom: 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            label,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          formatVND(entry.value),
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: LinearProgressIndicator(
                        value: pct,
                        minHeight: 8,
                        backgroundColor: AppColors.divider,
                        color: color,
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildTopCategoryCard(String topCat, Map<String, double> byCategory) {
    final label = AppConstants.categoryLabels[topCat] ?? topCat;
    final amount = byCategory[topCat] ?? 0;
    final color = AppConstants.categoryColor(topCat);
    final icon = AppConstants.categoryIcons[topCat] ?? Icons.more_horiz;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: color),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Danh mục chi nhiều nhất',
                    style: TextStyle(
                      fontSize: 11,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  Text(
                    label,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            Text(
              formatVND(amount),
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMemberReportCard(MemberModel member) {
    final balance = member.balance;
    final isPositive = balance >= 0;

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        contentPadding: const EdgeInsets.all(12),
        leading: UserAvatar(
          imageUrl: member.avatarUrl,
          name: member.fullName,
          radius: 22,
        ),
        title: Text(
          member.fullName,
          style: const TextStyle(fontWeight: FontWeight.bold),
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Text(
          'Đã đóng: ${formatVND(member.totalContributed)} · Còn nợ: ${formatVND(member.totalOwed)}',
          style: const TextStyle(fontSize: 11),
          overflow: TextOverflow.ellipsis,
        ),
        trailing: Text(
          isPositive ? '+${formatVND(balance)}' : formatVND(balance),
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: isPositive ? AppColors.secondary : AppColors.danger,
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../../models/finance_models.dart';
import '../../models/user_model.dart';
import '../../models/room_model.dart';
import '../../services/auth_service.dart';
import '../../services/room_service.dart';
import '../../utils/app_theme.dart';
import '../../widgets/common_widgets.dart';
import '../expense/add_expense_screen.dart';
import '../expense/expense_list_screen.dart';
import '../expense/personal_expense_screen.dart';
import '../fund/create_fund_screen.dart';
import '../fund/fund_list_screen.dart';
import '../profile/view_profile_screen.dart';
import '../../services/notification_service.dart';
import 'notifications_screen.dart';
import 'reports_screen.dart';

class HeadDashboardScreen extends StatefulWidget {
  final UserModel user;

  const HeadDashboardScreen({super.key, required this.user});

  @override
  State<HeadDashboardScreen> createState() => _HeadDashboardScreenState();
}

class _HeadDashboardScreenState extends State<HeadDashboardScreen> {
  final RoomService _roomService = RoomService();
  final AuthService _authService = AuthService();
  int _selectedIndex = 0;
  late Future<Map<String, dynamic>> _dashboardStatsFuture;

  @override
  void initState() {
    super.initState();
    _dashboardStatsFuture = _getRoomStats();
  }

  Future<Map<String, dynamic>> _getRoomStats() async {
    try {
      if (widget.user.currentRoomId != null) {
        return await _roomService.getDashboardStats(widget.user.currentRoomId!);
      }
      return {};
    } catch (e) {
      print('Error loading dashboard stats: $e');
      return {};
    }
  }

  @override
  Widget build(BuildContext context) {
    final roomId = widget.user.currentRoomId;
    if (roomId == null || roomId.isEmpty) {
      return Scaffold(
        backgroundColor: AppColors.surface,
        body: _buildBody(null),
        bottomNavigationBar: _buildBottomNav(),
      );
    }

    return StreamBuilder<RoomModel?>(
      key: Key('room_$roomId'),
      stream: _roomService.roomStream(roomId),
      builder: (context, roomSnap) {
        if (roomSnap.hasError) {
          return Scaffold(
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 48, color: Colors.red),
                  const SizedBox(height: 16),
                  const Text('Lỗi kết nối dữ liệu'),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () => setState(() {
                      _dashboardStatsFuture = _getRoomStats();
                    }),
                    child: const Text('Thử lại'),
                  ),
                ],
              ),
            ),
          );
        }
        final room = roomSnap.data;
        return Scaffold(
          backgroundColor: AppColors.surface,
          body: _buildBody(room),
          bottomNavigationBar: _buildBottomNav(),
        );
      },
    );
  }

  Widget _buildBody(RoomModel? room) {
    switch (_selectedIndex) {
      case 0:
        return _buildHomeTab(room);
      case 1:
        return _buildMembersTab(room);
      case 2:
        return _buildFundsTab(room);
      case 3:
        return _buildReportsTab(room);
      case 4:
        return PersonalExpenseScreen(user: widget.user);
      default:
        return _buildHomeTab(room);
    }
  }

  // ── Home Tab ──────────────────────────────────
  Widget _buildHomeTab(RoomModel? room) {
    return CustomScrollView(
      slivers: [
        _buildSliverAppBar(room),
        SliverPadding(
          padding: const EdgeInsets.all(16),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              // Stat cards
              FutureBuilder<Map<String, dynamic>>(
                future: _dashboardStatsFuture,
                builder: (context, statsSnap) {
                  final stats = statsSnap.data ?? {};
                  if (statsSnap.hasError) {
                    return const SizedBox(
                      height: 100,
                      child: Center(child: Text('Không thể tải thống kê')),
                    );
                  }
                  return GridView.count(
                    crossAxisCount: 2,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 1.4,
                    children: [
                      StatCard(
                        title: 'Chi tháng này',
                        value: formatVND(
                          (stats['totalExpenseThisMonth'] as double?) ?? 0,
                        ),
                        icon: Icons.receipt_long,
                        color: AppColors.danger,
                        onTap: () => setState(() => _selectedIndex = 2),
                      ),
                      StatCard(
                        title: 'Số dư quỹ',
                        value: formatVND(
                          (stats['totalFundBalance'] as double?) ?? 0,
                        ),
                        icon: Icons.account_balance_wallet,
                        color: AppColors.secondary,
                        onTap: () => setState(() => _selectedIndex = 2),
                      ),
                      StatCard(
                        title: 'Chưa đóng tiền',
                        value:
                            '${(stats['unpaidMemberCount'] as int?) ?? 0} người',
                        icon: Icons.warning_amber_rounded,
                        color: AppColors.warning,
                        onTap: () => setState(() => _selectedIndex = 1),
                      ),
                      StatCard(
                        title: 'Quỹ đang hoạt động',
                        value: '${(stats['activeFundCount'] as int?) ?? 0} quỹ',
                        icon: Icons.savings,
                        color: AppColors.primary,
                        onTap: () => setState(() => _selectedIndex = 2),
                      ),
                    ],
                  );
                },
              ),
              const SizedBox(height: 20),

              // Members preview
              SectionHeader(
                title: 'Thành viên',
                actionLabel: 'Xem tất cả',
                onAction: () => setState(() => _selectedIndex = 1),
              ),
              const SizedBox(height: 12),
              if (room != null)
                StreamBuilder<List<MemberModel>>(
                  key: Key('members_${room.roomId}'),
                  stream: _roomService.membersStream(room.roomId),
                  builder: (ctx, snap) {
                    if (snap.hasError) {
                      return const SizedBox.shrink();
                    }
                    final members = snap.data ?? [];
                    if (members.isEmpty) {
                      return const SizedBox.shrink();
                    }
                    return SizedBox(
                      height: 80,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: members.length,
                        itemBuilder: (ctx, i) => _memberChip(members[i]),
                      ),
                    );
                  },
                ),
              const SizedBox(height: 20),

              // Quick actions
              SectionHeader(title: 'Thao tác nhanh'),
              const SizedBox(height: 12),
              _buildQuickActions(room),
              const SizedBox(height: 80),
            ]),
          ),
        ),
      ],
    );
  }

  // ── FIX 1: expandedHeight 180→200, padding top 60→56
  // Thêm SingleChildScrollView + mainAxisSize.min để tránh overflow khi pinned
  Widget _buildSliverAppBar(RoomModel? room) {
    return SliverAppBar(
      expandedHeight: 200,
      pinned: true,
      backgroundColor: AppColors.primaryDark,
      actions: [
        StreamBuilder<int>(
          stream: NotificationService().getUnreadCountStream(widget.user.uid),
          builder: (context, snapshot) {
            final unreadCount = snapshot.data ?? 0;
            return Stack(
              alignment: Alignment.center,
              children: [
                IconButton(
                  icon: const Icon(Icons.notifications_none, color: Colors.white),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => NotificationsScreen(userId: widget.user.uid),
                      ),
                    );
                  },
                ),
                if (unreadCount > 0)
                  Positioned(
                    right: 8,
                    top: 12,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                      ),
                      child: Text(
                        unreadCount > 9 ? '9+' : '$unreadCount',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
        if (room != null)
          IconButton(
            icon: const Icon(Icons.share, color: Colors.white),
            tooltip: 'Chia sẻ mã phòng',
            onPressed: () => _showJoinCode(room.joinCode),
          ),
        const SizedBox(width: 8),
      ],
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [AppColors.primaryDark, AppColors.primary],
            ),
          ),
          padding: const EdgeInsets.fromLTRB(20, 56, 20, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.end,
            mainAxisSize: MainAxisSize.min, // ✅ không chiếm toàn bộ height
            children: [
              Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            ViewProfileScreen(userId: widget.user.uid),
                      ),
                    ),
                    child: UserAvatar(
                      imageUrl: widget.user.avatarUrl,
                      name: widget.user.fullName,
                      radius: 22, // ✅ giảm từ 26→22 để tiết kiệm chiều cao
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded( // ✅ bọc Expanded để tránh overflow ngang
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Xin chào, ${widget.user.fullName.split(' ').last} 👋',
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 12,
                          ),
                          overflow: TextOverflow.ellipsis, // ✅ cắt nếu quá dài
                        ),
                        const Text(
                          'Trưởng phòng',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.logout, color: Colors.white),
                    onPressed: () async {
                      try {
                        await _authService.logout();
                      } catch (e) {
                        debugPrint('Logout error: $e');
                      }
                    },
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                room?.roomName ?? 'Chưa có phòng',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
                overflow: TextOverflow.ellipsis, // ✅ cắt nếu tên phòng quá dài
              ),
              if (room?.address != null)
                Text(
                  room!.address!,
                  style: const TextStyle(color: Colors.white60, fontSize: 12),
                  overflow: TextOverflow.ellipsis, // ✅ cắt nếu địa chỉ quá dài
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _memberChip(MemberModel member) {
    return Padding(
      padding: const EdgeInsets.only(right: 16),
      child: Column(
        children: [
          UserAvatar(
            imageUrl: member.avatarUrl,
            name: member.fullName,
            radius: 26,
          ),
          const SizedBox(height: 6),
          Text(
            member.fullName.split(' ').last,
            style: const TextStyle(
              fontSize: 11,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions(RoomModel? room) {
    final actions = [
      _QuickAction(
        label: 'Thêm chi tiêu',
        icon: Icons.add_shopping_cart,
        color: AppColors.danger,
        onTap: () {
          if (room == null) {
            _showComingSoon('Thêm chi tiêu');
            return;
          }
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => AddExpenseScreen(
                roomId: room.roomId,
                user: widget.user,
              ),
            ),
          );
        },
      ),
      _QuickAction(
        label: 'Tạo quỹ',
        icon: Icons.savings,
        color: AppColors.secondary,
        onTap: () {
          if (room == null) {
            _showComingSoon('Tạo quỹ');
            return;
          }
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => CreateFundScreen(
                roomId: room.roomId,
                createdBy: widget.user.uid,
              ),
            ),
          );
        },
      ),
      _QuickAction(
        label: 'Thêm thành viên',
        icon: Icons.person_add,
        color: AppColors.primary,
        onTap: () => setState(() => _selectedIndex = 1),
      ),
      _QuickAction(
        label: 'Báo cáo',
        icon: Icons.bar_chart,
        color: AppColors.warning,
        onTap: () => setState(() => _selectedIndex = 3),
      ),
    ];

    return GridView.count(
      crossAxisCount: 4,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 8,
      children: actions.map((a) => _quickActionItem(a)).toList(),
    );
  }

  Widget _quickActionItem(_QuickAction action) {
    return GestureDetector(
      onTap: action.onTap,
      child: Column(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: action.color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(action.icon, color: action.color, size: 26),
          ),
          const SizedBox(height: 6),
          Text(
            action.label,
            style: const TextStyle(
              fontSize: 10,
              color: AppColors.textSecondary,
            ),
            textAlign: TextAlign.center,
            overflow: TextOverflow.ellipsis, // ✅
          ),
        ],
      ),
    );
  }

  // ── Members Tab ───────────────────────────────
  Widget _buildMembersTab(RoomModel? room) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Quản lý thành viên'),
        automaticallyImplyLeading: false,
        actions: [
          if (room != null)
            IconButton(
              icon: const Icon(Icons.person_add, color: Colors.white),
              onPressed: () => _showJoinCode(room.joinCode),
            ),
        ],
      ),
      body: room == null
          ? const EmptyState(icon: Icons.group_off, title: 'Chưa có phòng')
          : StreamBuilder<List<MemberModel>>(
              stream: _roomService.membersStream(room.roomId),
              builder: (ctx, snap) {
                if (snap.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                final members = snap.data ?? [];
                if (members.isEmpty) {
                  return const EmptyState(
                    icon: Icons.group,
                    title: 'Chưa có thành viên',
                  );
                }
                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: members.length,
                  itemBuilder: (ctx, i) => _memberCard(members[i], room),
                );
              },
            ),
    );
  }

  // ── FIX 2: bọc Expanded cho title Row, thêm Flexible cho subtitle
  Widget _memberCard(MemberModel member, RoomModel room) {
    final isHead = member.userId == room.headId;
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        contentPadding: const EdgeInsets.all(12),
        leading: UserAvatar(
          imageUrl: member.avatarUrl,
          name: member.fullName,
          radius: 24,
        ),
        title: Row(
          children: [
            // ✅ Expanded để tên không tràn ra ngoài
            Expanded(
              child: Text(
                member.fullName,
                style: const TextStyle(fontWeight: FontWeight.bold),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (isHead) ...[
              const SizedBox(width: 6),
              // ✅ Flexible để badge không bị đẩy ra ngoài khi tên dài
              Flexible(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Text(
                    'Trưởng phòng',
                    style: TextStyle(
                      fontSize: 10,
                      color: AppColors.primary,
                      fontWeight: FontWeight.bold,
                    ),
                    overflow: TextOverflow.ellipsis, // ✅
                  ),
                ),
              ),
            ],
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            // ✅ Row miniStat bọc trong IntrinsicWidth để không overflow
            Row(
              children: [
                Expanded( // ✅
                  child: _miniStat(
                    'Đã đóng',
                    formatVND(member.totalContributed),
                    AppColors.secondary,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded( // ✅
                  child: _miniStat(
                    'Còn nợ',
                    formatVND(member.totalOwed),
                    AppColors.danger,
                  ),
                ),
              ],
            ),
            Text(
              'Tham gia: ${DateFormat('dd/MM/yyyy').format(member.joinedAt)}',
              style: const TextStyle(
                fontSize: 11,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
        trailing: !isHead
            ? PopupMenuButton<String>(
                onSelected: (val) {
                  if (val == 'remove') _confirmRemoveMember(member, room);
                  if (val == 'transfer_head') {
                    _confirmTransferHead(member, room);
                  }
                },
                itemBuilder: (_) => [
                  const PopupMenuItem(
                    value: 'transfer_head',
                    child: Row(
                      children: [
                        Icon(Icons.admin_panel_settings_outlined, color: Colors.green),
                        SizedBox(width: 8),
                        Text('Nhường chức', style: TextStyle(color: Colors.green)),
                      ],
                    ),
                  ),

                  const PopupMenuItem(
                    value: 'remove',
                    child: Row(
                      children: [
                        Icon(Icons.remove_circle_outline, color: Colors.red),
                        SizedBox(width: 8),
                        Text(
                          'Xoá khỏi phòng',
                          style: TextStyle(color: Colors.red),
                        ),
                      ],
                    ),
                  ),
                ],
              )
            : null,
      ),
    );
  }

  Widget _miniStat(String label, String value, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 10, color: AppColors.textSecondary),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 12,
            color: color,
            fontWeight: FontWeight.bold,
          ),
          overflow: TextOverflow.ellipsis, // ✅
        ),
      ],
    );
  }

  // ── Funds Tab ─────────────────────────────────
  Widget _buildFundsTab(RoomModel? room) {
    if (room != null) {
      return DefaultTabController(
        length: 2,
        child: Scaffold(
          appBar: AppBar(
            title: const Text('Quỹ & Chi tiêu'),
            automaticallyImplyLeading: false,
            bottom: const TabBar(
              tabs: [
                Tab(icon: Icon(Icons.savings_outlined), text: 'Quỹ chung'),
                Tab(icon: Icon(Icons.receipt_long_outlined), text: 'Chi tiêu'),
              ],
            ),
          ),
          body: TabBarView(
            children: [
              FundListScreen(
                user: widget.user,
                roomId: room.roomId,
                isHead: true,
                showAppBar: false,
              ),
              ExpenseListScreen(
                user: widget.user,
                roomId: room.roomId,
                isHead: true,
                showAppBar: false,
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Quản lý quỹ & Chi tiêu'),
        automaticallyImplyLeading: false,
        actions: [
          if (room != null)
            IconButton(
              icon: const Icon(Icons.add, color: Colors.white),
              onPressed: () => _showComingSoon('Tạo quỹ mới'),
            ),
        ],
      ),
      body: const Center(
        child: EmptyState(
          icon: Icons.savings,
          title: 'Quản lý quỹ',
          subtitle: 'Tạo phòng trước khi quản lý quỹ và chi tiêu.',
        ),
      ),
      floatingActionButton: null,
    );
  }

  Widget _buildMockFundCard(FundModel fund) {
    final paidCount = fund.memberStatus.values.where((s) => s == 'paid').length;
    final totalMembers = fund.memberStatus.length;
    final progress = fund.progressPercent;

    return Card(
      margin: const EdgeInsets.only(bottom: 14),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
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
                        ),
                        overflow: TextOverflow.ellipsis, // ✅
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
                    color: progress >= 1
                        ? AppColors.secondary.withValues(alpha: 0.12)
                        : AppColors.warning.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    progress >= 1 ? 'Đủ quỹ' : '$paidCount/$totalMembers đóng',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: progress >= 1
                          ? AppColors.secondary
                          : AppColors.warning,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
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
                        color: AppColors.primary,
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
                        ),
                      ),
                    ],
                  ),
              ],
            ),
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 8,
                backgroundColor: AppColors.divider,
                color: AppColors.secondary,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              '${(progress * 100).toStringAsFixed(0)}% hoàn thành',
              style: const TextStyle(
                fontSize: 11,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMockExpenseTile(ExpenseModel expense) {
    final catLabel =
        AppConstants.categoryLabels[expense.category] ?? expense.category;
    final catIcon =
        AppConstants.categoryIcons[expense.category] ?? Icons.more_horiz;
    final catColor = AppConstants.categoryColor(expense.category);

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        leading: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: catColor.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(catIcon, color: catColor, size: 22),
        ),
        title: Text(
          expense.title,
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
          overflow: TextOverflow.ellipsis, // ✅
        ),
        subtitle: Text(
          '$catLabel · ${expense.paidByName} trả · ${DateFormat('dd/MM').format(expense.expenseDate)}',
          style: const TextStyle(fontSize: 11),
          overflow: TextOverflow.ellipsis, // ✅
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              formatVND(expense.totalAmount),
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: expense.isPersonalNote ? AppColors.danger : AppColors.secondary,
                fontSize: 14,
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
      ),
    );
  }

  // ── Reports Tab ───────────────────────────────
  Widget _buildReportsTab(RoomModel? room) {
    if (room != null) {
      return ReportsScreen(roomId: room.roomId, user: widget.user);
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Báo cáo & Thống kê'),
        automaticallyImplyLeading: false,
      ),
      body: const Center(
        child: EmptyState(
          icon: Icons.bar_chart,
          title: 'Chưa có phòng',
          subtitle: 'Tạo hoặc tham gia phòng để xem báo cáo thống kê.',
        ),
      ),
    );
  }

  // ── Bottom Nav ────────────────────────────────
  Widget _buildBottomNav() {
    return NavigationBar(
      selectedIndex: _selectedIndex,
      onDestinationSelected: (i) => setState(() => _selectedIndex = i),
      backgroundColor: Colors.white,
      indicatorColor: AppColors.primary.withValues(alpha: 0.12),
      destinations: const [
        NavigationDestination(
          icon: Icon(Icons.home_outlined),
          selectedIcon: Icon(Icons.home),
          label: 'Tổng quan',
        ),
        NavigationDestination(
          icon: Icon(Icons.group_outlined),
          selectedIcon: Icon(Icons.group),
          label: 'Thành viên',
        ),
        NavigationDestination(
          icon: Icon(Icons.account_balance_wallet_outlined),
          selectedIcon: Icon(Icons.account_balance_wallet),
          label: 'Quỹ',
        ),
        NavigationDestination(
          icon: Icon(Icons.bar_chart_outlined),
          selectedIcon: Icon(Icons.bar_chart),
          label: 'Báo cáo',
        ),
        NavigationDestination(
          icon: Icon(Icons.account_balance_wallet_outlined),
          selectedIcon: Icon(Icons.account_balance_wallet),
          label: 'Cá nhân',
        ),
      ],
    );
  }

  // ── Helpers ───────────────────────────────────
  void _showJoinCode(String code) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Mã tham gia phòng'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Chia sẻ mã này để thêm thành viên:'),
            const SizedBox(height: 16),
            GestureDetector(
              onTap: () => _copyCode(code),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  vertical: 16,
                  horizontal: 32,
                ),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppColors.primary.withValues(alpha: 0.3),
                  ),
                ),
                child: Text(
                  code,
                  style: const TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 8,
                    color: AppColors.primaryDark,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              'Nhấn vào mã để sao chép',
              style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
            ),
          ],
        ),
        actions: [
          TextButton.icon(
            onPressed: () => _copyCode(code),
            icon: const Icon(Icons.copy, size: 18),
            label: const Text('Sao chép'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Đóng'),
          ),
        ],
      ),
    );
  }

  void _copyCode(String code) {
    Clipboard.setData(ClipboardData(text: code));
    if (Navigator.canPop(context)) Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white, size: 18),
            const SizedBox(width: 8),
            Text('Đã sao chép mã: $code'),
          ],
        ),
        backgroundColor: AppColors.secondary,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Future<void> _confirmRemoveMember(MemberModel member, RoomModel room) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Xoá thành viên'),
        content: Text('Bạn có chắc muốn xoá ${member.fullName} khỏi phòng?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Huỷ'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Xoá', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirm == true) {

      try {
        await _roomService.removeMember(
          roomId: room.roomId,
          userId: member.userId,
        );
        if (!mounted) return;
        setState(() {
          _dashboardStatsFuture = _getRoomStats();
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Đã xoá ${member.fullName} khỏi phòng'),
            backgroundColor: AppColors.secondary,
            behavior: SnackBarBehavior.floating,
          ),
        );
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Không thể xoá thành viên: $e'),
            backgroundColor: AppColors.danger,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _confirmTransferHead(MemberModel member, RoomModel room) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Nhường chức trưởng phòng'),
        content: Text(
          'Bạn có chắc muốn nhường chức trưởng phòng cho ${member.fullName} không?\n'
          'Sau khi nhường chức, bạn sẽ trở thành thành viên bình thường.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Huỷ'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              'Nhường chức',
              style: TextStyle(color: AppColors.secondary),
            ),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      await _roomService.transferHeadRole(
        roomId: room.roomId,
        currentHeadId: widget.user.uid,
        newHeadId: member.userId,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Đã nhường chức trưởng phòng cho ${member.fullName}'),
          backgroundColor: AppColors.secondary,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Không thể nhường chức: $e'),
          backgroundColor: AppColors.danger,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _showComingSoon(String feature) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$feature: sẽ triển khai ở bước tiếp theo'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}

class _QuickAction {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  _QuickAction({
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
  });
}

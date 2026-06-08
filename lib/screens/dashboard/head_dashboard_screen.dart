import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/user_model.dart';
import '../../models/room_model.dart';
import '../../services/auth_service.dart';
import '../../services/room_service.dart';
import '../../utils/app_theme.dart';
import '../../widgets/common_widgets.dart';
import '../profile/view_profile_screen.dart';

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
    return StreamBuilder<RoomModel?>(
      key: Key('room_${widget.user.currentRoomId}'),
      stream: _roomService.roomStream(widget.user.currentRoomId ?? ''),
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

  Widget _buildSliverAppBar(RoomModel? room) {
    return SliverAppBar(
      expandedHeight: 180,
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
          padding: const EdgeInsets.fromLTRB(20, 60, 20, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.end,
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
                      radius: 26,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Xin chào, ${widget.user.fullName.split(' ').last} 👋',
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 13,
                          ),
                        ),
                        const Text(
                          'Trưởng phòng',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.logout, color: Colors.white70),
                    onPressed: () async {
                      await _authService.logout();
                    },
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                room?.roomName ?? 'Chưa có phòng',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (room?.address != null)
                Text(
                  room!.address!,
                  style: const TextStyle(color: Colors.white60, fontSize: 12),
                ),
            ],
          ),
        ),
      ),
      actions: [
        if (room != null)
          IconButton(
            icon: const Icon(Icons.share, color: Colors.white),
            tooltip: 'Chia sẻ mã phòng',
            onPressed: () => _showJoinCode(room.joinCode),
          ),
      ],
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
        onTap: () => _showComingSoon('Thêm chi tiêu'),
      ),
      _QuickAction(
        label: 'Đóng quỹ',
        icon: Icons.savings,
        color: AppColors.secondary,
        onTap: () => _showComingSoon('Đóng quỹ'),
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
            Text(
              member.fullName,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            if (isHead) ...[
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
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
                ),
              ),
            ],
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Row(
              children: [
                _miniStat(
                  'Đã đóng',
                  formatVND(member.totalContributed),
                  AppColors.secondary,
                ),
                const SizedBox(width: 12),
                _miniStat(
                  'Còn nợ',
                  formatVND(member.totalOwed),
                  AppColors.danger,
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
                },
                itemBuilder: (_) => [
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
        ),
      ],
    );
  }

  // ── Funds Tab ─────────────────────────────────
  Widget _buildFundsTab(RoomModel? room) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Quản lý quỹ & Chi tiêu'),
        automaticallyImplyLeading: false,
      ),
      body: const Center(
        child: EmptyState(
          icon: Icons.savings,
          title: 'Quản lý quỹ',
          subtitle: 'Màn hình này sẽ được\ntriển khai ở nhóm Fund & Expense',
        ),
      ),
    );
  }

  // ── Reports Tab ───────────────────────────────
  Widget _buildReportsTab(RoomModel? room) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Báo cáo & Thống kê'),
        automaticallyImplyLeading: false,
      ),
      body: const Center(
        child: EmptyState(
          icon: Icons.bar_chart,
          title: 'Báo cáo thống kê',
          subtitle: 'Màn hình này sẽ được\ntriển khai ở nhóm Reports',
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
            Container(
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 32),
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
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Đóng'),
          ),
        ],
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
      await RoomService().removeMember(
        roomId: room.roomId,
        userId: member.userId,
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

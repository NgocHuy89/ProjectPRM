import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/user_model.dart';
import '../../models/room_model.dart';
import '../../services/auth_service.dart';
import '../../services/room_service.dart';
import '../../utils/app_theme.dart';
import '../../widgets/common_widgets.dart';
import '../profile/view_profile_screen.dart';

class MemberDashboardScreen extends StatefulWidget {
  final UserModel user;

  const MemberDashboardScreen({super.key, required this.user});

  @override
  State<MemberDashboardScreen> createState() => _MemberDashboardScreenState();
}

class _MemberDashboardScreenState extends State<MemberDashboardScreen> {
  final RoomService _roomService = RoomService();
  final AuthService _authService = AuthService();
  int _selectedIndex = 0;

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
                    onPressed: () => setState(() {}),
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
        return _buildFundsTab(room);
      case 2:
        return _buildExpensesTab(room);
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
              // My contribution card
              _buildMyContributionCard(room),
              const SizedBox(height: 20),

              // Room info
              if (room != null) ...[
                SectionHeader(title: 'Thông tin phòng'),
                const SizedBox(height: 12),
                _buildRoomInfoCard(room),
                const SizedBox(height: 20),
              ],

              // Members
              SectionHeader(
                title: 'Các thành viên',
                actionLabel: 'Xem tất cả',
                onAction: () => setState(() => _selectedIndex = 0),
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
                    return _buildMembersRow(members);
                  },
                ),
              const SizedBox(height: 80),
            ]),
          ),
        ),
      ],
    );
  }

  Widget _buildSliverAppBar(RoomModel? room) {
    return SliverAppBar(
      expandedHeight: 160,
      pinned: true,
      backgroundColor: AppColors.primary,
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF2E5FA3), AppColors.primary],
            ),
          ),
          padding: const EdgeInsets.fromLTRB(20, 56, 20, 16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Text(
                      'Xin chào, ${widget.user.fullName.split(' ').last} 👋',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      room?.roomName ?? 'Chưa vào phòng',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (room?.address != null)
                      Text(
                        room!.address!,
                        style: const TextStyle(
                          color: Colors.white60,
                          fontSize: 12,
                        ),
                      ),
                  ],
                ),
              ),
              GestureDetector(
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ViewProfileScreen(userId: widget.user.uid),
                  ),
                ),
                child: UserAvatar(
                  imageUrl: widget.user.avatarUrl,
                  name: widget.user.fullName,
                  radius: 28,
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.logout, color: Colors.white70),
          onPressed: () async => _authService.logout(),
        ),
      ],
    );
  }

  Widget _buildMyContributionCard(RoomModel? room) {
    if (room == null) return const SizedBox.shrink();

    return StreamBuilder<List<MemberModel>>(
      key: Key('me_${room.roomId}'),
      stream: _roomService.membersStream(room.roomId),
      builder: (ctx, snap) {
        if (snap.hasError) {
          return const SizedBox.shrink();
        }
        final me = snap.data?.firstWhere(
          (m) => m.userId == widget.user.uid,
          orElse: () => MemberModel(
            userId: widget.user.uid,
            fullName: widget.user.fullName,
            role: 'member',
            joinedAt: DateTime.now(),
          ),
        );

        return Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [AppColors.primary, Color(0xFF2E5FA3)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.3),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Tổng quan của tôi',
                style: TextStyle(color: Colors.white70, fontSize: 13),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _contributionItem(
                      label: 'Đã đóng',
                      value: formatVND(me?.totalContributed ?? 0),
                      icon: Icons.check_circle_outline,
                    ),
                  ),
                  Container(width: 1, height: 48, color: Colors.white24),
                  Expanded(
                    child: _contributionItem(
                      label: 'Còn nợ',
                      value: formatVND(me?.totalOwed ?? 0),
                      icon: Icons.warning_amber_outlined,
                    ),
                  ),
                  Container(width: 1, height: 48, color: Colors.white24),
                  Expanded(
                    child: _contributionItem(
                      label: 'Chênh lệch',
                      value: formatVND(me?.balance ?? 0),
                      icon: Icons.account_balance,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                'Tham gia: ${DateFormat('dd/MM/yyyy').format(me?.joinedAt ?? DateTime.now())}',
                style: const TextStyle(color: Colors.white54, fontSize: 11),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _contributionItem({
    required String label,
    required String value,
    required IconData icon,
  }) {
    return Column(
      children: [
        Icon(icon, color: Colors.white70, size: 18),
        const SizedBox(height: 6),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 13,
          ),
        ),
        Text(
          label,
          style: const TextStyle(color: Colors.white60, fontSize: 11),
        ),
      ],
    );
  }

  Widget _buildRoomInfoCard(RoomModel room) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            InfoRow(
              icon: Icons.people,
              label: 'Số thành viên',
              value: '${room.memberCount}/${room.maxMembers} người',
            ),
            const Divider(height: 1),
            if (room.monthlyRent != null)
              InfoRow(
                icon: Icons.home,
                label: 'Tiền thuê/tháng',
                value: formatVND(room.monthlyRent!),
              ),
            if (room.rentDueDay != null) ...[
              const Divider(height: 1),
              InfoRow(
                icon: Icons.calendar_today,
                label: 'Ngày đóng tiền',
                value: 'Ngày ${room.rentDueDay} hàng tháng',
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildMembersRow(List<MemberModel> members) {
    return SizedBox(
      height: 96,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: members.length,
        itemBuilder: (ctx, i) {
          final m = members[i];
          return Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Column(
              children: [
                Stack(
                  children: [
                    UserAvatar(
                      imageUrl: m.avatarUrl,
                      name: m.fullName,
                      radius: 28,
                    ),
                    if (m.isHead)
                      Positioned(
                        right: 0,
                        bottom: 0,
                        child: Container(
                          width: 16,
                          height: 16,
                          decoration: const BoxDecoration(
                            color: AppColors.warning,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.star,
                            size: 10,
                            color: Colors.white,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  m.fullName.split(' ').last,
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  // ── Funds Tab ─────────────────────────────────
  Widget _buildFundsTab(RoomModel? room) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Quỹ chung'),
        automaticallyImplyLeading: false,
      ),
      body: const Center(
        child: EmptyState(
          icon: Icons.savings,
          title: 'Quỹ chung',
          subtitle: 'Sẽ được triển khai\nở nhóm Fund & Expense',
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {},
        icon: const Icon(Icons.add),
        label: const Text('Đóng tiền quỹ'),
        backgroundColor: AppColors.primary,
      ),
    );
  }

  // ── Expenses Tab ──────────────────────────────
  Widget _buildExpensesTab(RoomModel? room) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Chi tiêu chung'),
        automaticallyImplyLeading: false,
      ),
      body: const Center(
        child: EmptyState(
          icon: Icons.receipt_long,
          title: 'Chi tiêu chung',
          subtitle: 'Sẽ được triển khai\nở nhóm Fund & Expense',
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
          icon: Icon(Icons.savings_outlined),
          selectedIcon: Icon(Icons.savings),
          label: 'Quỹ',
        ),
        NavigationDestination(
          icon: Icon(Icons.receipt_long_outlined),
          selectedIcon: Icon(Icons.receipt_long),
          label: 'Chi tiêu',
        ),
      ],
    );
  }
}

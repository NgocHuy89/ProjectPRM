const fs = require('fs');

let content = fs.readFileSync('lib/screens/dashboard/head_dashboard_screen.dart', 'utf8');

// Use split/join or robust replace for Windows newlines
content = content.replace(/  bool get _useDevData => widget\.user\.uid == HeadDevMockData\.devUid;[\r\n]+/, '');
content = content.replace(/import '\.\.\/\.\.\/data\/head_dev_mock_data\.dart';[\r\n]+/, '');

// Fix _dashboardStatsFuture
content = content.replace(
  /    _dashboardStatsFuture = _useDevData[\r\n\s]+\? Future\.value\(HeadDevMockData\.stats\)[\r\n\s]+: _getRoomStats\(\);/,
  '    _dashboardStatsFuture = _getRoomStats();'
);

// Fix build method branch
content = content.replace(
  /    if \(_useDevData\) \{[\s\S]*?body: _buildBody\(HeadDevMockData\.room\),[\s\S]*?\}\s+/,
  ''
);

// Fix members preview in home tab
content = content.replace(
  /              if \(_useDevData\)[\s\S]*?_memberChip\(HeadDevMockData\.members\[i\]\),[\s\S]*?\)\s+else if \(room != null\)/,
  '              if (room != null)'
);

// Fix quick actions
content = content.replace(
  /          if \(room == null || _useDevData\) \{/g,
  '          if (room == null) {'
);

// Fix _buildMembersTab
content = content.replace(
  /      body: _useDevData[\s\S]*?_memberCard\(HeadDevMockData\.members\[i\], HeadDevMockData\.room\),[\s\S]*?\)\s+: room == null/,
  '      body: room == null'
);

// Fix _buildFundsTab
const fundsTabRegex = /  \/\/ ── Funds Tab ─────────────────────────────────[\s\S]*?Widget _buildFundsTab\(RoomModel\? room\) \{[\s\S]*?if \(!_useDevData && room != null\) \{[\s\S]*?return Scaffold\([\s\S]*?title: const Text\('Quản lý quỹ & Chi tiêu'\),[\s\S]*?body: _useDevData[\s\S]*?HeadDevMockData\.funds\.map\(_buildMockFundCard\)[\s\S]*?HeadDevMockData\.expenses\.map\(_buildMockExpenseTile\)[\s\S]*?\: null,[\s\S]*?\);[\s\S]*?\}/;
const fundsTabNew = `  // ── Funds Tab ─────────────────────────────────
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
      ),
      body: const Center(
        child: EmptyState(
          icon: Icons.savings,
          title: 'Quản lý quỹ',
          subtitle: 'Tạo phòng trước khi quản lý quỹ và chi tiêu.',
        ),
      ),
    );
  }`;
content = content.replace(fundsTabRegex, fundsTabNew);

// Fix _buildReportsTab
const reportsTabRegex = /  \/\/ ── Reports Tab ───────────────────────────────[\s\S]*?Widget _buildReportsTab\(RoomModel\? room\) \{[\s\S]*?if \(!_useDevData\) \{[\s\S]*?final data = HeadDevMockData\.monthlyReport;[\s\S]*?HeadDevMockData\.members\.map\(_buildMemberReportCard\)[\s\S]*?\]\s*,\s*\)[\s\S]*?\);[\s\S]*?\}/;
const reportsTabNew = `  // ── Reports Tab ───────────────────────────────
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
          subtitle: 'Màn hình này sẽ được\\ntriển khai ở nhóm Reports',
        ),
      ),
    );
  }`;
content = content.replace(reportsTabRegex, reportsTabNew);

// Remove mock functions
content = content.replace(/  Widget _buildReportSummaryRow\([\s\S]*?Widget _buildMemberReportCard\(MemberModel member\) \{[\s\S]*?\}[\r\n\s]+Widget _buildMockFundCard/m, '  Widget _buildMockFundCard');
content = content.replace(/  Widget _buildMockFundCard[\s\S]*?Widget _buildMockExpenseTile[\s\S]*?\}\s*?(?=  \/\/ ── Reports Tab)/, '');
content = content.replace(/  Widget _buildReportSummaryRow[\s\S]*?Widget _buildMemberReportCard[\s\S]*?\}\s*?(?=  \/\/ ── Tùy chọn thành viên)/, '');

// Fix _confirmRemoveMember (remove the dev data check)
const removeMemberRegex = /    if \(confirm == true\) \{[\s\S]*?if \(_useDevData\) \{[\s\S]*?HeadDevMockData\.members\.removeWhere[\s\S]*?return;\s*\}[\s\S]*?try \{/;
const removeMemberNew = `    if (confirm == true) {\n      try {`;
content = content.replace(removeMemberRegex, removeMemberNew);

// Find missing mock function definitions and remove them
content = content.replace(/  Widget _buildMockFundCard[\s\S]*?Widget _buildBottomNav/m, '  // ── Bottom Nav ────────────────────────────────\n  Widget _buildBottomNav');

fs.writeFileSync('lib/screens/dashboard/head_dashboard_screen.dart', content);
console.log('Fixed head_dashboard_screen.dart completely');

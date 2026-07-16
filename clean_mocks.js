const fs = require('fs');
let code = fs.readFileSync('lib/screens/dashboard/head_dashboard_screen.dart', 'utf8');

function removeBlock(startRegex, endRegex, replacement = '') {
    const startMatch = code.match(startRegex);
    const endMatch = code.match(endRegex);
    if (startMatch && endMatch && startMatch.index < endMatch.index) {
        code = code.substring(0, startMatch.index) + replacement + code.substring(endMatch.index);
    } else {
        console.log("Failed to find block:", startRegex, "to", endRegex);
    }
}

code = code.replace("import '../../data/head_dev_mock_data.dart';\n", "");
code = code.replace(/  bool get _useDevData => false;\n/, "");
code = code.replace(/_dashboardStatsFuture = _useDevData\s*\?\s*Future\.value\(HeadDevMockData\.stats\)\s*:\s*_getRoomStats\(\);/, "_dashboardStatsFuture = _getRoomStats();");

removeBlock(/    if \(_useDevData\) \{/, /    final roomId = widget\.user\.currentRoomId;/, "    final roomId = widget.user.currentRoomId;");
removeBlock(/              if \(_useDevData\)/, /              else if \(room != null\)/, "              if (room != null)");
removeBlock(/      body: _useDevData/, /          : room == null/, "      body: room == null");
removeBlock(/        actions: \[\n          if \(_useDevData \|\| room != null\)/, /        \],/, "        actions: [\n          if (room != null)\n            IconButton(\n              icon: const Icon(Icons.add, color: Colors.white),\n              onPressed: () => _showComingSoon('Tạo quỹ mới'),\n            ),\n        ],");
removeBlock(/      body: _useDevData/, /          : const Center\(/, "      body: const Center(");
removeBlock(/      floatingActionButton: _useDevData/, /          : null,/, "      floatingActionButton: null,");
removeBlock(/  Widget _buildMockFundCard/, /  \/\/ ── Reports Tab/, "  // ── Reports Tab");

const reportsTabReplacement = `  Widget _buildReportsTab(RoomModel? room) {
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
  }

`;
removeBlock(/  Widget _buildReportsTab/, /  Future<void> _confirmRemoveMember/, reportsTabReplacement + "  Future<void> _confirmRemoveMember");

code = code.replace(/      if \(_useDevData\) \{\n        _showComingSoon\('Xoá thành viên'\);\n        return;\n      \}\n/, "");

fs.writeFileSync('lib/screens/dashboard/head_dashboard_screen.dart', code);
console.log("Done cleaning mocks!");

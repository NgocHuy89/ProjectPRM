import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'services/auth_service.dart';
import 'services/user_service.dart';
import 'models/user_model.dart';
import 'utils/app_theme.dart';
import 'screens/auth/login_screen.dart';
import 'screens/room/create_room_screen.dart';
import 'screens/room/join_room_screen.dart';
import 'screens/dashboard/head_dashboard_screen.dart';
import 'screens/dashboard/member_dashboard_screen.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const RoommateFinanceApp());
}

class RoommateFinanceApp extends StatelessWidget {
  const RoommateFinanceApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Roommate Finance',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      home: const AuthGate(),
    );
  }
}

// ─── Auth Gate ────────────────────────────────────────────
// Lắng nghe Firebase Auth + Firestore user stream,
// tự động chuyển hướng khi currentRoomId thay đổi
class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, authSnap) {
        // Đang kiểm tra trạng thái auth
        if (authSnap.connectionState == ConnectionState.waiting) {
          return const _SplashScreen();
        }

        // Chưa đăng nhập → màn hình Login
        if (!authSnap.hasData || authSnap.data == null) {
          return const LoginScreen();
        }

        // Đã đăng nhập → lắng nghe user data từ Firestore theo stream
        // Dùng StreamBuilder thay vì FutureBuilder để tự động rebuild
        // khi currentRoomId thay đổi sau khi tạo/tham gia phòng
        return StreamBuilder<UserModel?>(
          stream: UserService().userStream(authSnap.data!.uid),
          builder: (context, userSnap) {
            if (userSnap.connectionState == ConnectionState.waiting) {
              return const _SplashScreen();
            }
            final user = userSnap.data;
            if (user == null) return const LoginScreen();

            // Chưa vào phòng nào → màn hình chọn phòng
            if (user.currentRoomId == null) {
              return _NoRoomScreen(user: user);
            }

            // Phân quyền theo role
            if (user.isHead) {
              return HeadDashboardScreen(user: user);
            } else {
              return MemberDashboardScreen(user: user);
            }
          },
        );
      },
    );
  }
}

// ─── Splash Screen ────────────────────────────────────────
class _SplashScreen extends StatelessWidget {
  const _SplashScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primaryDark,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(24),
              ),
              child: const Icon(
                Icons.account_balance_wallet,
                size: 56,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Roommate Finance',
              style: TextStyle(
                color: Colors.white,
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Quản lý tài chính phòng trọ',
              style: TextStyle(color: Colors.white60, fontSize: 14),
            ),
            const SizedBox(height: 48),
            const CircularProgressIndicator(color: Colors.white54),
          ],
        ),
      ),
    );
  }
}

// ─── No Room Screen ───────────────────────────────────────
class _NoRoomScreen extends StatelessWidget {
  final UserModel user;
  const _NoRoomScreen({required this.user});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        title: const Text('Chọn phòng'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => AuthService().logout(),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Icon(Icons.home_outlined, size: 80, color: AppColors.primary),
            const SizedBox(height: 24),
            Text(
              'Xin chào, ${user.fullName}!',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Bạn chưa thuộc phòng nào.\nTạo phòng mới hoặc tham gia phòng có sẵn.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 40),
            ElevatedButton.icon(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => CreateRoomScreen(user: user),
                ),
              ),
              icon: const Icon(Icons.add_home),
              label: const Text('Tạo phòng mới'),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => JoinRoomScreen(user: user),
                ),
              ),
              icon: const Icon(Icons.login),
              label: const Text('Tham gia phòng'),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(double.infinity, 52),
                side: const BorderSide(color: AppColors.primary),
                foregroundColor: AppColors.primary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
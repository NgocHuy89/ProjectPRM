import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import '../../models/user_model.dart';
import '../../services/user_service.dart';
import '../../utils/app_theme.dart';
import '../../widgets/common_widgets.dart';

// ═══════════════════════════════════════════════
// VIEW PROFILE SCREEN
// ═══════════════════════════════════════════════
class ViewProfileScreen extends StatelessWidget {
  final String userId;

  const ViewProfileScreen({super.key, required this.userId});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<UserModel?>(
      stream: UserService().userStream(userId),
      builder: (context, snap) {
        final user = snap.data;
        return Scaffold(
          backgroundColor: AppColors.surface,
          body: user == null
              ? const Center(child: CircularProgressIndicator())
              : CustomScrollView(
                  slivers: [
                    _buildAppBar(context, user),
                    SliverPadding(
                      padding: const EdgeInsets.all(16),
                      sliver: SliverList(
                        delegate: SliverChildListDelegate([
                          _buildProfileCard(user),
                          const SizedBox(height: 16),
                          _buildInfoCard(user),
                          const SizedBox(height: 16),
                          _buildRoomCard(user),
                          const SizedBox(height: 24),
                          // Edit button (chỉ hiện nếu xem profile của chính mình)
                          ElevatedButton.icon(
                            onPressed: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => EditProfileScreen(user: user),
                              ),
                            ),
                            icon: const Icon(Icons.edit),
                            label: const Text('Chỉnh sửa hồ sơ'),
                          ),
                          const SizedBox(height: 32),
                        ]),
                      ),
                    ),
                  ],
                ),
        );
      },
    );
  }

  SliverAppBar _buildAppBar(BuildContext context, UserModel user) {
    return SliverAppBar(
      expandedHeight: 220,
      pinned: true,
      backgroundColor: AppColors.primaryDark,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: Colors.white),
        onPressed: () => Navigator.pop(context),
      ),
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [AppColors.primaryDark, AppColors.primary],
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(height: 40),
              UserAvatar(
                imageUrl: user.avatarUrl,
                name: user.fullName,
                radius: 44,
              ),
              const SizedBox(height: 12),
              Text(
                user.fullName,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  user.isHead ? '👑 Trưởng phòng' : '👤 Thành viên',
                  style: const TextStyle(color: Colors.white, fontSize: 13),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfileCard(UserModel user) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Thông tin cá nhân',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 15,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 12),
            InfoRow(icon: Icons.person, label: 'Họ tên', value: user.fullName),
            const Divider(height: 1),
            InfoRow(icon: Icons.email, label: 'Email', value: user.email),
            if (user.phone != null) ...[
              const Divider(height: 1),
              InfoRow(
                icon: Icons.phone,
                label: 'Điện thoại',
                value: user.phone!,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard(UserModel user) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Tài khoản',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 15,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 12),
            InfoRow(
              icon: Icons.calendar_today,
              label: 'Ngày tham gia',
              value: DateFormat('dd/MM/yyyy').format(user.createdAt),
            ),
            if (user.lastLoginAt != null) ...[
              const Divider(height: 1),
              InfoRow(
                icon: Icons.access_time,
                label: 'Đăng nhập gần nhất',
                value: DateFormat('dd/MM/yyyy HH:mm').format(user.lastLoginAt!),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildRoomCard(UserModel user) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Phòng trọ',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 15,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 12),
            InfoRow(
              icon: Icons.home,
              label: 'Trạng thái',
              value: user.currentRoomId != null
                  ? 'Đang ở phòng'
                  : 'Chưa vào phòng',
            ),
            if (user.currentRoomId != null) ...[
              const Divider(height: 1),
              InfoRow(
                icon: Icons.badge,
                label: 'Vai trò',
                value: user.isHead ? 'Trưởng phòng' : 'Thành viên',
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════
// EDIT PROFILE SCREEN
// ═══════════════════════════════════════════════
class EditProfileScreen extends StatefulWidget {
  final UserModel user;

  const EditProfileScreen({super.key, required this.user});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final UserService _userService = UserService();
  final ImagePicker _picker = ImagePicker();

  File? _selectedImage;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _nameController.text = widget.user.fullName;
    _phoneController.text = widget.user.phone ?? '';
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Chụp ảnh'),
              onTap: () => Navigator.pop(context, ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Chọn từ thư viện'),
              onTap: () => Navigator.pop(context, ImageSource.gallery),
            ),
          ],
        ),
      ),
    );

    if (source == null) return;
    final picked = await _picker.pickImage(source: source, imageQuality: 80);
    if (picked != null) {
      setState(() => _selectedImage = File(picked.path));
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    try {
      String? newAvatarUrl;
      if (_selectedImage != null) {
        newAvatarUrl = await _userService.uploadAvatar(
          uid: widget.user.uid,
          imageFile: _selectedImage!,
        );
      }

      await _userService.updateProfile(
        uid: widget.user.uid,
        fullName: _nameController.text.trim(),
        phone: _phoneController.text.trim().isEmpty
            ? null
            : _phoneController.text.trim(),
        avatarUrl: newAvatarUrl,
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Cập nhật hồ sơ thành công!'),
          backgroundColor: AppColors.secondary,
          behavior: SnackBarBehavior.floating,
        ),
      );
      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Lỗi: $e'),
          backgroundColor: AppColors.danger,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return LoadingOverlay(
      isLoading: _isLoading,
      child: Scaffold(
        appBar: AppBar(title: const Text('Chỉnh sửa hồ sơ')),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            autovalidateMode: AutovalidateMode.onUserInteraction,
            child: Column(
              children: [
                // Avatar picker
                Center(
                  child: Stack(
                    children: [
                      _selectedImage != null
                          ? CircleAvatar(
                              radius: 56,
                              backgroundImage: FileImage(_selectedImage!),
                            )
                          : UserAvatar(
                              imageUrl: widget.user.avatarUrl,
                              name: widget.user.fullName,
                              radius: 56,
                            ),
                      Positioned(
                        right: 0,
                        bottom: 0,
                        child: GestureDetector(
                          onTap: _pickImage,
                          child: Container(
                            width: 36,
                            height: 36,
                            decoration: const BoxDecoration(
                              color: AppColors.primary,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.camera_alt,
                              color: Colors.white,
                              size: 18,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),

                // Full name
                AppTextField(
                  label: 'Họ và tên',
                  hint: 'Nhập họ và tên',
                  controller: _nameController,
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) {
                      return 'Họ tên không được để trống';
                    }
                    if (v.trim().length < 2) {
                      return 'Tên phải có ít nhất 2 ký tự';
                    }
                    return null;
                  },
                  prefixIcon: const Icon(Icons.person_outline),
                ),
                const SizedBox(height: 16),

                // Phone
                AppTextField(
                  label: 'Số điện thoại',
                  hint: 'Nhập số điện thoại (tuỳ chọn)',
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  textInputAction: TextInputAction.done,
                  prefixIcon: const Icon(Icons.phone_outlined),
                  validator: (v) {
                    if (v != null &&
                        v.isNotEmpty &&
                        !RegExp(r'^[0-9]{9,11}$').hasMatch(v)) {
                      return 'Số điện thoại không hợp lệ';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 8),

                // Email (read-only)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Email',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.divider),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.lock_outline,
                            size: 18,
                            color: AppColors.textSecondary,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            widget.user.email,
                            style: const TextStyle(
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Email không thể thay đổi',
                      style: TextStyle(
                        fontSize: 11,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 32),

                ElevatedButton.icon(
                  onPressed: _isLoading ? null : _save,
                  icon: const Icon(Icons.save),
                  label: const Text('Lưu thay đổi'),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

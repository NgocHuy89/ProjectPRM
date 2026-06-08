import 'package:flutter/material.dart';
import '../../models/user_model.dart';
import '../../services/room_service.dart';
import '../../utils/app_theme.dart';
import '../../widgets/common_widgets.dart';

class CreateRoomScreen extends StatefulWidget {
  final UserModel user;
  const CreateRoomScreen({super.key, required this.user});

  @override
  State<CreateRoomScreen> createState() => _CreateRoomScreenState();
}

class _CreateRoomScreenState extends State<CreateRoomScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();
  final _rentCtrl = TextEditingController();
  final _dueDayCtrl = TextEditingController();
  final _roomService = RoomService();
  bool _isLoading = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _addressCtrl.dispose();
    _rentCtrl.dispose();
    _dueDayCtrl.dispose();
    super.dispose();
  }

  Future<void> _createRoom() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    try {
      await _roomService.createRoom(
        headId: widget.user.uid,
        headName: widget.user.fullName,
        headAvatarUrl: widget.user.avatarUrl ?? '',
        roomName: _nameCtrl.text.trim(),
        address: _addressCtrl.text.trim().isEmpty
            ? null
            : _addressCtrl.text.trim(),
        monthlyRent: _rentCtrl.text.trim().isEmpty
            ? null
            : double.tryParse(
                _rentCtrl.text.trim().replaceAll(',', '').replaceAll('.', ''),
              ),
        rentDueDay: _dueDayCtrl.text.trim().isEmpty
            ? null
            : int.tryParse(_dueDayCtrl.text.trim()),
      );
      // AuthGate sẽ tự refresh vì user.currentRoomId thay đổi
      if (!mounted) return;
      Navigator.of(context).popUntil((r) => r.isFirst);
    } catch (e) {
      if (!mounted) return;
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
        appBar: AppBar(title: const Text('Tạo phòng mới')),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            autovalidateMode: AutovalidateMode.onUserInteraction,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header icon
                Center(
                  child: Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Icon(
                      Icons.add_home_work,
                      size: 40,
                      color: AppColors.primary,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                const Center(
                  child: Text(
                    'Tạo phòng trọ mới',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                const Center(
                  child: Text(
                    'Bạn sẽ là trưởng phòng',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 13,
                    ),
                  ),
                ),
                const SizedBox(height: 28),

                // Tên phòng (bắt buộc)
                AppTextField(
                  label: 'Tên phòng *',
                  hint: 'VD: Phòng 101 Nguyễn Văn Cừ',
                  controller: _nameCtrl,
                  prefixIcon: const Icon(Icons.home_outlined),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) {
                      return 'Vui lòng nhập tên phòng';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Địa chỉ (optional)
                AppTextField(
                  label: 'Địa chỉ (tuỳ chọn)',
                  hint: 'Nhập địa chỉ phòng trọ',
                  controller: _addressCtrl,
                  prefixIcon: const Icon(Icons.location_on_outlined),
                  maxLines: 2,
                ),
                const SizedBox(height: 16),

                // Tiền thuê/tháng (optional)
                AppTextField(
                  label: 'Tiền thuê/tháng (tuỳ chọn)',
                  hint: 'VD: 3000000',
                  controller: _rentCtrl,
                  keyboardType: TextInputType.number,
                  prefixIcon: const Icon(Icons.payments_outlined),
                  validator: (v) {
                    if (v != null && v.isNotEmpty) {
                      final clean = v.replaceAll(',', '').replaceAll('.', '');
                      if (double.tryParse(clean) == null) {
                        return 'Số tiền không hợp lệ';
                      }
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Ngày đóng tiền (optional)
                AppTextField(
                  label: 'Ngày đóng tiền hàng tháng (tuỳ chọn)',
                  hint: 'VD: 5 (ngày 5 hàng tháng)',
                  controller: _dueDayCtrl,
                  keyboardType: TextInputType.number,
                  textInputAction: TextInputAction.done,
                  prefixIcon: const Icon(Icons.calendar_today_outlined),
                  validator: (v) {
                    if (v != null && v.isNotEmpty) {
                      final n = int.tryParse(v);
                      if (n == null || n < 1 || n > 31) {
                        return 'Ngày phải từ 1 đến 31';
                      }
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 8),
                const Text(
                  '* Sau khi tạo phòng, bạn sẽ nhận được mã phòng để chia sẻ với thành viên.',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                    fontStyle: FontStyle.italic,
                  ),
                ),
                const SizedBox(height: 28),

                ElevatedButton.icon(
                  onPressed: _isLoading ? null : _createRoom,
                  icon: const Icon(Icons.add_home),
                  label: const Text('Tạo phòng'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

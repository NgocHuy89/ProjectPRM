import 'package:flutter/material.dart';
import '../../services/finance_service.dart';
import '../../services/room_service.dart';
import '../../utils/app_theme.dart';
import '../../widgets/common_widgets.dart';

class CreateFundScreen extends StatefulWidget {
  final String roomId;
  final String createdBy;

  const CreateFundScreen({
    super.key,
    required this.roomId,
    required this.createdBy,
  });

  @override
  State<CreateFundScreen> createState() => _CreateFundScreenState();
}

class _CreateFundScreenState extends State<CreateFundScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _targetCtrl = TextEditingController();
  final _perMemberCtrl = TextEditingController();
  DateTime? _dueDate;
  bool _isLoading = false;

  final _financeService = FinanceService();
  final _roomService = RoomService();

  @override
  void dispose() {
    _nameCtrl.dispose();
    _descCtrl.dispose();
    _targetCtrl.dispose();
    _perMemberCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDueDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 7)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) setState(() => _dueDate = picked);
  }

  Future<void> _createFund() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    try {
      // Lấy danh sách thành viên
      final membersSnap = await _roomService
          .membersStream(widget.roomId)
          .first;
      final memberIds = membersSnap.map((m) => m.userId).toList();

      await _financeService.createFund(
        roomId: widget.roomId,
        name: _nameCtrl.text.trim(),
        description: _descCtrl.text.trim().isEmpty
            ? null
            : _descCtrl.text.trim(),
        targetAmount: _targetCtrl.text.trim().isEmpty
            ? null
            : double.tryParse(
                _targetCtrl.text.trim().replaceAll(',', '').replaceAll('.', ''),
              ),
        contributionPerMember: _perMemberCtrl.text.trim().isEmpty
            ? null
            : double.tryParse(
                _perMemberCtrl.text.trim().replaceAll(',', '').replaceAll('.', ''),
              ),
        dueDate: _dueDate,
        createdBy: widget.createdBy,
        memberIds: memberIds,
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Tạo quỹ thành công!'),
          backgroundColor: AppColors.secondary,
          behavior: SnackBarBehavior.floating,
        ),
      );
      Navigator.pop(context);
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
        appBar: AppBar(title: const Text('Tạo quỹ mới')),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            autovalidateMode: AutovalidateMode.onUserInteraction,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Tên quỹ
                AppTextField(
                  label: 'Tên quỹ *',
                  hint: 'VD: Quỹ điện nước tháng 6, Quỹ sinh hoạt...',
                  controller: _nameCtrl,
                  prefixIcon: const Icon(Icons.savings_outlined),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) {
                      return 'Vui lòng nhập tên quỹ';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Mô tả
                AppTextField(
                  label: 'Mô tả (tuỳ chọn)',
                  hint: 'Ghi chú thêm về quỹ',
                  controller: _descCtrl,
                  maxLines: 3,
                ),
                const SizedBox(height: 16),

                // Mục tiêu
                AppTextField(
                  label: 'Số tiền mục tiêu (tuỳ chọn)',
                  hint: 'VD: 5000000',
                  controller: _targetCtrl,
                  keyboardType: TextInputType.number,
                  prefixIcon: const Icon(Icons.flag_outlined),
                  validator: (v) {
                    if (v != null && v.isNotEmpty) {
                      final clean = v.replaceAll(',', '').replaceAll('.', '');
                      final n = double.tryParse(clean);
                      if (n == null || n <= 0) return 'Số tiền không hợp lệ';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Đóng góp mỗi người
                AppTextField(
                  label: 'Mỗi người đóng (tuỳ chọn)',
                  hint: 'VD: 500000',
                  controller: _perMemberCtrl,
                  keyboardType: TextInputType.number,
                  prefixIcon: const Icon(Icons.person_outlined),
                  validator: (v) {
                    if (v != null && v.isNotEmpty) {
                      final clean = v.replaceAll(',', '').replaceAll('.', '');
                      final n = double.tryParse(clean);
                      if (n == null || n <= 0) return 'Số tiền không hợp lệ';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Hạn chót
                GestureDetector(
                  onTap: _pickDueDate,
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.divider),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.calendar_month_outlined,
                          color: AppColors.textSecondary,
                          size: 20,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Hạn chót đóng tiền (tuỳ chọn)',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                              Text(
                                _dueDate == null
                                    ? 'Chọn ngày'
                                    : '${_dueDate!.day}/${_dueDate!.month}/${_dueDate!.year}',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w500,
                                  color: _dueDate == null
                                      ? AppColors.textSecondary
                                      : AppColors.textPrimary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Icon(
                          Icons.arrow_forward_ios,
                          size: 14,
                          color: AppColors.textSecondary,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 32),

                ElevatedButton.icon(
                  onPressed: _isLoading ? null : _createFund,
                  icon: const Icon(Icons.savings),
                  label: const Text('Tạo quỹ'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

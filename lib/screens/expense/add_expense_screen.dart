import 'package:flutter/material.dart';
import '../../models/room_model.dart';
import '../../models/user_model.dart';
import '../../services/finance_service.dart';
import '../../services/room_service.dart';
import '../../utils/app_theme.dart';
import '../../widgets/common_widgets.dart';

class AddExpenseScreen extends StatefulWidget {
  final String roomId;
  final UserModel user;

  const AddExpenseScreen({
    super.key,
    required this.roomId,
    required this.user,
  });

  @override
  State<AddExpenseScreen> createState() => _AddExpenseScreenState();
}

class _AddExpenseScreenState extends State<AddExpenseScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleCtrl = TextEditingController();
  final _amountCtrl = TextEditingController();
  final _noteCtrl = TextEditingController();

  String _selectedCategory = 'other';
  DateTime _expenseDate = DateTime.now();
  String? _paidByUserId;
  String? _paidByUserName;
  bool _isLoading = false;
  bool _isPersonalNote = false;

  List<MemberModel> _members = [];

  final _financeService = FinanceService();
  final _roomService = RoomService();

  final Map<String, String> _categories = {
    'electricity': 'Tiền điện',
    'water': 'Tiền nước',
    'internet': 'Internet',
    'supplies': 'Đồ dùng',
    'other': 'Khác',
  };

  @override
  void initState() {
    super.initState();
    _paidByUserId = widget.user.uid;
    _paidByUserName = widget.user.fullName;
    _loadMembers();
  }

  Future<void> _loadMembers() async {
    final members = await _roomService.membersStream(widget.roomId).first;
    if (mounted) {
      setState(() => _members = members);
    }
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _amountCtrl.dispose();
    _noteCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _expenseDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked != null) setState(() => _expenseDate = picked);
  }

  Future<void> _addExpense() async {
    if (!_formKey.currentState!.validate()) return;
    if (_paidByUserId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vui lòng chọn người trả'),
          backgroundColor: AppColors.warning,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      final amount = double.parse(
        _amountCtrl.text.trim().replaceAll(',', '').replaceAll('.', ''),
      );

      await _financeService.addExpense(
        roomId: widget.roomId,
        title: _titleCtrl.text.trim(),
        category: _selectedCategory,
        totalAmount: amount,
        paidBy: _paidByUserId!,
        paidByName: _paidByUserName!,
        note: _noteCtrl.text.trim().isEmpty ? null : _noteCtrl.text.trim(),
        expenseDate: _expenseDate,
        createdBy: widget.user.uid,
        isPersonalNote: _isPersonalNote,
        memberIds: _members.map((m) => m.userId).toList(),
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Đã thêm chi tiêu!'),
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
        appBar: AppBar(title: const Text('Thêm chi tiêu')),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            autovalidateMode: AutovalidateMode.onUserInteraction,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Tiêu đề
                AppTextField(
                  label: 'Tiêu đề *',
                  hint: 'VD: Tiền điện tháng 6',
                  controller: _titleCtrl,
                  prefixIcon: const Icon(Icons.title),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) {
                      return 'Vui lòng nhập tiêu đề';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Danh mục
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Danh mục *',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _categories.entries.map((entry) {
                        final isSelected = _selectedCategory == entry.key;
                        final color =
                            AppConstants.categoryColor(entry.key);
                        final icon =
                            AppConstants.categoryIcons[entry.key] ??
                                Icons.more_horiz;
                        return GestureDetector(
                          onTap: () =>
                              setState(() => _selectedCategory = entry.key),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 10,
                            ),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? color.withValues(alpha: 0.15)
                                  : Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: isSelected
                                    ? color
                                    : AppColors.divider,
                                width: isSelected ? 2 : 1,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(icon, size: 16, color: color),
                                const SizedBox(width: 6),
                                Text(
                                  entry.value,
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: isSelected
                                        ? color
                                        : AppColors.textSecondary,
                                    fontWeight: isSelected
                                        ? FontWeight.bold
                                        : FontWeight.normal,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Số tiền
                AppTextField(
                  label: 'Số tiền *',
                  hint: 'Nhập số tiền (VNĐ)',
                  controller: _amountCtrl,
                  keyboardType: TextInputType.number,
                  prefixIcon: const Icon(Icons.payments_outlined),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) {
                      return 'Vui lòng nhập số tiền';
                    }
                    final clean = v.replaceAll(',', '').replaceAll('.', '');
                    final n = double.tryParse(clean);
                    if (n == null || n <= 0) return 'Số tiền không hợp lệ';
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Người trả
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Người trả *',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      initialValue: _paidByUserId,
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide:
                              BorderSide(color: AppColors.divider),
                        ),
                        prefixIcon: const Icon(Icons.person_pin),
                      ),
                      items: _members.map((m) {
                        return DropdownMenuItem(
                          value: m.userId,
                          child: Text(m.fullName),
                        );
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) {
                          final m = _members.firstWhere(
                            (m) => m.userId == val,
                          );
                          setState(() {
                            _paidByUserId = val;
                            _paidByUserName = m.fullName;
                          });
                        }
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 16),
 
                // Ngày chi tiêu
                GestureDetector(
                  onTap: _pickDate,
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
                          Icons.calendar_today,
                          color: AppColors.textSecondary,
                          size: 20,
                        ),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Ngày chi tiêu',
                              style: TextStyle(
                                fontSize: 12,
                                color: AppColors.textSecondary,
                              ),
                            ),
                            Text(
                              '${_expenseDate.day}/${_expenseDate.month}/${_expenseDate.year}',
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w500,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ],
                        ),
                        const Spacer(),
                        const Icon(
                          Icons.arrow_forward_ios,
                          size: 14,
                          color: AppColors.textSecondary,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
 
                // Ghi chú
                AppTextField(
                  label: 'Ghi chú (tuỳ chọn)',
                  hint: 'Thêm ghi chú cho khoản chi này',
                  controller: _noteCtrl,
                  maxLines: 3,
                  textInputAction: TextInputAction.done,
                ),
                const SizedBox(height: 12),
 
                // Personal note toggle
                Row(
                  children: [
                    Switch(
                      value: _isPersonalNote,
                      activeThumbColor: AppColors.primary,
                      onChanged: (v) => setState(() => _isPersonalNote = v),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          Text(
                            'Ghi chú cá nhân',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                          ),
                          Text(
                            'Chi tiêu chung nhưng dùng vào việc cá nhân',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 28),

                ElevatedButton.icon(
                  onPressed: _isLoading ? null : _addExpense,
                  icon: const Icon(Icons.add_shopping_cart),
                  label: const Text('Thêm chi tiêu'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.danger,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import '../../models/user_model.dart';
import '../../services/finance_service.dart';
import '../../utils/app_theme.dart';
import '../../widgets/common_widgets.dart';

class AddPersonalExpenseScreen extends StatefulWidget {
  final UserModel user;

  const AddPersonalExpenseScreen({super.key, required this.user});

  @override
  State<AddPersonalExpenseScreen> createState() => _AddPersonalExpenseScreenState();
}

class _AddPersonalExpenseScreenState extends State<AddPersonalExpenseScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleCtrl = TextEditingController();
  final _amountCtrl = TextEditingController();
  final _noteCtrl = TextEditingController();
  final _customCategoryCtrl = TextEditingController();

  String _selectedCategory = 'other';
  DateTime _expenseDate = DateTime.now();
  bool _isLoading = false;

  final _financeService = FinanceService();

  final Map<String, String> _categories = {
    'food': 'Ăn uống',
    'transport': 'Di chuyển',
    'shopping': 'Mua sắm',
    'entertainment': 'Giải trí',
    'health': 'Sức khoẻ',
    'other': 'Khác',
  };

  @override
  void dispose() {
    _titleCtrl.dispose();
    _amountCtrl.dispose();
    _noteCtrl.dispose();
    _customCategoryCtrl.dispose();
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

  Future<void> _saveExpense() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    try {
      final amount = double.parse(
        _amountCtrl.text.trim().replaceAll(',', '').replaceAll('.', ''),
      );

      final finalCategory = _selectedCategory == 'other'
          ? (_customCategoryCtrl.text.trim().isEmpty
              ? 'Khác'
              : _customCategoryCtrl.text.trim())
          : _selectedCategory;

      await _financeService.addPersonalExpense(
        userId: widget.user.uid,
        title: _titleCtrl.text.trim(),
        category: finalCategory,
        amount: amount,
        expenseDate: _expenseDate,
        note: _noteCtrl.text.trim().isEmpty ? null : _noteCtrl.text.trim(),
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Đã thêm chi tiêu cá nhân!'),
          backgroundColor: AppColors.secondary,
        ),
      );
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Lỗi: $e'),
          backgroundColor: AppColors.danger,
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
        appBar: AppBar(title: const Text('Thêm chi tiêu cá nhân')),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            autovalidateMode: AutovalidateMode.onUserInteraction,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                AppTextField(
                  label: 'Tiêu đề *',
                  hint: 'VD: Ăn trưa, Đổ xăng...',
                  controller: _titleCtrl,
                  prefixIcon: const Icon(Icons.title),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return 'Vui lòng nhập tiêu đề';
                    return null;
                  },
                ),
                const SizedBox(height: 16),
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
                        final color = AppConstants.categoryColor(entry.key);
                        final icon = AppConstants.categoryIcons[entry.key] ?? Icons.more_horiz;
                        return GestureDetector(
                          onTap: () => setState(() => _selectedCategory = entry.key),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                            decoration: BoxDecoration(
                              color: isSelected ? color.withValues(alpha: 0.15) : Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: isSelected ? color : AppColors.divider,
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
                                    color: isSelected ? color : AppColors.textSecondary,
                                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    if (_selectedCategory == 'other') ...[
                      const SizedBox(height: 12),
                      AppTextField(
                        label: 'Nhập tên danh mục *',
                        hint: 'VD: Mua tivi, Mua quạt...',
                        controller: _customCategoryCtrl,
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) {
                            return 'Vui lòng nhập tên danh mục';
                          }
                          return null;
                        },
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 16),
                AppTextField(
                  label: 'Số tiền *',
                  hint: 'Nhập số tiền (VNĐ)',
                  controller: _amountCtrl,
                  keyboardType: TextInputType.number,
                  prefixIcon: const Icon(Icons.payments_outlined),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return 'Vui lòng nhập số tiền';
                    final clean = v.replaceAll(',', '').replaceAll('.', '');
                    final n = double.tryParse(clean);
                    if (n == null || n <= 0) return 'Số tiền không hợp lệ';
                    return null;
                  },
                ),
                const SizedBox(height: 16),
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
                        const Icon(Icons.calendar_today, color: AppColors.textSecondary, size: 20),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Ngày chi tiêu',
                              style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
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
                        const Icon(Icons.arrow_forward_ios, size: 14, color: AppColors.textSecondary),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                AppTextField(
                  label: 'Ghi chú (tuỳ chọn)',
                  hint: 'Thêm ghi chú',
                  controller: _noteCtrl,
                  maxLines: 3,
                  textInputAction: TextInputAction.done,
                ),
                const SizedBox(height: 28),
                ElevatedButton.icon(
                  onPressed: _isLoading ? null : _saveExpense,
                  icon: const Icon(Icons.save),
                  label: const Text('Lưu chi tiêu'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

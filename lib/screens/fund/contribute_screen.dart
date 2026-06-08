import 'package:flutter/material.dart';
import '../../models/finance_models.dart';
import '../../models/user_model.dart';
import '../../services/finance_service.dart';
import '../../utils/app_theme.dart';
import '../../widgets/common_widgets.dart';

class ContributeScreen extends StatefulWidget {
  final FundModel fund;
  final String roomId;
  final UserModel user;

  const ContributeScreen({
    super.key,
    required this.fund,
    required this.roomId,
    required this.user,
  });

  @override
  State<ContributeScreen> createState() => _ContributeScreenState();
}

class _ContributeScreenState extends State<ContributeScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountCtrl = TextEditingController();
  final _noteCtrl = TextEditingController();
  final _financeService = FinanceService();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // Pre-fill với số tiền mỗi người
    if (widget.fund.contributionPerMember != null) {
      _amountCtrl.text =
          widget.fund.contributionPerMember!.toStringAsFixed(0);
    }
  }

  @override
  void dispose() {
    _amountCtrl.dispose();
    _noteCtrl.dispose();
    super.dispose();
  }

  Future<void> _contribute() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    try {
      final amount = double.parse(
        _amountCtrl.text.trim().replaceAll(',', '').replaceAll('.', ''),
      );

      await _financeService.addContribution(
        roomId: widget.roomId,
        fundId: widget.fund.fundId,
        userId: widget.user.uid,
        userName: widget.user.fullName,
        amount: amount,
        note: _noteCtrl.text.trim().isEmpty ? null : _noteCtrl.text.trim(),
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Đóng tiền thành công! 🎉'),
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
        appBar: AppBar(title: const Text('Đóng tiền quỹ')),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Fund info card
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [AppColors.primary, AppColors.primaryDark],
                    ),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Quỹ',
                        style: TextStyle(color: Colors.white60, fontSize: 12),
                      ),
                      Text(
                        widget.fund.name,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Text(
                            'Số dư: ',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 13,
                            ),
                          ),
                          Text(
                            formatVND(widget.fund.currentBalance),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          if (widget.fund.targetAmount != null) ...[
                            const Text(
                              ' / ',
                              style: TextStyle(
                                color: Colors.white60,
                                fontSize: 13,
                              ),
                            ),
                            Text(
                              formatVND(widget.fund.targetAmount!),
                              style: const TextStyle(
                                color: Colors.white60,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 28),

                // Amount field
                AppTextField(
                  label: 'Số tiền đóng *',
                  hint: 'Nhập số tiền',
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

                // Gợi ý số tiền
                if (widget.fund.contributionPerMember != null) ...[
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: [
                      ActionChip(
                        label: Text(
                          'Đúng phần: ${formatVND(widget.fund.contributionPerMember!)}',
                        ),
                        onPressed: () => _amountCtrl.text =
                            widget.fund.contributionPerMember!
                                .toStringAsFixed(0),
                        backgroundColor:
                            AppColors.primary.withValues(alpha: 0.1),
                        labelStyle: const TextStyle(color: AppColors.primary),
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: 16),

                // Note
                AppTextField(
                  label: 'Ghi chú (tuỳ chọn)',
                  hint: 'VD: Đóng phần tháng 6',
                  controller: _noteCtrl,
                  maxLines: 3,
                  textInputAction: TextInputAction.done,
                ),
                const SizedBox(height: 32),

                ElevatedButton.icon(
                  onPressed: _isLoading ? null : _contribute,
                  icon: const Icon(Icons.payment),
                  label: const Text('Xác nhận đóng tiền'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.secondary,
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

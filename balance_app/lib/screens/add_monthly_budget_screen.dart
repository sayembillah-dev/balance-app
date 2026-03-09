import 'package:flutter/material.dart';
import '../data/dummy_data.dart';
import 'add_monthly_budget_categories_screen.dart';

const Color _kBgGrey = Color(0xFFF2F2F7);
const Color _kTextDark = Color(0xFF1C1C1E);
const Color _kBorderGrey = Color(0xFFE5E5EA);

/// Step 1: Select month/year and enter regular income. Next / Cancel.
/// If [editBudget] is set, form is pre-filled and saving updates that budget.
class AddMonthlyBudgetScreen extends StatefulWidget {
  const AddMonthlyBudgetScreen({super.key, this.editBudget});

  final MonthlyBudget? editBudget;

  @override
  State<AddMonthlyBudgetScreen> createState() => _AddMonthlyBudgetScreenState();
}

class _AddMonthlyBudgetScreenState extends State<AddMonthlyBudgetScreen> {
  late int _month;
  late int _year;
  late TextEditingController _incomeController;

  @override
  void initState() {
    super.initState();
    if (widget.editBudget != null) {
      final b = widget.editBudget!;
      _month = b.month;
      _year = b.year;
      _incomeController = TextEditingController(text: b.regularIncome.toStringAsFixed(b.regularIncome.truncateToDouble() == b.regularIncome ? 0 : 2));
    } else {
      final now = DateTime.now();
      _month = now.month;
      _year = now.year;
      _incomeController = TextEditingController(text: '0');
    }
  }

  @override
  void dispose() {
    _incomeController.dispose();
    super.dispose();
  }

  Future<void> _pickMonthYear() async {
    int sheetMonth = _month;
    int sheetYear = _year;
    final now = DateTime.now();
    final years = List.generate(11, (i) => now.year - 2 + i); // 2 years back, 8 forward

    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setSheetState) {
            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Month & year',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey[700],
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                            decoration: BoxDecoration(
                              border: Border.all(color: _kBorderGrey),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<int>(
                                value: sheetMonth,
                                isExpanded: true,
                                items: List.generate(12, (i) => i + 1).map((m) {
                                  return DropdownMenuItem(
                                    value: m,
                                    child: Text(
                                      MonthlyBudget.monthNames[m - 1],
                                      style: const TextStyle(fontSize: 16),
                                    ),
                                  );
                                }).toList(),
                                onChanged: (v) {
                                  if (v != null) setSheetState(() => sheetMonth = v);
                                },
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                            decoration: BoxDecoration(
                              border: Border.all(color: _kBorderGrey),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<int>(
                                value: sheetYear,
                                isExpanded: true,
                                items: years.map((y) => DropdownMenuItem(value: y, child: Text('$y', style: const TextStyle(fontSize: 16)))).toList(),
                                onChanged: (v) {
                                  if (v != null) setSheetState(() => sheetYear = v);
                                },
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    FilledButton(
                      onPressed: () {
                        if (mounted) setState(() { _month = sheetMonth; _year = sheetYear; });
                        Navigator.of(ctx).pop();
                      },
                      style: FilledButton.styleFrom(
                        backgroundColor: Colors.black,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      child: const Text('Done'),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _next() {
    final raw = _incomeController.text.trim();
    final income = raw.isEmpty ? 0.0 : (double.tryParse(raw) ?? -1);
    if (income < 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter a valid amount or leave empty for no income')),
      );
      return;
    }
    Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (context) => AddMonthlyBudgetCategoriesScreen(
          month: _month,
          year: _year,
          regularIncome: income,
          editBudget: widget.editBudget,
        ),
      ),
    ).then((added) {
      if (added == true && mounted) Navigator.of(context).pop(true);
    });
  }

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final padding = media.size.width < 360 ? 16.0 : 20.0;

    return Scaffold(
      backgroundColor: _kBgGrey,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.close_rounded),
          onPressed: () => Navigator.of(context).pop(false),
        ),
        title: Text(
          widget.editBudget != null ? 'Edit monthly budget' : 'Monthly budget',
          style: const TextStyle(
            color: _kTextDark,
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: Colors.white,
        foregroundColor: _kTextDark,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(padding, 24, padding, 24 + media.padding.bottom),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Step 1 of 2',
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 20),
            _label('Month & year'),
            const SizedBox(height: 8),
            Material(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              child: InkWell(
                onTap: _pickMonthYear,
                borderRadius: BorderRadius.circular(14),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: _kBorderGrey),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.calendar_today_rounded, size: 22, color: _kTextDark),
                      const SizedBox(width: 12),
                      Text(
                        '${MonthlyBudget.monthNames[_month - 1]} $_year',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: _kTextDark,
                        ),
                      ),
                      const Spacer(),
                      Icon(Icons.keyboard_arrow_down_rounded, color: Colors.grey[600]),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
            _label('Regular income (optional)'),
            const SizedBox(height: 8),
            TextField(
              controller: _incomeController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(
                hintText: '0 — leave empty if you don\'t track salary',
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: _kBorderGrey),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              ),
            ),
            const SizedBox(height: 32),
            FilledButton(
              onPressed: _next,
              style: FilledButton.styleFrom(
                backgroundColor: Colors.black,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: const Text('Next'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _label(String text) {
    return Text(
      text,
      style: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: Colors.grey[700],
      ),
    );
  }
}

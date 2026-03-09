import 'package:flutter/material.dart';
import 'add_monthly_budget_screen.dart';

const Color _kBgGrey = Color(0xFFF2F2F7);
const Color _kCardWhite = Color(0xFFFAFAFA);
const Color _kTextDark = Color(0xFF1C1C1E);
const Color _kBorderGrey = Color(0xFFE5E5EA);

/// Choose budget type: Monthly Budget or Particular Budget. Shows definitions. Cancel with X.
class AddBudgetTypeScreen extends StatelessWidget {
  const AddBudgetTypeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBgGrey,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.close_rounded),
          onPressed: () => Navigator.of(context).pop(false),
        ),
        title: const Text(
          'New budget',
          style: TextStyle(
            color: _kTextDark,
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: Colors.white,
        foregroundColor: _kTextDark,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(
          MediaQuery.of(context).size.width < 360 ? 16 : 20,
          24,
          MediaQuery.of(context).size.width < 360 ? 16 : 20,
          24 + MediaQuery.of(context).padding.bottom,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'What type of budget would you like to create?',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: _kTextDark,
              ),
            ),
            const SizedBox(height: 24),
            _BudgetTypeCard(
              icon: Icons.calendar_month_rounded,
              title: 'Monthly Budget',
              definition:
                  'Plan your income and spending for a specific month. Set your regular income and allocate budgets to categories (e.g. Food, Transport). Helps you see how much remains after planned expenses.',
              onTap: () async {
                final added = await Navigator.of(context).push<bool>(
                  MaterialPageRoute(
                    builder: (context) => const AddMonthlyBudgetScreen(),
                  ),
                );
                if (added == true && context.mounted) {
                  Navigator.of(context).pop(true);
                }
              },
            ),
            const SizedBox(height: 16),
            _BudgetTypeCard(
              icon: Icons.flag_rounded,
              title: 'Particular Budget',
              definition:
                  'Save for a specific goal or event (e.g. vacation, new device). Set a target amount and timeline. Coming soon.',
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                      content: Text('Particular Budget will be available later')),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _BudgetTypeCard extends StatelessWidget {
  const _BudgetTypeCard({
    required this.icon,
    required this.title,
    required this.definition,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String definition;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: _kCardWhite,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: _kBorderGrey),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: _kBgGrey,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    alignment: Alignment.center,
                    child: Icon(icon, size: 26, color: _kTextDark),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      title,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w600,
                        color: _kTextDark,
                      ),
                    ),
                  ),
                  Icon(Icons.chevron_right_rounded, color: Colors.grey[400]),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                definition,
                style: TextStyle(
                  fontSize: 14,
                  height: 1.4,
                  color: Colors.grey[700],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

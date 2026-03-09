import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/iso_currencies.dart';
import '../theme/app_theme.dart';
import '../providers/currency_provider.dart';

/// Full-screen list of ISO currencies with search. Tapping a currency saves it and pops.
class CurrencyPickerScreen extends ConsumerStatefulWidget {
  const CurrencyPickerScreen({super.key});

  @override
  ConsumerState<CurrencyPickerScreen> createState() => _CurrencyPickerScreenState();
}

class _CurrencyPickerScreenState extends ConsumerState<CurrencyPickerScreen> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocus = FocusNode();
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocus.dispose();
    super.dispose();
  }

  List<IsoCurrency> get _filtered {
    if (_query.trim().isEmpty) return isoCurrencies;
    final q = _query.trim().toLowerCase();
    return isoCurrencies.where((c) {
      return c.code.toLowerCase().contains(q) || c.name.toLowerCase().contains(q);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final isNarrow = media.size.width < 360;
    final padding = isNarrow ? 16.0 : 20.0;
    final selectedAsync = ref.watch(selectedCurrencyProvider);
    final currentCode = selectedAsync.valueOrNull ?? 'USD';
    final list = _filtered;

    return Scaffold(
      backgroundColor: const Color(0xFFF2F2F7),
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Default currency',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
        ),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Column(
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(padding, 16, padding, 12),
            child: TextField(
              controller: _searchController,
              focusNode: _searchFocus,
              onChanged: (v) => setState(() => _query = v),
              decoration: InputDecoration(
                hintText: 'Search by code or name',
                prefixIcon: const Icon(Icons.search_rounded, color: Color(0xFF8E8E93)),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
              style: const TextStyle(
                fontFamily: AppFonts.family,
                fontSize: 16,
              ),
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: EdgeInsets.fromLTRB(padding, 0, padding, 24 + media.padding.bottom),
              itemCount: list.length,
              itemBuilder: (context, index) {
                final c = list[index];
                final isSelected = c.code == currentCode;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Material(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    child: ListTile(
                      title: Text(
                        c.code,
                        style: const TextStyle(
                          fontFamily: AppFonts.family,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF1C1C1E),
                          fontSize: 16,
                        ),
                      ),
                      subtitle: Text(
                        c.name,
                        style: TextStyle(
                          fontFamily: AppFonts.family,
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                      trailing: isSelected
                          ? const Icon(Icons.check_rounded, color: Colors.black, size: 24)
                          : null,
                      onTap: () async {
                        await ref.read(selectedCurrencyProvider.notifier).setCurrency(c.code);
                        if (context.mounted) Navigator.of(context).pop();
                      },
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

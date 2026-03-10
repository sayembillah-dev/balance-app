import 'package:flutter/material.dart';
import '../data/dummy_data.dart';

/// Single transaction row for the list: square emoji placeholder, category + description, amount + chevron.
/// Use [displayAmount] when showing in selected currency (e.g. from formatStoredAmountWithCurrency).
class TransactionListRow extends StatelessWidget {
  const TransactionListRow({
    super.key,
    required this.item,
    required this.isNarrow,
    this.displayAmount,
    this.onTap,
  });

  final TransactionItem item;
  final bool isNarrow;
  /// If set, shown instead of item.amount (e.g. formatted in user's currency).
  final String? displayAmount;
  final VoidCallback? onTap;

  static Color _amountColor(TransactionType type) {
    switch (type) {
      case TransactionType.added:
        return const Color.fromARGB(255, 1, 197, 50); // green - income
      case TransactionType.deducted:
        return const Color.fromARGB(255, 208, 12, 1); // red - expense
      case TransactionType.transferred:
        return const Color.fromARGB(255, 2, 95, 195); // blue - transfer
    }
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        splashColor: const Color(0xFF1C1C1E).withOpacity(0.06),
        highlightColor: const Color(0xFF1C1C1E).withOpacity(0.04),
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: 4,
            vertical: isNarrow ? 12 : 14,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Square icon placeholder with emoji (light grey, rounded)
              Container(
                width: isNarrow ? 42 : 46,
                height: isNarrow ? 42 : 46,
                decoration: BoxDecoration(
                  color: const Color(0xFFF2F2F7),
                  borderRadius: BorderRadius.circular(12),
                ),
                alignment: Alignment.center,
                child: Text(
                  item.type == TransactionType.transferred ? '💸' : item.emoji,
                  style: TextStyle(fontSize: isNarrow ? 22 : 24),
                ),
              ),
              SizedBox(width: isNarrow ? 14 : 16),
              // Category name + description (left-aligned, stacked); show "Transfer" for transfers
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      item.type == TransactionType.transferred ? 'Transfer' : item.categoryName,
                      style: const TextStyle(
                        color: Color(0xFF1C1C1E),
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (item.description != null &&
                        item.description!.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        item.description!,
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: isNarrow ? 12 : 13,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
              SizedBox(width: isNarrow ? 12 : 16),
              Text(
                displayAmount ?? item.amount,
                style: TextStyle(
                  color: _amountColor(item.type),
                  fontSize: 15,
                  fontWeight: FontWeight.w400,
                ),
              ),
              const SizedBox(width: 6),
              Icon(
                Icons.chevron_right_rounded,
                color: Colors.grey[400],
                size: 22,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

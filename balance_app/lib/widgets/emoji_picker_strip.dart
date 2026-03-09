import 'package:flutter/material.dart';
import '../data/emoji_options.dart';

const int _emojiRows = 5;

/// Horizontal scrollable grid of emojis (5 rows). User can swipe right to explore. Tap to select.
class EmojiPickerStrip extends StatelessWidget {
  const EmojiPickerStrip({
    super.key,
    required this.selectedEmoji,
    required this.onEmojiSelected,
    this.cellSize = 44,
    this.emojiSize = 26,
  });

  final String? selectedEmoji;
  final ValueChanged<String> onEmojiSelected;
  final double cellSize;
  final double emojiSize;

  @override
  Widget build(BuildContext context) {
    final list = emojiOptionsForCategories;
    final columnCount = (list.length / _emojiRows).ceil();
    const rowSpacing = 6.0;
    const columnSpacing = 8.0;
    final rowHeight = cellSize + rowSpacing;
    // Add small buffer to avoid overflow from elevation/border/rounding
    final totalHeight = _emojiRows * rowHeight - rowSpacing + 4.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'Choose emoji',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.grey[700],
          ),
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: totalHeight,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.only(right: 8),
            itemCount: columnCount,
            itemBuilder: (context, columnIndex) {
              return Padding(
                padding: EdgeInsets.only(right: columnIndex < columnCount - 1 ? columnSpacing : 0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: List.generate(_emojiRows, (rowIndex) {
                    final index = columnIndex * _emojiRows + rowIndex;
                    if (index >= list.length) return const SizedBox.shrink();
                    final emoji = list[index];
                    final selected = selectedEmoji == emoji;
                    return Padding(
                      padding: EdgeInsets.only(bottom: rowIndex < _emojiRows - 1 ? rowSpacing : 0),
                      child: Material(
                        color: selected ? Colors.white : const Color(0xFFF2F2F7),
                        borderRadius: BorderRadius.circular(12),
                        elevation: selected ? 1 : 0,
                        shadowColor: Colors.black26,
                        child: InkWell(
                          onTap: () => onEmojiSelected(emoji),
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            width: cellSize,
                            height: cellSize,
                            alignment: Alignment.center,
                            child: Text(
                              emoji,
                              style: TextStyle(
                                fontSize: emojiSize,
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  }),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Swipe right to see more emojis',
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[500],
          ),
        ),
      ],
    );
  }
}

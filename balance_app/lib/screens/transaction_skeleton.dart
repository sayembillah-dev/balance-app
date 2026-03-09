import 'package:flutter/material.dart';

/// Skeleton placeholder for transaction card while loading. Animated.
class TransactionSkeletonCard extends StatefulWidget {
  const TransactionSkeletonCard({
    super.key,
    this.isNarrow = false,
  });

  final bool isNarrow;

  @override
  State<TransactionSkeletonCard> createState() => _TransactionSkeletonCardState();
}

class _TransactionSkeletonCardState extends State<TransactionSkeletonCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);
    _animation = Tween<double>(begin: 0.3, end: 0.7).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE5E5EA), width: 1),
          ),
          clipBehavior: Clip.hardEdge,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                height: widget.isNarrow ? 52 : 56,
                color: Color.lerp(
                  const Color(0xFFE8E8ED),
                  const Color(0xFFF2F2F7),
                  _animation.value,
                ),
              ),
              Padding(
                padding: EdgeInsets.fromLTRB(
                  widget.isNarrow ? 10 : 12,
                  widget.isNarrow ? 8 : 10,
                  widget.isNarrow ? 10 : 12,
                  widget.isNarrow ? 8 : 10,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      height: 14,
                      width: 80,
                      decoration: BoxDecoration(
                        color: Color.lerp(
                          const Color(0xFFE8E8ED),
                          const Color(0xFFD1D1D6),
                          _animation.value,
                        ),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    SizedBox(height: widget.isNarrow ? 6 : 8),
                    Container(
                      height: 10,
                      width: 120,
                      decoration: BoxDecoration(
                        color: Color.lerp(
                          const Color(0xFFE8E8ED),
                          const Color(0xFFD1D1D6),
                          _animation.value,
                        ),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    SizedBox(height: widget.isNarrow ? 8 : 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          height: 12,
                          width: 60,
                          decoration: BoxDecoration(
                            color: Color.lerp(
                              const Color(0xFFE8E8ED),
                              const Color(0xFFD1D1D6),
                              _animation.value,
                            ),
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                        Container(
                          height: 10,
                          width: 50,
                          decoration: BoxDecoration(
                            color: Color.lerp(
                              const Color(0xFFE8E8ED),
                              const Color(0xFFD1D1D6),
                              _animation.value,
                            ),
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

/// Skeleton for a single transaction list row (square + lines + amount). Animated.
class TransactionSkeletonRow extends StatefulWidget {
  const TransactionSkeletonRow({
    super.key,
    this.isNarrow = false,
  });

  final bool isNarrow;

  @override
  State<TransactionSkeletonRow> createState() => _TransactionSkeletonRowState();
}

class _TransactionSkeletonRowState extends State<TransactionSkeletonRow>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);
    _animation = Tween<double>(begin: 0.3, end: 0.7).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Padding(
          padding: EdgeInsets.symmetric(
            horizontal: 0,
            vertical: widget.isNarrow ? 12 : 14,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: widget.isNarrow ? 42 : 46,
                height: widget.isNarrow ? 42 : 46,
                decoration: BoxDecoration(
                  color: Color.lerp(
                    const Color(0xFFE8E8ED),
                    const Color(0xFFD1D1D6),
                    _animation.value,
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              SizedBox(width: widget.isNarrow ? 14 : 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      height: 14,
                      width: 100,
                      decoration: BoxDecoration(
                        color: Color.lerp(
                          const Color(0xFFE8E8ED),
                          const Color(0xFFD1D1D6),
                          _animation.value,
                        ),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    SizedBox(height: 6),
                    Container(
                      height: 10,
                      width: 140,
                      decoration: BoxDecoration(
                        color: Color.lerp(
                          const Color(0xFFE8E8ED),
                          const Color(0xFFD1D1D6),
                          _animation.value,
                        ),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                height: 14,
                width: 50,
                decoration: BoxDecoration(
                  color: Color.lerp(
                    const Color(0xFFE8E8ED),
                    const Color(0xFFD1D1D6),
                    _animation.value,
                  ),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const SizedBox(width: 4),
              Icon(Icons.chevron_right_rounded, color: Colors.grey[300], size: 22),
            ],
          ),
        );
      },
    );
  }
}

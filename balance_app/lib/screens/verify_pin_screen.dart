import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/app_theme.dart';
import '../data/local_storage.dart';

/// Screen that asks for current PIN; pops with true if correct, null otherwise.
class VerifyPinScreen extends StatefulWidget {
  const VerifyPinScreen({
    super.key,
    this.title = 'Enter PIN',
    this.subtitle,
  });

  final String title;
  final String? subtitle;

  @override
  State<VerifyPinScreen> createState() => _VerifyPinScreenState();
}

class _VerifyPinScreenState extends State<VerifyPinScreen> {
  static const int _pinLength = 4;
  final List<String> _digits = [];
  String? _error;
  bool _validating = false;

  void _onDigit(String digit) {
    if (_validating || _digits.length >= _pinLength) return;
    setState(() {
      _error = null;
      _digits.add(digit);
    });
    if (_digits.length == _pinLength) _validate();
  }

  void _onBackspace() {
    if (_validating || _digits.isEmpty) return;
    setState(() {
      _error = null;
      _digits.removeLast();
    });
  }

  Future<void> _validate() async {
    setState(() => _validating = true);
    final pin = _digits.join();
    final ok = await validatePin(pin);
    if (!mounted) return;
    if (ok) {
      Navigator.of(context).pop(true);
    } else {
      setState(() {
        _validating = false;
        _digits.clear();
        _error = 'Wrong PIN. Try again.';
      });
      HapticFeedback.heavyImpact();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF2F2F7),
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        elevation: 0,
        title: Text(
          widget.title,
          style: const TextStyle(
            fontFamily: AppFonts.family,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            children: [
              const SizedBox(height: 24),
              if (widget.subtitle != null) ...[
                Text(
                  widget.subtitle!,
                  style: TextStyle(
                    fontFamily: AppFonts.family,
                    color: Colors.black87,
                    fontSize: 16,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
              ],
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(_pinLength, (i) {
                  final filled = i < _digits.length;
                  return Container(
                    margin: const EdgeInsets.symmetric(horizontal: 8),
                    width: 14,
                    height: 14,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: filled
                          ? Colors.black87
                          : Colors.black.withValues(alpha: 0.2),
                    ),
                  );
                }),
              ),
              if (_error != null) ...[
                const SizedBox(height: 16),
                Text(
                  _error!,
                  style: TextStyle(
                    fontFamily: AppFonts.family,
                    color: Colors.red.shade700,
                    fontSize: 14,
                  ),
                ),
              ],
              const Spacer(),
              _PinPad(
                onDigit: _onDigit,
                onBackspace: _onBackspace,
                enabled: !_validating,
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}

class _PinPad extends StatelessWidget {
  const _PinPad({
    required this.onDigit,
    required this.onBackspace,
    this.enabled = true,
  });

  final ValueChanged<String> onDigit;
  final VoidCallback onBackspace;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final color = enabled ? const Color(0xFF1C1C1E) : Colors.black26;
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _PadButton(label: '1', onTap: () => onDigit('1'), color: color, enabled: enabled),
            _PadButton(label: '2', onTap: () => onDigit('2'), color: color, enabled: enabled),
            _PadButton(label: '3', onTap: () => onDigit('3'), color: color, enabled: enabled),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _PadButton(label: '4', onTap: () => onDigit('4'), color: color, enabled: enabled),
            _PadButton(label: '5', onTap: () => onDigit('5'), color: color, enabled: enabled),
            _PadButton(label: '6', onTap: () => onDigit('6'), color: color, enabled: enabled),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _PadButton(label: '7', onTap: () => onDigit('7'), color: color, enabled: enabled),
            _PadButton(label: '8', onTap: () => onDigit('8'), color: color, enabled: enabled),
            _PadButton(label: '9', onTap: () => onDigit('9'), color: color, enabled: enabled),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(width: 72, height: 72),
            _PadButton(label: '0', onTap: () => onDigit('0'), color: color, enabled: enabled),
            _PadButton(icon: Icons.backspace_outlined, onTap: onBackspace, color: color, enabled: enabled),
          ],
        ),
      ],
    );
  }
}

class _PadButton extends StatelessWidget {
  const _PadButton({
    this.label,
    this.icon,
    required this.onTap,
    required this.color,
    this.enabled = true,
  }) : assert(label != null || icon != null);

  final String? label;
  final IconData? icon;
  final VoidCallback onTap;
  final Color color;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: enabled ? onTap : null,
          borderRadius: BorderRadius.circular(36),
          child: Container(
            width: 72,
            height: 72,
            alignment: Alignment.center,
            child: label != null
                ? Text(
                    label!,
                    style: TextStyle(
                      fontFamily: AppFonts.family,
                      fontSize: 28,
                      fontWeight: AppFonts.medium,
                      color: color,
                    ),
                  )
                : Icon(icon, size: 28, color: color),
          ),
        ),
      ),
    );
  }
}

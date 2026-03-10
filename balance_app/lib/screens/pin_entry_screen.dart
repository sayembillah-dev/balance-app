import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/app_theme.dart';
import '../data/local_storage.dart';

/// Lock screen: user must enter correct PIN to reach the dashboard.
class PinEntryScreen extends StatefulWidget {
  const PinEntryScreen({super.key});

  @override
  State<PinEntryScreen> createState() => _PinEntryScreenState();
}

class _PinEntryScreenState extends State<PinEntryScreen> {
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
      Navigator.of(context).pushReplacementNamed('/dashboard');
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
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            children: [
              const Spacer(flex: 2),
              Text(
                'Enter PIN',
                style: TextStyle(
                  fontFamily: AppFonts.family,
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: AppFonts.semiBold,
                ),
              ),
              const SizedBox(height: 32),
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
                          ? Colors.white
                          : Colors.white.withValues(alpha: 0.25),
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
                    color: Colors.red.shade300,
                    fontSize: 14,
                  ),
                ),
              ],
              const Spacer(flex: 3),
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
    required this.enabled,
  });

  final ValueChanged<String> onDigit;
  final VoidCallback onBackspace;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _PadButton(label: '1', onTap: () => onDigit('1'), enabled: enabled),
            _PadButton(label: '2', onTap: () => onDigit('2'), enabled: enabled),
            _PadButton(label: '3', onTap: () => onDigit('3'), enabled: enabled),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _PadButton(label: '4', onTap: () => onDigit('4'), enabled: enabled),
            _PadButton(label: '5', onTap: () => onDigit('5'), enabled: enabled),
            _PadButton(label: '6', onTap: () => onDigit('6'), enabled: enabled),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _PadButton(label: '7', onTap: () => onDigit('7'), enabled: enabled),
            _PadButton(label: '8', onTap: () => onDigit('8'), enabled: enabled),
            _PadButton(label: '9', onTap: () => onDigit('9'), enabled: enabled),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(width: 72, height: 72),
            _PadButton(label: '0', onTap: () => onDigit('0'), enabled: enabled),
            _PadButton(
              icon: Icons.backspace_outlined,
              onTap: onBackspace,
              enabled: enabled,
            ),
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
    required this.enabled,
  }) : assert(label != null || icon != null);

  final String? label;
  final IconData? icon;
  final VoidCallback onTap;
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
                      color: enabled
                          ? Colors.white
                          : Colors.white.withValues(alpha: 0.4),
                    ),
                  )
                : Icon(
                    icon,
                    size: 28,
                    color: enabled
                        ? Colors.white
                        : Colors.white.withValues(alpha: 0.4),
                  ),
          ),
        ),
      ),
    );
  }
}

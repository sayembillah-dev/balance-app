import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/app_theme.dart';
import '../data/local_storage.dart';

/// Change PIN: verify current PIN, then enter and confirm new PIN.
class ChangePinScreen extends StatefulWidget {
  const ChangePinScreen({super.key});

  @override
  State<ChangePinScreen> createState() => _ChangePinScreenState();
}

class _ChangePinScreenState extends State<ChangePinScreen> {
  static const int _pinLength = 4;
  int _step = 0; // 0 = current, 1 = new, 2 = confirm new
  final List<String> _currentPin = [];
  final List<String> _newPin = [];
  final List<String> _confirmPin = [];
  String? _error;
  bool _verifying = false;

  List<String> get _digits {
    if (_step == 0) return _currentPin;
    if (_step == 1) return _newPin;
    return _confirmPin;
  }

  String get _title {
    if (_step == 0) return 'Current PIN';
    if (_step == 1) return 'New PIN';
    return 'Confirm new PIN';
  }

  String get _subtitle {
    if (_step == 0) return 'Enter your current PIN';
    if (_step == 1) return 'Choose a new 4-digit PIN';
    return 'Enter your new PIN again';
  }

  void _onDigit(String digit) {
    if (_verifying || _digits.length >= _pinLength) return;
    setState(() {
      _error = null;
      if (_step == 0) _currentPin.add(digit);
      else if (_step == 1) _newPin.add(digit);
      else _confirmPin.add(digit);
    });
    if (_digits.length == _pinLength) _advance();
  }

  void _onBackspace() {
    if (_verifying) return;
    setState(() {
      _error = null;
      if (_step == 0 && _currentPin.isNotEmpty) _currentPin.removeLast();
      else if (_step == 1 && _newPin.isNotEmpty) _newPin.removeLast();
      else if (_step == 2 && _confirmPin.isNotEmpty) _confirmPin.removeLast();
    });
  }

  Future<void> _advance() async {
    if (_step == 0) {
      setState(() => _verifying = true);
      final ok = await validatePin(_currentPin.join());
      if (!mounted) return;
      if (ok) {
        setState(() {
          _step = 1;
          _verifying = false;
        });
      } else {
        setState(() {
          _verifying = false;
          _currentPin.clear();
          _error = 'Wrong PIN. Try again.';
        });
        HapticFeedback.heavyImpact();
      }
    } else if (_step == 1) {
      setState(() => _step = 2);
    } else {
      final a = _newPin.join();
      final b = _confirmPin.join();
      if (a != b) {
        setState(() {
          _error = 'PINs do not match';
          _confirmPin.clear();
        });
        HapticFeedback.heavyImpact();
      } else {
        await savePinHash(a);
        if (!mounted) return;
        Navigator.of(context).pop(true);
      }
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
          _title,
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
              Text(
                _subtitle,
                style: TextStyle(
                  fontFamily: AppFonts.family,
                  color: Colors.black87,
                  fontSize: 16,
                ),
                textAlign: TextAlign.center,
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
                enabled: !_verifying,
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

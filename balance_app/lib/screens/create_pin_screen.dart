import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/app_theme.dart';
import '../data/local_storage.dart';

/// Create a new 4-digit PIN. Asks for PIN then confirmation; saves and enables PIN.
class CreatePinScreen extends StatefulWidget {
  const CreatePinScreen({super.key});

  @override
  State<CreatePinScreen> createState() => _CreatePinScreenState();
}

class _CreatePinScreenState extends State<CreatePinScreen> {
  static const int _pinLength = 4;
  int _step = 0; // 0 = enter, 1 = confirm
  final List<String> _firstPin = [];
  final List<String> _confirmPin = [];
  String? _error;

  List<String> get _currentDigits => _step == 0 ? _firstPin : _confirmPin;

  void _onDigit(String digit) {
    if (_currentDigits.length >= _pinLength) return;
    setState(() {
      _error = null;
      if (_step == 0) {
        _firstPin.add(digit);
      } else {
        _confirmPin.add(digit);
      }
    });
    if (_currentDigits.length == _pinLength) _advance();
  }

  void _onBackspace() {
    if (_step == 0) {
      if (_firstPin.isEmpty) return;
      setState(() {
        _error = null;
        _firstPin.removeLast();
      });
    } else {
      if (_confirmPin.isEmpty) return;
      setState(() {
        _error = null;
        _confirmPin.removeLast();
      });
    }
  }

  void _advance() {
    if (_step == 0) {
      setState(() => _step = 1);
    } else {
      final a = _firstPin.join();
      final b = _confirmPin.join();
      if (a != b) {
        setState(() {
          _error = 'PINs do not match';
          _confirmPin.clear();
        });
        HapticFeedback.heavyImpact();
      } else {
        _saveAndPop(a);
      }
    }
  }

  Future<void> _saveAndPop(String pin) async {
    await savePinHash(pin);
    await savePinEnabled(true);
    if (!mounted) return;
    Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final isConfirm = _step == 1;
    return Scaffold(
      backgroundColor: const Color(0xFFF2F2F7),
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        elevation: 0,
        title: Text(
          isConfirm ? 'Confirm PIN' : 'Create PIN',
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
                isConfirm
                    ? 'Enter your PIN again'
                    : 'Choose a 4-digit PIN to unlock the app',
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
                  final filled = i < _currentDigits.length;
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
  });

  final ValueChanged<String> onDigit;
  final VoidCallback onBackspace;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _PadButton(label: '1', onTap: () => onDigit('1')),
            _PadButton(label: '2', onTap: () => onDigit('2')),
            _PadButton(label: '3', onTap: () => onDigit('3')),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _PadButton(label: '4', onTap: () => onDigit('4')),
            _PadButton(label: '5', onTap: () => onDigit('5')),
            _PadButton(label: '6', onTap: () => onDigit('6')),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _PadButton(label: '7', onTap: () => onDigit('7')),
            _PadButton(label: '8', onTap: () => onDigit('8')),
            _PadButton(label: '9', onTap: () => onDigit('9')),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(width: 72, height: 72),
            _PadButton(label: '0', onTap: () => onDigit('0')),
            _PadButton(
              icon: Icons.backspace_outlined,
              onTap: onBackspace,
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
  }) : assert(label != null || icon != null);

  final String? label;
  final IconData? icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(36),
          child: Container(
            width: 72,
            height: 72,
            alignment: Alignment.center,
            child: label != null
                ? Text(
                    label!,
                    style: const TextStyle(
                      fontFamily: AppFonts.family,
                      fontSize: 28,
                      fontWeight: AppFonts.medium,
                      color: Color(0xFF1C1C1E),
                    ),
                  )
                : Icon(icon, size: 28, color: const Color(0xFF1C1C1E)),
          ),
        ),
      ),
    );
  }
}

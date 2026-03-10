import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../data/local_storage.dart';
import 'create_pin_screen.dart';
import 'change_pin_screen.dart';
import 'verify_pin_screen.dart';

/// Settings for App PIN: create, enable/disable, or change PIN.
class PinSettingsScreen extends StatefulWidget {
  const PinSettingsScreen({super.key});

  @override
  State<PinSettingsScreen> createState() => _PinSettingsScreenState();
}

class _PinSettingsScreenState extends State<PinSettingsScreen> {
  bool _hasPin = false;
  bool _pinEnabled = false;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final pinExists = await hasPin();
    final enabled = await loadPinEnabled();
    if (!mounted) return;
    setState(() {
      _hasPin = pinExists;
      _pinEnabled = enabled;
      _loading = false;
    });
  }

  Future<void> _toggleEnabled(bool value) async {
    if (!_hasPin && value) {
      final created = await Navigator.of(context).push<bool>(
        MaterialPageRoute(builder: (_) => const CreatePinScreen()),
      );
      if (mounted && created == true) setState(() { _hasPin = true; _pinEnabled = true; });
      return;
    }
    if (!value) {
      // Turning off: require PIN first
      final verified = await Navigator.of(context).push<bool>(
        MaterialPageRoute(
          builder: (_) => const VerifyPinScreen(
            title: 'Turn off PIN',
            subtitle: 'Enter your PIN to turn off the app lock.',
          ),
        ),
      );
      if (verified != true || !mounted) return;
      await savePinEnabled(false);
      if (mounted) setState(() => _pinEnabled = false);
    } else {
      await savePinEnabled(true);
      if (mounted) setState(() => _pinEnabled = true);
    }
  }

  Future<void> _createPin() async {
    final created = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => const CreatePinScreen()),
    );
    if (mounted && created == true) await _load();
  }

  Future<void> _changePin() async {
    final changed = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => const ChangePinScreen()),
    );
    if (mounted && changed == true) await _load();
  }

  Future<void> _removePin() async {
    final verified = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => const VerifyPinScreen(
          title: 'Remove PIN',
          subtitle: 'Enter your PIN to remove it.',
        ),
      ),
    );
    if (verified != true || !mounted) return;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove PIN?'),
        content: const Text(
          'Your PIN will be removed and the app will no longer ask for it. You can create a new one later.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
    if (confirm != true || !mounted) return;
    await clearPin();
    if (mounted) setState(() { _hasPin = false; _pinEnabled = false; });
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(
        backgroundColor: const Color(0xFFF2F2F7),
        appBar: AppBar(
          backgroundColor: Colors.black,
          foregroundColor: Colors.white,
          elevation: 0,
          title: const Text(
            'App PIN',
            style: TextStyle(fontFamily: AppFonts.family, fontWeight: FontWeight.w600),
          ),
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF2F2F7),
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'App PIN',
          style: TextStyle(fontFamily: AppFonts.family, fontWeight: FontWeight.w600),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
        children: [
          if (!_hasPin) ...[
            Text(
              'Create a 4-digit PIN to lock the app when you open it. Data stays on this device.',
              style: TextStyle(
                fontFamily: AppFonts.family,
                fontSize: 15,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _createPin,
                style: FilledButton.styleFrom(
                  backgroundColor: Colors.black,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Create PIN'),
              ),
            ),
          ] else ...[
            SwitchListTile(
              value: _pinEnabled,
              onChanged: _toggleEnabled,
              title: const Text(
                'Require PIN to open app',
                style: TextStyle(fontFamily: AppFonts.family, fontWeight: FontWeight.w500),
              ),
              activeColor: Colors.black,
            ),
            const SizedBox(height: 8),
            ListTile(
              leading: const Icon(Icons.edit_rounded, color: Color(0xFF1C1C1E)),
              title: const Text(
                'Change PIN',
                style: TextStyle(fontFamily: AppFonts.family, fontWeight: FontWeight.w500),
              ),
              trailing: const Icon(Icons.chevron_right_rounded, color: Colors.grey),
              onTap: _changePin,
            ),
            const Divider(height: 1),
            ListTile(
              leading: Icon(Icons.delete_outline_rounded, color: Colors.red.shade700),
              title: Text(
                'Remove PIN',
                style: TextStyle(
                  fontFamily: AppFonts.family,
                  fontWeight: FontWeight.w500,
                  color: Colors.red.shade700,
                ),
              ),
              onTap: _removePin,
            ),
          ],
        ],
      ),
    );
  }
}

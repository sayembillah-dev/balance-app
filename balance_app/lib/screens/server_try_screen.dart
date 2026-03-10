import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../data/local_storage.dart';

/// First-time welcome only: Try (local) or Sign in. User sees both options once;
/// if they choose Try, next launches go straight to dashboard. Sign in also in Settings.
class ServerTryScreen extends StatelessWidget {
  const ServerTryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            children: [
              const Spacer(flex: 3),
              // Logo + name
              Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.balance_rounded,
                    size: 40,
                    color: Colors.black.withValues(alpha: 0.9),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'Balance',
                    style: TextStyle(
                      fontFamily: AppFonts.family,
                      color: Colors.black.withValues(alpha: 0.9),
                      fontSize: 28,
                      fontWeight: AppFonts.semiBold,
                      letterSpacing: -0.5,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                'Track your money, your way.',
                style: textTheme.bodyLarge?.copyWith(
                  color: Colors.black.withValues(alpha: 0.5),
                  fontSize: 16,
                  letterSpacing: 0.2,
                ),
              ),
              const Spacer(flex: 2),
              // Try — primary CTA; persist choice so next launch goes to dashboard
              SizedBox(
                width: double.infinity,
                height: 52,
                child: FilledButton(
                  onPressed: () async {
                    await saveChoseTryMode(true);
                    if (context.mounted) {
                      Navigator.of(context).pushReplacementNamed('/dashboard');
                    }
                  },
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.black,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: Text(
                    'Try',
                    style: TextStyle(
                      fontFamily: AppFonts.family,
                      fontWeight: AppFonts.semiBold,
                      fontSize: 16,
                      letterSpacing: 0.2,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              // Sign in — placeholder; also available in Settings
              SizedBox(
                width: double.infinity,
                height: 52,
                child: OutlinedButton(
                  onPressed: null,
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(
                      color: Colors.black.withValues(alpha: 0.2),
                      width: 1.2,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Sign in',
                        style: TextStyle(
                          fontFamily: AppFonts.family,
                          fontWeight: AppFonts.medium,
                          fontSize: 16,
                          color: Colors.black.withValues(alpha: 0.5),
                          letterSpacing: 0.2,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Coming soon',
                        style: TextStyle(
                          fontFamily: AppFonts.family,
                          fontWeight: AppFonts.regular,
                          fontSize: 12,
                          color: Colors.black.withValues(alpha: 0.35),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const Spacer(flex: 3),
            ],
          ),
        ),
      ),
    );
  }
}

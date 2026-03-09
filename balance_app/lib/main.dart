import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'theme/app_theme.dart';
import 'screens/dashboard_screen.dart';
import 'screens/add_transaction_screen.dart';
import 'screens/transactions_screen.dart';
import 'screens/transaction_detail_screen.dart';
import 'screens/accounts_screen.dart';
import 'screens/account_detail_screen.dart';
import 'screens/categories_screen.dart';
import 'screens/presets_screen.dart';
import 'screens/budgets_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/server_try_screen.dart';

void main() {
  runApp(const ProviderScope(child: BalanceApp()));
}

class BalanceApp extends StatelessWidget {
  const BalanceApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Balance',
      debugShowCheckedModeBanner: false,
      theme: appTheme,
      builder: (context, child) {
        return DefaultTextStyle(
          style: TextStyle(fontFamily: AppFonts.family),
          child: child!,
        );
      },
      initialRoute: '/',
      routes: {
        '/': (context) => const SplashScreen(),
        '/server-try': (context) => const ServerTryScreen(),
        '/dashboard': (context) => const DashboardScreen(),
        '/add-transaction': (context) => const AddTransactionScreen(),
        '/transactions': (context) => const TransactionsScreen(),
        '/transaction-detail': (context) => const TransactionDetailScreen(),
        '/accounts': (context) => const AccountsScreen(),
        '/account-detail': (context) => const AccountDetailScreen(),
        '/categories': (context) => const CategoriesScreen(),
        '/presets': (context) => const PresetsScreen(),
        '/budgets': (context) => const BudgetsScreen(),
        '/settings': (context) => const SettingsScreen(),
      },
    );
  }
}

/// Animated splash screen: white background, black "Balance" logo with icon.
/// After the animation completes, navigates to the home screen.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
      ),
    );

    _scaleAnimation = Tween<double>(begin: 0.6, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.7, curve: Curves.easeOutCubic),
      ),
    );

    _controller.forward();

    // After splash animation + short hold, navigate to Server/Try screen
    Future.delayed(const Duration(milliseconds: 2800), _navigateToWelcome);
  }

  void _navigateToWelcome() {
    if (!mounted) return;
    Navigator.of(context).pushReplacementNamed('/server-try');
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            return Opacity(
              opacity: _fadeAnimation.value,
              child: Transform.scale(
                scale: _scaleAnimation.value,
                child: child,
              ),
            );
          },
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Dummy icon – replace with your own asset later, e.g.:
              // Image.asset('assets/icons/app_icon.png', width: 48, height: 48)
              Icon(Icons.balance_rounded, size: 48, color: Colors.black),
              const SizedBox(width: 12),
              Text(
                'Balance',
                style: TextStyle(
                  fontFamily: AppFonts.family,
                  color: Colors.black,
                  fontSize: 36,
                  fontWeight: AppFonts.semiBold,
                  letterSpacing: -0.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

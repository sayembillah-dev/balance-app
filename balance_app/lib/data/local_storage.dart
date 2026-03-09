import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'models.dart';

const String _keyAccounts = 'accounts';
const String _keyTransactions = 'transactions';
const String _keyPresets = 'presets';
const String _keyMonthlyBudgets = 'monthly_budgets';
const String _keyCategories = 'categories';
const String _keySelectedCurrency = 'selected_currency';

/// Returns SharedPreferences, or null if the plugin is not available (e.g. after hot restart, or in tests).
Future<SharedPreferences?> _prefs() async {
  try {
    return await SharedPreferences.getInstance();
  } on MissingPluginException catch (_) {
    if (kDebugMode) {
      // ignore: avoid_print
      print(
        'shared_preferences not available (e.g. hot restart); using in-memory fallback.',
      );
    }
    return null;
  }
}

Future<void> saveAccounts(List<AccountItem> list) async {
  final prefs = await _prefs();
  if (prefs == null) return;
  await prefs.setString(
    _keyAccounts,
    jsonEncode(list.map((e) => e.toJson()).toList()),
  );
}

Future<List<AccountItem>> loadAccounts() async {
  final prefs = await _prefs();
  if (prefs == null) return [];
  final raw = prefs.getString(_keyAccounts);
  if (raw == null) return [];
  try {
    final list = jsonDecode(raw) as List<dynamic>;
    return list
        .map((e) => AccountItem.fromJson(e as Map<String, dynamic>))
        .toList();
  } catch (_) {
    return [];
  }
}

Future<void> saveTransactions(List<TransactionItem> list) async {
  final prefs = await _prefs();
  if (prefs == null) return;
  await prefs.setString(
    _keyTransactions,
    jsonEncode(list.map((e) => e.toJson()).toList()),
  );
}

Future<List<TransactionItem>> loadTransactions() async {
  final prefs = await _prefs();
  if (prefs == null) return [];
  final raw = prefs.getString(_keyTransactions);
  if (raw == null) return [];
  try {
    final list = jsonDecode(raw) as List<dynamic>;
    return list
        .map((e) => TransactionItem.fromJson(e as Map<String, dynamic>))
        .toList();
  } catch (_) {
    return [];
  }
}

Future<void> savePresets(List<PresetItem> list) async {
  final prefs = await _prefs();
  if (prefs == null) return;
  await prefs.setString(
    _keyPresets,
    jsonEncode(list.map((e) => e.toJson()).toList()),
  );
}

Future<List<PresetItem>> loadPresets() async {
  final prefs = await _prefs();
  if (prefs == null) return [];
  final raw = prefs.getString(_keyPresets);
  if (raw == null) return [];
  try {
    final list = jsonDecode(raw) as List<dynamic>;
    return list
        .map((e) => PresetItem.fromJson(e as Map<String, dynamic>))
        .toList();
  } catch (_) {
    return [];
  }
}

Future<void> saveMonthlyBudgets(List<MonthlyBudget> list) async {
  final prefs = await _prefs();
  if (prefs == null) return;
  await prefs.setString(
    _keyMonthlyBudgets,
    jsonEncode(list.map((e) => e.toJson()).toList()),
  );
}

Future<List<MonthlyBudget>> loadMonthlyBudgets() async {
  final prefs = await _prefs();
  if (prefs == null) return [];
  final raw = prefs.getString(_keyMonthlyBudgets);
  if (raw == null) return [];
  try {
    final list = jsonDecode(raw) as List<dynamic>;
    return list
        .map((e) => MonthlyBudget.fromJson(e as Map<String, dynamic>))
        .toList();
  } catch (_) {
    return [];
  }
}

Future<void> saveCategories(List<TransactionCategory> list) async {
  final prefs = await _prefs();
  if (prefs == null) return;
  await prefs.setString(
    _keyCategories,
    jsonEncode(list.map((e) => e.toJson()).toList()),
  );
}

Future<List<TransactionCategory>> loadCategories() async {
  final prefs = await _prefs();
  if (prefs == null) return [];
  final raw = prefs.getString(_keyCategories);
  if (raw == null) return [];
  try {
    final list = jsonDecode(raw) as List<dynamic>;
    return list
        .map((e) => TransactionCategory.fromJson(e as Map<String, dynamic>))
        .toList();
  } catch (_) {
    return [];
  }
}

const String defaultCurrencyCode = 'USD';

Future<void> saveSelectedCurrency(String code) async {
  final prefs = await _prefs();
  if (prefs == null) return;
  await prefs.setString(_keySelectedCurrency, code);
}

Future<String> loadSelectedCurrency() async {
  final prefs = await _prefs();
  if (prefs == null) return defaultCurrencyCode;
  return prefs.getString(_keySelectedCurrency) ?? defaultCurrencyCode;
}

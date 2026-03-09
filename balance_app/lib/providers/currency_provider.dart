import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/local_storage.dart';

class SelectedCurrencyNotifier extends AsyncNotifier<String> {
  @override
  Future<String> build() async => await loadSelectedCurrency();

  Future<void> setCurrency(String code) async {
    await saveSelectedCurrency(code);
    state = AsyncValue.data(code);
  }
}

final selectedCurrencyProvider =
    AsyncNotifierProvider<SelectedCurrencyNotifier, String>(SelectedCurrencyNotifier.new);

/// Synchronous access to current currency code; use when building UI that must not depend on async.
/// Returns [defaultCurrencyCode] until loaded.
final selectedCurrencyCodeProvider = Provider<String>((ref) {
  return ref.watch(selectedCurrencyProvider).valueOrNull ?? defaultCurrencyCode;
});

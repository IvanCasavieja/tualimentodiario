import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class LogObserver extends ProviderObserver {
  @override
  void didAddProvider(ProviderBase provider, Object? value, ProviderContainer container) {
    if (kDebugMode) {
      debugPrint('[RP] added ${provider.name ?? provider.runtimeType} = $value');
    }
    super.didAddProvider(provider, value, container);
  }

  @override
  void didUpdateProvider(ProviderBase provider, Object? previousValue, Object? newValue, ProviderContainer container) {
    if (kDebugMode) {
      debugPrint('[RP] update ${provider.name ?? provider.runtimeType} -> $newValue (prev: $previousValue)');
    }
    super.didUpdateProvider(provider, previousValue, newValue, container);
  }

  @override
  void didDisposeProvider(ProviderBase provider, ProviderContainer container) {
    if (kDebugMode) {
      debugPrint('[RP] dispose ${provider.name ?? provider.runtimeType}');
    }
    super.didDisposeProvider(provider, container);
  }
}

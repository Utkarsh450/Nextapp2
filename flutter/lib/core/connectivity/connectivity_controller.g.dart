// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'connectivity_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Matches `useOnline` (`hooks/useOnline.ts`) — whether the device
/// currently has network connectivity, via the real OS-level signal
/// (`connectivity_plus`) rather than the browser's `navigator.onLine`.

@ProviderFor(IsOnline)
final isOnlineProvider = IsOnlineProvider._();

/// Matches `useOnline` (`hooks/useOnline.ts`) — whether the device
/// currently has network connectivity, via the real OS-level signal
/// (`connectivity_plus`) rather than the browser's `navigator.onLine`.
final class IsOnlineProvider extends $StreamNotifierProvider<IsOnline, bool> {
  /// Matches `useOnline` (`hooks/useOnline.ts`) — whether the device
  /// currently has network connectivity, via the real OS-level signal
  /// (`connectivity_plus`) rather than the browser's `navigator.onLine`.
  IsOnlineProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'isOnlineProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$isOnlineHash();

  @$internal
  @override
  IsOnline create() => IsOnline();
}

String _$isOnlineHash() => r'0b3859566a27a1bfa82fbd348f5fb0ceda30f0a5';

/// Matches `useOnline` (`hooks/useOnline.ts`) — whether the device
/// currently has network connectivity, via the real OS-level signal
/// (`connectivity_plus`) rather than the browser's `navigator.onLine`.

abstract class _$IsOnline extends $StreamNotifier<bool> {
  Stream<bool> build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<AsyncValue<bool>, bool>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<bool>, bool>,
              AsyncValue<bool>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}

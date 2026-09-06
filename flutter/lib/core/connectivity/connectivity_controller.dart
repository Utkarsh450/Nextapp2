import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'connectivity_controller.g.dart';

/// Matches `useOnline` (`hooks/useOnline.ts`) — whether the device
/// currently has network connectivity, via the real OS-level signal
/// (`connectivity_plus`) rather than the browser's `navigator.onLine`.
@riverpod
class IsOnline extends _$IsOnline {
  @override
  Stream<bool> build() async* {
    final connectivity = Connectivity();
    final initial = await connectivity.checkConnectivity();
    yield !initial.contains(ConnectivityResult.none);
    yield* connectivity.onConnectivityChanged.map(
      (results) => !results.contains(ConnectivityResult.none),
    );
  }
}

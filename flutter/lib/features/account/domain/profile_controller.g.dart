// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'profile_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Direct port of the profile half of `hooks/useSession.ts`'s
/// `saveProfileForEmail`/`readStoredProfiles` (`lib/profile/index.ts`).
/// **In-memory only**, matching every other controller in this build — the
/// source persists this to `localStorage`.

@ProviderFor(ProfileController)
final profileControllerProvider = ProfileControllerProvider._();

/// Direct port of the profile half of `hooks/useSession.ts`'s
/// `saveProfileForEmail`/`readStoredProfiles` (`lib/profile/index.ts`).
/// **In-memory only**, matching every other controller in this build — the
/// source persists this to `localStorage`.
final class ProfileControllerProvider
    extends $NotifierProvider<ProfileController, Map<String, UserProfile>> {
  /// Direct port of the profile half of `hooks/useSession.ts`'s
  /// `saveProfileForEmail`/`readStoredProfiles` (`lib/profile/index.ts`).
  /// **In-memory only**, matching every other controller in this build — the
  /// source persists this to `localStorage`.
  ProfileControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'profileControllerProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$profileControllerHash();

  @$internal
  @override
  ProfileController create() => ProfileController();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(Map<String, UserProfile> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<Map<String, UserProfile>>(value),
    );
  }
}

String _$profileControllerHash() => r'94952d16ce28b84914dc534b0755fa538eea1799';

/// Direct port of the profile half of `hooks/useSession.ts`'s
/// `saveProfileForEmail`/`readStoredProfiles` (`lib/profile/index.ts`).
/// **In-memory only**, matching every other controller in this build — the
/// source persists this to `localStorage`.

abstract class _$ProfileController extends $Notifier<Map<String, UserProfile>> {
  Map<String, UserProfile> build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref =
        this.ref as $Ref<Map<String, UserProfile>, Map<String, UserProfile>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<Map<String, UserProfile>, Map<String, UserProfile>>,
              Map<String, UserProfile>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}

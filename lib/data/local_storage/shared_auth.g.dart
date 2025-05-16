// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'shared_auth.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$setConnectedStatusHash() =>
    r'3175a0d6fb215bbf3f4a5643a7260110c96b625d';

/// Copied from Dart SDK
class _SystemHash {
  _SystemHash._();

  static int combine(int hash, int value) {
    // ignore: parameter_assignments
    hash = 0x1fffffff & (hash + value);
    // ignore: parameter_assignments
    hash = 0x1fffffff & (hash + ((0x0007ffff & hash) << 10));
    return hash ^ (hash >> 6);
  }

  static int finish(int hash) {
    // ignore: parameter_assignments
    hash = 0x1fffffff & (hash + ((0x03ffffff & hash) << 3));
    // ignore: parameter_assignments
    hash = hash ^ (hash >> 11);
    return 0x1fffffff & (hash + ((0x00003fff & hash) << 15));
  }
}

/// See also [setConnectedStatus].
@ProviderFor(setConnectedStatus)
const setConnectedStatusProvider = SetConnectedStatusFamily();

/// See also [setConnectedStatus].
class SetConnectedStatusFamily extends Family<AsyncValue<void>> {
  /// See also [setConnectedStatus].
  const SetConnectedStatusFamily();

  /// See also [setConnectedStatus].
  SetConnectedStatusProvider call({required bool status}) {
    return SetConnectedStatusProvider(status: status);
  }

  @override
  SetConnectedStatusProvider getProviderOverride(
    covariant SetConnectedStatusProvider provider,
  ) {
    return call(status: provider.status);
  }

  static const Iterable<ProviderOrFamily>? _dependencies = null;

  @override
  Iterable<ProviderOrFamily>? get dependencies => _dependencies;

  static const Iterable<ProviderOrFamily>? _allTransitiveDependencies = null;

  @override
  Iterable<ProviderOrFamily>? get allTransitiveDependencies =>
      _allTransitiveDependencies;

  @override
  String? get name => r'setConnectedStatusProvider';
}

/// See also [setConnectedStatus].
class SetConnectedStatusProvider extends AutoDisposeFutureProvider<void> {
  /// See also [setConnectedStatus].
  SetConnectedStatusProvider({required bool status})
    : this._internal(
        (ref) =>
            setConnectedStatus(ref as SetConnectedStatusRef, status: status),
        from: setConnectedStatusProvider,
        name: r'setConnectedStatusProvider',
        debugGetCreateSourceHash:
            const bool.fromEnvironment('dart.vm.product')
                ? null
                : _$setConnectedStatusHash,
        dependencies: SetConnectedStatusFamily._dependencies,
        allTransitiveDependencies:
            SetConnectedStatusFamily._allTransitiveDependencies,
        status: status,
      );

  SetConnectedStatusProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.status,
  }) : super.internal();

  final bool status;

  @override
  Override overrideWith(
    FutureOr<void> Function(SetConnectedStatusRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: SetConnectedStatusProvider._internal(
        (ref) => create(ref as SetConnectedStatusRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        status: status,
      ),
    );
  }

  @override
  AutoDisposeFutureProviderElement<void> createElement() {
    return _SetConnectedStatusProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is SetConnectedStatusProvider && other.status == status;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, status.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin SetConnectedStatusRef on AutoDisposeFutureProviderRef<void> {
  /// The parameter `status` of this provider.
  bool get status;
}

class _SetConnectedStatusProviderElement
    extends AutoDisposeFutureProviderElement<void>
    with SetConnectedStatusRef {
  _SetConnectedStatusProviderElement(super.provider);

  @override
  bool get status => (origin as SetConnectedStatusProvider).status;
}

String _$getConnectedStatusHash() =>
    r'8272324086031992339d72c4abb0d3b1d9657b23';

/// See also [getConnectedStatus].
@ProviderFor(getConnectedStatus)
final getConnectedStatusProvider = AutoDisposeProvider<bool>.internal(
  getConnectedStatus,
  name: r'getConnectedStatusProvider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$getConnectedStatusHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef GetConnectedStatusRef = AutoDisposeProviderRef<bool>;
String _$setMainTokenIdHash() => r'4fa0676db5ddb6544bf8dabc7f40d8c9a221eb24';

/// See also [setMainTokenId].
@ProviderFor(setMainTokenId)
const setMainTokenIdProvider = SetMainTokenIdFamily();

/// See also [setMainTokenId].
class SetMainTokenIdFamily extends Family<AsyncValue<void>> {
  /// See also [setMainTokenId].
  const SetMainTokenIdFamily();

  /// See also [setMainTokenId].
  SetMainTokenIdProvider call({required String tokenId}) {
    return SetMainTokenIdProvider(tokenId: tokenId);
  }

  @override
  SetMainTokenIdProvider getProviderOverride(
    covariant SetMainTokenIdProvider provider,
  ) {
    return call(tokenId: provider.tokenId);
  }

  static const Iterable<ProviderOrFamily>? _dependencies = null;

  @override
  Iterable<ProviderOrFamily>? get dependencies => _dependencies;

  static const Iterable<ProviderOrFamily>? _allTransitiveDependencies = null;

  @override
  Iterable<ProviderOrFamily>? get allTransitiveDependencies =>
      _allTransitiveDependencies;

  @override
  String? get name => r'setMainTokenIdProvider';
}

/// See also [setMainTokenId].
class SetMainTokenIdProvider extends AutoDisposeFutureProvider<void> {
  /// See also [setMainTokenId].
  SetMainTokenIdProvider({required String tokenId})
    : this._internal(
        (ref) => setMainTokenId(ref as SetMainTokenIdRef, tokenId: tokenId),
        from: setMainTokenIdProvider,
        name: r'setMainTokenIdProvider',
        debugGetCreateSourceHash:
            const bool.fromEnvironment('dart.vm.product')
                ? null
                : _$setMainTokenIdHash,
        dependencies: SetMainTokenIdFamily._dependencies,
        allTransitiveDependencies:
            SetMainTokenIdFamily._allTransitiveDependencies,
        tokenId: tokenId,
      );

  SetMainTokenIdProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.tokenId,
  }) : super.internal();

  final String tokenId;

  @override
  Override overrideWith(
    FutureOr<void> Function(SetMainTokenIdRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: SetMainTokenIdProvider._internal(
        (ref) => create(ref as SetMainTokenIdRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        tokenId: tokenId,
      ),
    );
  }

  @override
  AutoDisposeFutureProviderElement<void> createElement() {
    return _SetMainTokenIdProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is SetMainTokenIdProvider && other.tokenId == tokenId;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, tokenId.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin SetMainTokenIdRef on AutoDisposeFutureProviderRef<void> {
  /// The parameter `tokenId` of this provider.
  String get tokenId;
}

class _SetMainTokenIdProviderElement
    extends AutoDisposeFutureProviderElement<void>
    with SetMainTokenIdRef {
  _SetMainTokenIdProviderElement(super.provider);

  @override
  String get tokenId => (origin as SetMainTokenIdProvider).tokenId;
}

String _$getMainTokenIdHash() => r'eef365bc48916b5bb25c833546248d82e1ca570d';

/// See also [getMainTokenId].
@ProviderFor(getMainTokenId)
final getMainTokenIdProvider = AutoDisposeProvider<String>.internal(
  getMainTokenId,
  name: r'getMainTokenIdProvider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$getMainTokenIdHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef GetMainTokenIdRef = AutoDisposeProviderRef<String>;
String _$setTypeUserHash() => r'319d7668453e424535a237f9a80504bc74eb8503';

/// See also [setTypeUser].
@ProviderFor(setTypeUser)
const setTypeUserProvider = SetTypeUserFamily();

/// See also [setTypeUser].
class SetTypeUserFamily extends Family<AsyncValue<void>> {
  /// See also [setTypeUser].
  const SetTypeUserFamily();

  /// See also [setTypeUser].
  SetTypeUserProvider call({required String typeUser}) {
    return SetTypeUserProvider(typeUser: typeUser);
  }

  @override
  SetTypeUserProvider getProviderOverride(
    covariant SetTypeUserProvider provider,
  ) {
    return call(typeUser: provider.typeUser);
  }

  static const Iterable<ProviderOrFamily>? _dependencies = null;

  @override
  Iterable<ProviderOrFamily>? get dependencies => _dependencies;

  static const Iterable<ProviderOrFamily>? _allTransitiveDependencies = null;

  @override
  Iterable<ProviderOrFamily>? get allTransitiveDependencies =>
      _allTransitiveDependencies;

  @override
  String? get name => r'setTypeUserProvider';
}

/// See also [setTypeUser].
class SetTypeUserProvider extends AutoDisposeFutureProvider<void> {
  /// See also [setTypeUser].
  SetTypeUserProvider({required String typeUser})
    : this._internal(
        (ref) => setTypeUser(ref as SetTypeUserRef, typeUser: typeUser),
        from: setTypeUserProvider,
        name: r'setTypeUserProvider',
        debugGetCreateSourceHash:
            const bool.fromEnvironment('dart.vm.product')
                ? null
                : _$setTypeUserHash,
        dependencies: SetTypeUserFamily._dependencies,
        allTransitiveDependencies: SetTypeUserFamily._allTransitiveDependencies,
        typeUser: typeUser,
      );

  SetTypeUserProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.typeUser,
  }) : super.internal();

  final String typeUser;

  @override
  Override overrideWith(
    FutureOr<void> Function(SetTypeUserRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: SetTypeUserProvider._internal(
        (ref) => create(ref as SetTypeUserRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        typeUser: typeUser,
      ),
    );
  }

  @override
  AutoDisposeFutureProviderElement<void> createElement() {
    return _SetTypeUserProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is SetTypeUserProvider && other.typeUser == typeUser;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, typeUser.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin SetTypeUserRef on AutoDisposeFutureProviderRef<void> {
  /// The parameter `typeUser` of this provider.
  String get typeUser;
}

class _SetTypeUserProviderElement extends AutoDisposeFutureProviderElement<void>
    with SetTypeUserRef {
  _SetTypeUserProviderElement(super.provider);

  @override
  String get typeUser => (origin as SetTypeUserProvider).typeUser;
}

String _$getTypeUserHash() => r'9ce24dfecdeb42c629ef67776fef7dbcb9947756';

/// See also [getTypeUser].
@ProviderFor(getTypeUser)
final getTypeUserProvider = AutoDisposeProvider<String>.internal(
  getTypeUser,
  name: r'getTypeUserProvider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product') ? null : _$getTypeUserHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef GetTypeUserRef = AutoDisposeProviderRef<String>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package

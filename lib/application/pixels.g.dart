// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'pixels.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$pixelsRepositoryHash() => r'8275cc195b8e416b981abcf9eac5b77e517cf3ed';

/// See also [_pixelsRepository].
@ProviderFor(_pixelsRepository)
final _pixelsRepositoryProvider =
    AutoDisposeProvider<PixelsRepository>.internal(
  _pixelsRepository,
  name: r'_pixelsRepositoryProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$pixelsRepositoryHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef _PixelsRepositoryRef = AutoDisposeProviderRef<PixelsRepository>;
String _$fetchPixelsHash() => r'3c0c0cdc826f00e015c0880c4b757392f1f0c5dd';

/// See also [fetchPixels].
@ProviderFor(fetchPixels)
final fetchPixelsProvider = AutoDisposeFutureProvider<List<Pixel>>.internal(
  fetchPixels,
  name: r'fetchPixelsProvider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product') ? null : _$fetchPixelsHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef FetchPixelsRef = AutoDisposeFutureProviderRef<List<Pixel>>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package

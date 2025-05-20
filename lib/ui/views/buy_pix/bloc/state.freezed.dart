// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'state.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

/// @nodoc
mixin _$BuyTokenFormState {
  String? get error => throw _privateConstructorUsedError;
  bool get walletValidationInProgress => throw _privateConstructorUsedError;
  FeeEstimations? get estimatedFee => throw _privateConstructorUsedError;
  int? get selectedPixAmount => throw _privateConstructorUsedError;
  BigInt? get correspondingFriAmount => throw _privateConstructorUsedError;
  bool get isLoadingFee => throw _privateConstructorUsedError;

  /// Create a copy of BuyTokenFormState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $BuyTokenFormStateCopyWith<BuyTokenFormState> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $BuyTokenFormStateCopyWith<$Res> {
  factory $BuyTokenFormStateCopyWith(
          BuyTokenFormState value, $Res Function(BuyTokenFormState) then) =
      _$BuyTokenFormStateCopyWithImpl<$Res, BuyTokenFormState>;
  @useResult
  $Res call(
      {String? error,
      bool walletValidationInProgress,
      FeeEstimations? estimatedFee,
      int? selectedPixAmount,
      BigInt? correspondingFriAmount,
      bool isLoadingFee});
}

/// @nodoc
class _$BuyTokenFormStateCopyWithImpl<$Res, $Val extends BuyTokenFormState>
    implements $BuyTokenFormStateCopyWith<$Res> {
  _$BuyTokenFormStateCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of BuyTokenFormState
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? error = freezed,
    Object? walletValidationInProgress = null,
    Object? estimatedFee = freezed,
    Object? selectedPixAmount = freezed,
    Object? correspondingFriAmount = freezed,
    Object? isLoadingFee = null,
  }) {
    return _then(_value.copyWith(
      error: freezed == error
          ? _value.error
          : error // ignore: cast_nullable_to_non_nullable
              as String?,
      walletValidationInProgress: null == walletValidationInProgress
          ? _value.walletValidationInProgress
          : walletValidationInProgress // ignore: cast_nullable_to_non_nullable
              as bool,
      estimatedFee: freezed == estimatedFee
          ? _value.estimatedFee
          : estimatedFee // ignore: cast_nullable_to_non_nullable
              as FeeEstimations?,
      selectedPixAmount: freezed == selectedPixAmount
          ? _value.selectedPixAmount
          : selectedPixAmount // ignore: cast_nullable_to_non_nullable
              as int?,
      correspondingFriAmount: freezed == correspondingFriAmount
          ? _value.correspondingFriAmount
          : correspondingFriAmount // ignore: cast_nullable_to_non_nullable
              as BigInt?,
      isLoadingFee: null == isLoadingFee
          ? _value.isLoadingFee
          : isLoadingFee // ignore: cast_nullable_to_non_nullable
              as bool,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$BuyTokenFormStateImplCopyWith<$Res>
    implements $BuyTokenFormStateCopyWith<$Res> {
  factory _$$BuyTokenFormStateImplCopyWith(_$BuyTokenFormStateImpl value,
          $Res Function(_$BuyTokenFormStateImpl) then) =
      __$$BuyTokenFormStateImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String? error,
      bool walletValidationInProgress,
      FeeEstimations? estimatedFee,
      int? selectedPixAmount,
      BigInt? correspondingFriAmount,
      bool isLoadingFee});
}

/// @nodoc
class __$$BuyTokenFormStateImplCopyWithImpl<$Res>
    extends _$BuyTokenFormStateCopyWithImpl<$Res, _$BuyTokenFormStateImpl>
    implements _$$BuyTokenFormStateImplCopyWith<$Res> {
  __$$BuyTokenFormStateImplCopyWithImpl(_$BuyTokenFormStateImpl _value,
      $Res Function(_$BuyTokenFormStateImpl) _then)
      : super(_value, _then);

  /// Create a copy of BuyTokenFormState
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? error = freezed,
    Object? walletValidationInProgress = null,
    Object? estimatedFee = freezed,
    Object? selectedPixAmount = freezed,
    Object? correspondingFriAmount = freezed,
    Object? isLoadingFee = null,
  }) {
    return _then(_$BuyTokenFormStateImpl(
      error: freezed == error
          ? _value.error
          : error // ignore: cast_nullable_to_non_nullable
              as String?,
      walletValidationInProgress: null == walletValidationInProgress
          ? _value.walletValidationInProgress
          : walletValidationInProgress // ignore: cast_nullable_to_non_nullable
              as bool,
      estimatedFee: freezed == estimatedFee
          ? _value.estimatedFee
          : estimatedFee // ignore: cast_nullable_to_non_nullable
              as FeeEstimations?,
      selectedPixAmount: freezed == selectedPixAmount
          ? _value.selectedPixAmount
          : selectedPixAmount // ignore: cast_nullable_to_non_nullable
              as int?,
      correspondingFriAmount: freezed == correspondingFriAmount
          ? _value.correspondingFriAmount
          : correspondingFriAmount // ignore: cast_nullable_to_non_nullable
              as BigInt?,
      isLoadingFee: null == isLoadingFee
          ? _value.isLoadingFee
          : isLoadingFee // ignore: cast_nullable_to_non_nullable
              as bool,
    ));
  }
}

/// @nodoc

class _$BuyTokenFormStateImpl extends _BuyTokenFormState {
  const _$BuyTokenFormStateImpl(
      {this.error,
      this.walletValidationInProgress = false,
      this.estimatedFee,
      this.selectedPixAmount,
      this.correspondingFriAmount,
      this.isLoadingFee = false})
      : super._();

  @override
  final String? error;
  @override
  @JsonKey()
  final bool walletValidationInProgress;
  @override
  final FeeEstimations? estimatedFee;
  @override
  final int? selectedPixAmount;
  @override
  final BigInt? correspondingFriAmount;
  @override
  @JsonKey()
  final bool isLoadingFee;

  @override
  String toString() {
    return 'BuyTokenFormState(error: $error, walletValidationInProgress: $walletValidationInProgress, estimatedFee: $estimatedFee, selectedPixAmount: $selectedPixAmount, correspondingFriAmount: $correspondingFriAmount, isLoadingFee: $isLoadingFee)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$BuyTokenFormStateImpl &&
            (identical(other.error, error) || other.error == error) &&
            (identical(other.walletValidationInProgress,
                    walletValidationInProgress) ||
                other.walletValidationInProgress ==
                    walletValidationInProgress) &&
            (identical(other.estimatedFee, estimatedFee) ||
                other.estimatedFee == estimatedFee) &&
            (identical(other.selectedPixAmount, selectedPixAmount) ||
                other.selectedPixAmount == selectedPixAmount) &&
            (identical(other.correspondingFriAmount, correspondingFriAmount) ||
                other.correspondingFriAmount == correspondingFriAmount) &&
            (identical(other.isLoadingFee, isLoadingFee) ||
                other.isLoadingFee == isLoadingFee));
  }

  @override
  int get hashCode => Object.hash(
      runtimeType,
      error,
      walletValidationInProgress,
      estimatedFee,
      selectedPixAmount,
      correspondingFriAmount,
      isLoadingFee);

  /// Create a copy of BuyTokenFormState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$BuyTokenFormStateImplCopyWith<_$BuyTokenFormStateImpl> get copyWith =>
      __$$BuyTokenFormStateImplCopyWithImpl<_$BuyTokenFormStateImpl>(
          this, _$identity);
}

abstract class _BuyTokenFormState extends BuyTokenFormState {
  const factory _BuyTokenFormState(
      {final String? error,
      final bool walletValidationInProgress,
      final FeeEstimations? estimatedFee,
      final int? selectedPixAmount,
      final BigInt? correspondingFriAmount,
      final bool isLoadingFee}) = _$BuyTokenFormStateImpl;
  const _BuyTokenFormState._() : super._();

  @override
  String? get error;
  @override
  bool get walletValidationInProgress;
  @override
  FeeEstimations? get estimatedFee;
  @override
  int? get selectedPixAmount;
  @override
  BigInt? get correspondingFriAmount;
  @override
  bool get isLoadingFee;

  /// Create a copy of BuyTokenFormState
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$BuyTokenFormStateImplCopyWith<_$BuyTokenFormStateImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

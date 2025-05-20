// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'pixel.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

/// @nodoc
mixin _$Pixel {
  int? get dx => throw _privateConstructorUsedError;
  int? get dy => throw _privateConstructorUsedError;
  Color? get color => throw _privateConstructorUsedError;
  bool? get isPendingPixel => throw _privateConstructorUsedError;

  /// Create a copy of Pixel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $PixelCopyWith<Pixel> get copyWith => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $PixelCopyWith<$Res> {
  factory $PixelCopyWith(Pixel value, $Res Function(Pixel) then) =
      _$PixelCopyWithImpl<$Res, Pixel>;
  @useResult
  $Res call({int? dx, int? dy, Color? color, bool? isPendingPixel});
}

/// @nodoc
class _$PixelCopyWithImpl<$Res, $Val extends Pixel>
    implements $PixelCopyWith<$Res> {
  _$PixelCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of Pixel
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? dx = freezed,
    Object? dy = freezed,
    Object? color = freezed,
    Object? isPendingPixel = freezed,
  }) {
    return _then(_value.copyWith(
      dx: freezed == dx
          ? _value.dx
          : dx // ignore: cast_nullable_to_non_nullable
              as int?,
      dy: freezed == dy
          ? _value.dy
          : dy // ignore: cast_nullable_to_non_nullable
              as int?,
      color: freezed == color
          ? _value.color
          : color // ignore: cast_nullable_to_non_nullable
              as Color?,
      isPendingPixel: freezed == isPendingPixel
          ? _value.isPendingPixel
          : isPendingPixel // ignore: cast_nullable_to_non_nullable
              as bool?,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$PixelImplCopyWith<$Res> implements $PixelCopyWith<$Res> {
  factory _$$PixelImplCopyWith(
          _$PixelImpl value, $Res Function(_$PixelImpl) then) =
      __$$PixelImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({int? dx, int? dy, Color? color, bool? isPendingPixel});
}

/// @nodoc
class __$$PixelImplCopyWithImpl<$Res>
    extends _$PixelCopyWithImpl<$Res, _$PixelImpl>
    implements _$$PixelImplCopyWith<$Res> {
  __$$PixelImplCopyWithImpl(
      _$PixelImpl _value, $Res Function(_$PixelImpl) _then)
      : super(_value, _then);

  /// Create a copy of Pixel
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? dx = freezed,
    Object? dy = freezed,
    Object? color = freezed,
    Object? isPendingPixel = freezed,
  }) {
    return _then(_$PixelImpl(
      dx: freezed == dx
          ? _value.dx
          : dx // ignore: cast_nullable_to_non_nullable
              as int?,
      dy: freezed == dy
          ? _value.dy
          : dy // ignore: cast_nullable_to_non_nullable
              as int?,
      color: freezed == color
          ? _value.color
          : color // ignore: cast_nullable_to_non_nullable
              as Color?,
      isPendingPixel: freezed == isPendingPixel
          ? _value.isPendingPixel
          : isPendingPixel // ignore: cast_nullable_to_non_nullable
              as bool?,
    ));
  }
}

/// @nodoc

class _$PixelImpl extends _Pixel {
  const _$PixelImpl({this.dx, this.dy, this.color, this.isPendingPixel})
      : super._();

  @override
  final int? dx;
  @override
  final int? dy;
  @override
  final Color? color;
  @override
  final bool? isPendingPixel;

  @override
  String toString() {
    return 'Pixel(dx: $dx, dy: $dy, color: $color, isPendingPixel: $isPendingPixel)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$PixelImpl &&
            (identical(other.dx, dx) || other.dx == dx) &&
            (identical(other.dy, dy) || other.dy == dy) &&
            (identical(other.color, color) || other.color == color) &&
            (identical(other.isPendingPixel, isPendingPixel) ||
                other.isPendingPixel == isPendingPixel));
  }

  @override
  int get hashCode => Object.hash(runtimeType, dx, dy, color, isPendingPixel);

  /// Create a copy of Pixel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$PixelImplCopyWith<_$PixelImpl> get copyWith =>
      __$$PixelImplCopyWithImpl<_$PixelImpl>(this, _$identity);
}

abstract class _Pixel extends Pixel {
  const factory _Pixel(
      {final int? dx,
      final int? dy,
      final Color? color,
      final bool? isPendingPixel}) = _$PixelImpl;
  const _Pixel._() : super._();

  @override
  int? get dx;
  @override
  int? get dy;
  @override
  Color? get color;
  @override
  bool? get isPendingPixel;

  /// Create a copy of Pixel
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$PixelImplCopyWith<_$PixelImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

import 'package:flutter/material.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'pixel.freezed.dart';

@freezed
class Pixel with _$Pixel {
  const factory Pixel({
    final int? dx,
    final int? dy,
    final Color? color,
    final bool? isPendingPixel,
  }) = _Pixel;

  const Pixel._();
}

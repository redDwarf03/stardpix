import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class CurrentColor extends StateNotifier<Color> {
  CurrentColor()
      : super(
          Colors.orange[200]!,
        );

  // ignore: use_setters_to_change_properties
  void setColor(Color newColor) {
    state = newColor;
  }
}

final _currentColorProvider = StateNotifierProvider<CurrentColor, Color>(
  (ref) => CurrentColor(),
);

abstract class CurrentColorProviders {
  static final currentColorProvider = _currentColorProvider;
}

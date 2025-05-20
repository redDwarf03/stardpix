import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stardpix/model/pixel.dart';

class PixelCanvas extends StateNotifier<List<Pixel>> {
  PixelCanvas() : super(<Pixel>[]);

  void updatePixelsList(List<Pixel> newPixels, WidgetRef ref) {
    state = [...newPixels];
  }
}

final _pixelCanvasProvider =
    StateNotifierProvider<PixelCanvas, List<Pixel>>((ref) {
  return PixelCanvas();
});

abstract class PixelCanvasProviders {
  static final pixelCanvasProvider = _pixelCanvasProvider;
}

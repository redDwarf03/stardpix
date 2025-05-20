import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:stardpix/application/services/war_service.dart';
import 'package:stardpix/model/pixel.dart';

part 'pixels.g.dart';

@riverpod
PixelsRepository _pixelsRepository(Ref ref) => PixelsRepository();

@riverpod
Future<List<Pixel>> fetchPixels(Ref ref) async {
  return ref.watch(_pixelsRepositoryProvider).getPixels();
}

class PixelsRepository {
  Future<List<Pixel>> getPixels() async {
    return PixelWarService.defaultConfig().getPixels();
  }
}

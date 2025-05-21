import 'dart:ui'; // For Color
import 'package:starknet/starknet.dart'; // For Felt and BigInt

mixin ContractDataUtilsMixin {
  List<Felt> bigIntToU256FeltList(BigInt value) {
    final u128Mask = (BigInt.one << 128) - BigInt.one;
    final lowHex = (value & u128Mask).toRadixString(16);
    final highHex = ((value >> 128) & u128Mask).toRadixString(16);

    // Ensure 0x prefix for Felt.fromHexString
    final low = Felt.fromHexString('0x$lowHex');
    final high = Felt.fromHexString('0x$highHex');
    return [low, high];
  }

  int _rgbToFelt(double r, double g, double b) {
    final r_ = r.clamp(0, 255).toInt();
    final g_ = g.clamp(0, 255).toInt();
    final b_ = b.clamp(0, 255).toInt();

    return (r_ << 16) | (g_ << 8) | b_;
  }

  Map<String, int> feltToRgb(int colorFelt) {
    return {
      'r': (colorFelt >> 16) & 0xFF,
      'g': (colorFelt >> 8) & 0xFF,
      'b': colorFelt & 0xFF,
    };
  }

  Color feltToColor(int colorFelt) {
    final rgb = feltToRgb(colorFelt);
    return Color.fromRGBO(rgb['r']!, rgb['g']!, rgb['b']!, 1);
  }

  int colorToFelt(Color color) {
    return _rgbToFelt(color.r, color.g, color.b);
  }
}

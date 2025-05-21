import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stardpix/application/balance.dart';
import 'package:stardpix/application/pixels_canvas.dart';
import 'package:stardpix/application/services/war_service.dart';
import 'package:stardpix/application/session/provider.dart';
import 'package:stardpix/model/pixel.dart';
import 'package:stardpix/ui/views/layer/bloc/state.dart';

final _layerFormProvider =
    NotifierProvider.autoDispose<LayerFormNotifier, LayerFormState>(
  () {
    return LayerFormNotifier();
  },
);

class LayerFormNotifier extends AutoDisposeNotifier<LayerFormState> {
  LayerFormNotifier();

  @override
  LayerFormState build() => const LayerFormState();

  void setError(String errorText) {
    state = state.copyWith(errorText: errorText);
  }

  void setRefreshInProgress(bool refreshInProgress) {
    state = state.copyWith(refreshInProgress: refreshInProgress);
  }

  void setCreateInProgress(bool createInProgress) {
    state = state.copyWith(createInProgress: createInProgress);
  }

  void setMode(Mode mode) {
    state = state.copyWith(mode: mode);
  }

  Future<bool> addPendingPixels(
    int? dx,
    int? dy,
    Color? hexColor,
    WidgetRef ref,
  ) async {
    final pixel = Pixel(dx: dx, dy: dy, color: hexColor, isPendingPixel: true);

    final resultExists = state.pendingPixels
        .any((element) => element.dx == dx && element.dy == dy);

    // Pending existing Pixel ?
    if (state.mode == Mode.edit) {
      if (resultExists) {
        final newPendingPixels = [...state.pendingPixels];
        // ignore: cascade_invocations
        newPendingPixels
          ..removeWhere((element) => element.dx == dx && element.dy == dy)
          ..add(pixel);
        state = state.copyWith(
          pendingPixels: newPendingPixels,
        );
      } else {
        final balance = await ref.read(userBalanceProvider.future);
        if (balance > 0) {
          if (state.nbPixEdit >= balance) {
            state = state.copyWith(
              errorText: "you don't have enough PIX",
            );
            return false;
          }

          if (state.nbPixEdit >= state.maxPixEdit) {
            state = state.copyWith(
              errorText: 'The maximum number of pixels per round is 64 pixels',
            );
            return false;
          }
        }
        final newPendingPixels = [...state.pendingPixels, pixel];
        state = state.copyWith(
          pendingPixels: newPendingPixels,
          nbPixEdit: state.nbPixEdit + 1,
        );
      }
    } else {
      if (resultExists) {
        final newPendingPixels = [...state.pendingPixels];
        // ignore: cascade_invocations
        newPendingPixels
            .removeWhere((element) => element.dx == dx && element.dy == dy);
        state = state.copyWith(
          nbPixEdit: state.nbPixEdit - 1,
          pendingPixels: newPendingPixels,
          mode: state.nbPixEdit - 1 == 0 ? Mode.edit : Mode.erase,
        );
      }
    }

    return true;
  }

  Future<void> cancelValidation(WidgetRef ref) async {
    final pixels = ref.read(PixelCanvasProviders.pixelCanvasProvider);

    ref
        .read(
          PixelCanvasProviders.pixelCanvasProvider.notifier,
        )
        .updatePixelsList(pixels, ref);
    clearPendingPixels();
    ref.invalidate(userBalanceProvider);
  }

  void clearPendingPixels() {
    state = state.copyWith(
      pendingPixels: [],
      nbPixEdit: 0,
    );
  }

  void setIsBuyProcess(bool isBuyProcess, WidgetRef ref) {
    if (isBuyProcess == true) {
      state = state.copyWith(
        isBuyProcess: isBuyProcess,
        isWalletProcess: false,
        displayAbout: false,
        displayColorPicker: false,
        pickColor: false,
      );
      cancelValidation(
        ref,
      );
    } else {
      state = state.copyWith(isBuyProcess: isBuyProcess);
    }
  }

  void setIsWalletProcess(bool isWalletProcess, WidgetRef ref) {
    if (isWalletProcess == true) {
      state = state.copyWith(
        isWalletProcess: isWalletProcess,
        isBuyProcess: false,
        displayAbout: false,
        displayColorPicker: false,
        pickColor: false,
      );
      cancelValidation(
        ref,
      );
    } else {
      state = state.copyWith(isWalletProcess: isWalletProcess);
    }
  }

  void setDisplayColorPicker(bool displayColorPicker) {
    if (displayColorPicker == true) {
      state = state.copyWith(
        isBuyProcess: false,
        isWalletProcess: false,
        displayAbout: false,
        displayColorPicker: displayColorPicker,
        pickColor: false,
      );
    } else {
      state = state.copyWith(displayColorPicker: displayColorPicker);
    }
  }

  void setDisplayAbout(bool displayAbout, WidgetRef ref) {
    if (displayAbout == true) {
      state = state.copyWith(
        isBuyProcess: false,
        isWalletProcess: false,
        displayAbout: displayAbout,
        displayColorPicker: false,
        pickColor: false,
      );
      cancelValidation(
        ref,
      );
    } else {
      state = state.copyWith(displayAbout: displayAbout);
    }
  }

  void setTimeLockInSeconds(int timeLockInSeconds) {
    state = state.copyWith(timeLockInSeconds: timeLockInSeconds);
  }

  void setPickColor(bool pickColor, WidgetRef ref) {
    if (pickColor == true) {
      state = state.copyWith(
        isBuyProcess: false,
        isWalletProcess: false,
        displayAbout: false,
        displayColorPicker: false,
        pickColor: pickColor,
      );
    } else {
      state = state.copyWith(pickColor: pickColor);
    }
  }

  void setQuickDrawMode(bool quickDrawMode) {
    state = state.copyWith(quickDrawMode: quickDrawMode);
  }

  void setZoomLevel(int zoomLevel) {
    state = state.copyWith(zoomLevel: zoomLevel);
  }

  Future<void> getTimeLockInSeconds() async {
    var timeLockInSeconds = 0;
    final accountAddress = ref.read(accountAddressProvider);
    if (accountAddress.isEmpty) {
      setTimeLockInSeconds(0);
      return;
    }
    final unlockTime = await PixelWarService.defaultConfig().getUnlockTime(
      accountAddress,
    );

    final nowTimestamp = DateTime.now().millisecondsSinceEpoch;
    if (unlockTime * 1000 > nowTimestamp) {
      timeLockInSeconds = DateTime.fromMillisecondsSinceEpoch(
        unlockTime * 1000,
      )
          .difference(
            DateTime.fromMillisecondsSinceEpoch(
              nowTimestamp,
            ),
          )
          .inSeconds;
    }
    setTimeLockInSeconds(timeLockInSeconds);
  }
}

abstract class LayerFormProvider {
  static final layerForm = _layerFormProvider;
}

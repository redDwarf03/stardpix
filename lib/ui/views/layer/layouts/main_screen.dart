// ignore_for_file: empty_catches

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stardpix/application/current_color.dart';
import 'package:stardpix/application/pixels.dart';
import 'package:stardpix/application/pixels_canvas.dart';
import 'package:stardpix/application/session/provider.dart';
import 'package:stardpix/ui/views/about/layouts/about_screen.dart';
import 'package:stardpix/ui/views/buy_pix/layouts/buy_screen.dart';
import 'package:stardpix/ui/views/layer/bloc/provider.dart';
import 'package:stardpix/ui/views/layer/layouts/components/buttons/icon_about.dart';
import 'package:stardpix/ui/views/layer/layouts/components/buttons/icon_buy.dart';
import 'package:stardpix/ui/views/layer/layouts/components/buttons/icon_color.dart';
import 'package:stardpix/ui/views/layer/layouts/components/buttons/icon_edit.dart';
import 'package:stardpix/ui/views/layer/layouts/components/buttons/icon_pick.dart';
import 'package:stardpix/ui/views/layer/layouts/components/buttons/icon_pixel_validation.dart';
import 'package:stardpix/ui/views/layer/layouts/components/buttons/icon_pixel_validation_cancel.dart';
import 'package:stardpix/ui/views/layer/layouts/components/buttons/icon_refresh.dart';
import 'package:stardpix/ui/views/layer/layouts/components/buttons/icon_timer.dart';
import 'package:stardpix/ui/views/layer/layouts/components/buttons/icon_wallet.dart';
import 'package:stardpix/ui/views/layer/layouts/components/canvas_viewer.dart';
import 'package:stardpix/ui/views/layer/layouts/components/color_picker.dart';

class MainScreen extends ConsumerStatefulWidget {
  const MainScreen({super.key});

  @override
  ConsumerState<MainScreen> createState() => MainScreenState();
}

class MainScreenState extends ConsumerState<MainScreen> {
  int? timeLockInSeconds;
  Timer? _pixelsListTimer;

  @override
  void initState() {
    Future.delayed(Duration.zero, () async {
      if (mounted) {
        try {
          final sessionNotifier = ref.read(sessionNotifierProvider.notifier);
          await sessionNotifier.connectWallet();
        } catch (_) {}

        try {
          final pixels = await ref.read(fetchPixelsProvider.future);
          ref
              .read(PixelCanvasProviders.pixelCanvasProvider.notifier)
              .updatePixelsList(pixels, ref);

          Timer.periodic(const Duration(seconds: 30), (timer) async {
            final pixels = await ref.read(fetchPixelsProvider.future);
            ref
                .read(PixelCanvasProviders.pixelCanvasProvider.notifier)
                .updatePixelsList(pixels, ref);
          });
        } catch (e) {}

        await ref
            .read(LayerFormProvider.layerForm.notifier)
            .getTimeLockInSeconds();
      }
    });

    super.initState();
  }

  @override
  void dispose() {
    _pixelsListTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final layer = ref.watch(LayerFormProvider.layerForm);

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        alignment: Alignment.bottomCenter,
        children: [
          Container(
            width: double.infinity,
            height: double.infinity,
            padding: const EdgeInsets.only(
              top: 5,
              left: 5,
              right: 5,
              bottom: 30,
            ),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.bottomCenter,
                end: Alignment.topCenter,
                colors: [Colors.orangeAccent, Colors.red],
              ),
            ),
            child: Container(
              margin: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.yellow[300]!),
              ),
              child: Container(
                margin: const EdgeInsets.all(1),
                decoration: BoxDecoration(
                  border: Border.all(width: 3),
                ),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.bottomLeft,
                      end: Alignment.topRight,
                      colors: [Color(0xFF5d4cb8), Color(0xFF7276f9)],
                    ),
                  ),
                  child: Container(
                    margin: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      border: Border.all(width: 3),
                    ),
                    child: Container(
                      padding: const EdgeInsets.all(1),
                      decoration: const BoxDecoration(
                        color: Color(0xff232193),
                      ),
                      child: Container(
                        margin: const EdgeInsets.all(1),
                        decoration: BoxDecoration(
                          border: Border.all(width: 3),
                        ),
                        child: DecoratedBox(
                          decoration: const BoxDecoration(
                            color: Colors.white,
                          ),
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              const CanvasViewer(),
                              if (layer.isBuyProcess) const BuyScreen(),
                              if (layer.displayAbout) const AboutScreen(),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          if (layer.displayColorPicker)
            Positioned(
              bottom: -1,
              child: SizedBox(
                width: MediaQuery.sizeOf(context).width < 650
                    ? MediaQuery.sizeOf(context).width
                    : 650,
                child: ColorPicker(
                  color: ref.watch(
                    CurrentColorProviders.currentColorProvider,
                  ),
                  onColorChanged: (color) {
                    ref
                        .read(
                          CurrentColorProviders.currentColorProvider.notifier,
                        )
                        .setColor(color);
                  },
                ),
              ),
            ),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const IconEdit(),
                const IconTimer(),
                if (layer.pendingPixels.isNotEmpty)
                  const IconPixelValicationCancel(),
                if (layer.pendingPixels.isNotEmpty) const IconPixelValidation(),
                const IconRefresh(),
                const IconWallet(),
                const IconBuy(),
                const IconColor(),
                const IconPick(),
                const IconAbout(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

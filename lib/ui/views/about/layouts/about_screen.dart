import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pixelarticons/pixel.dart' as pixelarticons;
import 'package:stardpix/application/services/dpixou_service.dart';
import 'package:stardpix/application/services/war_service.dart';
import 'package:stardpix/ui/views/about/layouts/components/icon_close.dart';
import 'package:url_launcher/url_launcher.dart';

class AboutScreen extends ConsumerWidget {
  const AboutScreen({
    super.key,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final textTheme = Theme.of(context)
        .textTheme
        .apply(displayColor: Theme.of(context).colorScheme.onSurface);

    return Stack(
      children: [
        Container(
          margin: const EdgeInsets.all(1),
          decoration: BoxDecoration(
            border: Border.all(width: 3),
          ),
          child: Container(
            padding: const EdgeInsets.all(5),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.bottomCenter,
                end: Alignment.topCenter,
                colors: [Colors.orangeAccent, Colors.red],
              ),
            ),
            child: Container(
              margin: const EdgeInsets.all(1),
              decoration: BoxDecoration(
                border: Border.all(width: 3),
              ),
              child: Container(
                width: 600,
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomLeft,
                    end: Alignment.topRight,
                    colors: [Color(0xFF5d4cb8), Color(0xFF7276f9)],
                  ),
                ),
                padding: const EdgeInsets.only(
                  top: 10,
                  left: 30,
                  right: 30,
                ),
                child: SingleChildScrollView(
                  // Ajout du SingleChildScrollView
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      Text(
                        'Welcome to the world of decentralized pixel war!',
                        style: textTheme.titleMedium,
                      ),
                      const SizedBox(
                        height: 10,
                      ),
                      Text(
                        'This application runs on the Starknet blockchain.',
                        style: textTheme.titleSmall,
                      ),
                      const SizedBox(
                        height: 10,
                      ),
                      Center(
                        child: Image.asset(
                          'assets/images/starDPix_welcome.png',
                          height: 170,
                        ),
                      ),
                      Text(
                        "You can consult the game's smart contracts here:",
                        style: textTheme.titleSmall,
                      ),
                      const SizedBox(
                        height: 10,
                      ),
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              'War Contract Address:\n${PixelWarService.defaultConfig().contractAddress.toHexString()}',
                              style: textTheme.bodySmall,
                            ),
                          ),
                          const SizedBox(
                            width: 10,
                          ),
                          InkWell(
                            onTap: () async {
                              await launchUrl(
                                Uri.parse(
                                  'https://starkscan.co/search/${PixelWarService.defaultConfig().contractAddress.toHexString()}',
                                ),
                              );
                            },
                            child: const Icon(pixelarticons.Pixel.link),
                          ),
                        ],
                      ),
                      const SizedBox(
                        height: 10,
                      ),
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              'dPixou Contract Address:\n${DpixouService.defaultConfig().contractAddress.toHexString()}',
                              style: textTheme.bodySmall,
                            ),
                          ),
                          const SizedBox(
                            width: 10,
                          ),
                          InkWell(
                            onTap: () async {
                              await launchUrl(
                                Uri.parse(
                                  'https://starkscan.co/search/${DpixouService.defaultConfig().contractAddress.toHexString()}',
                                ),
                              );
                            },
                            child: const Icon(pixelarticons.Pixel.link),
                          ),
                        ],
                      ),
                      const SizedBox(
                        height: 10,
                      ),
                      Text(
                        'Have fun!',
                        style: textTheme.titleMedium,
                      ),
                      const SizedBox(
                        height: 10,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
        const Positioned(
          top: -1,
          right: -1,
          child: IconClose(),
        ),
      ],
    );
  }
}

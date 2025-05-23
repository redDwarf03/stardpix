import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stardpix/ui/views/wallet/layouts/components/icon_close.dart';
import 'package:wallet_kit/wallet_kit.dart';

class WalletScreen extends ConsumerStatefulWidget {
  const WalletScreen({
    super.key,
  });

  @override
  ConsumerState<WalletScreen> createState() => WalletScreenState();
}

class WalletScreenState extends ConsumerState<WalletScreen> {
  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final selectedAccount =
        ref.watch(walletsProvider.select((value) => value.selectedAccount));
    if (selectedAccount != null) {
      ref.read(walletsProvider.notifier)
        ..refreshEthBalance(
          selectedAccount.walletId,
          selectedAccount.id,
        )
        ..refreshStrkBalance(
          selectedAccount.walletId,
          selectedAccount.id,
        );
    }
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
                height: 300,
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomLeft,
                    end: Alignment.topRight,
                    colors: [Color(0xFF5d4cb8), Color(0xFF7276f9)],
                  ),
                ),
                padding: const EdgeInsets.only(
                  top: 10,
                  left: 10,
                  right: 10,
                ),
                child: const Column(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        WalletSelector(),
                        AccountAddress(),
                        DeployAccountButton(),
                      ],
                    ),
                    SizedBox(height: 10),
                    WalletErrorHandler(),
                  ],
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

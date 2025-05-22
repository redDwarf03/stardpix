import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logging/logging.dart';
import 'package:starknet/starknet.dart' as s;
import 'package:wallet_kit/wallet_kit.dart';

/// Provider that exposes the connection status from wallet_kit
final isConnectedProvider = Provider<bool>((ref) {
  final selectedAccount = ref.watch(selectedAccountProvider);
  return selectedAccount != null;
});

/// Provider that exposes the deployment status from wallet_kit
final isDeployedProvider = Provider<bool>((ref) {
  final selectedAccount = ref.watch(selectedAccountProvider);
  return selectedAccount != null && selectedAccount.isDeployed;
});

/// Provider that exposes the connected account address (or empty string)
final accountAddressProvider = Provider<String>((ref) {
  final selectedAccount = ref.watch(selectedAccountProvider);
  return selectedAccount?.address ?? '';
});

/// Provider that exposes the connected account
final selectedAccountProvider = Provider<Account?>((ref) {
  final walletsState = ref.watch(walletsProvider);
  return walletsState.selectedAccount;
});

// Class for secureStoreProvider arguments
class SecureStoreRequestArgs {
  const SecureStoreRequestArgs(this.context, this.walletId);
  final BuildContext context;
  final String walletId;
}

final secureStoreProvider =
    FutureProvider.family<dynamic, SecureStoreRequestArgs>(
        (ref, requestArgs) async {
  final logger = Logger('secureStoreProvider')
    ..info(
      'Attempting to retrieve SecureStore for walletId: ${requestArgs.walletId}',
    );
  final walletsNotifier = ref.read(walletsProvider.notifier);
  try {
    final secureStore = await walletsNotifier.getSecureStoreForWallet(
      context: requestArgs.context,
      walletId: requestArgs.walletId,
    );
    return secureStore;
  } catch (e) {
    logger.severe(
      'Error retrieving SecureStore in secureStoreProvider for walletId ${requestArgs.walletId}: $e',
    );
    return null;
  }
});

/// Asynchronous provider that exposes the current s.Account from wallet_kit, or null if not connected.
/// Takes BuildContext to allow password prompt if needed.
final accountStarknetProvider =
    FutureProvider.family<s.Account?, BuildContext>((ref, context) async {
  final logger = Logger('accountStarknetProvider');
  final walletsState =
      ref.watch(walletsProvider); // Watch for changes in wallet state

  final selectedWalletKitAccount = walletsState.selectedAccount;
  final selectedWallet = walletsState.selectedWallet;

  if (selectedWalletKitAccount == null || selectedWallet == null) {
    logger.info('No selected WalletKit account or wallet, returning null.');
    return null;
  }

  try {
    logger.info(
      'Attempting to retrieve s.Account with SecureStore for walletId: ${selectedWallet.id}',
    );
    final secureStoreRequest =
        SecureStoreRequestArgs(context, selectedWallet.id);
    final secureStore =
        await ref.watch(secureStoreProvider(secureStoreRequest).future);

    if (secureStore == null) {
      logger.warning(
        'SecureStore could not be retrieved via secureStoreProvider for walletId: ${selectedWallet.id}. Cannot create s.Account.',
      );
      return null;
    }

    logger.info(
      'SecureStore retrieved successfully via secureStoreProvider for walletId: ${selectedWallet.id}. Proceeding to get s.Account.',
    );
    return WalletService.getStarknetAccount(
      secureStore: secureStore,
      account: selectedWalletKitAccount,
      walletId: selectedWallet.id,
    );
  } catch (e) {
    logger.severe(
      'Error in accountStarknetProvider for walletId ${selectedWallet.id}: $e',
    );
    return null;
  }
});

// Notifier to observe application lifecycle and invalidate providers.
class AppLifecycleNotifier extends Notifier<void> with WidgetsBindingObserver {
  final _logger = Logger('AppLifecycleNotifier');

  @override
  void build() {
    _logger
        .info('AppLifecycleNotifier initialized and observing app lifecycle.');
    WidgetsBinding.instance.addObserver(this);
    ref.onDispose(() {
      _logger.info(
          'AppLifecycleNotifier disposed and no longer observing app lifecycle.');
      WidgetsBinding.instance.removeObserver(this);
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    _logger.info('App lifecycle state changed to: $state');
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached) {
      _logger
          .info('App is paused or detached. Invalidating secureStoreProvider.');
      ref.invalidate(secureStoreProvider);
    }
  }
}

// Provider for the AppLifecycleNotifier.
// This needs to be initialized (e.g., watched or read) by your app for it to work.
final appLifecycleNotifierProvider =
    NotifierProvider<AppLifecycleNotifier, void>(AppLifecycleNotifier.new);

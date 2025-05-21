import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logging/logging.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:stardpix/application/session/provider.dart';
import 'package:stardpix/infrastructure/balance.repository.dart';

part 'balance.g.dart';

final logger = Logger('userBalance');

@riverpod
Future<int> userBalance(Ref ref) async {
  final accountAddress = ref.watch(accountAddressProvider);

  if (accountAddress.isEmpty) {
    return 0;
  }

  final pixTokenContractAddress = dotenv.env['PIX_TOKEN_CONTRACT_ADDRESS'];

  if (pixTokenContractAddress == null) {
    logger.severe('Error: PIX_TOKEN_CONTRACT_ADDRESS not found in .env file.');
    return 0;
  }

  try {
    final balanceRepository = BalanceRepositoryImpl.defaultConfig();
    final tokenBalanceDouble = await balanceRepository.getBalance(
      accountAddress,
      pixTokenContractAddress,
    );
    return tokenBalanceDouble.toInt();
  } catch (e) {
    logger.severe('Error fetching user PIX balance: $e');
    return 0;
  }
}

/// Provider exposing the user's PIX balance as a BigInt (native units, 18 decimals).
@riverpod
Future<BigInt> userBalanceBigInt(Ref ref) async {
  final accountAddress = ref.watch(accountAddressProvider);

  if (accountAddress.isEmpty) {
    return BigInt.zero;
  }

  final pixTokenContractAddress = dotenv.env['PIX_TOKEN_CONTRACT_ADDRESS'];

  if (pixTokenContractAddress == null) {
    logger.severe('Error: PIX_TOKEN_CONTRACT_ADDRESS not found in .env file.');
    return BigInt.zero;
  }

  try {
    final balanceRepository = BalanceRepositoryImpl.defaultConfig();
    final tokenBalanceBigInt = await balanceRepository.getBalanceBigInt(
      accountAddress,
      pixTokenContractAddress,
    );
    return tokenBalanceBigInt;
  } catch (e) {
    logger.severe('Error fetching user PIX balance (BigInt): $e');
    return BigInt.zero;
  }
}

/// Provider exposing the user's FRI balance as a BigInt (native units, 18 decimals).
@riverpod
Future<BigInt> userFriBalanceBigInt(Ref ref) async {
  final accountAddress = ref.watch(accountAddressProvider);

  if (accountAddress.isEmpty) {
    return BigInt.zero;
  }

  final friTokenContractAddress = dotenv.env['FRI_TOKEN_CONTRACT_ADDRESS'];

  if (friTokenContractAddress == null) {
    logger.severe('Error: FRI_TOKEN_CONTRACT_ADDRESS not found in .env file.');
    return BigInt.zero;
  }

  try {
    final balanceRepository = BalanceRepositoryImpl.defaultConfig();
    final tokenBalanceBigInt = await balanceRepository.getBalanceBigInt(
      accountAddress,
      friTokenContractAddress,
    );
    return tokenBalanceBigInt;
  } catch (e) {
    logger.severe('Error fetching user FRI balance (BigInt): $e');
    return BigInt.zero;
  }
}

/// Provider exposing the user's ETH balance as a BigInt (native units, 18 decimals).
@riverpod
Future<BigInt> userEthBalanceBigInt(Ref ref) async {
  final accountAddress = ref.watch(accountAddressProvider);

  if (accountAddress.isEmpty) {
    return BigInt.zero;
  }

  try {
    final balanceRepository = BalanceRepositoryImpl.defaultConfig();
    final tokenBalanceBigInt = await balanceRepository.getEthBalanceBigInt(
      accountAddress,
    );
    return tokenBalanceBigInt;
  } catch (e) {
    logger.severe('Error fetching user ETH balance (BigInt): $e');
    return BigInt.zero;
  }
}

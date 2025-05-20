import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:logging/logging.dart';
import 'package:stardpix/domain/repositories/balance.repository.dart';
import 'package:starknet/starknet.dart';
import 'package:starknet_provider/starknet_provider.dart';

class BalanceRepositoryImpl implements BalanceRepository {
  BalanceRepositoryImpl({required this.provider});
  factory BalanceRepositoryImpl.defaultConfig() {
    final rpcUrlStr = dotenv.env['RPC_URL'];
    if (rpcUrlStr == null) {
      throw Exception('env variables not found');
    }
    return BalanceRepositoryImpl(
      provider: JsonRpcProvider(nodeUri: Uri.parse(rpcUrlStr)),
    );
  }
  final Logger logger = Logger('BalanceRepositoryImpl');
  final JsonRpcProvider provider;

  /// Returns the balance as a double (for UI display only).
  @override
  Future<double> getBalance(
    String accountAddress,
    String tokenContractAddress,
  ) async {
    final balanceBigInt =
        await getBalanceBigInt(accountAddress, tokenContractAddress);
    return balanceBigInt.toDouble() / BigInt.from(10).pow(18).toDouble();
  }

  /// Returns the balance as a BigInt (for calculations and transactions).
  @override
  Future<BigInt> getBalanceBigInt(
    String accountAddress,
    String tokenContractAddress,
  ) async {
    try {
      final response = await provider.call(
        request: FunctionCall(
          contractAddress: Felt.fromHexString(tokenContractAddress),
          entryPointSelector: getSelectorByName('balanceOf'),
          calldata: [
            Felt.fromHexString(accountAddress),
          ],
        ),
        blockId: BlockId.latest,
      );

      return response.when(
        result: (data) {
          if (data.isNotEmpty) {
            return data.first.toBigInt();
          } else {
            logger.warning(
              'Warning: balanceOf call returned empty data for token $tokenContractAddress',
            );
            return BigInt.zero;
          }
        },
        error: (error) {
          logger.severe(
            'Error fetching balance for token $tokenContractAddress: ${error.message}',
          );
          throw Exception(
            'Failed to fetch balance for $tokenContractAddress: ${error.message}',
          );
        },
      );
    } catch (e) {
      logger.severe(
        'Exception in getBalanceBigInt for $tokenContractAddress: $e',
      );
      throw Exception(
        'Failed to fetch balance for $tokenContractAddress due to: $e',
      );
    }
  }

  @override
  Future<BigInt> getEthBalanceBigInt(String accountAddress) async {
    final ethTokenContractAddress = dotenv.env['ETH_TOKEN_CONTRACT_ADDRESS'];
    if (ethTokenContractAddress == null || ethTokenContractAddress.isEmpty) {
      logger.severe(
        'Error: ETH_TOKEN_CONTRACT_ADDRESS not found or empty in .env file.',
      );
      throw Exception(
        'ETH_TOKEN_CONTRACT_ADDRESS not configured for fetching ETH balance.',
      );
    }
    // Reuse the existing getBalanceBigInt method, which handles ERC20 balances
    return getBalanceBigInt(accountAddress, ethTokenContractAddress);
  }
}

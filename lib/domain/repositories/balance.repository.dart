abstract class BalanceRepository {
  Future<double> getBalance(String accountAddress, String tokenContractAddress);

  Future<BigInt> getBalanceBigInt(
    String accountAddress,
    String tokenContractAddress,
  );

  Future<BigInt> getEthBalanceBigInt(String accountAddress);
}

enum Failure implements Exception {
  invalidParams(
    code: -32602,
    message: 'Invalid parameters',
  ),
  unsupportedMethod(
    code: -32601,
    message: 'Unsupported method.',
  ),
  userRejected(
    code: 4001,
    message: 'User rejected operation',
  ),
  connectivity(
    code: 4901,
    message: 'Connectivity issue.',
  ),
  other(
    code: 5000,
    message: 'Technical error',
  ),
  timeout(
    code: 5001,
    message: 'Operation timeout.',
  ),
  invalidTransaction(
    code: 5003,
    message: 'Invalid transaction',
  ),
  insufficientFunds(
    code: 5004,
    message: 'Insufficient funds.',
  ),
  unknownAccount(
    code: 5005,
    message: 'Unknown account.',
  );

  const Failure({
    required this.code,
    required this.message,
  });

  final int code;
  final String message;
}

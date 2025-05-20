/// Represents the different environments available for the Starknet network.
///
/// Each environment has a unique label and endpoint, allowing the user to
/// differentiate between Mainnet, Testnet and Devnet.
enum Environment {
  /// The development network (Devnet) for local testing.
  devnet(label: 'Starknet Devnet', endpoint: 'http://localhost:5050');

  /// Creates an [Environment] with a specific [label] and [endpoint].
  const Environment({required this.label, required this.endpoint});

  /// The human-readable name of the environment.
  final String label;

  /// The URL endpoint for the environment.
  final String endpoint;

  /// Retrieves the [Environment] corresponding to the given [endpoint].
  ///
  /// Throws a [StateError] if no environment matches the provided endpoint.
  static Environment byEndpoint(String endpoint) =>
      Environment.values.firstWhere(
        (environment) => environment.endpoint == endpoint,
        orElse: () =>
            throw StateError('No environment found for endpoint $endpoint'),
      );
}

# starDPix

Are you ready for a decentralized pixels war on Starknet blockchain!
Flutter application to interact with StarkNet contracts: PixelWar, Dpixou, and PixToken.

## Prerequisites

Before you begin, ensure you have the following tools installed:

*   **Flutter**: Follow the installation instructions at [flutter.dev](https://flutter.dev).
*   **Starkli**: CLI tool for StarkNet interactions. Instructions at [book.starkli.rs/installation](https://book.starkli.rs/installation).
*   **Starknet-devnet**: Local development node for StarkNet. Instructions on [GitHub](https://github.com/0xSpaceShard/starknet-devnet).
*   **Scarb**: Cairo package manager and build tool (if you compile contracts from source). Instructions at [docs.swmansion.com/scarb](https://docs.swmansion.com/scarb/download).

## Key Component Versions

This project relies on specific versions of tools and libraries. While the `pubspec.yaml` and `Scarb.toml` files are the sources of truth for exact dependencies, here's a summary of the key components:

### Core Development Tools

The versions of core development tools are managed via the `.tool-versions` file (if you use a version manager like `asdf`):

*   **Flutter**: `3.27.4-stable`
*   **Scarb (Cairo Package Manager)**: `2.9.4`
*   **Starkli (StarkNet CLI)**: `0.3.5`
*   **Starknet Devnet**: `0.2.0`

### Flutter Application Dependencies

Key dependencies for the Flutter application (see `pubspec.yaml` for the full list):

*   **`flutter_dotenv`**: `^5.2.1` (For managing environment variables)
*   **`flutter_riverpod`**: `^2.6.1` (For state management)
*   **`go_router`**: `^14.6.1` (For navigation)
*   **`starknet.dart` SDK**:
    *   `starknet`: Sourced from Git (`https://github.com/focustree/starknet.dart/tree/main/packages/starknet`)
    *   `starknet_provider`: Sourced from Git (`https://github.com/focustree/starknet.dart/tree/main/packages/starknet_provider`)
    *(Refer to `pubspec.yaml` for the exact commit or branch used if specified).*

### Cairo Smart Contract Dependencies

Key dependencies for the Cairo smart contracts (see `lib/application/contracts/Scarb.toml` for details):

*   **`starknet` (Cairo library)**: `>=2.2.0`
*   **`openzeppelin` (Cairo contracts)**: Sourced from Git (`https://github.com/OpenZeppelin/cairo-contracts.git`, tag `v1.0.0`)

Ensuring compatibility with these versions is recommended for a smooth development experience.

## Smart Contracts

The backend of starDPix is powered by a suite of smart contracts developed in Cairo, running on the StarkNet blockchain. These contracts manage the game logic, tokenomics, and pixel data.

### Overview of Contracts

The application utilizes three main Cairo contracts:

1.  **`PixelWar.cairo`**: This is the core contract for the Pixel War game.
    *   It manages the canvas, allowing users to place pixels with a specific color at given coordinates (x, y).
    *   To place pixels, users must spend `PIX` tokens (currently 1 PIX per pixel, where 1 PIX = 10^18 of the smallest unit). These tokens are burned from the user's account.
    *   The contract interacts with the `PixToken` contract (whose address is provided during `PixelWar` deployment) to perform the `burnFrom` operation after the user has approved `PixelWar` to spend their PIX.
    *   Includes a cooldown mechanism (`LOCK_TIME`) to regulate pixel placement frequency per user.
    *   Supports placing multiple pixels in a single transaction (`add_pixels`) with a cooldown proportional to the number of pixels.
    *   Stores pixel data in `pixel_map` and tracks occupied pixels for efficient querying.
    *   Provides functions to get the color of a specific pixel (`get_pixel_color`) and to retrieve all placed pixels (`get_all_pixels`).
    *   Source code: `lib/application/contracts/src/war.cairo`

2.  **`PixToken.cairo`**: An ERC20-compliant token contract for the `PIX` token.
    *   Handles standard token functionalities like `transfer`, `transferFrom`, `approve`, `balanceOf`, and `totalSupply`.
    *   Includes an `admin` role with the ability to `mint` new tokens. Initially, the deploying account is set as admin. The initial supply minted at deployment is 0.
    *   Crucially, after deployment, the admin rights for `PixToken` are transferred to the `Dpixou` contract. This makes `Dpixou` the sole entity capable of minting new `PIX` tokens, ensuring that token creation is strictly governed by the exchange logic in `Dpixou`.
    *   The metadata (name: "PIX Token", symbol: "PIX", decimals: 18) is set in the constructor.
    *   Source code: `lib/application/contracts/src/pix_token.cairo`

3.  **`Dpixou.cairo`**: A contract that facilitates the exchange between the `STRK` token (Starknet's native token) and the `PIX` token.
    *   Users can `buy_pix` by spending `STRK` tokens at a predefined rate (`STRK_PER_PIX`).
    *   The contract interacts with both the `STRK` token contract (using `IERC20`) and the `PixToken` contract (using `IPixToken`).
    *   After deployment, the `Dpixou` contract becomes the admin of the `PixToken` contract, granting it the exclusive right to call `mint` on `PixToken` when users purchase PIX.
    *   Provides helper functions to calculate exchange rates (`get_nb_pix_for_strk`, `get_nb_strk_for_pix`).
    *   Source code: `lib/application/contracts/src/dpixou.cairo`

### Cairo Code and Compilation

*   All Cairo smart contract source files (`.cairo`) are located in the `lib/application/contracts/src/` directory.
*   The main library file `lib.cairo` in this directory modules the individual contracts.
*   The `Scarb.toml` file in `lib/application/contracts/` defines the project's dependencies, including `starknet` and `openzeppelin` cairo libraries.
*   To compile the contracts, navigate to the `lib/application/contracts/` directory and run `scarb build`. This command, as detailed in the "Compile Contracts" section below, generates the necessary `.contract_class.json` files in the `target/dev/` subdirectory. These JSON files contain the compiled bytecode and ABI of the contracts, which are required for deployment.

### Deployment

The deployment of these smart contracts to a StarkNet network (typically a local devnet for development) is automated by the `scripts/deploy_sc.sh` script.
This script performs the following actions:

1.  **Declares** each contract class (`PixToken`, `Dpixou`, `PixelWar`) to the StarkNet network using `starkli declare`.
2.  **Deploys** instances of these contracts:
    *   `PixToken`: Deploys the main `PIX` token with an initial supply of 0. The deploying account is temporarily set as admin.
    *   `Dpixou`: Deploys the exchange contract, linking it to the Starknet `STRK` token and the deployed `PixToken` addresses.
    *   `PixelWar`: Deploys the main game contract, providing it with the address of the deployed `PixToken` contract for pixel payment processing.
3.  **Transfers `PixToken` Admin Rights**: The script then calls the `change_admin` function on the deployed `PixToken` contract to transfer the administrative (minting) rights to the deployed `Dpixou` contract address. This ensures that only `Dpixou` can mint new `PIX` tokens.
4.  **Outputs** the addresses of all deployed contracts to the terminal.
5.  **Creates/Updates** an `.env` file located at `lib/application/contracts/.env`. This file stores the deployed contract addresses (`PIX_TOKEN_CONTRACT_ADDRESS`, `DPIXOU_CONTRACT_ADDRESS`, `PIXELWAR_CONTRACT_ADDRESS`), the `STRK_TOKEN_CONTRACT_ADDRESS` (for the Starknet STRK token), and other essential configuration details. **Crucially, the `RPC_URL` in this `.env` file is the primary source of truth for the Flutter application to connect to the StarkNet network.** Account details (address and private key for the devnet deployer) are also stored here.

Detailed steps for running the deployment script are covered in the "Deployment and Setup" section.

## Wallet Lifecycle & Integration (wallet_kit & starknet_provider)

starDPix uses [wallet_kit](https://pub.dev/packages/wallet_kit) to manage the full lifecycle of user wallets and accounts, and [starknet_provider](https://pub.dev/packages/starknet_provider) for blockchain interactions. The RPC endpoint used by `wallet_kit` for creating `Account` objects for transactions is configured during `WalletKit().init()` in `main.dart`, using the `RPC_URL` from the `lib/application/contracts/.env` file.

### Wallet Lifecycle Management

- **wallet_kit** provides all UI and logic for:
  - Creating a new Starknet wallet (OpenZeppelin, Argent, Braavos, etc.)
  - Importing an existing wallet (via seed phrase)
  - Managing multiple wallets/accounts, with secure storage (password or OS keychain)
  - Selecting the active account, and handling on-chain deployment if needed
  - Prompting for password when required (for password-protected wallets)
- The app uses wallet_kit's Riverpod providers to track:
  - Connection state (`isConnectedProvider`)
  - Current account address (`accountAddressProvider`)
  - The full Starknet account object (`accountStarknetProvider(context).future`) for signing transactions

### Blockchain Interaction

- All contract calls (buy PIX, place pixels, etc.) are signed and sent using the currently selected wallet/account from wallet_kit.
- The app uses [starknet_provider](https://pub.dev/packages/starknet_provider) and [starknet.dart](https://pub.dev/packages/starknet) for all Starknet JSON-RPC interactions.
- When a transaction requires a signature, wallet_kit will prompt the user for their password if the wallet is protected.

### User Flow Example

1. **On App Launch:**  
   - The canvas and game info are displayed.
   - The wallet button opens a popup (wallet_kit UI) to view, create, or import a wallet/account.

2. **Wallet Actions:**  
   - The user can create a new wallet, import an existing one, or select a previously created account.
   - If the wallet is password-protected, wallet_kit will prompt for the password when needed.

3. **Buying PIX:**  
   - The user clicks "Buy PIX", enters the amount, and confirms.
   - The transaction is signed with the selected wallet/account (password prompt if needed).
   - On success, balances are updated reactively.

4. **Gameplay:**  
   - All game actions (placing pixels, etc.) use the selected wallet/account for contract calls and signatures.

### Technical Notes

- The app never stores or manages private keys directly; all sensitive operations are delegated to wallet_kit and secure_store.
- All Riverpod providers for session/account state are derived from wallet_kit's state, ensuring a single source of truth. The `accountStarknetProvider` in `lib/application/session/provider.dart` has been specifically configured to ensure it uses the RPC settings provided during `WalletKit().init()`.
- The integration is compatible with both local devnet and public Starknet networks, provided the `RPC_URL` in the `.env` file is set accordingly.

## Advanced SecureStore Management and Application Lifecycle



### SecureStore Caching with `secureStoreProvider`

To avoid repeated and potentially costly calls (which may include user prompts) to retrieve the `SecureStore`, a new Riverpod provider has been introduced:

-   `secureStoreProvider`: This is a `FutureProvider.family` that takes a `SecureStoreRequestArgs` object (containing the `BuildContext` and `walletId`) as an argument. This provider retrieves the `SecureStore` and caches it. Subsequent calls with the same `SecureStoreRequestArgs` will return the cached instance, improving performance and user experience.

The `accountStarknetProvider` has been refactored to use `secureStoreProvider` to obtain the `SecureStore` necessary for creating a StarkNet account instance.

### SecureStore Cache Invalidation and Lifecycle Management

For security and resource management reasons, the `SecureStore` cache is automatically invalidated when the application is no longer in the foreground.

-   `AppLifecycleNotifier`: A Riverpod `Notifier` that implements `WidgetsBindingObserver` has been created to monitor the application lifecycle states.
-   When the application enters a `paused` state (goes to the background) or `detached` state (about to be destroyed), `AppLifecycleNotifier` invalidates `secureStoreProvider`. This effectively removes all cached `SecureStore` instances from memory.

### Required Initialization

For `AppLifecycleNotifier` to function and invalidate the cache, its provider, `appLifecycleNotifierProvider`, **must be initialized** when the application starts. This is typically done by reading or watching the provider in the root widget of the application (e.g., in the `build` method of your main `MyApp` widget):

```dart
// In your root widget (e.g., main.dart or app.dart)
class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Initialize the application lifecycle observer.
    ref.watch(appLifecycleNotifierProvider);
    // Note: accountStarknetProvider now takes BuildContext directly if needed here or elsewhere.
    // Example: ref.watch(accountStarknetProvider(context).future);

    return MaterialApp(
      // ... your MaterialApp configuration
    );
  }
}
```

These changes ensure more robust and secure management of sensitive wallet data while optimizing performance.

---

## Flutter Application Services

The Flutter application interacts with the deployed StarkNet smart contracts through a set of Dart service classes. These services encapsulate the logic for calling contract functions, handling data conversion, and managing transactions. They rely on the `starknet.dart` SDK and use the configuration (contract addresses, account details, RPC URL) loaded from the `.env` file.

A utility mixin, `ContractDataUtilsMixin` (located in `lib/application/services/utils/contract_data_utils.dart`), provides common helper functions used across these services, such as `getSelectorByName`, `feltToBigInt`, `bigIntToFelt`, and `waitForAcceptance`. This promotes code reuse and consistency.

### 1. `PixelWarService.dart`

This service is responsible for all interactions with the `PixelWar` smart contract.

*   **Location**: `lib/application/services/war_service.dart`
*   **Initialization**:
    *   The `PixelWarService.defaultConfig()` factory constructor reads necessary details like `PIXELWAR_CONTRACT_ADDRESS`, `ACCOUNT_ADDRESS`, `STARKNET_PRIVATE_KEY`, `RPC_URL`, and `PIX_TOKEN_CONTRACT_ADDRESS` from the `.env` file.
    *   It sets up the `JsonRpcProvider` and the `Account` for interacting with the StarkNet, and stores the `PixToken` contract address.
*   **Key Functionalities**:
    *   `Future<List<Pixel>> getPixels()`: Calls the `get_all_pixels` view function on the `PixelWar` contract. It retrieves all currently placed pixels, converts their coordinates and `felt252` color values into a list of `Pixel` objects (which likely use Flutter's `Color` type).
    *   `Future<Result<void, Failure>> addPixels(List<Pixel> pixels)`:
        *   Calculates the total number of `PIX` tokens required to place the given pixels (1 PIX per pixel).
        *   Initiates an `approve` transaction to the `PixToken` contract, authorizing the `PixelWar` contract to spend the calculated amount of `PIX` tokens from the user's account.
        *   Once approved, it calls the `add_pixels` external function on the `PixelWar` contract. This function on the contract side will then call `burnFrom` on the `PixToken` contract.
        *   The service handles the transaction execution for both approval and the actual pixel placement, and waits for their acceptance.
    *   `Future<int> getPixelColor(int x, int y)`: Calls the `get_pixel_color` view function to fetch the `felt252` color of a pixel at specified coordinates.
    *   `Future<int> getUnlockTime(String userAddress)`: Calls the `get_unlock_time` view function to check the timestamp until which a user cannot place new pixels.
*   **Helper Methods**: Includes private methods for converting between RGB color values / Flutter `Color` objects and the `felt252` representation used by the contract (e.g., `_rgbToFelt`, `_feltToRgb`, `_feltToColor`, `_colorToFelt`), and for validating pixel coordinates.

### 2. `DpixouService.dart`

This service manages interactions with the `Dpixou` smart contract, which handles the exchange of `STRK` tokens for `PIX` tokens.

*   **Location**: `lib/application/services/dpixou_service.dart`
*   **Initialization**:
    *   Similar to `PixelWarService`, `DpixouService.defaultConfig()` loads `DPIXOU_CONTRACT_ADDRESS`, `STRK_TOKEN_CONTRACT_ADDRESS`, and other necessary details from the `.env` file.
*   **Key Functionalities**:
    *   `Future<Result<void, Failure>> buyPix(BigInt amountStrk)`:
        *   First, it calls an internal helper to approve the `Dpixou` contract to spend the required `amountStrk` from the user's STRK token balance. This involves an `approve` call to the STRK token contract.
        *   After successful approval, it calls the `buy_pix` external function on the `Dpixou` contract.
        *   The service prepares these two calls (`approve` and `buy_pix`) as a list of `FunctionCall` objects and executes them as a single multi-call transaction using `account.execute`.
        *   It handles the transaction execution and waits for its acceptance.
    *   `Future<EstimateFeeResponse> estimateBuyPixFee(BigInt amountStrk)`:
        *   Prepares the same list of `FunctionCall` objects (for `approve` STRK and `buy_pix`) as the `buyPix` method.
        *   Calls `account.estimateFee` (or a similar method on the `Account` object from `starknet.dart`) to estimate the network fees for executing these calls.
        *   Returns the fee estimation, allowing the UI to display potential transaction costs to the user.
    *   `Future<BigInt> getNbPixForStrk(BigInt amountStrk)`: Calls the `get_nb_pix_for_strk` view function to calculate how many PIX tokens would be received for a given `amountStrk`.

These services provide a clean abstraction layer, making it easier for the Flutter UI and application logic to interact with the StarkNet backend without dealing directly with the low-level details of contract calls and data serialization.

### 3. Balance Management (`balance.repository.dart` & `balance.dart`)

The application includes components to fetch and display user token balances, covering `PIX` tokens (for gameplay), `STRK` tokens (for purchasing PIX), and `ETH` (for network transaction fees).

*   **Domain Layer (`lib/domain/repositories/balance.repository.dart`)**:
    *   Defines an abstract `BalanceRepository` interface with methods like:
        *   `Future<double> getBalance(String accountAddress, String tokenContractAddress)`: (Potentially legacy) To get the balance of a specific ERC20 token, typically returning a `double` for display.
        *   `Future<BigInt> getBalanceBigInt(String accountAddress, String tokenContractAddress)`: To get the raw `BigInt` balance of a specific ERC20 token (in its smallest unit, e.g., wei).
        *   `Future<BigInt> getEthBalanceBigInt(String accountAddress)`: To get the user's `ETH` balance as a `BigInt`.

*   **Infrastructure Layer (`lib/infrastructure/balance.repository.dart`)**:
    *   `BalanceRepositoryImpl` provides the concrete implementation for `BalanceRepository`.
    *   **Initialization**: `BalanceRepositoryImpl.defaultConfig()` sets up a `JsonRpcProvider` using the `RPC_URL` from the `.env` file.
    *   **Key Functionalities**:
        *   `Future<BigInt> getBalanceBigInt(String accountAddress, String tokenContractAddress)`:
            *   Calls the standard `balanceOf` function on the given ERC20 `tokenContractAddress` for the specified `accountAddress`.
            *   Returns the balance as a `BigInt`.
        *   `Future<double> getBalance(String accountAddress, String tokenContractAddress)`:
            *   Utilizes `getBalanceBigInt` and then converts the `BigInt` result to a `double`, assuming an 18-decimal precision for the token. Primarily for UI display.
        *   `Future<BigInt> getEthBalanceBigInt(String accountAddress)`:
            *   Retrieves the `ETH_TOKEN_CONTRACT_ADDRESS` from the `.env` file.
            *   Calls `getBalanceBigInt` with the user's account address and the ETH token contract address to fetch the ETH balance.
            *   Throws an exception if `ETH_TOKEN_CONTRACT_ADDRESS` is not configured in `.env`.

*   **Application Layer (`lib/application/balance.dart`)**:
    *   Several Riverpod providers are defined to make user balances easily accessible:
        *   `userPixBalanceBigIntProvider` (or similarly named, e.g., `userBalanceBigIntProvider`): Fetches the user's `PIX` token balance as a `BigInt` using `BalanceRepositoryImpl`.
        *   `userStrkBalanceBigIntProvider`: Fetches the user's `STRK` token balance as a `BigInt`.
        *   `userEthBalanceBigIntProvider`: Fetches the user's `ETH` balance as a `BigInt`.
    *   These providers watch the current user's `accountAddress` from a session provider.
    *   They retrieve necessary token contract addresses (like `PIX_TOKEN_CONTRACT_ADDRESS`, `STRK_TOKEN_CONTRACT_ADDRESS`) from the `.env` file via their respective service configurations or directly within the repository.
    *   They include error handling and return `BigInt.zero` if necessary information is missing or if fetching fails.
    *   An older provider `userBalanceProvider` (returning `int` for PIX) might exist but preference should be given to the `BigInt` based providers for accuracy and consistency.

This setup allows the UI to reactively display the user's various token balances by watching the relevant providers.

## Deployment and Setup

### 1. Compile Contracts (If Modified)

If you've made changes to the Cairo contracts (`.cairo` files located in `lib/application/contracts/src`), you'll need to recompile them:

```bash
# Navigate to the contracts directory
cd lib/application/contracts/

# Compile the contracts using Scarb
scarb build
```
This will generate the necessary `.contract_class.json` files in the `target/dev/` directory.

**Important**: After recompiling, `starkli declare` (run as part of the deployment script or manually) will output new Class Hashes if the contract bytecode has changed. You **must** update these Class Hashes in the `starkli deploy ...` commands within your `scripts/deploy_sc.sh` script. Failure to do so will result in deployment errors or deployment of outdated contract versions.

### 2. Start StarkNet Devnet

Open a new terminal window and start your local StarkNet devnet.
**For development and testing, especially when using an emulator or physical device, it's crucial to make the devnet accessible from your local network.**

Start `starknet-devnet` with the `--host` flag set to `0.0.0.0` or your computer's specific local IP address (e.g., `192.168.1.X`):
```bash
starknet-devnet --seed 0 --port 5050 --host 0.0.0.0
```
Or, if you know your machine's IP:
```bash
starknet-devnet --seed 0 --port 5050 --host YOUR_COMPUTER_IP_ADDRESS
```
Keep this terminal window running. The deployment script and Flutter app will connect to this devnet instance.

### 3. Deploy Contracts & Configure Flutter App

In another terminal window, from the root of your `starDPix` project:

1.  **Make the deployment script executable (if you haven't already):**
    ```bash
    chmod +x scripts/deploy_sc.sh
    ```
2.  **Run the deployment script:**
    ```bash
    ./scripts/deploy_sc.sh
    ```
    This script will:
    *   Declare and deploy the `PixToken`, `Dpixou`, and `PixelWar` contracts to your local devnet.
    *   The `STRK` token on Starknet devnet (with seed 0) is typically predeployed at address `0x04718f5a0fc34cc1af16a1cdee98ffb20c31f5cd61d6ab07201858f4287c938d`. The script configures `Dpixou` to use this address.
    *   Display the deployed contract addresses in the terminal.
    *   Create/update a `.env` file located at `lib/application/contracts/.env`. This file will contain the deployed contract addresses, the `STRK_TOKEN_CONTRACT_ADDRESS`, and the `RPC_URL` (e.g., `http://YOUR_COMPUTER_IP_ADDRESS:5050` if you're testing on a device, or `http://localhost:5050` if testing only on the host machine and your devnet is started accordingly).
    *   **Important for ETH Balance**: Ensure this script (or you manually) adds the `ETH_TOKEN_CONTRACT_ADDRESS` for your StarkNet network to the `.env` file. This address is required for the application to display the user's ETH balance, which is used for transaction fees.

### 4. Configure Flutter Environment

The Flutter application uses the `.env` file (generated in the previous step) to get the contract addresses and other StarkNet-related configurations.

1.  **Add `flutter_dotenv` dependency:**
    Ensure your `pubspec.yaml` file includes `flutter_dotenv`:
    ```yaml
    dependencies:
      flutter:
        sdk: flutter
      # ... other dependencies
      flutter_dotenv: ^5.1.0 # Or the latest version
    ```
    If you've added or changed this, run:
    ```bash
    flutter pub get
    ```

2.  **Load `.env` file in `main.dart`:**
    In your `lib/main.dart` file (or wherever your app initialization occurs), make sure to load the environment variables before running the app:
    ```dart
    import 'package:flutter/material.dart';
    import 'package:flutter_dotenv/flutter_dotenv.dart';
    // ... other imports

    Future<void> main() async {
      WidgetsFlutterBinding.ensureInitialized(); // Ensure bindings are initialized
      // Load the .env file from lib/application/contracts/.env
      // This .env file contains RPC_URL, contract addresses, etc.
      await dotenv.load(fileName: "lib/application/contracts/.env"); 
      
      // Initialize WalletKit with the RPC_URL from the .env file
      // This ensures all blockchain interactions via wallet_kit use the correct endpoint.
      await WalletKit().init(
        accountClassHash: dotenv.env['ACCOUNT_CLASS_HASH']!, // Ensure ACCOUNT_CLASS_HASH is in your .env
        rpc: dotenv.env['RPC_URL']!,
      );

      runApp(
        ProviderScope( // Wrap with ProviderScope if you use Riverpod
          child: MyApp(), // Replace MyApp with your main app widget
        ),
      );
    }
    ```

### 5. Run the Flutter Application

You can now run your Flutter application:

```bash
flutter run
```

The application services (`PixelWarService`, `DpixouService`, and the balance provider) should now use the contract addresses and configuration from the `.env` file, allowing them to interact with your locally deployed contracts.

### Testing on a Physical Device

If you want to run and test the Flutter application on a physical Android device (connected via USB) while your StarkNet devnet is running on your computer, follow these steps carefully:

1.  **Find Your Computer's Local IP Address:**
    Your phone needs to connect to your computer over the local network.
    *   On **macOS**, you can typically find this by opening a terminal and running `ipconfig getifaddr en0` (for Wi-Fi) or `ipconfig getifaddr en1` (for Ethernet).
    *   On **Linux**, use `hostname -I` or `ip addr show`.
    *   On **Windows**, use `ipconfig` in the Command Prompt and look for the "IPv4 Address" of your active network connection.
    Let's assume your computer's local IP is `192.168.1.X`.

2.  **Ensure StarkNet Devnet is Accessible on Your Network:**
    As mentioned in "Start StarkNet Devnet" (Step 2 of Deployment and Setup), ensure your `starknet-devnet` is started with `--host 0.0.0.0` or `--host YOUR_COMPUTER_IP_ADDRESS`. For example:
    ```bash
    starknet-devnet --seed 0 --port 5050 --host 0.0.0.0
    ```
    Keep this devnet terminal running.

3.  **Configure `RPC_URL` in Deployment Script (`scripts/deploy_sc.sh`):**
    The `scripts/deploy_sc.sh` script defines the `RPC_URL` that will be written into the `lib/application/contracts/.env` file. This `.env` file is then used by the Flutter app.
    *   Open the `scripts/deploy_sc.sh` file.
    *   Locate the line similar to `export RPC_URL="http://192.168.1.55:5050"`.
    *   **Crucially, for physical device testing, this IP address MUST match your computer's local IP address found in step 1.** For example, if your IP is `192.168.1.100`, change the line to:
        ```bash
        export RPC_URL="http://192.168.1.100:5050"
        ```
    *   If you are only testing on an emulator that can access `localhost` of the host machine (e.g., Android emulator's special `10.0.2.2` address dificuldades by `localhost` from host), or only on the host, you might use `http://localhost:5050`. However, for consistency and to simplify physical device testing, using your computer's actual local IP is recommended.

4.  **Run the Deployment Script:**
    After configuring the `RPC_URL` in `deploy_sc.sh` and ensuring your devnet is running and accessible, execute the script from the project root:
    ```bash
    ./scripts/deploy_sc.sh
    ```
    This will deploy/re-deploy the contracts and generate/update the `lib/application/contracts/.env` file with the `RPC_URL` (e.g., `http://YOUR_COMPUTER_IP_ADDRESS:5050`).

5.  **Rebuild and Run the Flutter App:**
    Ensure your `main.dart` loads the `.env` file and initializes `WalletKit` with the `RPC_URL` from this `.env` file (as shown in "Configure Flutter Environment" Step 2).
    Then, with your physical device connected, rebuild and run your Flutter app:
    ```bash
    flutter run
    ```
    The app should now connect to the StarkNet devnet running on your computer using the IP address.

**Important Network Notes:**
*   Ensure your computer and your physical Android device are connected to the **same local network** (e.g., the same Wi-Fi).
*   Your computer's firewall might need to be configured to allow incoming connections on port `5050` (or whichever port your devnet is using).
*   If you encounter persistent connection issues from the device despite correct IP configuration, you can use `adb reverse tcp:LOCAL_PORT tcp:HOST_PORT` as a debugging tool. For example, `adb reverse tcp:5050 tcp:5050` would forward requests from the device's `localhost:5050` to your host machine's `localhost:5050`. However, with the app correctly using the host's IP from the `.env` file, `adb reverse` should generally not be necessary for the primary RPC connection.

### 6. Testing with CLI (`scripts/create_example.sh`)

For direct command-line interaction and testing of the core contract functionalities after deployment, you can use the `scripts/create_example.sh` script.

This script demonstrates a full workflow:
1.  Sources contract addresses and RPC configuration from `lib/application/contracts/.env`.
2.  Purchases `PIX` tokens by interacting with the `Dpixou` contract (which involves approving `Dpixou` to spend `STRK` tokens and then calling `buy_pix`).
3.  Approves the `PixelWar` contract to spend the newly acquired `PIX` tokens.
4.  Calls the `add_pixels` function on the `PixelWar` contract to place a predefined set of pixels.

**Prerequisites for running `create_example.sh`:**
*   Ensure you have successfully run `scripts/deploy_sc.sh` at least once to deploy the contracts and create the `lib/application/contracts/.env` file.
*   The `devnet-acct.json` file (specified by `ACCOUNT_FILE` in the script) should exist, typically in `lib/application/contracts/` as created by `deploy_sc.sh`.
*   The account specified in `.env` and `devnet-acct.json` must have sufficient `STRK` tokens (minted by the devnet or `deploy_sc.sh`) to purchase the `PIX` tokens needed by the script.

**To run the script:**

From the root of your project:
```bash
chmod +x scripts/create_example.sh # If you haven't made it executable yet
./scripts/create_example.sh
```
This script is useful for quick verification of the contract interactions without launching the full Flutter application.

## Development Notes

*   The `ACCOUNT_ADDRESS` and `STARKNET_PRIVATE_KEY` used in `scripts/deploy_sc.sh` and subsequently written to the `.env` file are for development purposes on a local devnet. **Do not use these credentials on a mainnet or any public testnet with real value.**
*   Remember to add `lib/application/contracts/.env` to your `.gitignore` file to avoid committing environment-specific configurations and private keys to your repository.
    ```
    # .gitignore
    lib/application/contracts/.env
    ```

# Extra

Thanks to Gregory H. for his gift!

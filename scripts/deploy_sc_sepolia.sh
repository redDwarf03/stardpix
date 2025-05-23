#!/bin/bash

# This script deploys the PixelWar, Dpixou, and PixToken contracts to StarkNet Sepolia Testnet.

# --- Configuration ---
# RPC URL for StarkNet Sepolia Testnet
# You can find more public RPC endpoints at: https://docs.starknet.io/ecosystem/open-rpc-endpoints-sepolia-faucets/
DEFAULT_RPC_URL="https://starknet-sepolia.public.blastapi.io/"
# Official STRK token contract address on StarkNet Sepolia Testnet
# Source: User verified on Starkscan: https://sepolia.starkscan.co/contract/0x04718f5a0fc34cc1af16a1cdee98ffb20c31f5cd61d6ab07201858f4287c938d
DEFAULT_STRK_TOKEN_CONTRACT_ADDRESS="0x04718f5a0fc34cc1af16a1cdee98ffb20c31f5cd61d6ab07201858f4287c938d"
# Official ETH token contract address on StarkNet Sepolia Testnet (same as Goerli and mainnet ETH wrapper)
# Source: User verified on Starkscan: https://sepolia.starkscan.co/contract/0x049d36570d4e46f48e99674bd3fcc84644ddd6b96f7c741b1562b82f9e004dc7
DEFAULT_ETH_TOKEN_CONTRACT_ADDRESS="0x049d36570d4e46f48e99674bd3fcc84644ddd6b96f7c741b1562b82f9e004dc7"

# --- User Prompts ---
echo "--------------------------------------------------------------------"
echo "StarkNet Sepolia Testnet Deployment Script"
echo "--------------------------------------------------------------------"
echo "You will need an account funded with Sepolia ETH for transaction fees"
echo "and Sepolia STRK if you plan to test buying PIX tokens."
echo "Get Sepolia ETH and STRK from a faucet, e.g., https://starknet-faucet.vercel.app/"
echo "--------------------------------------------------------------------"
echo ""

read -p "Enter your StarkNet Sepolia Account Address (e.g., 0x...): " ACCOUNT_ADDRESS
if [ -z "$ACCOUNT_ADDRESS" ]; then
    echo "Account Address cannot be empty. Exiting."
    exit 1
fi

read -s -p "Enter your StarkNet Sepolia Private Key (will not be shown): " STARKNET_PRIVATE_KEY
echo ""
if [ -z "$STARKNET_PRIVATE_KEY" ]; then
    echo "Private Key cannot be empty. Exiting."
    exit 1
fi

read -p "Enter the path to your StarkNet Sepolia Account JSON File (e.g., my_sepolia_account.json): " ACCOUNT_FILE
if [ -z "$ACCOUNT_FILE" ]; then
    echo "Account File path cannot be empty. Exiting."
    exit 1
fi
if [ ! -f "$ACCOUNT_FILE" ]; then
    echo "Account File not found at $ACCOUNT_FILE. Exiting."
    exit 1
fi

# Convert ACCOUNT_FILE to an absolute path before changing directory
# This ensures starkli can find it even after we cd into $CONTRACTS_DIR
if [[ "$ACCOUNT_FILE" != /* ]]; then
  # If not absolute, make it absolute relative to current PWD (project root at this point)
  ACCOUNT_FILE_ABS="$(pwd)/$ACCOUNT_FILE"
else
  ACCOUNT_FILE_ABS="$ACCOUNT_FILE"
fi
# Update ACCOUNT_FILE to its absolute path. realpath could also be used for a canonical path if available.
ACCOUNT_FILE="$ACCOUNT_FILE_ABS"

read -p "Enter RPC URL for StarkNet Sepolia Testnet [default: $DEFAULT_RPC_URL]: " RPC_URL
RPC_URL=${RPC_URL:-$DEFAULT_RPC_URL}

read -p "Enter STRK Token Contract Address on Sepolia [default: $DEFAULT_STRK_TOKEN_CONTRACT_ADDRESS]: " STRK_TOKEN_CONTRACT_ADDRESS
STRK_TOKEN_CONTRACT_ADDRESS=${STRK_TOKEN_CONTRACT_ADDRESS:-$DEFAULT_STRK_TOKEN_CONTRACT_ADDRESS}

read -p "Enter ETH Token Contract Address on Sepolia [default: $DEFAULT_ETH_TOKEN_CONTRACT_ADDRESS]: " ETH_TOKEN_CONTRACT_ADDRESS
ETH_TOKEN_CONTRACT_ADDRESS=${ETH_TOKEN_CONTRACT_ADDRESS:-$DEFAULT_ETH_TOKEN_CONTRACT_ADDRESS}

# This is an example OpenZeppelin account class hash.
# You can find yours in your account JSON file or from starkli account new output.
DEFAULT_ACCOUNT_CLASS_HASH="0x061dac032f228abef9c6626f995015233097ae253a7f72d68552db02f2971b8f" # Common for OZ v0.8.0 / Cairo 1
read -p "Enter your Account Class Hash [default: $DEFAULT_ACCOUNT_CLASS_HASH]: " ACCOUNT_CLASS_HASH
ACCOUNT_CLASS_HASH=${ACCOUNT_CLASS_HASH:-$DEFAULT_ACCOUNT_CLASS_HASH}


echo ""
echo "--------------------------------------------------------------------"
echo "Configuration Summary:"
echo "--------------------------------------------------------------------"
echo "Account Address: $ACCOUNT_ADDRESS"
echo "Account File: $ACCOUNT_FILE"
echo "RPC URL: $RPC_URL"
echo "STRK Token Address: $STRK_TOKEN_CONTRACT_ADDRESS"
echo "ETH Token Address: $ETH_TOKEN_CONTRACT_ADDRESS"
echo "Account Class Hash: $ACCOUNT_CLASS_HASH"
echo "--------------------------------------------------------------------"
echo ""
read -p "Proceed with deployment? (y/N): " CONFIRM
if [[ "$CONFIRM" != "y" && "$CONFIRM" != "Y" ]]; then
  echo "Deployment cancelled by user."
  exit 0
fi
echo ""

# Export necessary environment variables for starkli to use for signing
export STARKNET_PRIVATE_KEY
export ACCOUNT_ADDRESS # Starkli might use STARKNET_ACCOUNT_ADDRESS or similar

# --- Ensure we are in the correct directory ---
# Assuming this script is in the 'scripts' directory and contracts are in 'lib/application/contracts'
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
CONTRACTS_DIR="$SCRIPT_DIR/../lib/application/contracts"

if [ ! -d "$CONTRACTS_DIR" ]; then
    echo "Error: Contracts directory not found at $CONTRACTS_DIR"
    echo "Please ensure this script is in the 'scripts' directory and run it from the project root, or adjust CONTRACTS_DIR."
    exit 1
fi
cd "$CONTRACTS_DIR" || exit

# --- Compile Contracts (if not already done) ---
echo "Ensuring contracts are compiled..."
echo "If you've made changes to .cairo files, run 'scarb build' in '$CONTRACTS_DIR' first."
if [ ! -f "target/dev/contract_PixToken.contract_class.json" ] || \
   [ ! -f "target/dev/contract_Dpixou.contract_class.json" ] || \
   [ ! -f "target/dev/contract_PixelWar.contract_class.json" ]; then
    echo "Contract class files not found. Attempting to compile with Scarb..."
    if scarb build; then
        echo "Contracts compiled successfully."
    else
        echo "Scarb build failed. Please compile the contracts manually in '$CONTRACTS_DIR' and try again."
        exit 1
    fi
else
    echo "Found existing compiled contract files."
fi
echo ""

# --- Declare Contracts ---
echo "Declaring contracts... This might take a while."
echo "If declaration fails or hangs, ensure your account is funded and the RPC is responsive."

echo "Declaring PixToken..."
PIXTOKEN_DECLARE_OUTPUT=$(starkli declare --watch --rpc "$RPC_URL" --account "$ACCOUNT_FILE" target/dev/contract_PixToken.contract_class.json 2>&1)
# Try to get hash if already declared (hash is on the next line)
PIXTOKEN_CLASS_HASH=$(echo "$PIXTOKEN_DECLARE_OUTPUT" | awk '/Not declaring class as it'\''s already declared. Class hash:/ {getline; print $1; exit}')
# If not found (i.e., it was newly declared), try the original pattern
if [ -z "$PIXTOKEN_CLASS_HASH" ]; then
    PIXTOKEN_CLASS_HASH=$(echo "$PIXTOKEN_DECLARE_OUTPUT" | awk '/Class hash declared:/ {print $NF}')
fi

if [ -z "$PIXTOKEN_CLASS_HASH" ]; then
    echo "Failed to declare PixToken or retrieve existing class hash. Output:"
    echo "$PIXTOKEN_DECLARE_OUTPUT"
    exit 1
fi
echo "PixToken Class Hash: $PIXTOKEN_CLASS_HASH"
echo ""

echo "Declaring Dpixou..."
DPIXOU_DECLARE_OUTPUT=$(starkli declare --watch --rpc "$RPC_URL" --account "$ACCOUNT_FILE" target/dev/contract_Dpixou.contract_class.json 2>&1)
DPIXOU_CLASS_HASH=$(echo "$DPIXOU_DECLARE_OUTPUT" | awk '/Not declaring class as it'\''s already declared. Class hash:/ {getline; print $1; exit}')
if [ -z "$DPIXOU_CLASS_HASH" ]; then
    DPIXOU_CLASS_HASH=$(echo "$DPIXOU_DECLARE_OUTPUT" | awk '/Class hash declared:/ {print $NF}')
fi

if [ -z "$DPIXOU_CLASS_HASH" ]; then
    echo "Failed to declare Dpixou or retrieve existing class hash. Output:"
    echo "$DPIXOU_DECLARE_OUTPUT"
    exit 1
fi
echo "Dpixou Class Hash: $DPIXOU_CLASS_HASH"
echo ""

echo "Declaring PixelWar..."
PIXELWAR_DECLARE_OUTPUT=$(starkli declare --watch --rpc "$RPC_URL" --account "$ACCOUNT_FILE" target/dev/contract_PixelWar.contract_class.json 2>&1)
PIXELWAR_CLASS_HASH=$(echo "$PIXELWAR_DECLARE_OUTPUT" | awk '/Not declaring class as it'\''s already declared. Class hash:/ {getline; print $1; exit}')
if [ -z "$PIXELWAR_CLASS_HASH" ]; then
    PIXELWAR_CLASS_HASH=$(echo "$PIXELWAR_DECLARE_OUTPUT" | awk '/Class hash declared:/ {print $NF}')
fi

if [ -z "$PIXELWAR_CLASS_HASH" ]; then
    echo "Failed to declare PixelWar or retrieve existing class hash. Output:"
    echo "$PIXELWAR_DECLARE_OUTPUT"
    exit 1
fi
echo "PixelWar Class Hash: $PIXELWAR_CLASS_HASH"
echo ""

# --- Deploy Contracts ---

# PixToken deployment
echo "Deploying PixToken..."
# Constructor args from pix_token.cairo: initial_supply (u256), recipient (ContractAddress), admin (ContractAddress)
# Name, Symbol, Decimals are hardcoded in the contract's constructor.
OUTPUT_PIXTOKEN=$(starkli deploy --watch --rpc "$RPC_URL" --account "$ACCOUNT_FILE" \
  "$PIXTOKEN_CLASS_HASH" \
  u256:0 \
  "$ACCOUNT_ADDRESS" \
  "$ACCOUNT_ADDRESS" 2>&1
)
PIX_TOKEN_ADDRESS=$(echo "$OUTPUT_PIXTOKEN" | awk '/Contract deployed:/ {getline; print $1; exit}')
if [ -z "$PIX_TOKEN_ADDRESS" ]; then
    echo "Failed to deploy PixToken or retrieve deployed address. Output:"
    echo "$OUTPUT_PIXTOKEN"
    exit 1
fi
echo "Pix Token Address: $PIX_TOKEN_ADDRESS"
echo ""

# Dpixou deployment
echo "Deploying Dpixou..."
# Constructor args from dpixou.cairo: strk_token_address (ContractAddress), pix_token_address (ContractAddress)
# STRK_PER_PIX rate is hardcoded in the Dpixou contract.
OUTPUT_DPIXOU=$(starkli deploy --watch --rpc "$RPC_URL" --account "$ACCOUNT_FILE" \
  "$DPIXOU_CLASS_HASH" \
  "$STRK_TOKEN_CONTRACT_ADDRESS" \
  "$PIX_TOKEN_ADDRESS" 2>&1
)
DPIXOU_ADDRESS=$(echo "$OUTPUT_DPIXOU" | awk '/Contract deployed:/ {getline; print $1; exit}')
if [ -z "$DPIXOU_ADDRESS" ]; then
    echo "Failed to deploy Dpixou or retrieve deployed address. Output:"
    echo "$OUTPUT_DPIXOU"
    exit 1
fi
echo "Dpixou Address: $DPIXOU_ADDRESS"
echo ""

# Change PixToken admin to Dpixou contract
echo "Changing PixToken admin to Dpixou contract..."
starkli invoke --watch --rpc "$RPC_URL" --account "$ACCOUNT_FILE" \
  "$PIX_TOKEN_ADDRESS" \
  change_admin \
  "$DPIXOU_ADDRESS"
echo "PixToken admin changed to $DPIXOU_ADDRESS"
echo ""

# PixelWar deployment
echo "Deploying PixelWar..."
# Constructor args: pix_token_address (ContractAddress)
OUTPUT_PIXELWAR=$(starkli deploy --watch --rpc "$RPC_URL" --account "$ACCOUNT_FILE" \
  "$PIXELWAR_CLASS_HASH" \
  "$PIX_TOKEN_ADDRESS" \
  2>&1
)
PIXELWAR_ADDRESS=$(echo "$OUTPUT_PIXELWAR" | awk '/Contract deployed:/ {getline; print $1; exit}')
if [ -z "$PIXELWAR_ADDRESS" ]; then
    echo "Failed to deploy PixelWar or retrieve deployed address. Output:"
    echo "$OUTPUT_PIXELWAR"
    exit 1
fi
echo "PixelWar Address: $PIXELWAR_ADDRESS"
echo ""

# --- Create .env file ---
echo "-------------------------------------"
echo "Deployed Contract Addresses Summary:"
echo "-------------------------------------"
echo "Pix Token Address:  $PIX_TOKEN_ADDRESS"
echo "STRK Token Address: $STRK_TOKEN_CONTRACT_ADDRESS (Sepolia)"
echo "Dpixou Address:     $DPIXOU_ADDRESS"
echo "PixelWar Address:   $PIXELWAR_ADDRESS"
echo "ETH Token Address:  $ETH_TOKEN_CONTRACT_ADDRESS (Sepolia)"
echo "-------------------------------------"
echo ""

ENV_FILE_NAME=".env"
ENV_FILE_PATH_IN_CONTRACTS_DIR="$ENV_FILE_NAME" # Create/Overwrite in lib/application/contracts/
ENV_FILE_PATH_FOR_FLUTTER="lib/application/contracts/$ENV_FILE_NAME" # Path for Flutter app

echo "WARNING: This will overwrite your existing $(pwd)/$ENV_FILE_PATH_IN_CONTRACTS_DIR file with Sepolia configuration!"
read -p "Are you sure you want to continue? (y/N): " OVERWRITE_CONFIRM
if [[ "$OVERWRITE_CONFIRM" != "y" && "$OVERWRITE_CONFIRM" != "Y" ]]; then
  echo "Operation cancelled. Your .env file was not modified."
  # Return to original directory before exiting
  cd "$SCRIPT_DIR/../../"
  exit 0
fi

echo "Creating/Overwriting $ENV_FILE_PATH_IN_CONTRACTS_DIR file with contract addresses and configuration..."

# Write contract addresses
echo "PIXELWAR_CONTRACT_ADDRESS=$PIXELWAR_ADDRESS" > "$ENV_FILE_PATH_IN_CONTRACTS_DIR"
echo "DPIXOU_CONTRACT_ADDRESS=$DPIXOU_ADDRESS" >> "$ENV_FILE_PATH_IN_CONTRACTS_DIR"
echo "PIX_TOKEN_CONTRACT_ADDRESS=$PIX_TOKEN_ADDRESS" >> "$ENV_FILE_PATH_IN_CONTRACTS_DIR"
echo "STRK_TOKEN_CONTRACT_ADDRESS=$STRK_TOKEN_CONTRACT_ADDRESS" >> "$ENV_FILE_PATH_IN_CONTRACTS_DIR"
echo "ETH_TOKEN_CONTRACT_ADDRESS=$ETH_TOKEN_CONTRACT_ADDRESS" >> "$ENV_FILE_PATH_IN_CONTRACTS_DIR"

# Write account and RPC details
echo "ACCOUNT_ADDRESS=$ACCOUNT_ADDRESS" >> "$ENV_FILE_PATH_IN_CONTRACTS_DIR"
echo "STARKNET_PRIVATE_KEY=$STARKNET_PRIVATE_KEY" >> "$ENV_FILE_PATH_IN_CONTRACTS_DIR"
echo "ACCOUNT_CLASS_HASH=$ACCOUNT_CLASS_HASH" >> "$ENV_FILE_PATH_IN_CONTRACTS_DIR"
echo "RPC_URL=$RPC_URL" >> "$ENV_FILE_PATH_IN_CONTRACTS_DIR"

echo "$ENV_FILE_NAME created/updated at $(pwd)/$ENV_FILE_PATH_IN_CONTRACTS_DIR"
echo ""
echo "--------------------------------------------------------------------"
echo "Deployment to StarkNet Sepolia Testnet Complete!"
echo "--------------------------------------------------------------------"
echo "Your Flutter app will now use the Sepolia configuration from '$ENV_FILE_PATH_FOR_FLUTTER'."
echo "To switch back to devnet, you will need to re-run the devnet deployment script (./scripts/deploy_sc.sh)."
echo "Ensure '$ENV_FILE_PATH_FOR_FLUTTER' is in your .gitignore if it contains sensitive information."
echo "Make sure your account ($ACCOUNT_ADDRESS) is funded with Sepolia ETH for gas fees and STRK for buying PIX."
echo "   Use a faucet like https://starknet-faucet.vercel.app/"
echo "--------------------------------------------------------------------"

# Return to original directory (project root if script was run from there)
cd "$SCRIPT_DIR/../../" 
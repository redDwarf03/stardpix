cd lib/application/contracts/

export STARKNET_PRIVATE_KEY="0x71d7bb07b9a64f6f78ac4c816aff4da9" 
export ACCOUNT_ADDRESS="0x64b48806902a367c8598f4f95c305e8c1a1acba5f082d294a43793113115691"
export RPC_URL="http://192.168.1.55:5050"
export ACCOUNT_FILE="devnet-acct.json"

# Standard STRK token address for devnet with --seed 0
export STRK_TOKEN_CONTRACT_ADDRESS="0x04718f5a0fc34cc1af16a1cdee98ffb20c31f5cd61d6ab07201858f4287c938d"

starkli declare --watch --rpc "$RPC_URL" --account "$ACCOUNT_FILE"  target/dev/contract_PixToken.contract_class.json
starkli declare --watch --rpc "$RPC_URL" --account "$ACCOUNT_FILE"  target/dev/contract_Dpixou.contract_class.json
starkli declare --watch --rpc "$RPC_URL" --account "$ACCOUNT_FILE"  target/dev/contract_PixelWar.contract_class.json

# Pixtoken deployment
echo "Deploying PixToken..."
OUTPUT_PIXTOKEN=$(starkli deploy --watch --rpc "$RPC_URL" --account "$ACCOUNT_FILE" \
  0x00ff7cd091079f6083e0c6a057abee1c4503af2bf9eabe1f2311037bab770e10 \
  u256:0 \
  "$ACCOUNT_ADDRESS" \
  "$ACCOUNT_ADDRESS" 2>&1
)
PIX_TOKEN_ADDRESS=$(echo "$OUTPUT_PIXTOKEN" | grep "The contract will be deployed at address" | awk '{print $NF}')
echo "Pix Token Address: $PIX_TOKEN_ADDRESS"

# Dpixou deployment
echo "Deploying Dpixou..."
# Note: The class hash for Dpixou might change if you recompile it after modifying its source for STRK.
# Ensure you have the correct class hash from 'scarb build' and 'starkli declare' output for Dpixou.
# Example Dpixou class hash (replace with your actual one if it changed):
# 0x04a98f52d8ba475f4e290a9ccd5329cce9b4afae5fbae89c598c77a78082e0fd 
# For now, using the one from the original script, but it will need verification after recompilation.
DPIXOU_CLASS_HASH="0x04a98f52d8ba475f4e290a9ccd5329cce9b4afae5fbae89c598c77a78082e0fd" 
echo "Using Dpixou Class Hash: $DPIXOU_CLASS_HASH (VERIFY THIS if Dpixou.cairo was recompiled)"
OUTPUT_DPIXOU=$(starkli deploy --watch --rpc "$RPC_URL" --account "$ACCOUNT_FILE" \
  "$DPIXOU_CLASS_HASH" \
  "$STRK_TOKEN_CONTRACT_ADDRESS" \
  "$PIX_TOKEN_ADDRESS" 2>&1
)
DPIXOU_ADDRESS=$(echo "$OUTPUT_DPIXOU" | grep "The contract will be deployed at address" | awk '{print $NF}')
echo "Dpixou Address: $DPIXOU_ADDRESS"

# Change PixToken admin to Dpixou contract
echo "Changing PixToken admin to Dpixou contract..."
starkli invoke --watch --rpc "$RPC_URL" --account "$ACCOUNT_FILE" \
  "$PIX_TOKEN_ADDRESS" \
  change_admin \
  "$DPIXOU_ADDRESS"
echo "PixToken admin changed to $DPIXOU_ADDRESS"

# PixelWar deployment
echo "Deploying PixelWar..."
# Example PixelWar class hash (replace with your actual one if it changed):
# 0x01938b5b050ac487e5d8523b5a5e06959f038ee0f5309d7e475ab23346bc0428
# For now, using the one from the original script.
PIXELWAR_CLASS_HASH="0x01938b5b050ac487e5d8523b5a5e06959f038ee0f5309d7e475ab23346bc0428"
echo "Using PixelWar Class Hash: $PIXELWAR_CLASS_HASH (VERIFY THIS if PixelWar.cairo was recompiled)"
OUTPUT_PIXELWAR=$(starkli deploy --watch --rpc "$RPC_URL" --account "$ACCOUNT_FILE" \
  "$PIXELWAR_CLASS_HASH" \
  "$PIX_TOKEN_ADDRESS" \
  2>&1
)
PIXELWAR_ADDRESS=$(echo "$OUTPUT_PIXELWAR" | grep "The contract will be deployed at address" | awk '{print $NF}')
echo "PixelWar Address: $PIXELWAR_ADDRESS"

echo ""
echo "-------------------------------------"
echo "Deployed Contract Addresses Summary:"
echo "-------------------------------------"
echo "Pix Token Address:  $PIX_TOKEN_ADDRESS"
echo "STRK Token Address: $STRK_TOKEN_CONTRACT_ADDRESS (Predeployed)"
echo "Dpixou Address:     $DPIXOU_ADDRESS"
echo "PixelWar Address:   $PIXELWAR_ADDRESS"
echo "-------------------------------------"

echo ""
echo "Creating .env file with contract addresses and configuration..."
ENV_FILE=".env" # This file will be created in the current directory (lib/application/contracts/)

# Write contract addresses
echo "PIXELWAR_CONTRACT_ADDRESS=$PIXELWAR_ADDRESS" > "$ENV_FILE"
echo "DPIXOU_CONTRACT_ADDRESS=$DPIXOU_ADDRESS" >> "$ENV_FILE"
echo "PIX_TOKEN_CONTRACT_ADDRESS=$PIX_TOKEN_ADDRESS" >> "$ENV_FILE"
echo "STRK_TOKEN_CONTRACT_ADDRESS=$STRK_TOKEN_CONTRACT_ADDRESS" >> "$ENV_FILE"

# Add the predeployed ETH token address for devnet with seed 0
echo "ETH_TOKEN_CONTRACT_ADDRESS=0x049d36570d4e46f48e99674bd3fcc84644ddd6b96f7c741b1562b82f9e004dc7" >> "$ENV_FILE"

# Write account and RPC details from existing script variables
echo "ACCOUNT_ADDRESS=$ACCOUNT_ADDRESS" >> "$ENV_FILE"
echo "STARKNET_PRIVATE_KEY=$STARKNET_PRIVATE_KEY" >> "$ENV_FILE"
echo "ACCOUNT_CLASS_HASH=0x061dac032f228abef9c6626f995015233097ae253a7f72d68552db02f2971b8f" >> "$ENV_FILE" # This is an example OpenZeppelin account class hash
echo "RPC_URL=$RPC_URL" >> "$ENV_FILE"

echo ".env file created at $(pwd)/$ENV_FILE"

# Mint 1 ETH to the account for devnet fees
echo ""
echo "Minting 1 ETH to the account for devnet fees..."
curl -X POST "$RPC_URL/mint" \
  -H "Content-Type: application/json" \
  -d "{\"address\": \"$ACCOUNT_ADDRESS\", \"amount\": 1000000000000000000}"
echo "1 ETH minted to $ACCOUNT_ADDRESS"

# Mint some STRK to the account for testing Dpixou
echo ""
echo "Minting 1000 STRK to the account for testing Dpixou..."
curl -X POST "$RPC_URL/mint" \
  -H "Content-Type: application/json" \
  -d "{\"address\": \"$ACCOUNT_ADDRESS\", \"amount\": 1000000000000000000000, \"unit\": \"FRI\"}"
echo ""
echo "1000 STRK minted to $ACCOUNT_ADDRESS (using unit FRI)"

cd ../../.. # Return to project root
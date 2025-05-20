cd lib/application/contracts/

export STARKNET_PRIVATE_KEY="0x71d7bb07b9a64f6f78ac4c816aff4da9" 
export ACCOUNT_ADDRESS="0x64b48806902a367c8598f4f95c305e8c1a1acba5f082d294a43793113115691"
export RPC_URL="http://192.168.1.55:5050"
export ACCOUNT_FILE="devnet-acct.json"

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

# FRI token deployment
echo "Deploying FRI Token..."
OUTPUT_FRI_TOKEN=$(starkli deploy --watch --rpc "$RPC_URL" --account "$ACCOUNT_FILE" \
  0x00ff7cd091079f6083e0c6a057abee1c4503af2bf9eabe1f2311037bab770e10 \
  u256:1000000000000000000000000 \
  "$ACCOUNT_ADDRESS" \
  "$ACCOUNT_ADDRESS" 2>&1
)
FRI_TOKEN_ADDRESS=$(echo "$OUTPUT_FRI_TOKEN" | grep "The contract will be deployed at address" | awk '{print $NF}')
echo "FRI Token Address: $FRI_TOKEN_ADDRESS"

# Dpixou deployment
echo "Deploying Dpixou..."
OUTPUT_DPIXOU=$(starkli deploy --watch --rpc "$RPC_URL" --account "$ACCOUNT_FILE" \
  0x03604657ab0094ecdc8cc2cea642bff4c13dd21546e2ee7d7fc52eacd92f7afd \
  "$FRI_TOKEN_ADDRESS" \
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
OUTPUT_PIXELWAR=$(starkli deploy --watch --rpc "$RPC_URL" --account "$ACCOUNT_FILE" \
  0x01938b5b050ac487e5d8523b5a5e06959f038ee0f5309d7e475ab23346bc0428 \
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
echo "FRI Token Address:  $FRI_TOKEN_ADDRESS"
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
echo "FRI_TOKEN_CONTRACT_ADDRESS=$FRI_TOKEN_ADDRESS" >> "$ENV_FILE"

# Add the predeployed ETH token address for devnet with seed 0
echo "ETH_TOKEN_CONTRACT_ADDRESS=0x049d36570d4e46f48e99674bd3fcc84644ddd6b96f7c741b1562b82f9e004dc7" >> "$ENV_FILE"

# Write account and RPC details from existing script variables
echo "ACCOUNT_ADDRESS=$ACCOUNT_ADDRESS" >> "$ENV_FILE"
echo "STARKNET_PRIVATE_KEY=$STARKNET_PRIVATE_KEY" >> "$ENV_FILE"
echo "RPC_URL=$RPC_URL" >> "$ENV_FILE"

echo ".env file created at $(pwd)/$ENV_FILE"

# Mint 1 ETH to the account for devnet fees
echo ""
echo "Minting 1 ETH to the account for devnet fees..."
curl -X POST "$RPC_URL/mint" \
  -H "Content-Type: application/json" \
  -d "{\"address\": \"$ACCOUNT_ADDRESS\", \"amount\": 1000000000000000000}"
echo "1 ETH minted to $ACCOUNT_ADDRESS"
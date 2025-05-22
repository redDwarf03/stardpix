#!/bin/bash

# Usage: ./get_tokens.sh [ACCOUNT_ADDRESS]
# If ACCOUNT_ADDRESS is not provided, it will be read from .env

cd "$(dirname "$0")/../lib/application/contracts/"

# Load environment variables from .env
if [ -f .env ]; then
    set -o allexport
    source .env
    set +o allexport
else
    echo "Error: .env file not found in lib/application/contracts/. Please run deploy_sc.sh first."
    exit 1
fi


# Use argument if provided, else from .env
if [ -n "$1" ]; then
    ACCOUNT_ADDRESS="$1"
fi

if [ -z "$ACCOUNT_ADDRESS" ]; then
    echo "Error: ACCOUNT_ADDRESS not set. Provide as argument or in .env."
    exit 1
fi

echo "Using account address: $ACCOUNT_ADDRESS"
echo "Minting 1 ETH to $ACCOUNT_ADDRESS on devnet..."
curl -X POST "$RPC_URL/mint" \
  -H "Content-Type: application/json" \
  -d "{\"address\": \"$ACCOUNT_ADDRESS\", \"amount\": 1000000000000000000}"
echo # for newline

# Mint some STRK to the account for testing Dpixou
echo ""
echo "Minting 1000 STRK to the account for testing Dpixou..."
curl -X POST "$RPC_URL/mint" \
  -H "Content-Type: application/json" \
  -d "{\"address\": \"$ACCOUNT_ADDRESS\", \"amount\": 1000000000000000000000, \"unit\": \"FRI\"}"
echo ""
echo "1000 STRK minted to $ACCOUNT_ADDRESS (using unit FRI)"
echo # for newline

echo "Done."

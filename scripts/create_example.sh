cd lib/application/contracts/

# Source environment variables from .env file
if [ -f .env ]; then
    set -o allexport # Automatically export all variables sourced
    source .env
    set +o allexport
else
    echo "Error: .env file not found in lib/application/contracts/. Please run deploy_sc.sh first."
    exit 1
fi

# Variables from .env are now available, e.g., $ACCOUNT_ADDRESS, $RPC_URL, $PIX_TOKEN_CONTRACT_ADDRESS, etc.
# Ensure your devnet-acct.json is in the right place relative to where starkli is called or use an absolute path.
# For simplicity, assuming devnet-acct.json is in lib/application/contracts/ as well for this script.
export ACCOUNT_FILE="devnet-acct.json"

# Amount of STRK to spend to get 2 PIX (2 PIX * 0.01 STRK/PIX * 10^18)
# 2 * 0.01 = 0.02 STRK. With 18 decimals: 0.02 * 10^18
AMOUNT_STRK_TO_SPEND_FOR_2_PIX="u256:2000000000000000000"

echo "Attempting to buy 2 PIX by spending $AMOUNT_STRK_TO_SPEND_FOR_2_PIX STRK..."

echo "1. Approving Dpixou contract ($DPIXOU_CONTRACT_ADDRESS) to spend $AMOUNT_STRK_TO_SPEND_FOR_2_PIX STRK from account $ACCOUNT_ADDRESS via token $STRK_TOKEN_CONTRACT_ADDRESS ..."
starkli invoke --watch --rpc "$RPC_URL" --account "$ACCOUNT_FILE" \
  "$STRK_TOKEN_CONTRACT_ADDRESS" \
  approve \
  "$DPIXOU_CONTRACT_ADDRESS" \
  $AMOUNT_STRK_TO_SPEND_FOR_2_PIX

if [ $? -ne 0 ]; then
    echo "STRK Approval for Dpixou failed. Exiting."
    exit 1
fi
echo "STRK Approval for Dpixou successful."

echo "2. Calling buy_pix on Dpixou contract ($DPIXOU_CONTRACT_ADDRESS) to get PIX..."
starkli invoke --watch --rpc "$RPC_URL" --account "$ACCOUNT_FILE" \
  "$DPIXOU_CONTRACT_ADDRESS" \
  buy_pix \
  $AMOUNT_STRK_TO_SPEND_FOR_2_PIX

if [ $? -ne 0 ]; then
    echo "buy_pix call failed. Exiting."
    exit 1
fi
echo "buy_pix call successful. Should now have 2 additional PIX."

# Amount to approve for PixelWar to spend (2 PIX, as we are adding 2 pixels)
# 1 PIX = 1000000000000000000 (u256)
AMOUNT_PIX_TO_APPROVE_FOR_PIXELWAR="u256:2000000000000000000"

echo "Approving PixelWar contract ($PIXELWAR_CONTRACT_ADDRESS) to spend $AMOUNT_PIX_TO_APPROVE_FOR_PIXELWAR PIX from account $ACCOUNT_ADDRESS via token $PIX_TOKEN_CONTRACT_ADDRESS ..."
starkli invoke --watch --rpc "$RPC_URL" --account "$ACCOUNT_FILE" \
  "$PIX_TOKEN_CONTRACT_ADDRESS" \
  approve \
  "$PIXELWAR_CONTRACT_ADDRESS" \
  $AMOUNT_PIX_TO_APPROVE_FOR_PIXELWAR

if [ $? -ne 0 ]; then
    echo "PIX Approval for PixelWar failed. Exiting."
    exit 1
fi

echo "PIX Approval for PixelWar successful. Placing pixels using add_pixels..."

# Calldata for Array<Pixel>: [array_len, x1, y1, color1, x2, y2, color2, ...]
# Adding 2 pixels: (10, 20, 0x1234) and (10, 21, 0x1234)
PIXELS_CALLDATA="2 10 20 0x1234 10 21 0x1234"

starkli invoke --watch --rpc "$RPC_URL" --account "$ACCOUNT_FILE" \
  "$PIXELWAR_CONTRACT_ADDRESS" \
  add_pixels \
  $PIXELS_CALLDATA

if [ $? -ne 0 ]; then
    echo "add_pixels call failed. Exiting."
    exit 1
fi

echo "add_pixels call successful."

echo "Done."
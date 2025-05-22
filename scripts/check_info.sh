export STARKNET_PRIVATE_KEY="0x71d7bb07b9a64f6f78ac4c816aff4da9" 
export ACCOUNT_ADDRESS="0x64b48806902a367c8598f4f95c305e8c1a1acba5f082d294a43793113115691"
export RPC_URL="http://localhost:5050"
export ACCOUNT_FILE="devnet-acct.json"
export PIXEL_WAR_ADDRESS="0x02a26e4436a7424793af27b43b5ecc2ffe9ee50947df9a65e0153c715be1c4fe"

# Check the number of pixels on the PixelWar contract. Should be 
# [
#    "0x0000000000000000000000000000000000000000000000000000000000000000"
# ]
starkli call $PIXEL_WAR_ADDRESS get_all_pixels --rpc $RPC_URL

starkli call --rpc $RPC_URL $PIXEL_WAR_ADDRESS get_unlock_time $ACCOUNT_ADDRESS

starkli call --rpc $RPC_URL $PIXEL_WAR_ADDRESS get_pixel_color 10 20

starkli balance --rpc $RPC_URL $ACCOUNT_ADDRESS

starkli call "0x042c540c107fc91e38c865b47904989dd88506f9e49ef7fc32be755c77866590" get_nb_pix_for_strk u256:100 --rpc $RPC_URL

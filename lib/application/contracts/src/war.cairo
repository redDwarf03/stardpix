use starknet::ContractAddress as TopLevelContractAddress;
use core::array::ArrayTrait;
use core::integer::u256;

#[starknet::contract]
mod PixelWar {
    use starknet::{ContractAddress, get_caller_address, get_block_timestamp};
    use starknet::storage::Map;
    use core::option::OptionTrait; 
    use core::serde::Serde;

    // Interface for PixToken (for burnFrom)
    #[starknet::interface]
    trait IPixToken<TContractState> {
        fn burnFrom(ref self: TContractState, account: ContractAddress, amount: u256);
    }

    const MAX_X: u32 = 300;
    const MAX_Y: u32 = 100;
    const MAX_PIXELS_PER_TX: u32 = 64;
    const LOCK_TIME: u64 = 1;

    #[storage]
    struct Storage {
        pixel_map: Map<(u32, u32), felt252>,
        timers: Map<ContractAddress, u64>,
        // Track pixels that have been placed
        occupied_pixels: Map<u32, bool>,  // We'll use a flattened coordinate system
        pix_token_address: ContractAddress, // Address of the PIX token contract
    }

    #[derive(Copy, Drop, Serde, starknet::Store)]
    struct Pixel {
        x: u32,
        y: u32,
        color: felt252,
    }

    #[event]
    #[derive(Drop, starknet::Event)]
    enum Event {
        PixelPlaced: PixelPlaced,
        PixelsPlaced: PixelsPlaced
    }

    #[derive(Drop, starknet::Event)]
    struct PixelPlaced {
        x: u32,
        y: u32,
        color: felt252,
    }

    #[derive(Drop, starknet::Event)]
    struct PixelsPlaced {
        count: u32,
    }

    #[constructor]
    fn constructor(ref self: ContractState, pix_token: ContractAddress) {
        self.pix_token_address.write(pix_token);
    }

    #[abi(embed_v0)]
    impl PixelWarImpl of IPixelWar<ContractState> {
        fn add_pixel(ref self: ContractState, x: u32, y: u32, color: felt252) {
            validate_pixel_coordinates(x, y);
            
            // Check if user is allowed to place pixel (time-based)
            let caller = get_caller_address();
            let current_time = get_block_timestamp();
            
            // Use direct read without Option pattern matching
            let unlock_time = self.timers.read(caller);
            if unlock_time != 0 {
                assert(current_time >= unlock_time, 'Cannot place pixel yet');
            }
            
            // Burn 1 PIX token (1 * 10^18)
            let one_pix_in_wei: u256 = 1000000000000000000_u256; // 1 PIX
            IPixTokenDispatcher { contract_address: self.pix_token_address.read() }.burnFrom(caller, one_pix_in_wei);
            
            // Set cooldown for next pixel placement
            self.timers.write(caller, current_time + LOCK_TIME);
            
            // Place the pixel
            self.pixel_map.write((x, y), color);
            
            // Track the placed pixel
            let flat_index = flatten_coordinates(x, y);
            self.occupied_pixels.write(flat_index, true);
            
            // Emit event
            self.emit(PixelPlaced { x, y, color });
        }

        // New function to add multiple pixels simultaneously
        fn add_pixels(ref self: ContractState, pixels: Array<Pixel>) {
            let len = pixels.len();
            
            // Checks
            assert(len > 0, 'No pixels to add');
            assert(len <= MAX_PIXELS_PER_TX, 'Too many pixels');
            
            // Validate each pixel
            let mut i: u32 = 0;
            loop {
                if i >= len {
                    break;
                }
                
                let pixel = *pixels.at(i);
                validate_pixel_coordinates(pixel.x, pixel.y);
                
                i += 1;
            };
            
            // Check timer
            let caller = get_caller_address();
            let current_time = get_block_timestamp();
            
            let unlock_time = self.timers.read(caller);
            if unlock_time != 0 {
                assert(current_time >= unlock_time, 'Cannot place pixels yet');
            }
            
            // Burn PIX tokens (number of pixels * 1 PIX)
            let num_pixels_u256: u256 = len.into();
            let one_pix_in_wei: u256 = 1000000000000000000_u256;
            let total_amount_to_burn: u256 = num_pixels_u256 * one_pix_in_wei;
            IPixTokenDispatcher { contract_address: self.pix_token_address.read() }.burnFrom(caller, total_amount_to_burn);
            
            // Calculate the new lock time (based on the number of pixels)
            let lock_duration = LOCK_TIME * len.into();
            self.timers.write(caller, current_time + lock_duration);
            
            // Place all pixels
            let mut j: u32 = 0;
            loop {
                if j >= len {
                    break;
                }
                
                let pixel = *pixels.at(j);
                self.pixel_map.write((pixel.x, pixel.y), pixel.color);
                
                // Track the placed pixel
                let flat_index = flatten_coordinates(pixel.x, pixel.y);
                self.occupied_pixels.write(flat_index, true);
                
                j += 1;
            };
            
            // Emit an event
            self.emit(PixelsPlaced { count: len });
        }

        fn get_pixel_color(self: @ContractState, x: u32, y: u32) -> felt252 {
            validate_pixel_coordinates(x, y);
            self.pixel_map.read((x, y))
        }

        fn get_unlock_time(self: @ContractState, user: ContractAddress) -> u64 {
            // Just return the raw value - 0 if not set
            self.timers.read(user)
        }
        
        // New function to get all pixels
        fn get_all_pixels(self: @ContractState) -> Array<Pixel> {
            let mut pixels = ArrayTrait::new();
            
            // For each possible coordinate
            let mut x: u32 = 0;
            loop {
                if x >= MAX_X {
                    break;
                }
                
                let mut y: u32 = 0;
                loop {
                    if y >= MAX_Y {
                        break;
                    }
                    
                    // Check if this coordinate is occupied
                    let flat_index = flatten_coordinates(x, y);
                    let is_occupied = self.occupied_pixels.read(flat_index);
                    
                    if is_occupied {
                        let color = self.pixel_map.read((x, y));
                        pixels.append(Pixel { x, y, color });
                    }
                    
                    y += 1;
                };
                
                x += 1;
            };
            
            pixels
        }
    }

    // Interface trait for external functions
    #[starknet::interface]
    trait IPixelWar<TContractState> {
        fn add_pixel(ref self: TContractState, x: u32, y: u32, color: felt252);
        fn add_pixels(ref self: TContractState, pixels: Array<Pixel>);
        fn get_pixel_color(self: @TContractState, x: u32, y: u32) -> felt252;
        fn get_unlock_time(self: @TContractState, user: ContractAddress) -> u64;
        fn get_all_pixels(self: @TContractState) -> Array<Pixel>;
    }

    // Helper function
    fn validate_pixel_coordinates(x: u32, y: u32) {
        assert(x < MAX_X, 'Invalid X coordinate');
        assert(y < MAX_Y, 'Invalid Y coordinate');
    }
    
    // Helper function to flatten 2D coordinates to a single index
    fn flatten_coordinates(x: u32, y: u32) -> u32 {
        x * MAX_Y + y
    }
}

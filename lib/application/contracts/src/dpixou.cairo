use starknet::{ContractAddress, get_caller_address, get_contract_address};
use core::traits::Into;
use core::option::OptionTrait;
use core::serde::Serde;
use core::array::ArrayTrait;
use core::integer::u256;

// Standard ERC20 interface
#[starknet::interface]
trait IERC20<TContractState> {
    fn transferFrom(ref self: TContractState, sender: ContractAddress, recipient: ContractAddress, amount: u256) -> bool;
    fn balanceOf(self: @TContractState, account: ContractAddress) -> u256;
}

// Interface for PixToken with its mint function
#[starknet::interface]
trait IPixToken<TContractState> {
    fn mint(ref self: TContractState, recipient: ContractAddress, amount: u256);
}

// Interface for Dpixou
#[starknet::interface]
trait IDpixou<TContractState> {
    fn buy_pix(ref self: TContractState, amount_fri: u256);
    fn get_nb_pix_for_fri(self: @TContractState, amount_fri: u256) -> u256;
    fn get_nb_fri_for_pix(self: @TContractState, amount_pix: u256) -> u256;
}

#[starknet::contract]
mod Dpixou {
    use super::{ContractAddress, get_caller_address, get_contract_address, u256};
    use super::{IERC20Dispatcher, IERC20DispatcherTrait};
    use super::{IPixTokenDispatcher, IPixTokenDispatcherTrait};
    use super::{IDpixou};

    // 100 FRI for 1 PIX
    const FRI_PER_PIX: u256 = 100_u256;

    #[storage]
    struct Storage {
        fri_token: ContractAddress,
        pix_token: ContractAddress,
    }

    #[event]
    #[derive(Drop, starknet::Event)]
    enum Event {
        PixBought: PixBought
    }

    #[derive(Drop, starknet::Event)]
    struct PixBought {
        buyer: ContractAddress,
        amount_fri: u256,
        amount_pix: u256,
    }

    #[constructor]
    fn constructor(ref self: ContractState, fri_token: ContractAddress, pix_token: ContractAddress) {
        self.fri_token.write(fri_token);
        self.pix_token.write(pix_token);
    }

    #[abi(embed_v0)]
    impl DpixouImpl of IDpixou<ContractState> {
        fn buy_pix(ref self: ContractState, amount_fri: u256) {
            let buyer = get_caller_address();
            
            // Check that the amount is > 0
            assert(amount_fri > 0_u256, 'Amount must be > 0');

            // Calculate the number of PIX to receive
            let amount_pix = amount_fri / FRI_PER_PIX;
            assert(amount_pix > 0_u256, 'Not enough FRI');

            // Transfer FRI from the buyer to this contract
            let fri_token_addr = self.fri_token.read();
            IERC20Dispatcher { contract_address: fri_token_addr }.transferFrom(
                buyer, 
                get_contract_address(),
                amount_fri
            );

            // Mint PIX for the buyer
            let pix_token_addr = self.pix_token.read();
            IPixTokenDispatcher { contract_address: pix_token_addr }.mint(
                buyer,
                amount_pix
            );

            // Emit the event
            self.emit(Event::PixBought(PixBought { buyer, amount_fri, amount_pix }));
        }

        fn get_nb_pix_for_fri(self: @ContractState, amount_fri: u256) -> u256 {
            amount_fri / FRI_PER_PIX
        }

        fn get_nb_fri_for_pix(self: @ContractState, amount_pix: u256) -> u256 {
            amount_pix * FRI_PER_PIX
        }
    }
} 
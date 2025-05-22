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
    fn buy_pix(ref self: TContractState, amount_strk: u256);
    fn get_nb_pix_for_strk(self: @TContractState, amount_strk: u256) -> u256;
    fn get_nb_strk_for_pix(self: @TContractState, amount_pix: u256) -> u256;
}

#[starknet::contract]
mod Dpixou {
    use super::{ContractAddress, get_caller_address, get_contract_address, u256};
    use super::{IERC20Dispatcher, IERC20DispatcherTrait};
    use super::{IPixTokenDispatcher, IPixTokenDispatcherTrait};
    use super::{IDpixou};

    #[storage]
    struct Storage {
        strk_token: ContractAddress,
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
        amount_strk: u256,
        amount_pix: u256,
    }

    #[constructor]
    fn constructor(ref self: ContractState, strk_token: ContractAddress, pix_token: ContractAddress) {
        self.strk_token.write(strk_token);
        self.pix_token.write(pix_token);
    }

    #[abi(embed_v0)]
    impl DpixouImpl of IDpixou<ContractState> {
        fn buy_pix(ref self: ContractState, amount_strk: u256) {
            let ratio_num = 1_u256;
            let ratio_den = 100_u256;

            let buyer = get_caller_address();

            // Check that the amount is > 0
            assert(amount_strk > 0_u256, 'Amount STRK must be > 0');

            // Calculate the number of PIX to receive: amount_pix = amount_strk * DEN / NUM
            let amount_pix = (amount_strk * ratio_den) / ratio_num;
            assert(amount_pix > 0_u256, 'Not enough STRK');

            // Transfer STRK from buyer to contract
            let strk_token_addr = self.strk_token.read();
            IERC20Dispatcher { contract_address: strk_token_addr }.transferFrom(
                buyer, 
                get_contract_address(),
                amount_strk
            );

            // Mint PIX to buyer
            let pix_token_addr = self.pix_token.read();
            IPixTokenDispatcher { contract_address: pix_token_addr }.mint(
                buyer,
                amount_pix
            );

            // Emit event
            self.emit(Event::PixBought(PixBought { buyer, amount_strk, amount_pix }));
        }


        fn get_nb_pix_for_strk(self: @ContractState, amount_strk: u256) -> u256 {
            let ratio_num = 1_u256;
            let ratio_den = 100_u256;
            (amount_strk * ratio_den) / ratio_num
        }

        fn get_nb_strk_for_pix(self: @ContractState, amount_pix: u256) -> u256 {
            let ratio_num = 1_u256;
            let ratio_den = 100_u256;
            (amount_pix * ratio_num) / ratio_den
        }
    }
} 
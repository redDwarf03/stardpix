// SPDX-License-Identifier: MIT
#[starknet::contract]
mod PixToken {
    use starknet::{ContractAddress, get_caller_address};
    use starknet::storage::Map;
    use core::integer::u256;
    use core::option::OptionTrait;
    use core::traits::TryInto;
    use core::byte_array::ByteArray;

    #[starknet::interface]
    trait IPixToken<TContractState> {
        fn mint(ref self: TContractState, recipient: ContractAddress, amount: u256);
        fn burnFrom(ref self: TContractState, account: ContractAddress, amount: u256);
    }

    #[storage]
    struct Storage {
        // Standard ERC20 storage
        balances: Map<ContractAddress, u256>,
        allowances: Map<(ContractAddress, ContractAddress), u256>,
        total_supply: u256,
        name: felt252,
        symbol: felt252,
        decimals: u8,
        // Admin who can mint
        admin: ContractAddress,
    }

    #[event]
    #[derive(Drop, starknet::Event)]
    enum Event {
        Transfer: Transfer,
        Approval: Approval
    }

    #[derive(Drop, starknet::Event)]
    struct Transfer {
        from: ContractAddress,
        to: ContractAddress,
        value: u256
    }

    #[derive(Drop, starknet::Event)]
    struct Approval {
        owner: ContractAddress,
        spender: ContractAddress,
        value: u256
    }

    #[constructor]
    fn constructor(
        ref self: ContractState,
        initial_supply: u256,
        recipient: ContractAddress,
        admin: ContractAddress
    ) {
        // ERC20 metadata configuration
        self.name.write('PIX Token');
        self.symbol.write('PIX');
        self.decimals.write(18);
        self.admin.write(admin);

        // Mint initial tokens
        if initial_supply > 0_u256 {
            _mint(ref self, recipient, initial_supply);
        }
    }

    #[external(v0)]
    fn mint(ref self: ContractState, recipient: ContractAddress, amount: u256) {
        // Only admin can mint
        let caller = get_caller_address();
        assert(caller == self.admin.read(), 'Only admin can mint');
        _mint(ref self, recipient, amount);
    }

    #[external(v0)]
    fn transfer(ref self: ContractState, recipient: ContractAddress, amount: u256) -> bool {
        let sender = get_caller_address();
        _transfer(ref self, sender, recipient, amount);
        true
    }

    #[external(v0)]
    fn transferFrom(
        ref self: ContractState, sender: ContractAddress, recipient: ContractAddress, amount: u256
    ) -> bool {
        let caller = get_caller_address();
        _spend_allowance(ref self, sender, caller, amount);
        _transfer(ref self, sender, recipient, amount);
        true
    }

    #[external(v0)]
    fn approve(ref self: ContractState, spender: ContractAddress, amount: u256) -> bool {
        let caller = get_caller_address();
        _approve(ref self, caller, spender, amount);
        true
    }

    #[external(v0)]
    fn name(self: @ContractState) -> felt252 {
        self.name.read()
    }

    #[external(v0)]
    fn symbol(self: @ContractState) -> felt252 {
        self.symbol.read()
    }

    #[external(v0)]
    fn decimals(self: @ContractState) -> u8 {
        self.decimals.read()
    }

    #[external(v0)]
    fn totalSupply(self: @ContractState) -> u256 {
        self.total_supply.read()
    }

    #[external(v0)]
    fn balanceOf(self: @ContractState, account: ContractAddress) -> u256 {
        self.balances.read(account)
    }

    #[external(v0)]
    fn allowance(
        self: @ContractState, owner: ContractAddress, spender: ContractAddress
    ) -> u256 {
        self.allowances.read((owner, spender))
    }

    #[external(v0)]
    fn change_admin(ref self: ContractState, new_admin: ContractAddress) {
        let caller = get_caller_address();
        assert(caller == self.admin.read(), 'Only admin');
        self.admin.write(new_admin);
    }

    #[external(v0)]
    fn burnFrom(ref self: ContractState, account: ContractAddress, amount: u256) {
        let caller = get_caller_address();
        _spend_allowance(ref self, account, caller, amount);
        _burn(ref self, account, amount);
    }

    // Internal functions
    fn _mint(ref self: ContractState, recipient: ContractAddress, amount: u256) {
        assert(!_is_zero_address(recipient), 'ERC20: mint to zero address');
        
        let supply = self.total_supply.read();
        let new_supply = supply + amount;
        self.total_supply.write(new_supply);
        
        let recipient_balance = self.balances.read(recipient);
        let new_balance = recipient_balance + amount;
        self.balances.write(recipient, new_balance);
        
        self.emit(Event::Transfer(Transfer { 
            from: starknet::contract_address_const::<0>(), 
            to: recipient, 
            value: amount 
        }));
    }

    fn _burn(ref self: ContractState, account: ContractAddress, amount: u256) {
        assert(!_is_zero_address(account), 'ERC20: burn from zero address');
        
        let account_balance = self.balances.read(account);
        assert(account_balance >= amount, 'Burn > balance');
        self.balances.write(account, account_balance - amount);
        
        let supply = self.total_supply.read();
        let new_supply = supply - amount;
        self.total_supply.write(new_supply);
        
        self.emit(Event::Transfer(Transfer { 
            from: account, 
            to: starknet::contract_address_const::<0>(), // Transfer to zero address for burn
            value: amount 
        }));
    }

    fn _transfer(
        ref self: ContractState, sender: ContractAddress, recipient: ContractAddress, amount: u256
    ) {
        assert(!_is_zero_address(sender), 'ERC20: transfer from 0');
        assert(!_is_zero_address(recipient), 'ERC20: transfer to 0');

        let sender_balance = self.balances.read(sender);
        assert(sender_balance >= amount, 'ERC20: insufficient balance');
        
        self.balances.write(sender, sender_balance - amount);
        
        let recipient_balance = self.balances.read(recipient);
        let new_recipient_balance = recipient_balance + amount;
        self.balances.write(recipient, new_recipient_balance);
        
        self.emit(Event::Transfer(Transfer { from: sender, to: recipient, value: amount }));
    }

    fn _approve(
        ref self: ContractState, owner: ContractAddress, spender: ContractAddress, amount: u256
    ) {
        assert(!_is_zero_address(owner), 'ERC20: approve from 0');
        assert(!_is_zero_address(spender), 'ERC20: approve to 0');
        
        self.allowances.write((owner, spender), amount);
        
        self.emit(Event::Approval(Approval { owner, spender, value: amount }));
    }

    fn _spend_allowance(
        ref self: ContractState, owner: ContractAddress, spender: ContractAddress, amount: u256
    ) {
        let current_allowance = self.allowances.read((owner, spender));
        
        if current_allowance != 0xffffffffffffffffffffffffffffffff_u256 {
            assert(current_allowance >= amount, 'ERC20: insufficient allowance');
            _approve(ref self, owner, spender, current_allowance - amount);
        }
    }

    // Helper function
    fn _is_zero_address(address: ContractAddress) -> bool {
        address == starknet::contract_address_const::<0>()
    }
}
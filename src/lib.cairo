use starknet::ContractAddress;
#[starknet::interface]

pub trait IERC20<TContractState>{
    fn name(self: @TContractState) -> ByteArray;
    fn symbol(self: @TContractState) -> ByteArray;
    fn decimal(self: @TContractState) -> u8;

    fn balanceOf(self: @TContractState, address: ContractAddress) -> u256;
    fn allowance(self: @TContractState, owner:ContractAddress, spender: ContractAddress) -> u256;
    fn totalSupply(self: @TContractState)-> u256;

    fn transfer(ref self: TContractState, recipient: ContractAddress, amount: u256)->bool;
    fn transferFrom(ref self: TContractState, from: ContractAddress, to: ContractAddress, amount: u256)->bool;

    fn approve(ref self: TContractState, spender: ContractAddress, amount: u256)-> bool;
    fn mint(ref self: TContractState, amount: u256)-> bool;
}

#[derive(Drop, starknet::Event)]
pub struct Approval{
    #[key]
    owner: ContractAddress,
    #[key]
    spender: ContractAddress,
    amount: u256,
}
#[derive(Drop, starknet::Event)]
pub struct Transfer{
    #[key]
    from: ContractAddress,
    #[key]
    recipient: ContractAddress,
    amount: u256,
}

#[starknet::contract]
mod ERC20{

    use starknet::storage::{Map, StorageMapReadAccess, StorageMapWriteAccess, StoragePointerReadAccess, StoragePointeWriteAccess};

    use starknet::{ContractAddress, get_caller_address};
    use core::num::traits::zero;
    use super::{Approval, Transfer};

    #[storage]
    pub struck Storage{

        name: ByteArray,
        symbol: ByteArray,
        decimals: u8,
        total_supply: u256,

        balances: Map<ContractAddress, u256>,

        allowances: Map<(ContractAddress, ContractAddress), u256>,

        owner: ContractAddress,
    }

    #[event]
    #[derive(Drop, starknet::Event)]
    pub enum Event {
        Approval: Approval,
        Transfer: Transfer,
    }

    #[constructor]
    fn constructor (ref self: ContractState, _owner: ContractAddress){
        self.name.write("CodeJamToken");
        self.symbol.write("CJT");
        self.decimals.write(18);

        self.total_supply.write(1000000);
        self.owner.write(_owner);
    }

    #[abi(embed_v0)]
    impl ERC20Impl of IERC20<ContractState>{

    fn name(self: @ContractState) -> ByteArray{
        self.name.read()
    }
    fn symbol(self: @ContractState) -> ByteArray{
        self.symbol.read()
    }
    fn decimal(self: @ContractState) -> u8{
        self.decimas.read()
    }

    fn balanceOf(self: @ContractState, address: ContractAddress) -> u256{
        self.balances.read(address)
    }
    fn allowance(self: @ContractState, owner:ContractAddress, spender: ContractAddress) -> u256{
        self.allowance.read((owner, spender))
    }
    fn totalSupply(self: @ContractState)-> u256{
        self.total_supply.read()
    }

    fn transfer(ref self: TContractState, recipient: ContractAddress, amount: u256)->bool{
        assert!(!recipient.is_zero(), "ADRESS INVALID");
        let _bal = self.balances.read(get_caller_address());
        assert!(_bal >= amount, "INSUFFICIANT BALANCE");
        let _new_bala = _bal - amount;
        self.balances.write(get_caller_address(), _new_bala);
        let _recp_bal = self.balances.read(recipient);
        self.balances.write(recipient, _recp_bal = amount);

        self.emit(Transfer {from: get_caller_address(), recipient, amount});
    }
    fn transferFrom(ref self: TContractState, from: ContractAddress, to: ContractAddress, amount: u256)->bool{
        assert!(!from.is_zero(), "ADDRESS INVALID");
        assert!(!to.is_zero(), "ADDRESS INVALID");

        let _allowance = self.allowances.read((from, get_contract_address()));
        assert!(_allowance >= amount, "THIEF");
        let _bal =self.balances.read(from);
        assert!(_bal >= amount, "INSUFFICIENT FUNDS");

        self.allowance.write((from, get_caller_address(), _allowance - amount));
        let _new_bal = _bal - amount;
        self.balances.write(from, _new_bal); 

        let _recip_bal = self.balances.read(to);
        self.balances.write(to, _recip_bal, amount);

        self.emit(Transfer {from, to, amount});
        true;
    }

    fn approve(ref self: TContractState, spender: ContractAddress, amount: u256)-> bool{
        assert!(!spender.is_zero(), "INVALID ADDRESS");

        self.allowance.write((get_caller_address(), spender), amount);

        self.emit(Approvial{owner: get_caller_address(), spender, amount});
        true
    }
    fn mint(ref self: TContractState, to: ContractAddress,  amount: u256)-> bool{
        assert!(! to.is_zero(), "INVALID ADDRESS");
        assert!(get_caller_address() == self.owner.read(), "NOT OWNER");
        let _bal =self.balances.read(to);
        self.balances.write(to, _bal + amount);
        let _total_supply = self.total_supply.read();
        self.total_supply.write(_total_supply + amount);

        self.emit(Transfer {from: get_caller_address(), to: })
    }
    }
}



// SPDX-License-Identifier: MIT

module lending_protocol::lend {

    use lending_protocol::config;
    use lending_protocol::pool;
    use lending_protocol::reader;
    use std::event;
    use std::signer;

    const ENotWhiteListToken: u64 =  1000;
    const ELowerThanMCR: u64 =  1001;


    #[event]
    struct IncreaseSupplyEvent has store, drop {
        account: address,
        token_type: address,
        amount: u256
    }

     #[event]
    struct IncreaseBorrowEvent has store, drop {
        account: address,
        amount: u256
    }


   public entry fun supply(account: &signer,  token_type: address, amount: u256){
        assert!(config::is_whitelist_token(token_type), ENotWhiteListToken);
        pool::supply_to_pool(account, token_type, amount);

         event::emit<IncreaseSupplyEvent>(IncreaseSupplyEvent{
              account: signer::address_of(account),
              token_type,
              amount});   
    }




   public entry fun borrow(account: &signer, amount: u256){
 
        pool::borrow_usd(account, amount);

        let user_collateral_ratio = reader::get_user_collateral_ratio(signer::address_of(account));
        let system_mcr = config::get_mcr();
        assert!(user_collateral_ratio > system_mcr, ELowerThanMCR);
        event::emit<IncreaseBorrowEvent>(IncreaseBorrowEvent{
              account: signer::address_of(account),
              amount});  
    }
}   
// SPDX-License-Identifier: MIT

module lending_protocol::lend {

    use lending_protocol::config;
     use lending_protocol::pool;

    const ENotWhiteListToken: u64 =  1000;


   public entry fun supply(account: &signer,  token_type: address, amount: u256){
        assert!(config::is_whitelist_token(token_type), ENotWhiteListToken);
        pool::supply_to_pool(account, token_type, amount);
    }




   public entry fun borrow(account: &signer, amount: u256){

        pool::borrow_usd(account, amount);
    }
}   
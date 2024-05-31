// SPDX-License-Identifier: MIT

module lending_protocol::config {

    use lending_protocol::usd;
    use std::signer;
    use std::vector;
    use std::primary_fungible_store;
    use std::fungible_asset::{Metadata};
    use std::simple_map::{Self, SimpleMap, borrow, borrow_mut, contains_key};
    use std::object::{Self, ExtendRef, Object};

    const MAX_COLLATERAL_RATIO:u256 = 10000;
    const PRECISION_DECIMALS: u256 = 6;
    const APP_OBJECT_SEED: vector<u8> = b"CONFIG";    

    struct Config has key {
        collateral_tokens: vector<address>,
        mcr: u256,

    }
    
    struct CollateralParam has store {
        max_collateral_ratio: u256,
    }

    fun init_module(deployer: &signer) {
        let constructor_ref = &object::create_named_object(deployer, APP_OBJECT_SEED, false);
        let app_signer = &object::generate_signer(constructor_ref); 
        move_to(app_signer,
                Config{
                     collateral_tokens: vector::empty(),
                     mcr: 1000000000
                }
        )
               
      }


    public entry fun set_collateral_param(token_type: address) acquires Config {
        //todo 
        let signer_address = get_app_signer_address();
        let config = borrow_global_mut<Config>(signer_address); 
        let is_whitelisted = vector::contains(&config.collateral_tokens, &token_type);

        if(!is_whitelisted){
            vector::push_back(&mut config.collateral_tokens, token_type);
           
        };
    }

    #[view]
    public fun is_whitelist_token(token_type: address): bool acquires Config{
        let signer_address = get_app_signer_address();
        let config = borrow_global<Config>(signer_address);
        return vector::contains(&config.collateral_tokens, &token_type)
    }

    #[view]
    public fun get_all_whitelist_tokens():vector<address> acquires Config{
        let signer_address = get_app_signer_address();
        let config = borrow_global<Config>(signer_address);
        return config.collateral_tokens
    }


     #[view]
    public fun get_app_signer_address(): address {
        object::create_object_address(@lending_protocol, APP_OBJECT_SEED)
    }
    


    
}   
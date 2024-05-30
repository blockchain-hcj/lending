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
    const PRECISION: u256 = 100000;
    const APP_OBJECT_SEED: vector<u8> = b"CONFIG";    

    struct Config has key {
        collateral_param: SimpleMap<address, CollateralParam>,
        collateral_tokens: vector<address>
    }
    
    struct CollateralParam has store {
        max_collateral_ratio: u256,
    }

    fun init_module(deployer: &signer) {
        let constructor_ref = &object::create_named_object(deployer, APP_OBJECT_SEED, false);
        let app_signer = &object::generate_signer(constructor_ref); 
        move_to(app_signer,
                Config{
                     collateral_param: simple_map::create(),
                     collateral_tokens: vector::empty()
                }
        )
               
      }


    public entry fun set_collateral_param(token_type: address) acquires Config {
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
    public fun get_app_signer_address(): address {
        object::create_object_address(@lending_protocol, APP_OBJECT_SEED)
    }
    


    
}   
// SPDX-License-Identifier: MIT

module lending_protocol::pool {

    use lending_protocol::usd;
    use lending_protocol::config;
    use std::signer;
    use std::primary_fungible_store;
    use std::fungible_asset::{Self, Metadata};
    use std::simple_map::{Self,  borrow, borrow_mut, contains_key};
    use std::object::{Self, ExtendRef};
    friend lending_protocol::lend;

    const APP_OBJECT_SEED: vector<u8> = b"LEND";



    //error
    const ENotWhiteListToken: u64 = 3000;        

    struct PoolController has key, store{
         app_extend_ref: ExtendRef
    }

    struct SupplyPool has store {
        user_supply: simple_map::SimpleMap<address, u256>,
        total_supply: u256,
    }

    struct BorrowPool has store {
        user_borrow: simple_map::SimpleMap<address, u256>,
        total_borrow: u256,
    }

    struct ProtocolPool has key {
        supply_pool: simple_map::SimpleMap<address, SupplyPool>,
        borrow_pool:  BorrowPool
    }

    fun init_module(deployer: &signer) {

        let constructor_ref = &object::create_named_object(deployer, APP_OBJECT_SEED, false);
        let extend_ref = object::generate_extend_ref(constructor_ref);
        let app_signer = &object::generate_signer(constructor_ref); 
        move_to(app_signer,
                ProtocolPool{ 
                    supply_pool: simple_map::create(),
                    borrow_pool: BorrowPool{
                         user_borrow: simple_map::create(),
                         total_borrow: 0,
                    }
                });
        move_to(app_signer, 
                PoolController {
                    app_extend_ref: extend_ref,
        });
                
   }


    public (friend) fun supply_to_pool(account: &signer, token_type: address, amount: u256) acquires ProtocolPool, PoolController{
        let signer_address = get_app_signer_address();
        let protocol_pool = borrow_global_mut<ProtocolPool>(signer_address);
        let user_address = signer::address_of(account);
        if(!contains_key(& protocol_pool.supply_pool, &token_type)){
            simple_map::add(&mut protocol_pool.supply_pool, token_type, SupplyPool{
                user_supply: simple_map::create(),
                 total_supply: 0,
            }); 
        };
        let supply_pool = borrow_mut(&mut protocol_pool.supply_pool, &token_type);

        //transfer in token
        module_transfer_in_token(account, token_type, amount);

        //add user
        if(!contains_key(& supply_pool.user_supply, &user_address)){
            simple_map::add(&mut supply_pool.user_supply, user_address, amount); 
        }else{
            let user_supply_value = borrow_mut(&mut supply_pool.user_supply, &user_address);
            *user_supply_value = *user_supply_value + amount;
        };   

        //add total
        supply_pool.total_supply = supply_pool.total_supply + amount;
    }


    public (friend) fun borrow_usd(account: &signer, amount: u256) acquires ProtocolPool {
        let usd_metadata = usd::get_usd_metadata();
        primary_fungible_store::ensure_primary_store_exists<Metadata>(signer::address_of(account), usd_metadata);
        let receiving_store = primary_fungible_store::primary_store(signer::address_of(account), usd_metadata);
        
        
        // transfer usd to user
        usd::mint_to(receiving_store, (amount as u64));


        let signer_address = get_app_signer_address();
        let protocol_pool = borrow_global_mut<ProtocolPool>(signer_address);
        let borrow_pool = &mut protocol_pool.borrow_pool;
        let user_address = signer::address_of(account);
        //add user borrow
        if(!contains_key(& borrow_pool.user_borrow, &user_address)){
            simple_map::add(&mut borrow_pool.user_borrow, user_address, amount); 
        }else{
            let user_borrow_value = borrow_mut(&mut borrow_pool.user_borrow, &user_address);
            *user_borrow_value = *user_borrow_value + amount;
        };   

        //add total borrow
        borrow_pool.total_borrow = borrow_pool.total_borrow + amount;

    }


    fun module_transfer_out_token(to: address, token_meta_data_address: address, amount: u256) acquires  PoolController{
        let router_signer = get_app_signer(get_app_signer_address());
        let router_signer_address = get_app_signer_address();
        let token_metadata = object::address_to_object<Metadata>(token_meta_data_address);
        let user_gas_fungible_store = primary_fungible_store::primary_store(to, token_metadata);
        let module_fungible_store = primary_fungible_store::primary_store(router_signer_address, token_metadata);
        fungible_asset::transfer(&router_signer, module_fungible_store, user_gas_fungible_store, (amount as u64));
    }


    fun module_transfer_in_token(from: &signer, token_meta_data_address: address, amount: u256) acquires  PoolController{
        let router_signer = get_app_signer(get_app_signer_address());
        let router_signer_address = get_app_signer_address();
        let token_metadata = object::address_to_object<Metadata>(token_meta_data_address);
        let user_gas_fungible_store = primary_fungible_store::primary_store(signer::address_of(from), token_metadata);
        let module_fungible_store = primary_fungible_store::ensure_primary_store_exists(router_signer_address, token_metadata);
        fungible_asset::transfer(from, user_gas_fungible_store, module_fungible_store, (amount as u64));
    }

   
       
    #[view]
    public fun get_app_signer_address(): address {
        object::create_object_address(@lending_protocol, APP_OBJECT_SEED)
    }

     #[view]
    public fun get_user_token_supply(user: address, token_type: address): u256 acquires ProtocolPool{
        let signer_address = get_app_signer_address();
        let is_whitelist_token = config::is_whitelist_token(token_type);
        assert!(is_whitelist_token, ENotWhiteListToken);
        let protocol_pool = borrow_global_mut<ProtocolPool>(signer_address);
        if(!contains_key(&protocol_pool.supply_pool, &token_type)){
            return 0 
        };
        let supply_pool = borrow(&protocol_pool.supply_pool, &token_type);
        if(!contains_key(&supply_pool.user_supply, &user)){
            return 0
        };
        let user_supply = borrow(&supply_pool.user_supply, &user);
        return *user_supply
    }

     #[view]
     public fun get_user_total_borrow(user: address): u256 acquires ProtocolPool{
        let signer_address = get_app_signer_address();
        let protocol_pool = borrow_global_mut<ProtocolPool>(signer_address);
        let borrow_pool = &protocol_pool.borrow_pool;
         if(!contains_key(&borrow_pool.user_borrow, &user)){
            return 0
        };
        let user_borrow = borrow(&borrow_pool.user_borrow, &user);
        return *user_borrow
     }



    fun get_app_signer(app_signer_address: address): signer acquires PoolController {
        object::generate_signer_for_extending(&borrow_global<PoolController>(app_signer_address).app_extend_ref)
    }
    
    
}   
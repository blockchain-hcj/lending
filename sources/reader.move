module lending_protocol::reader {
    use lending_protocol::config;
    use lending_protocol::pool;
    use std::vector;
    use oracle_service::pricefeed;

    public fun get_user_supply_total_usd(user: address):u256{
        let whitelist_tokens = config::get_all_whitelist_tokens();
        let tokens_length = vector::length(&whitelist_tokens);
        let usd_value = 0;
        for (i in 0..tokens_length) {
            let token_address_ref = vector::borrow(&whitelist_tokens, i);
            let user_token_supply = pool::get_user_token_supply(user, *token_address_ref);
            let (price, _) = pricefeed::lastest_round_data(*token_address_ref);

            //TODO precision
            usd_value = usd_value + user_token_supply * price;
        };
        return usd_value
    }

    public fun get_user_collateral_rate(): u256{
        return 1
    }

}
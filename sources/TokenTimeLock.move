module lahari_addr::TokenTimeLock {
    use aptos_framework::signer;
    use aptos_framework::coin::{Self, Coin};
    use aptos_framework::aptos_coin::AptosCoin;
    use aptos_framework::timestamp;
    struct TimeLock has store, key {
        locked_coins: Coin<AptosCoin>, 
        release_time: u64,       
        beneficiary: address,         
    }
    public fun create_time_lock(
        depositor: &signer, 
        beneficiary: address, 
        amount: u64, 
        lock_duration: u64
    ) {
        let current_time = timestamp::now_seconds();
        let release_time = current_time + lock_duration;
        let locked_coins = coin::withdraw<AptosCoin>(depositor, amount);
        let time_lock = TimeLock {
            locked_coins,
            release_time,
            beneficiary,
        };
        move_to(depositor, time_lock);
    }
    public fun release_tokens(beneficiary: &signer, locker_address: address) acquires TimeLock {
        let time_lock = borrow_global<TimeLock>(locker_address);
        let current_time = timestamp::now_seconds();
        assert!(current_time >= time_lock.release_time, 1); 
        assert!(signer::address_of(beneficiary) == time_lock.beneficiary, 2); 
        let TimeLock { locked_coins, release_time: _, beneficiary: _ } = move_from<TimeLock>(locker_address);
        coin::deposit<AptosCoin>(signer::address_of(beneficiary), locked_coins);
    }

}

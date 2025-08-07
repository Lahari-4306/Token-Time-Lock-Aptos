module lahari_addr::TokenTimeLock {
    use aptos_framework::signer;
    use aptos_framework::coin::{Self, Coin};
    use aptos_framework::aptos_coin::AptosCoin;
    use aptos_framework::timestamp;
    
    /// Struct representing a time-locked token deposit
    struct TimeLock has store, key {
        locked_coins: Coin<AptosCoin>, // The actual locked coins
        release_time: u64,             // Unix timestamp when tokens can be released
        beneficiary: address,          // Address that can claim the tokens
    }
    
    /// Function to create a time-locked deposit
    /// @param depositor: Account creating the time lock
    /// @param beneficiary: Address that will receive tokens after lock period
    /// @param amount: Amount of tokens to lock
    /// @param lock_duration: Duration in seconds to lock tokens
    public fun create_time_lock(
        depositor: &signer, 
        beneficiary: address, 
        amount: u64, 
        lock_duration: u64
    ) {
        // Calculate release time
        let current_time = timestamp::now_seconds();
        let release_time = current_time + lock_duration;
        
        // Withdraw tokens from depositor to lock them
        let locked_coins = coin::withdraw<AptosCoin>(depositor, amount);
        
        // Create time lock struct with the coins inside
        let time_lock = TimeLock {
            locked_coins,
            release_time,
            beneficiary,
        };
        
        // Store the time lock resource
        move_to(depositor, time_lock);
    }
    
    /// Function to release tokens after lock period expires
    /// @param beneficiary: The beneficiary account claiming tokens
    /// @param locker_address: Address where the time lock was created
    public fun release_tokens(beneficiary: &signer, locker_address: address) acquires TimeLock {
        let time_lock = borrow_global<TimeLock>(locker_address);
        let current_time = timestamp::now_seconds();
        
        // Verify release conditions
        assert!(current_time >= time_lock.release_time, 1); // Time lock not expired
        assert!(signer::address_of(beneficiary) == time_lock.beneficiary, 2); // Not authorized beneficiary
        
        // Remove the time lock and extract coins
        let TimeLock { locked_coins, release_time: _, beneficiary: _ } = move_from<TimeLock>(locker_address);
        
        // Deposit released coins to beneficiary
        coin::deposit<AptosCoin>(signer::address_of(beneficiary), locked_coins);
    }
}
# Cross-chain rebase token

1. A protocol that allows users to deposit into a vault and in return recieve rebase tokens that represent their underlying balance
2. Rebase token -> balanceOf function is dynamic to show the changing balance with time 
        - Balance increases linearly with time
        - mint tokens to our users every time they perform an action (minting, burning, transferring or bridging)
3. Interest rate
    - Individually set an interest rate or each user based on some global interest rate of the protocol at the time the user deposits into the vault
    - The global interest rate is set to decrease to incentivise/reward early adopters 
    - Increase token adoption
                                                                        
     ┌───────────────────────────────────────────────────────────┐  
     │                                                           │  
     │           ┌─────────────────┐     ┌─────────────────┐     │  
     │           │*Vault Contract* │     │ *Rebase Token*  │     │  
 ┌───▼───┐       │                 │     │                 │     │  
 │ USER  ├───────┼► Deposit ETH────┼─────┼► user interest──┼─────┘  
 │       │       │                 │     │                 │        
 └───────┘       │  Receive Rebase │     │  global interest│        
                 │                 │     │                 │        
                 │                 │     │                 │        
                 │                 │     │                 │        
                 └─────────────────┘     └─────────────────┘           
            

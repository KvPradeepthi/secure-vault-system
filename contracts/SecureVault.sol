// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./AuthorizationManager.sol";

/**
 * @title SecureVault
 * @dev Secure vault for holding and transferring funds with authorization validation
 */
contract SecureVault {
    // Reference to the authorization manager contract
    AuthorizationManager public authorizationManager;
    
    // Track vault balance per user (for internal accounting)
    mapping(address => uint256) public balances;
    
    // Total balance in vault
    uint256 public totalBalance;
    
    // Emitted when funds are deposited
    event Deposit(address indexed depositor, uint256 amount);
    
    // Emitted when funds are withdrawn
    event Withdrawal(address indexed recipient, uint256 amount, uint256 nonce);
    
    // Emitted when vault is initialized
    event VaultInitialized(address indexed authManager);
    
    // Track initialization
    bool private initialized = false;
    
    /**
     * @dev Initialize the vault with authorization manager address
     * Can only be called once
     */
    function initialize(address _authorizationManager) external {
        require(!initialized, "Vault already initialized");
        require(_authorizationManager != address(0), "Invalid authorization manager");
        authorizationManager = AuthorizationManager(_authorizationManager);
        initialized = true;
        emit VaultInitialized(_authorizationManager);
    }
    
    /**
     * @dev Accept deposits of native blockchain currency
     */
    receive() external payable {
        require(msg.value > 0, "Deposit amount must be greater than 0");
        
        // Update accounting
        balances[msg.sender] += msg.value;
        totalBalance += msg.value;
        
        emit Deposit(msg.sender, msg.value);
    }
    
    /**
     * @dev Deposit native currency with a function call
     */
    function deposit() external payable {
        require(msg.value > 0, "Deposit amount must be greater than 0");
        
        // Update accounting
        balances[msg.sender] += msg.value;
        totalBalance += msg.value;
        
        emit Deposit(msg.sender, msg.value);
    }
    
    /**
     * @dev Withdraw funds using an authorization
     * @param recipient The address receiving the funds
     * @param amount The amount to withdraw
     * @param nonce Unique nonce for this authorization
     * @param signature The signature from the signer
     */
    function withdraw(
        address recipient,
        uint256 amount,
        uint256 nonce,
        bytes calldata signature
    ) external {
        require(initialized, "Vault not initialized");
        require(recipient != address(0), "Invalid recipient");
        require(amount > 0, "Withdrawal amount must be greater than 0");
        require(totalBalance >= amount, "Insufficient vault balance");
        
        // Request authorization validation
        // This will revert if authorization is invalid or already consumed
        bool authorized = authorizationManager.verifyAuthorization(
            address(this),
            recipient,
            amount,
            nonce,
            signature
        );
        
        require(authorized, "Authorization failed");
        
        // Update internal state BEFORE transferring funds
        totalBalance -= amount;
        
        // Transfer funds to recipient
        (bool success, ) = payable(recipient).call{value: amount}("");
        require(success, "Transfer failed");
        
        emit Withdrawal(recipient, amount, nonce);
    }
    
    /**
     * @dev Get the current vault balance
     */
    function getBalance() external view returns (uint256) {
        return totalBalance;
    }
    
    /**
     * @dev Get the balance of a specific user
     */
    function getUserBalance(address user) external view returns (uint256) {
        return balances[user];
    }
}

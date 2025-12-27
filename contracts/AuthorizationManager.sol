// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title AuthorizationManager
 * @dev Manages withdrawal authorizations and prevents replay attacks
 */
contract AuthorizationManager {
    // Track authorized withdrawals by their hash
    mapping(bytes32 => bool) public consumedAuthorizations;
    
    // Track the signer of authorizations
    address public authorizationSigner;
    
    // Emitted when an authorization is validated and consumed
    event AuthorizationConsumed(bytes32 indexed authHash, address indexed vault, address indexed recipient, uint256 amount);
    
    // Emitted when signer is set
    event SignerSet(address indexed signer);
    
    // Track initialization
    bool private initialized = false;
    
    /**
     * @dev Initialize the authorization manager with a signer address
     * Can only be called once
     */
    function initialize(address _signer) external {
        require(!initialized, "Already initialized");
        require(_signer != address(0), "Invalid signer");
        authorizationSigner = _signer;
        initialized = true;
        emit SignerSet(_signer);
    }
    
    /**
     * @dev Verify and consume an authorization
     * @param vault The vault contract address
     * @param recipient The withdrawal recipient
     * @param amount The withdrawal amount
     * @param nonce Unique nonce for this authorization
     * @param signature The signature from the signer
     * @return True if authorization is valid and successfully consumed
     */
    function verifyAuthorization(
        address vault,
        address recipient,
        uint256 amount,
        uint256 nonce,
        bytes calldata signature
    ) external returns (bool) {
        // Construct the authorization message
        bytes32 authHash = keccak256(abi.encodePacked(
            vault,
            recipient,
            amount,
            nonce,
            block.chainid
        ));
        
        // Check if authorization has already been used
        require(!consumedAuthorizations[authHash], "Authorization already consumed");
        
        // Recover the signer from the signature
        bytes32 messageHash = keccak256(abi.encodePacked(
            "\x19Ethereum Signed Message:\n32",
            authHash
        ));
        
        address recoveredSigner = recoverSigner(messageHash, signature);
        require(recoveredSigner == authorizationSigner, "Invalid signature");
        
        // Mark authorization as consumed before returning
        consumedAuthorizations[authHash] = true;
        
        emit AuthorizationConsumed(authHash, vault, recipient, amount);
        return true;
    }
    
    /**
     * @dev Check if an authorization has been consumed
     */
    function isAuthorizationConsumed(bytes32 authHash) external view returns (bool) {
        return consumedAuthorizations[authHash];
    }
    
    /**
     * @dev Recover the signer from a message hash and signature
     */
    function recoverSigner(
        bytes32 messageHash,
        bytes calldata signature
    ) internal pure returns (address) {
        require(signature.length == 65, "Invalid signature length");
        
        bytes32 r;
        bytes32 s;
        uint8 v;
        
        assembly {
            r := mload(add(signature.offset, 0x20))
            s := mload(add(signature.offset, 0x40))
            v := byte(0, mload(add(signature.offset, 0x60)))
        }
        
        if (v < 27) {
            v += 27;
        }
        
        require(v == 27 || v == 28, "Invalid signature v value");
        
        return ecrecover(messageHash, v, r, s);
    }
}

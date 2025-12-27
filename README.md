# Secure Vault System

A secure multi-contract vault system with off-chain authorization validation for decentralized fund management. This system implements a robust architecture where fund custody and permission validation are split across two smart contracts to enhance security and clarity.

## Overview

The Secure Vault System is composed of two smart contracts:

1. **AuthorizationManager**: Validates withdrawal permissions originating from off-chain signatures and prevents replay attacks
2. **SecureVault**: Holds funds and executes withdrawals only after authorization confirmation

## System Architecture

### Key Components

#### AuthorizationManager Contract
- Validates withdrawal authorizations using ECDSA signatures
- Tracks consumed authorizations to prevent replay attacks
- Stores the authorized signer address
- Implements initialization protection (can only be initialized once)

#### SecureVault Contract  
- Accepts native blockchain currency deposits
- Holds and manages funds in a secure manner
- Executes withdrawals only after authorization validation
- Tracks user balances and total vault balance
- Implements state-before-value-transfer pattern for reentrancy protection

## Security Features

### Authorization Binding
Each authorization is tightly bound to:
- Specific vault instance address
- Specific blockchain network (chainId)
- Specific recipient address
- Specific withdrawal amount
- Unique nonce to prevent duplicate effects

### Replay Attack Prevention
- Consumed authorizations are tracked and marked as used
- Each authorization can only be used once
- Attempting to reuse an authorization reverts with "Authorization already consumed"

### Reentrancy Protection
- Internal state updates (balance deductions) occur before external transfers
- Uses low-level call pattern with proper error handling

### Initialization Protection
- Both contracts can only be initialized once
- Prevents accidental or malicious reinitialization

## Project Structure

```
.
├── contracts/
│   ├── AuthorizationManager.sol    # Authorization validation contract
│   └── SecureVault.sol              # Vault holding and transfer contract
├── scripts/
│   └── deploy.js                   # Deployment script
├── tests/
│   └── system.spec.js              # Comprehensive test suite
├── docker/
│   ├── Dockerfile                  # Container image definition
│   └── entrypoint.sh               # Startup script
├── docker-compose.yml              # Docker Compose configuration
├── hardhat.config.js               # Hardhat configuration
├── package.json                    # Dependencies and scripts
└── README.md                       # This file
```

## Installation

### Prerequisites
- Node.js 18+
- Docker and Docker Compose (for containerized deployment)
- npm or yarn

### Setup

1. Clone the repository:
```bash
git clone <repository-url>
cd secure-vault-system
```

2. Install dependencies:
```bash
npm install
```

3. Compile contracts:
```bash
npm run compile
```

## Deployment

### Local Deployment (without Docker)

1. Start Hardhat node:
```bash
npx hardhat node
```

2. In another terminal, deploy contracts:
```bash
npm run deploy
```

The deployment script will output contract addresses and save them to `deployment-info.json`.

### Docker Deployment

1. Build and start the system:
```bash
docker-compose up
```

This will:
- Compile all smart contracts
- Start a local Hardhat blockchain
- Deploy both contracts
- Expose the RPC endpoint on `http://localhost:8545`
- Display deployment information in the logs

## Usage Guide

### Depositing Funds

Anyone can deposit native currency into the vault:

```javascript
// Using ethers.js
const vault = await ethers.getContractAt("SecureVault", vaultAddress);

// Option 1: Direct transfer
await deployer.sendTransaction({
    to: vault.address,
    value: ethers.utils.parseEther("10")
});

// Option 2: Using deposit function
await vault.deposit({ value: ethers.utils.parseEther("10") });
```

### Generating Authorizations

Off-chain, use the signer to create withdrawal authorizations:

```javascript
const ethers = require("ethers");

// Parameters
const vaultAddress = "0x..."; 
const recipientAddress = "0x...";
const withdrawAmount = ethers.utils.parseEther("5");
const nonce = 1;
const chainId = 31337; // Hardhat network

// Create authorization hash
const authHash = ethers.utils.solidityKeccak256(
    ["address", "address", "uint256", "uint256", "uint256"],
    [vaultAddress, recipientAddress, withdrawAmount, nonce, chainId]
);

// Sign authorization (signer must match AuthorizationManager's signer)
const signature = await signer.signMessage(ethers.utils.arrayify(authHash));

console.log("Authorization signature:", signature);
```

### Executing Withdrawals

Withdraw funds using the authorization:

```javascript
const vault = await ethers.getContractAt("SecureVault", vaultAddress);

await vault.withdraw(
    recipientAddress,
    withdrawAmount,
    nonce,
    signature
);
```

## Testing

Run the comprehensive test suite:

```bash
npm test
```

The test suite covers:
- Deposit functionality
- Withdrawal authorization and validation
- Authorization replay attack prevention
- Invalid signature rejection
- Insufficient balance handling
- Initialization protection
- Balance tracking

## Deployment Information

After deployment, contract addresses and network information are available in `deployment-info.json`:

```json
{
  "authorizationManager": "0x...",
  "secureVault": "0x...",
  "deployer": "0x...",
  "network": "localhost",
  "chainId": 31337,
  "timestamp": "2024-01-01T00:00:00.000Z"
}
```

## Events

The system emits the following events:

### AuthorizationManager
- `SignerSet(address indexed signer)` - Emitted when signer is set during initialization
- `AuthorizationConsumed(bytes32 indexed authHash, address indexed vault, address indexed recipient, uint256 amount)` - Emitted when authorization is validated and consumed

### SecureVault
- `VaultInitialized(address indexed authManager)` - Emitted when vault is initialized
- `Deposit(address indexed depositor, uint256 amount)` - Emitted when funds are deposited
- `Withdrawal(address indexed recipient, uint256 amount, uint256 nonce)` - Emitted when withdrawal succeeds

## Error Handling

The system provides clear error messages:

- `"Already initialized"` - Attempting to initialize an already-initialized contract
- `"Invalid signer"` - Providing invalid signer address
- `"Authorization already consumed"` - Attempting to reuse an authorization
- `"Invalid signature"` - Signature doesn't match authorized signer
- `"Vault not initialized"` - Vault hasn't been initialized
- `"Insufficient vault balance"` - Attempting to withdraw more than available
- `"Transfer failed"` - Failed to transfer funds to recipient

## Development

### Contract Modification

To modify the contracts:
1. Edit files in `contracts/`
2. Run `npm run compile` to compile
3. Update tests if contract interfaces change
4. Run `npm test` to verify changes

### Adding New Features

When extending the system:
- Maintain the separation of concerns (vault vs authorization)
- Preserve authorization binding to all contextual parameters
- Ensure state updates occur before value transfers
- Add corresponding tests

## Common Issues

### Port 8545 Already in Use
```bash
# Find and kill process using port 8545
lsof -i :8545
kill -9 <PID>
```

### Docker Build Failures
```bash
# Clean rebuild
docker-compose down
docker-compose build --no-cache
docker-compose up
```

## License

MIT

## Contact

For questions or issues, please open an issue in the repository.

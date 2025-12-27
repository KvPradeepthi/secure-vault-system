#!/bin/sh

echo "Starting Secure Vault System..."

# Compile contracts
echo "Compiling Solidity contracts..."
npm run compile

if [ $? -ne 0 ]; then
    echo "Compilation failed"
    exit 1
fi

echo "Contracts compiled successfully"

# Start hardhat node in the background
echo "Starting Hardhat local blockchain..."
npx hardhat node &
HARDHAT_PID=$!

# Wait for hardhat node to be ready
sleep 5

# Deploy contracts
echo "Deploying contracts..."
npm run deploy

if [ $? -ne 0 ]; then
    echo "Deployment failed"
    kill $HARDHAT_PID
    exit 1
fi

echo "Deployment completed successfully!"
echo "Deployment info saved to deployment-info.json"

# Display deployment info
if [ -f deployment-info.json ]; then
    echo ""
    echo "=== DEPLOYMENT INFORMATION ==="
    cat deployment-info.json
    echo ""
fi

echo "Hardhat node is running on http://0.0.0.0:8545"
echo "Keep this container running for testing and interaction"

# Keep the container running
wait $HARDHAT_PID

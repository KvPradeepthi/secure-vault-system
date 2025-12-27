const hre = require("hardhat");
const fs = require("fs");

async function main() {
    console.log("Deploying Secure Vault System...");

    // Get the deployer account
    const [deployer] = await ethers.getSigners();
    console.log(`Deploying contracts with account: ${deployer.address}`);

    // Deploy AuthorizationManager
    console.log("\nDeploying AuthorizationManager...");
    const AuthorizationManager = await ethers.getContractFactory("AuthorizationManager");
    const authManager = await AuthorizationManager.deploy();
    await authManager.deployed();
    console.log(`AuthorizationManager deployed at: ${authManager.address}`);

    // Initialize AuthorizationManager with the deployer as the signer
    console.log("\nInitializing AuthorizationManager...");
    let tx = await authManager.initialize(deployer.address);
    await tx.wait();
    console.log("AuthorizationManager initialized");

    // Deploy SecureVault
    console.log("\nDeploying SecureVault...");
    const SecureVault = await ethers.getContractFactory("SecureVault");
    const vault = await SecureVault.deploy();
    await vault.deployed();
    console.log(`SecureVault deployed at: ${vault.address}`);

    // Initialize SecureVault with AuthorizationManager
    console.log("\nInitializing SecureVault...");
    tx = await vault.initialize(authManager.address);
    await tx.wait();
    console.log("SecureVault initialized");

    // Output deployment information
    const deploymentInfo = {
        authorizationManager: authManager.address,
        secureVault: vault.address,
        deployer: deployer.address,
        network: hre.network.name,
        chainId: (await ethers.provider.getNetwork()).chainId,
        timestamp: new Date().toISOString()
    };

    console.log("\n=== Deployment Summary ===");
    console.log(JSON.stringify(deploymentInfo, null, 2));

    // Save deployment info to file
    fs.writeFileSync(
        "deployment-info.json",
        JSON.stringify(deploymentInfo, null, 2)
    );
    console.log("\nDeployment info saved to deployment-info.json");
}

main()
    .then(() => process.exit(0))
    .catch((error) => {
        console.error(error);
        process.exit(1);
    });

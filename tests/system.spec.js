const { expect } = require("chai");
const { ethers } = require("hardhat");

describe("Secure Vault System", function () {
    let authManager, vault, owner, signer, user1, user2;

    beforeEach(async function () {
        [owner, signer, user1, user2] = await ethers.getSigners();

        // Deploy AuthorizationManager
        const AuthorizationManager = await ethers.getContractFactory("AuthorizationManager");
        authManager = await AuthorizationManager.deploy();
        await authManager.deployed();

        // Initialize with signer
        await authManager.initialize(signer.address);

        // Deploy SecureVault
        const SecureVault = await ethers.getContractFactory("SecureVault");
        vault = await SecureVault.deploy();
        await vault.deployed();

        // Initialize vault
        await vault.initialize(authManager.address);
    });

    describe("Deposits", function () {
        it("Should accept deposits", async function () {
            const depositAmount = ethers.utils.parseEther("10");
            await owner.sendTransaction({
                to: vault.address,
                value: depositAmount
            });

            const balance = await vault.getBalance();
            expect(balance).to.equal(depositAmount);
        });

        it("Should reject zero deposits", async function () {
            await expect(
                owner.sendTransaction({
                    to: vault.address,
                    value: 0
                })
            ).to.be.reverted;
        });
    });

    describe("Withdrawals with Authorization", function () {
        beforeEach(async function () {
            // Deposit funds
            const depositAmount = ethers.utils.parseEther("100");
            await owner.sendTransaction({
                to: vault.address,
                value: depositAmount
            });
        });

        it("Should allow valid authorized withdrawal", async function () {
            const withdrawAmount = ethers.utils.parseEther("10");
            const nonce = 1;

            // Create authorization message
            const authHash = ethers.utils.solidityKeccak256(
                ["address", "address", "uint256", "uint256", "uint256"],
                [vault.address, user1.address, withdrawAmount, nonce, (await ethers.provider.getNetwork()).chainId]
            );

            // Sign the authorization
            const signature = await signer.signMessage(ethers.utils.arrayify(authHash));

            // Execute withdrawal
            await expect(
                vault.withdraw(user1.address, withdrawAmount, nonce, signature)
            ).to.emit(vault, "Withdrawal");
        });

        it("Should prevent reuse of authorizations", async function () {
            const withdrawAmount = ethers.utils.parseEther("10");
            const nonce = 2;

            const authHash = ethers.utils.solidityKeccak256(
                ["address", "address", "uint256", "uint256", "uint256"],
                [vault.address, user1.address, withdrawAmount, nonce, (await ethers.provider.getNetwork()).chainId]
            );

            const signature = await signer.signMessage(ethers.utils.arrayify(authHash));

            // First withdrawal should succeed
            await vault.withdraw(user1.address, withdrawAmount, nonce, signature);

            // Reusing same authorization should fail
            await expect(
                vault.withdraw(user1.address, withdrawAmount, nonce, signature)
            ).to.be.revertedWith("Authorization already consumed");
        });

        it("Should reject withdrawals with invalid signature", async function () {
            const withdrawAmount = ethers.utils.parseEther("10");
            const nonce = 3;

            const authHash = ethers.utils.solidityKeccak256(
                ["address", "address", "uint256", "uint256", "uint256"],
                [vault.address, user1.address, withdrawAmount, nonce, (await ethers.provider.getNetwork()).chainId]
            );

            // Sign with wrong account
            const wrongSignature = await user2.signMessage(ethers.utils.arrayify(authHash));

            await expect(
                vault.withdraw(user1.address, withdrawAmount, nonce, wrongSignature)
            ).to.be.revertedWith("Invalid signature");
        });

        it("Should reject withdrawal with insufficient balance", async function () {
            const withdrawAmount = ethers.utils.parseEther("200");
            const nonce = 4;

            const authHash = ethers.utils.solidityKeccak256(
                ["address", "address", "uint256", "uint256", "uint256"],
                [vault.address, user1.address, withdrawAmount, nonce, (await ethers.provider.getNetwork()).chainId]
            );

            const signature = await signer.signMessage(ethers.utils.arrayify(authHash));

            await expect(
                vault.withdraw(user1.address, withdrawAmount, nonce, signature)
            ).to.be.revertedWith("Insufficient vault balance");
        });
    });

    describe("System State Management", function () {
        it("Should only initialize once", async function () {
            const newAuthManager = await (await ethers.getContractFactory("AuthorizationManager")).deploy();
            await newAuthManager.deployed();

            await expect(
                vault.initialize(newAuthManager.address)
            ).to.be.revertedWith("Vault already initialized");
        });

        it("Should track balances correctly", async function () {
            const amount1 = ethers.utils.parseEther("10");
            const amount2 = ethers.utils.parseEther("20");

            await owner.sendTransaction({ to: vault.address, value: amount1 });
            expect(await vault.getUserBalance(owner.address)).to.equal(amount1);

            await signer.sendTransaction({ to: vault.address, value: amount2 });
            expect(await vault.getUserBalance(signer.address)).to.equal(amount2);
        });
    });
});

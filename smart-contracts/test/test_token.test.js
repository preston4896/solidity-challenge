const RewardToken = artifacts.require("RewardToken");

contract("RewardToken", (accounts) => {
    
    let expected_owner = accounts[0];
    let token;

    before(async () => {
        token = await RewardToken.deployed();
    })

    it("1. Verify token owner and initial token mint distributed to the owner.", async() => {
        let actual_owner = await token.minter();
        assert.equal(actual_owner, expected_owner, "Owner address should match.");

        let expected_balance = 10000;
        await token.mint(actual_owner, expected_balance);
        let actual_balance = await token.balanceOf(actual_owner);
        assert.equal(actual_balance, expected_balance, "Minted token with a balance of 10000.");
    })

    it("2. Test direct transfer of token.", async() => {
        // account 1 attempts to transfer with zero balance.
        try {
            await token.transfer(expected_owner, 100, {from: accounts[1]});
        } catch (error) {
            assert(error.message.indexOf("revert") >= 0, "error message must contain revert.");
        }

        // owner still has 10000 tokens.
        let expected_balance = 10000;
        let actual_balance = await token.balanceOf(expected_owner);
        assert.equal(actual_balance, expected_balance, "Owner should still have a balance of 10000.");

        // owner transfers 1000 tokens to accounts[1]
        await token.transfer(accounts[1], 1000);

        // verify owner balance.
        let bal_0 = await token.balanceOf(expected_owner);
        assert.equal(bal_0, 9000, "Owner should have 9000 tokens");

        // verify recipient's balance.
        let bal_1 = await token.balanceOf(accounts[1]);
        assert.equal(bal_1, 1000, "Recipient should have 1000 tokens");
    })

    it("3. Test delegated transfer of tokens.", async() => {
        // account 2 attempts to make a transfer on behalf of accounts[1] without approval
        try {
            await token.transferFrom(accounts[1], expected_owner, 1000, {from: accounts[2]});
        } catch (error) {
            assert(error.message.indexOf("revert") >= 0, "error message must contain revert.");
        }

        // accounts[1] authorizes accounts[2].
        let amount = 900
        await token.approve(accounts[2], amount, {from: accounts[1]});

        await token.transferFrom(accounts[1], expected_owner, amount, {from: accounts[2]});

        // verify balance
        let spender_bal = await token.balanceOf(accounts[1]);
        let owner_bal = await token.balanceOf(expected_owner);
        assert.equal(spender_bal, 100);
        assert.equal(owner_bal, 9900);

        // account 2 attemps to transfer the remaining balance again - expected to fail because it has used up all of its allowance.
        try {
            await token.transferFrom(accounts[1], expected_owner, 1000 - amount, {from: accounts[2]});
        } catch (error) {
            assert(error.message.indexOf("revert") >= 0, "error message must contain revert.");
        }
    })

    it("4. Test mint.", async() => {
        // accounts[1] attempts to mint new tokens for himself
        try {
            await token.mint(accounts[1], 10, {from: accounts[1]});
        } catch(error) {
            assert(error.message.indexOf("revert") >= 0, "error message must contain revert.");
        }

        // owner mints new tokens for accounts[2]
        let amount = 1000;
        await token.mint(accounts[2], amount);

        // verify balance.
        let bal_2 = await token.balanceOf(accounts[2]);
        assert.equal(bal_2, amount);
    })
})
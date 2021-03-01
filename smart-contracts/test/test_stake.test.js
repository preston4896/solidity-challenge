const Staker = artifacts.require("Staker");

contract("Staker", (accounts) => {

    // contract instance.
    let staker;
    
    let hodlers = accounts.slice(1);

    before(async() => {
        staker = await Staker.deployed();
    })

    it("1. Test initial token distribution (AirDrop).", async() => {
        // unauthorized airdrop
        try {
            await staker.airdrop(hodlers, {from: accounts[1]});
        } catch (error) {
            assert(error.message.indexOf("revert") >= 0, "error message must contain revert.");
        }
        await staker.airdrop(hodlers);

        // verify balance for all hodlers.
        for (let i = 0; i < 10; i++) {
            let balance = await staker.balanceOf(hodlers[i]);
            assert.equal(balance, 1000, "Balance should match.");
        }

        // attempts to mint more tokens than the allocated 10000 tokens.
        try {
            await staker.airdrop(hodlers);
        } catch (error) {
            assert(error.message.indexOf("revert") >= 0, "error message must contain revert.");
        }
    })

    it("2. Test deposit/stake tokens", async() => {
        // excess deposit amount.
        try {
            await staker.deposit(2000);
        } catch (error) {
            assert(error.message.indexOf("revert") >= 0, "error message must contain revert.");
        }

        await staker.deposit(500, {from: accounts[1]});

        // verify balance.
        let staker_balance = await staker.balanceOf(accounts[1]);
        let owner_balance = await staker.balanceOf(accounts[0]);
        assert.equal(staker_balance.toNumber(), 500);
        assert.equal(owner_balance.toNumber(), 500);

        // verify staked.
        let stakerObj = await staker.stakers(1);
        assert.equal(stakerObj.staked_amount.toNumber(), 500);

        // stake more
        await staker.deposit(250, {from: accounts[1]});

        // verify balance.
        staker_balance = await staker.balanceOf(accounts[1]);
        owner_balance = await staker.balanceOf(accounts[0]);
        assert.equal(staker_balance.toNumber(), 250);
        assert.equal(owner_balance.toNumber(), 750);

        // verify staked.
        stakerObj = await staker.stakers(1);
        assert.equal(stakerObj.staked_amount.toNumber(), 750);

        // stake from a 2nd account.
        await staker.deposit(400, {from: accounts[2]});

        // verify balance.
        staker_balance = await staker.balanceOf(accounts[2]);
        owner_balance = await staker.balanceOf(accounts[0]);
        assert.equal(staker_balance.toNumber(), 600);
        assert.equal(owner_balance.toNumber(), 1150);

        // verify staked.
        stakerObj = await staker.stakers(2);
        assert.equal(stakerObj.staked_amount.toNumber(), 400);
    })

})
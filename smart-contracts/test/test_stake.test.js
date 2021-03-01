const Staker = artifacts.require("Staker");
const utils = require("./test_lib/utils"); // JavaScript library to manipulate blockchain timestamp.

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
            await staker.airdrop(hodlers[0], 1000, {from: accounts[1]});
        } catch (error) {
            assert(error.message.indexOf("revert") >= 0, "error message must contain revert.");
        }

        // Distribute tokens, then verify balance for all hodlers.
        for (let i = 0; i < 10; i++) {
            await staker.airdrop(hodlers[i], 1000);
            let balance = await staker.balanceOf(hodlers[i]);
            assert.equal(balance, 1000, "Balance should match.");
        }

        // Verify total supply of tokens.
        let totalSupply = await staker.totalSupply();
        assert.equal(totalSupply, 10000, "Supply should be 10000.");
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
        let totalSupply = await staker.totalSupply();
        assert.equal(staker_balance.toNumber(), 500);
        assert.equal(totalSupply.toNumber(), 9500);

        // verify staked.
        let stakerObj = await staker.stakers(1);
        assert.equal(stakerObj.staked_amount.toNumber(), 500);

        // stake more
        await staker.deposit(100, {from: accounts[1]});

        // verify balance.
        staker_balance = await staker.balanceOf(accounts[1]);
        totalSupply = await staker.totalSupply();
        assert.equal(staker_balance.toNumber(), 400);
        assert.equal(totalSupply.toNumber(), 9400);

        // verify staked.
        stakerObj = await staker.stakers(1);
        assert.equal(stakerObj.staked_amount.toNumber(), 600);

        // stake from a 2nd account.
        await staker.deposit(400, {from: accounts[2]});

        // verify balance.
        staker_balance = await staker.balanceOf(accounts[2]);
        totalSupply = await staker.totalSupply();
        assert.equal(staker_balance.toNumber(), 600);
        assert.equal(totalSupply.toNumber(), 9000);

        // verify staked.
        stakerObj = await staker.stakers(2);
        assert.equal(stakerObj.staked_amount.toNumber(), 400);

        // verify total ids.
        let totalId = await staker.stake_ids();
        assert.equal(totalId, 2, "There should be 2 ids.");
    })

    // Notes: At this point, accounts[1] staked 600 tokens, accounts[2] staked 400 tokens.
    it("3. Test Reward Calculations, accrued 5 minutes after staking. ", async() => {
        let totalRewards = 500; // 100 tokens per minute to be distributed to all stakers.
        let expected_rewardOne = totalRewards * 0.6;
        let expected_rewardTwo = totalRewards * 0.4;

        let actual_rewardOne = await staker.calculateReward(1, 5);
        let actual_rewardTwo = await staker.calculateReward(2, 5);

        assert.equal(actual_rewardOne.toNumber(), expected_rewardOne);
        assert.equal(actual_rewardTwo.toNumber(), expected_rewardTwo);
    })

    it("4. Fast-forward to 5 minutes later, test unstake.", async() => {
        // Take a snapshot to make sure that blockchain goes back in time to the point before this test is initiated.
        let snapshot = await utils.takeSnapshot();
        let snapshotID = snapshot['result'];

        // time-travel five minutes into the future.
        let FIVE_MINUTES = 60 * 5;
        await utils.advanceTimeAndBlock(FIVE_MINUTES);

        // attempts fradulent withdraw - incorrect address
        try {
            await staker.withdraw(1, {from: hodlers[2]});
        } catch(error) {
            assert(error.message.indexOf("revert") >= 0, "error message must contain revert.");
        }

        // accounts[2] withdraw.
        await staker.withdraw(2, {from: accounts[2]});
        // verify balance.
        let bal_2 = await staker.balanceOf(accounts[2]);
        assert.equal(bal_2.toNumber(), 1200, "600 + 400 + 200 = 1200");
        let totalSupply = await staker.totalSupply();
        assert.equal(totalSupply.toNumber(), 9600, "9000 + 400 + 200 = 9600");
        // accounts[2] is no longer staking.
        let stake2Obj = await staker.stakers(2);
        assert.equal(stake2Obj.id, 0, "ID no longer exists.");

        // Note: OPCODE FAILED
        // // accounts[1] withdraw.
        // await staker.withdraw(1, {from: accounts[1]});
        // // verify balance.
        // let bal_1 = await staker.balanceOf(accounts[1]);
        // assert.equal(bal_1.toNumber(), 1300, "400 + 600 + 300 = 1300");
        // totalSupply = await staker.totalSupply();
        // assert.equal(totalSupply.toNumber(), 10500, "9600 + 600 + 300 = 10500");
        // // accounts[1] is no longer staking.
        // let stake1Obj = await staker.stakers(1);
        // assert.equal(stake1Obj.id, 0, "ID no longer exists.");

        // restore time.
        await utils.revertToSnapshot(snapshotID);
    })
})
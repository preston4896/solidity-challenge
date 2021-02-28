const Staker = artifacts.require("Staker");

contract("Staker", (accounts) => {

    // contract instance.
    let staker;
    
    let hodlers = accounts.slice(1);

    before(async() => {
        staker = await Staker.deployed();
    })

    it("1. Test token distribution (AirDrop).", async() => {
        // unauthorized airdrop
        try {
            await staker.distributeTokens(hodlers, {from: accounts[1]});
        } catch (error) {
            assert(error.message.indexOf("revert") >= 0, "error message must contain revert.");
        }
        await staker.distributeTokens(hodlers);

        // verify balance for all hodlers.
        for (let i = 0; i < 10; i++) {
            let balance = await staker.balanceOf(hodlers[i]);
            assert.equal(balance, 1000, "Balance should match.");
        }

        // attempts to mint more tokens than the allocated 10000 tokens.
        try {
            await staker.distributeTokens(hodlers);
        } catch (error) {
            assert(error.message.indexOf("revert") >= 0, "error message must contain revert.");
        }
    })

})
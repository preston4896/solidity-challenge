const RewardToken = artifacts.require("RewardToken");
const Stake = artifacts.require("Stake");

module.exports = function(deployer) {
    deployer.deploy(RewardToken,10000);
    deployer.deploy(Stake);
}
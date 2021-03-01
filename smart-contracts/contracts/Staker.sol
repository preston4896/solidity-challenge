// Contract to possess staked tokens and to distribute rewards.

pragma solidity ^0.6.0;

import "./libs/SafeMath.sol";
import "./RewardToken.sol";

contract Staker is RewardToken {

    using SafeMath for uint256;

    address public owner;
    uint256 public stake_ids;
    mapping(uint256 => StakeProfile) public stakers; // keeps track of stakers.
    mapping(address => uint256) public addrToId; // associates IDs with staker address.
    uint256 public totalRewardRate = 100; // a total of 100 rewards generated per minute to be distributed proportionally to all stakers.

    event Staked(address user, uint256 amount);
    event Unstaked(address user, uint256 amount);

    /**
    * @dev Struct to keep record of staker profile.
    */
    struct StakeProfile {
        uint256 id;
        uint256 staked_amount; // the amount of token locked for staking.
        uint256 reward_earned;
        uint256 starting_date;
        address addr;
        bool isWithdrawable; // check if all gains are realized.
    }

    constructor() public {
        owner = msg.sender;
    }

    /**
    * @dev Function to calculate the reward.
    */
    function calculateReward(uint256 id, uint256 present) public view returns(uint256) {
        uint durationInMin = (present.sub(stakers[id].starting_date)).div(60);
        uint totalReward = totalRewardRate.mul(durationInMin);
        uint staked = stakers[id].staked_amount;
        uint percent = staked.div(balanceOf[address(this)]);
        return totalReward.mul(percent);
    }

    /**
    * @dev updates rewards. (Does not mint new tokens until withdrawal)
    */
    modifier updateReward(uint256 id) {
        require(stakers[id].staked_amount > 0, "Insufficient staked amount.");
        stakers[id].reward_earned = calculateReward(id, now);
        _;
    }

    /**
    * @dev Function to mint and distribute 1000 tokens to 10 addresses each. There will be a total supply of 10000 tokens by the end of this function call.
    */
    function airdrop(address[10] memory recipients) public returns(bool success) {
        require(totalSupply < 10000, "Total supply amount exceeded 10000");
        for (uint i = 0; i < 10; i++) {
            mint(recipients[i], 1000);
        }
        return true;
    }

    /**
    * @dev Function to allow stakers to deposit tokens to stake, requires a minimum of 100 tokens.
    * @return Staker ID.
    */
    function deposit(uint256 amount) public returns(uint256) {
        require(balanceOf[msg.sender] >= amount, "Insufficient balance.");
        require(amount >= 100, "Amount is below the minimum stake requirement.");
        require((msg.sender != owner) && (msg.sender != address(0)), "Owner or invaid address.");

        StakeProfile storage staker = stakers[addrToId[msg.sender]];
        transfer(owner, amount);

        emit Staked(msg.sender, amount);

        // check if the profile already exists.
        if (staker.id > 0) {
            staker.staked_amount = staker.staked_amount.add(amount);
            return staker.id;
        }
        else {
            stake_ids = stake_ids.add(1);
            StakeProfile memory newStaker = StakeProfile(stake_ids, amount, 0, now, msg.sender);
            addrToId[msg.sender] = stake_ids;
            stakers[stake_ids] = newStaker;
            return stake_ids;
        }
    }

    /**
     * @dev Function to withdraw. TEMP: only owners can unstake funds.
     */
    function withdraw(uint256 id) public updateReward(id) returns (bool success) {
        require(msg.sender == owner, "Not the owner, unauthorized caller.");
        require(stakers[id].reward_earned > 0 || stakers[id].staked_amount >= 100, "Insufficient gains.");
        // mint new tokens for rewards earned.
        if (stakers[id].reward_earned > 0) {
            mint(stakers[id].addr, stakers[id].reward_earned);
        }
        // transfer stake.
        transfer(stakers[id].addr, stakers[id].staked_amount);
        stakers[id].staked_amount = 0;
        stakers[id].reward_earned = 0;

        delete addrToId[stakers[id].addr];
        delete stakers[id];

        return true;
    }
}
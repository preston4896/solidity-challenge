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
    event Unstaked(address user);

    /**
    * @dev Struct to keep record of staker profile.
    */
    struct StakeProfile {
        uint256 id;
        uint256 staked_amount; // the amount of token locked for staking.
        uint256 reward_earned;
        uint256 starting_date;
        address addr;
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
        uint percent = staked.div(balanceOf[owner]); // the owner's balance can only contain total staked amount, because rewards are directly distributed to the stakers.
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
    * @dev Function to provide ICO/AirDrop capability for owners.
    */
    function airdrop(address recipient, uint256 amount) public returns(bool success) {
        require(msg.sender == owner, "Not the owner");
        _mint(recipient, amount);
        return true;
    }

    /**
    * @dev Function to allow stakers to deposit tokens to stake, requires a minimum of 100 tokens.
    * @return Staker ID.
    */
    function deposit(uint256 amount) public returns(uint256) {
        require(balanceOf[msg.sender] >= amount, "Insufficient balance.");
        require(amount >= 100, "Amount is below the minimum stake requirement.");
        require((msg.sender != owner) && (msg.sender != address(0)), "Owner or invaid address."); // TEMP

        StakeProfile storage staker = stakers[addrToId[msg.sender]];
        _burn(msg.sender, amount);

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
     * @dev Function to withdraw.
     */
    function withdraw(uint256 id) public updateReward(id) returns (bool success) {
        require(msg.sender == stakers[id].addr, "Not the staker, unauthorized caller.");
        require(stakers[id].reward_earned > 0 || stakers[id].staked_amount >= 100, "Insufficient gains.");
        // mint new tokens for rewards earned.
        if (stakers[id].reward_earned > 0) {
            _mint(stakers[id].addr, stakers[id].reward_earned);
        }
        // transfer stake.
        _mint(stakers[id].addr, stakers[id].staked_amount);
        stakers[id].staked_amount = 0;
        stakers[id].reward_earned = 0;

        emit Unstaked(stakers[id].addr);

        delete addrToId[stakers[id].addr];
        delete stakers[id];

        return true;
    }
}
// Contract to possess staked tokens and to distribute rewards.

pragma solidity ^0.6.0;

import "./libs/SafeMath.sol";
import "./RewardToken.sol";

contract Staker is RewardToken {

    using SafeMath for uint256;

    address public owner;
    uint256 public stake_ids;
    mapping(address => StakeProfile) public stakers; // keep track of stakers.
    uint256 private totalStakedTokens;
    uint256 public totalRewardRate = 100; // a total of 100 rewards generated per minute to be distributed proportionally to all stakers.

    /**
    * @dev Struct to keep record of staker profile.
    */
    struct StakeProfile {
        uint256 id;
        uint256 staked_amount; // the amount of token locked for staking.
        uint256 reward_amount; // the amount of reward earned.
        uint256 starting_date;
    }

    constructor() public {
        owner = msg.sender;
    }

    /**
     * @dev Function to mint and distribute 1000 tokens to 10 addresses each. There will be a total supply of 10000 tokens by the end of this function call.
     */
    function distributeTokens(address[10] memory recipients) public returns(bool success) {
        require(totalSupply < 10000, "Total supply amount exceeded 10000");
        for (uint i = 0; i < 10; i++) {
            mint(recipients[i], 1000);
        }
        return true;
    }

    /**
     * @dev Function to allow stakers to deposit tokens to stake.
     * @return Staker ID.
     */
    function deposit(uint256 amount) public returns(uint256) {
        require(balanceOf[msg.sender] >= amount, "Insufficient balance.");
        
        StakeProfile storage staker = stakers[msg.sender];

        // check if the profile already exists.
        if (staker.id > 0) {
            staker.staked_amount = staker.staked_amount.add(amount);
            return staker.id;
        }
        else {
            stake_ids = stake_ids.add(1);
            StakeProfile memory newStaker = StakeProfile(stake_ids, amount, 0, now);
            stakers[msg.sender] = newStaker;
            return stake_ids;
        }
    }
}
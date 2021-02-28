// Contract to possess staked tokens and to distribute rewards.

pragma solidity ^0.6.0;

import "./libs/SafeMath.sol";
import "./RewardToken.sol";

contract Staker is RewardToken {

    using SafeMath for uint256;

    address public owner;
    uint256 public stake_ids;
    uint256 public apy;
    mapping(address => uint256) public stakerId; // associate staker's id to their address.
    uint256 private totalStakedTokens;

    /**
    * Staker profile. An object to keep record of staked amount and period.
    */
    struct StakeProfile {
        uint256 id;
        uint256 staked_amount; // the amount of token locked for staking.
        uint256 starting_date;
        uint256 total_balance; // the sum of staked tokens and rewards.
        uint256 stake_period;
        bool withdrawalable; // cannot withdraw if current time is less than starting_date + stake_period.
    }

    constructor() public {
        owner = msg.sender;
    }

    /**
     * Mint and distribute 1000 tokens to 10 addresses each. There will be a total supply of 10000 tokens by the end 
     * of this function call.
     */
    function distributeTokens(address[10] memory recipients) public returns(bool success) {
        require(totalSupply < 10000, "Total supply amount exceeded 10000");
        for (uint i = 0; i < 10; i++) {
            mint(recipients[i], 1000);
        }
        return true;
    }
}
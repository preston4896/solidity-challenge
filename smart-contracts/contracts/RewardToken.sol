// Contract to define tokens for rewards and staking

pragma solidity ^0.6.0;

import "./libs/SafeMath.sol";

contract RewardToken {

    using SafeMath for uint256;

    // Token definition
    string public name = "Preston's Token";
    string public symbol = "PRES";
    uint256 public totalSupply;

    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

    // Direct transfer from msg.sender
    function transfer(address to, uint256 value) public returns (bool success) {
        require(balanceOf[msg.sender] >= value, "Insufficient balance.");
        balanceOf[msg.sender] = balanceOf[msg.sender].sub(value);
        balanceOf[to] = balanceOf[to].add(value);
        emit Transfer(msg.sender, to, value);
        return true;
    }

    // assign allowance to a delegate
    function approve(address spender, uint256 value) public returns (bool success) {
        allowance[msg.sender][spender] = value;
        emit Approval(msg.sender, spender, value);
        return true;
    }

    // delegate transfer.
    function transferFrom(address from, address to, uint256 value) public returns (bool success) {
        require(value <= balanceOf[from], "Insufficient balance");
        require(allowance[from][msg.sender] >= value, "Insufficient allowance");
        balanceOf[from] = balanceOf[from].sub(value);
        balanceOf[to] = balanceOf[to].add(value);
        allowance[from][msg.sender] = allowance[from][msg.sender].sub(value);
        emit Transfer(from, to, value);
        return true;
    }

    // mint tokens
    function _mint(address to, uint256 value) internal returns (bool success) {
        require(msg.sender != address(0), "Invalid address");
        totalSupply = totalSupply.add(value);
        balanceOf[to] = balanceOf[to].add(value);
        emit Transfer(address(0), to, value);
        return true;
    }

    // burn tokens
    function _burn(address from, uint256 value) internal returns (bool success) {
        require(msg.sender != address(0), "Invalid address");
        require(balanceOf[from] >= value, "Insufficient balance to burn");
        totalSupply = totalSupply.sub(value);
        balanceOf[from] = balanceOf[from].sub(value);
        emit Transfer(from, address(0), value);
        return true;
    }
}
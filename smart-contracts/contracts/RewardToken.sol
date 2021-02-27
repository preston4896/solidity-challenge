// Contract to define tokens for rewards and staking
// Reference source cited: https://www.dappuniversity.com/articles/code-your-own-cryptocurrency-on-ethereum

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

    // store owner address
    address private _owner;

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

    constructor(uint256 initSupply) public {
        _owner = msg.sender;
        totalSupply = initSupply;
        emit Transfer(address(0), msg.sender, initSupply);
    }

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

    // conditions to allow minting a new tokens, to be added.
    function mint(uint256 value) public returns (bool success) {
        require(msg.sender == _owner, "Only the owner is authorized to mint a token.");
        totalSupply = totalSupply.add(value);
        emit Transfer(address(0), msg.sender, value);
        return true;
    }
}
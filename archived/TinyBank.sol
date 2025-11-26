// staking
// deposit(MyToken) / withdraw(MyToken)

// MyToken : token balance management
//  - the balance of TinyBank address
// TinyBank : deposit / withdraw vault
//  - users token management
//  - user --> deposit --> TinyBank --> transfer(user --> TinyBank)

// Reward
//  - reward token : MyToken
//  - reward resources : 1 MT/block minting
//  - reward strategy : staked[user]/totalStaked distribution

//  - signer0 block 0 staking
//  - signer1 block 5 staking
//  - 0-- 1-- 2-- 3-- 4-- 5--
//    |                   |
//  - signer0 10MT        signer1 10MT

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;
import "./ManagedAccess.sol";
import "./MultiManagedAccess.sol";

interface IMyToken {
    function transferFrom(address from, address to, uint256 amount) external;

    function transfer(uint256 amount, address to) external;

    function mint(uint256 amount, address owner) external;
}

contract TinyBank is MultiManagedAccess {
    event Staked(address from, uint256 amount);
    event Withdraw(uint256 amount, address to);

    IMyToken public stakingToken;

    mapping(address => uint256) public lastClaimedBlock;

    uint256 public defaultRewardPerBlock = 1 * 10 ** 18;
    uint256 public rewardPerBlock;

    mapping(address => uint256) public staked;
    uint256 public totalStaked;

    constructor(
        IMyToken _stakingToken
    ) MultiManagedAccess(msg.sender, getManagers(), 3) {
        stakingToken = _stakingToken;
        rewardPerBlock = defaultRewardPerBlock;
    }

    function getManagers() internal pure returns (address[] memory) {
        address[] memory managers = new address[](3);

        // Account #17
        managers[0] = 0xbDA5747bFD65F08deb54cb465eB87D40e51B197E;

        // Account #18
        managers[1] = 0xdD2FD4581271e230360230F9337D5c0430Bf44C0;

        // Account #19
        managers[2] = 0x8626f6940E2eb28930eFb4CeF49B2d1F2C9C1199;

        return managers;
    }

    // who, when?
    // genesis staking
    modifier updateReward(address to) {
        if (staked[to] > 0) {
            uint256 blocks = block.number - lastClaimedBlock[to];
            uint256 reward = (blocks * rewardPerBlock * staked[to]) /
                totalStaked;
            stakingToken.mint(reward, to);
        }
        lastClaimedBlock[to] = block.number;
        _; // caller's code
    }

    function setRewardPerBlock(uint256 _amount) external onlyAllConfirmed {
        rewardPerBlock = _amount;
    }

    function stake(uint256 _amount) external updateReward(msg.sender) {
        require(_amount >= 0, "cannot stake 0 amount");
        stakingToken.transferFrom(msg.sender, address(this), _amount);
        staked[msg.sender] += _amount;
        totalStaked += _amount;
        emit Staked(msg.sender, _amount);
    }

    function withdraw(uint256 _amount) external updateReward(msg.sender) {
        require(staked[msg.sender] >= _amount, "insufficient staked token");
        stakingToken.transfer(_amount, msg.sender);
        staked[msg.sender] -= _amount;
        totalStaked -= _amount;
        emit Withdraw(_amount, msg.sender);
    }
}

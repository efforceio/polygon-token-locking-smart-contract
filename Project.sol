// contracts/WhitelistAddressContract.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import "hardhat/console.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "./ProjectsManagerContract.sol";
import "./RewardsManager.sol";

contract Project is Initializable, Common {
    using SafeMath for uint256;
    using SafeERC20Upgradeable for IERC20Upgradeable;

    struct Locked {
        uint256 amount;
        uint256 timestamp;
    }

    uint16 public id;
    ProjectsManagerContract public manager;
    RewardsManager public rewardsManager;

    mapping(address => Locked) public contributions;
    
    uint256 public expiresAt;
    function initialize(
        address _manager,
        uint256 _id,
        uint256 _expiresAt
    ) public initializer {
        manager = ProjectsManagerContract(_manager);
        id = uint16(_id);
        expiresAt = _expiresAt;
        _commonInit();
    }

    modifier onlyManager() {
        require(msg.sender == address(manager), "Unauthorized");
        _;
    }

    function contribute(
        address _address,
        uint256 _amount
    ) external onlyManager  returns(uint256) {
        if (contributions[_address].amount > 0) {
            contributions[_address].amount += _amount;
        } else {
            contributions[_address] = Locked(
                _amount,
                block.timestamp
            );
        }

        return  contributions[_address].amount;
    }

    function getLockedAmounts(address _address)
        external
        view
        returns (uint256)
    {
        return contributions[_address].amount;
    }

    function withdraw(address account) external onlyManager returns (uint256 totalWithdraw) {
        require(
            block.timestamp >= expiresAt,
            "Tokens are not Withdrawable at this time!"
        );
        totalWithdraw = contributions[account].amount;
        delete contributions[account];
        manager.wozxToken().safeTransfer(account, totalWithdraw);
        return totalWithdraw;
    }
}

// SPDX-FileType: SOURCE
// SPDX-FileCopyrightText: 2022 Efforce.io
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import "hardhat/console.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts/proxy/beacon/BeaconProxy.sol";
import "./Project.sol";
import "./Common.sol";

contract ProjectsManagerContract is Initializable, Common {
    using SafeMath for uint256;
    using SafeERC20Upgradeable for IERC20Upgradeable;

    IERC20Upgradeable public wozxToken;
   
    address public projectProxyToken;


    function initialize(IERC20Upgradeable _wozxToken) public initializer {
        wozxToken = _wozxToken;
        _commonInit();
    }

    event NewProject(uint256 id, uint256 minimumContribution, uint256 expiresAt);

    struct ProjectInfo {
        uint256 id;
        address payable addr;
        uint256 minimumContribution;
        uint256 expiresAt;
    }

    event LockingUpdate(
        address _address,
        uint256 id,
        uint256 value
    );

    ProjectInfo[] projects;

    function getProjects(uint256 _id)
        external
        view
        returns (
            uint256,
            address,
            uint256,
            uint256
        )
    {
        ProjectInfo memory project = projects[_id];
        return (
            project.id,
            project.addr,
            project.minimumContribution,
            project.expiresAt
        );
    }

    function getProxy() external view returns (address) {
        return projectProxyToken;
    }

    function setProjectProxyToken(address _address) external {
        projectProxyToken = _address;
    }

    function updateProject(
        uint256 _id,
        uint256 _minimumContribution,
        uint256 _expiresAt
    ) external onlyAuth {
        ProjectInfo storage p = projects[_id];
        p.minimumContribution = _minimumContribution;
        p.expiresAt = _expiresAt;
    }

    function addNewProject(
        uint256 _id,
        uint256 _minimumContribution,
        uint256 _expiresAt
    ) external onlyAuth {
        bytes memory payload = abi.encodeWithSelector(
            Project(address(0)).initialize.selector,
            address(this),
            _id,
            _expiresAt
        );

        BeaconProxy token = new BeaconProxy(projectProxyToken, payload);

        ProjectInfo memory project = ProjectInfo(
            _id,
            payable(address(token)),
            _minimumContribution,
            _expiresAt
        );
        projects.push(project);
        emit NewProject(project.id, project.minimumContribution, project.expiresAt);
    }

    modifier existingProject(uint256 _id) {
        require(_id >= 0 && _id < projects.length, "Project does not exist");
        _;
    }

    /// @notice Due to ERC20 protocol, before calling this function, allownce should be set by using wozxToken.approve(contractAddress, amount);
    function contribute(
        uint256 _id,
        uint256 _amount
    ) external existingProject(_id) {
        require(
            _amount >= projects[_id].minimumContribution,
            "Not enough woxz"
        );
        wozxToken.safeTransferFrom(msg.sender, projects[_id].addr, _amount);
        Project project = Project(projects[_id].addr);
        uint256 amount = project.contribute(msg.sender, _amount);
        emit LockingUpdate(msg.sender, _id, amount);
    }

    function isWhitelisted(uint256 _projectId) external view returns (uint256) {
        Project project = Project(projects[_projectId].addr);
        uint256 lockedAmount = project.getLockedAmounts(msg.sender);

        if (lockedAmount > 0) {
            return lockedAmount;
        }
        return 0;
    }

    function statsPerUser()
        external
        view
        returns (uint256 sum, uint256 withdrawable)
    {
        for (uint256 i = 0; i < projects.length; i++) {
            Project project = Project(projects[i].addr);
            uint256 lockedAmount = project.getLockedAmounts(msg.sender);
            sum += lockedAmount;
            if (block.timestamp >= projects[i].expiresAt) {
                withdrawable += lockedAmount;
            }
        }

        return (sum, withdrawable);
    }

    function withdraw(uint256 _id) external {
        Project project = Project(projects[_id].addr);
        project.withdraw(msg.sender);
    }

    function totalTokensLocked() external view returns (uint256 total) {
        for (uint256 i = 0; i < projects.length; i++) {
            total += wozxToken.balanceOf(projects[i].addr);
        }

        return total;
    }
}

// SPDX-FileType: SOURCE
// SPDX-FileCopyrightText: 2022 Efforce.io
// SPDX-License-Identifier:  UNLICENSED

pragma solidity ^0.8.10;

import '@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol';
import '@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol';
import '@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol';
import '@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol';
import '@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol';
import "hardhat/console.sol";

contract Common is
        PausableUpgradeable,
        OwnableUpgradeable,
        UUPSUpgradeable,
        AccessControlUpgradeable
{

    bytes32 public constant SUPERVISOR_ROLE = keccak256("SUPERVISOR_ROLE");

    address public orchestratorAddress;

    function _commonInit() internal onlyInitializing {
        __Context_init_unchained();
        __Ownable_init_unchained();
        __Pausable_init_unchained();
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
    }

    function isSupervisor() public view returns(bool isIndeed) {
        return orchestratorAddress == _msgSender() || owner() == _msgSender() || hasRole(SUPERVISOR_ROLE, _msgSender());
    }

    modifier onlySupervisor() {
        require(
            isSupervisor(),
            'Supervisor Caller not authorized'
        );
        _;
    }

    modifier onlyAuth() {
        require(
            orchestratorAddress == _msgSender() || owner() == _msgSender(),
            'Caller not authorized'
        );
        _;
    }

    function pause() public virtual onlyAuth {
        _pause();
    }

    function unpause() public virtual onlyAuth {
        _unpause();
    }

    function _authorizeUpgrade(address newImplementation)
    internal
    virtual
    override
    onlyOwner
    {}

}
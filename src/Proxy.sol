// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/proxy/Proxy.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/StorageSlot.sol";
import "./IAdmin.sol";

contract ProxyKara is Proxy {
    /**
     * @dev Storage slot with the address of the current implementation.
     * This is the keccak-256 hash of "eip1967.proxy.implementation" subtracted by 1, and is
     * validated in the constructor.
     */
    bytes32 internal constant _IMPLEMENTATION_SLOT =
        0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;

    /**
     * @dev Address of Admin contract
     */
    IAdmin internal constant _ADMIN =
        IAdmin(0x5418f11281cCF0c616Ca96865281944dfAA42173);

    /**
     * set the implementation
     */
    constructor(address _logic) {
        if (_logic != address(0)) {
            _setImplementation(_logic);
        }
    }

    /**
     * @dev Perform implementation upgrade
     *
     */
    function upgradeTo(address newImplementation) public {
        _ADMIN.mustMaster(msg.sender);
        _ADMIN.mustAudited(newImplementation);
        _setImplementation(newImplementation);
    }

    /**
     * @dev Returns the current implementation address.
     */
    function implementation() public view returns (address) {
        _ADMIN.mustMaster(msg.sender);
        return _implementation();
    }

    /**
     * @dev Returns the current implementation address.
     */
    function _implementation() internal view override returns (address) {
        return StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value;
    }

    /**
     * @dev Stores a new address in the EIP1967 implementation slot.
     */
    function _setImplementation(address newImplementation) private {
        require(
            Address.isContract(newImplementation),
            "ERC1967: new implementation is not a contract"
        );
        StorageSlot
            .getAddressSlot(_IMPLEMENTATION_SLOT)
            .value = newImplementation;
    }
}
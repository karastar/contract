// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.0;

import "./Comn.sol";

/**
 * @title price oracle
 */
contract PriceOracle is Comn {
    // current price in PLUR per accounting unit
    uint256 public umy = 1;

    uint256 public kara = 1;

    /**
     * @notice Returns the current price in PLUR per accounting unit and the current cheque value deduction amount.
     */
    function getUMY() external view returns (uint256) {
        return umy;
    }

    /**
     * @notice Returns the current price in PLUR per accounting unit and the current cheque value deduction amount.
     */
    function getKARA() external view returns (uint256) {
        return kara;
    }

    /**
     * @notice Update the price. Can only be called by the owner.
     * @param newPrice the new price
     */
    function setUMY(uint256 newPrice) external onlyMaster {
        umy = newPrice;
    }

    /**
     * @notice Update the price. Can only be called by the owner.
     * @param newPrice the new price
     */
    function setKARA(uint256 newPrice) external onlyMaster {
        kara = newPrice;
    }
}
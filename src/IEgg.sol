// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.0;

interface IEgg {
    function newEgg(
        address account,
        uint256 fatherID,
        uint256 motherID
    ) external returns (uint256);
}

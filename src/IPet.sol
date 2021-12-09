// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.0;

interface IPet {
    function layPet(
        uint256 eggid,
        uint256 fatherID,
        uint256 motherID
    ) external returns (uint256);
    
    function newPet(
        address account,
        uint256[] memory sets
    ) external returns (uint256);
}

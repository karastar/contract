// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.0;

interface IHold {
    function transferUMYBatch(address[] memory tos, uint256[] memory amounts, uint256 nonce)
        external
        returns (bool);
}
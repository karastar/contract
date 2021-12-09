// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.0;

interface ISale {
    function saleBatch(uint256[] memory ids, uint256[] memory prices) external;
    function offSaleBatch(uint256[] memory ids) external;
    function sale(uint256 id, uint256 price) external;
    function offSale(uint256 id) external;
    function balanceOf(address account) external view returns (uint256);
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.0;

interface ICoin {
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    function balanceOf(address account) external view returns (uint256);

    function decimals() external view returns (uint8);
}

interface IPrice {
    function getUMY() external view returns (uint256);

    function getKARA() external view returns (uint256);
}

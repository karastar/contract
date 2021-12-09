// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.0;

interface IAdmin {
    function mustAudited(address to) external view;
    function mustMaster(address addr) external view;
    function isMaster(address addr) external view returns (bool);
}
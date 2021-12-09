// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.0;

interface IReg {
    //function rand(uint256 max, uint256 seed) external view returns (uint256);

    function financer() external view returns (address);

    function broker() external view returns (address);
    
    function loanBroker() external view returns (address);

    function evolveLimit() external view returns (uint256);

    function saleFee() external view returns (uint256);

    function breedLimit() external view returns (uint256);

    function breedFee(uint256 breedNum) external view returns (uint256);

    function geneNum(uint256 bodyNum) external view returns (uint256);

    function laySeconds() external view returns (uint256[] memory);

    function priceAddr() external view returns (address);

    function umyAddr() external view returns (address);

    function karaAddr() external view returns (address);

    function nftAddr() external view returns (address);

    function petAddr() external view returns (address);

    function eggAddr() external view returns (address);

    function badgeAddr() external view returns (address);

    function saleAddr() external view returns (address);

    function loanAddr() external view returns (address);

    function holdAddr() external view returns (address);

    function msboxAddr() external view returns (address);

    function inNFTAddr(address addr) external view returns (bool);

    function umyPrice() external view returns (uint256);

    function karaPrice() external view returns (uint256);

    function petRandSets(uint256 grade)
        external
        view
        returns (uint256[] memory);
}
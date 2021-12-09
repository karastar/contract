// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

interface INFT is IERC721 {
    function amount() external view returns (uint256);

    function mintPet(address account) external returns (uint256);

    //function mintPet(address account, uint256 id) external returns (uint256);

    function mintEgg(address account) external returns (uint256);

    //function mintEgg(address account, uint256 id) external returns (uint256);

    function mintBadge(address account) external returns (uint256);

    function burnFor(uint256 id) external returns (bool);

    function transferFor(uint256 id, address to) external returns (bool);
    
    function lockFor(uint256 id, bool locked) external returns (bool);

    function isLocked(uint256 id) external view returns (bool);
}

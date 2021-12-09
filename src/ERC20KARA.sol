// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

/**
 * @dev KARA for karastar
 */
contract KARA is ERC20 {
    address private constant _TEAMER =
        0x8FeBa0F418561C038694f4e4Ba9168DE24E41B15; // team address
    address private constant _PLAYER =
        0x75F4Dc255C0F7121f41B1059147A7dDd93138886; // player address for pvp
    address private constant _MINER =
        0x75F4Dc255C0F7121f41B1059147A7dDd93138886; // player address for mining
    address private constant _SNSER =
        0x4A2410FB273e43184B72089e6148eAA72C09e625; // Community and ecosystem fund
    address private constant _DROPER =
        0xd0994Bfb75AA9Fc8598D1b10a3946343D9498b4C; // Airdrop rewards
    address private constant _PUBLICER =
        0x352F125cB9b49193BD0c0220E122519f36F71805; // Public sale
    address private constant _PRIVATER =
        0xc99b691593e39bBbF6FE678ec7E91D1529e5aff3; // Private sale

    uint256 private constant _AMOUNT = 10**14 * 5; // total amount

    uint256 startTime; // creat time

    uint256 teamUnLocked; // team unlocked amount

    uint256 snsUnLocked; // Community unlocked amount

    /**
     * @dev Mint token
     */
    constructor() ERC20("KaraStar KARA", "KARA") {
        _mint(_PLAYER, (_AMOUNT * 20) / 100);  // will cross all to xdai and send to the agency contract for pvp
        _mint(_MINER, (_AMOUNT * 29) / 100);  // will cross all to xdai and send to the agency contract for mining
        _mint(_DROPER, (_AMOUNT * 8) / 100);
        _mint(_PUBLICER, (_AMOUNT * 2) / 100);
        _mint(_PRIVATER, (_AMOUNT * 3) / 100);

        startTime = block.timestamp;
    }

    /**
     * @dev set decimals 6, same as usdt
     */
    function decimals() public view virtual override returns (uint8) {
        return 6;
    }

    /**
     * @dev team unlock
     * Locked 12 months, after which 20% will be released and the remaining tokens will be released within 48 months  
     */ 
    function teamUnlock() public virtual returns (bool) {
        uint256 count = (_AMOUNT * 25) / 100;
        if (count > teamUnLocked) {
            uint256 month = (block.timestamp - startTime) / 86400 / 30;
            if (month >= 12) {
                uint256 amount = ((count * 20) / 100) +
                    (((count * 80) / 100 / 48) * (month - 12));
                if (amount > count) {
                    amount = count;
                }
                if (amount > teamUnLocked) {
                    _mint(_TEAMER, amount - teamUnLocked);
                    teamUnLocked = amount;
                    return true;
                }
            }
        }
        return false;
    }

    /**
     * @dev Community unlock
     * 20% unlocked, 30% after 6 months unlocked, the remaining tokens will be released within 24 months  
     */ 
    function snsUnlock() public virtual returns (bool) {
        uint256 count = (_AMOUNT * 13) / 100;
        if (count > snsUnLocked) {
            uint256 month = (block.timestamp - startTime) / 86400 / 30;
            uint256 amount = (count * 20) / 100;
            if (month >= 6) {
                amount +=
                    ((count * 30) / 100) +
                    (((count * 50) / 100 / 24) * (month - 6));
                if (amount > count) {
                    amount = count;
                }
            }
            if (amount > snsUnLocked) {
                _mint(_SNSER, amount - snsUnLocked);
                snsUnLocked = amount;
                return true;
            }
        }
        return false;
    }
}

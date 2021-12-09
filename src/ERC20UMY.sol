// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

/**
 * @dev UMY for karastar
 */
contract UMY is ERC20 {
    address private constant _TEAMER =
        0x8FeBa0F418561C038694f4e4Ba9168DE24E41B15; // team address
    address private constant _PLAYER =
        0x75F4Dc255C0F7121f41B1059147A7dDd93138886; // player address
    address private constant _RAISER =
        0x95cA24c0573358cC60D0F5F62eFDA6e6089aef50; // genesis sale address

    uint256 private constant _AMOUNT = 10**16; // total amount

    uint256 startTime; // created time

    uint256 teamUnLocked; // team unlock amount

    /**
     * @dev Mint token
     */
    constructor() ERC20("KaraStar UMY", "UMY") {
        _mint(_PLAYER, (_AMOUNT * 80) / 100);  // will cross all to xdai and send to the agency contract for player
        _mint(_RAISER, (_AMOUNT * 6) / 100);

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
        uint256 count = (_AMOUNT * 14) / 100;
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
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.0;

import "./Comn.sol";
import "./INFT.sol";
import "./IPet.sol";
import "./IEgg.sol";
import "./ICoin.sol";

/**
 * @title karastar's NFT egg
 */
contract EggNFT is Comn, IEgg {
    mapping(uint256 => Egg) internal _eggs;

    // Egg struct
    struct Egg {
        uint8 breed; // times
        uint32 htime;
        uint128 father;
        uint128 mother;
    }

    /**
     * @dev Hatch completion trigger
     */
    event Hatched(uint256 indexed id, uint256 petID);

    /**
     * @dev generate a egg for pet contract
     */
    function newEgg(
        address account,
        uint256 fatherID,
        uint256 motherID
    ) public virtual override onlyPetCter returns (uint256) {
        uint256 id = INFT(reg.nftAddr()).mintEgg(account);
        _eggs[id] = Egg({
            breed: 0,
            htime: uint32(block.timestamp),
            father: uint128(fatherID),
            mother: uint128(motherID)
        });
        return id;
    }

    /**
     * @dev get egg info
     */
    function info(uint256 id) public view virtual returns (Egg memory) {
        return _eggs[id];
    }

    /**
     * @dev the egg can hatch?
     */
    function hatchCan(uint256 eggID) public view virtual returns (bool) {
        Egg memory egg = _eggs[eggID];

        // hatch time
        uint256[] memory secs = reg.laySeconds();
        uint256 i = egg.breed < secs.length ? egg.breed : secs.length - 1;
        require(
            egg.htime < (block.timestamp - secs[i]),
            "must bee wait seconds"
        );

        // must owner
        require(
            INFT(reg.nftAddr()).ownerOf(eggID) == msg.sender,
            "owner is wrong"
        );
        return true;
    }

    /**
     * @dev hatch th egg
     */
    function hatch(uint256 eggID) public virtual returns (uint256) {
        hatchCan(eggID);
        Egg storage egg = _eggs[eggID];
        egg.breed += 1;
        egg.htime = uint32(block.timestamp);
        // the third time they hatch a pet
        if (egg.breed > 2) {
            uint256 petID = IPet(reg.petAddr()).layPet(
                eggID,
                egg.father,
                egg.mother
            );
            INFT(reg.nftAddr()).burnFor(eggID);
            emit Hatched(eggID, petID);
            return petID;
        }
        return 0;
    }
}

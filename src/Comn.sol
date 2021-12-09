// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.0;

import "./IReg.sol";
import "./IAdmin.sol";

// NFT type
enum Genre {
    Pet,
    Egg,
    Badge
}

/**
 * @title Pet sol extends from this
 */
abstract contract Comn {
    IReg public constant reg = IReg(0xEB376e81a31B3543140fc7FAF466270Aa2405744);
    IAdmin public constant admin =
        IAdmin(0x5418f11281cCF0c616Ca96865281944dfAA42173);

    modifier onlyMaster() {
        admin.mustMaster(msg.sender);
        _;
    }

    modifier onlyNFTCter() {
        require(
            reg.nftAddr() == msg.sender
        );
        _;
    }

    modifier onlyPetCter() {
        require(
            reg.petAddr() == msg.sender
        );
        _;
    }

    modifier onlyEggCter() {
        require(
            reg.eggAddr() == msg.sender
        );
        _;
    }

    modifier onlyNFTCters() {
        require(reg.inNFTAddr(msg.sender));
        _;
    }

    modifier onlySaleCter() {
        require(
            reg.saleAddr() == msg.sender
        );
        _;
    }

    modifier onlyBroker() {
        require(
            reg.broker() == msg.sender
        );
        _;
    }

    /**
     * whether NFT contract
     */
    function isNFTCter() internal view returns (bool) {
        return reg.nftAddr() == msg.sender;
    }
    
    /**
     * whether NFT and related contracts
     */
    function inNFTCters() internal view returns (bool) {
        return reg.inNFTAddr(msg.sender);
    }

    /**
     * delete an array element
     * must store
     */
    function arrayDel(uint256[] storage _arr, uint256 val) internal {
        for (uint256 i = 0; i < _arr.length; i++) {
            if (_arr[i] == val) {
                if (i < _arr.length - 1) {
                    _arr[i] = _arr[_arr.length - 1];
                }
                _arr.pop();
                break;
            }
        }
    }
}

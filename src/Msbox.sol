// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "./Comn.sol";
import "./IPet.sol";
import "./INFT.sol";

/**
 * @title mystery box
 */
contract Msbox is Comn {
    uint256 internal _testnum; // test pet count
    mapping(address => uint256) internal _balances; // balance for financer
    mapping(uint256 => uint256[]) internal _boxsets; // nft mysterybox sets
    mapping(address => uint256) internal _boxnums;
    mapping(address => uint256) internal _boxnums2; 
    
    /**
     * @dev init set the mystery box
     */
    function boxset() public virtual onlyMaster {
        // money,amount,grade1,grade2,grade3,rate1,rate2
        if (_boxsets[1][0] == 0) {
            _boxsets[1] = [(10**16) * 32, 9998, 8998, 833, 167, 9000, 9833];
        }
        if (_boxsets[2][0] == 0) {
            _boxsets[2] = [(10**16) * 35, 16999, 15299, 1416, 284, 9000, 9833];
        }
    }

    /**
     * @dev get mystery box info
     */
    function getBox(uint256 boxgrade) public view virtual returns(uint256[] memory) {
        uint256[] memory sets = _boxsets[boxgrade];
        sets[2] = 0;
        sets[3] = 0;
        sets[4] = 0;
        return sets;
    }

    /**
     * @dev get mystery box info
     */
    function getBoxM(uint256 boxgrade) public view virtual onlyMaster returns(uint256[] memory) {
        uint256[] memory sets = _boxsets[boxgrade];
        return sets;
    }

    /**
     * @dev verify signature
     */
    function verify(bytes memory signature, address to, uint256 boxgrade, uint256 opennum) private view returns(bool) {
        canOpen(to, boxgrade, opennum);
        bytes32 digest = keccak256(abi.encode(address(this), to, keccak256("BuyBox(uint256,uint256)"), boxgrade, opennum));
        address recoveredSigner = ECDSA.recover(digest, signature);
        require(recoveredSigner == reg.broker());
        return true;
    }

    /**
     * @dev can buy mystery box remaining
     */
    function canOpen(address account, uint256 boxgrade, uint256 opennum) public view returns(uint256) {
        require(opennum <= 3 && opennum >= 1);
        //require(_boxnums2[account] <= 9 - opennum);
        uint256[] memory box = _boxsets[boxgrade];
        require(box[0] > 0 && box[1] >= opennum);
        return _boxnums2[account];
    }

    /**
     * @dev open mystery box
     */
    function open(bytes memory signature, uint256 boxgrade, uint256 opennum) public payable virtual {
        verify(signature, msg.sender, boxgrade, opennum);
        uint256[] storage box = _boxsets[boxgrade];
        require(box[0] * opennum == msg.value, "bid mistake");
        // rate and amount, hight to low
        for(uint256 i = 0; i < opennum; i++) {
            uint256 grade = 0;
            uint256 x = rand(10000, box[1]);
            // Fixed uneven probability distribution
            if (x <= box[5]) {
                if (box[1] % 59 == 0) {
                    if (box[4] > 0 && (box[1] / box[4]) < (10000 / (10000 - box[6]))) {
                        x = box[6] + 1;
                    }
                } else if (box[1] % 7 == 0) {
                    if (box[3] > 0 && (box[1] / box[3]) < (10000 / (10000 - box[5]))) {
                        x = box[5] + 1;
                    }
                }
            }
            // grade calculation
            if (x > box[6] && box[4] > 0) {
                grade = 3;
                box[4] -= 1;
            } else if (x > box[5] && box[3] > 0) {
                grade = 2;
                box[3] -= 1;
            } else if (box[2] > 0){
                grade = 1;
                box[2] -= 1;
            }
            // low sell out, to hight
            if (grade == 0) {
                if (box[3] > 0) {
                    grade = 2;
                    box[3] -= 1;
                } else if (box[4] > 0) {
                    grade = 3;
                    box[4] -= 1;
                }
            }
            require(grade > 0);
            box[1] -= 1;
            // get for grade sets
            uint256[] memory sets = reg.petRandSets(grade + 1);
            require(sets[0] > 0);
            IPet(reg.petAddr()).newPet(msg.sender, sets);
            _boxnums2[msg.sender] += 1;
        }
        _balances[reg.financer()] += msg.value;
    }
    
    /**
     * @dev rand pet for test online
     * After testing, the pets will be locked down and not allowed ininto the market
     * The first 27 pets
     */
    // function testFor(address account, uint256 grade, uint256 num) public virtual onlyMaster {
    //     require(_testnum <= 27 - num);
    //     for(uint256 i = 0; i < num; i++) {
    //         _testnum += 1;
    //         uint256[] memory sets = reg.petRandSets(grade);
    //         require(sets[0] > 0);
    //         IPet(reg.petAddr()).newPet(account, sets);
    //     }
    // }

    /**
     * @dev Pets are destroyed after testing
     * The first 27 pets
     * It will be destroyed one week after it goes online by master
     */
    function testBurn() public virtual onlyMaster {
        uint256 startID = 132927991875350122118009236524365906283;
        for(uint256 i = 0; i < 27; i++) {
            INFT(reg.nftAddr()).burnFor(startID);
            startID++;
        }
    }

    /**
     * @dev Pets are locked after online
     * The first 27 pets
     */
    function testLocked() public virtual onlyMaster {
        uint256 startID = 132927991875350122118009236524365906283;
        for(uint256 i = 0; i < 27; i++) {
            INFT(reg.nftAddr()).lockFor(startID, true);
            startID++;
        }
    }

    /**
     * @dev transfer the sales amount
     */
    function withdraw(uint256 amount) public virtual returns (bool) {
        require(amount <= _balances[msg.sender], "insufficient balance");
        _balances[msg.sender] -= amount;
        if (!payable(msg.sender).send(amount)) {
            _balances[msg.sender] += amount;
            return false;
        }
        return true;
    }

    /**
     * @dev random 0--max
     */
    function rand(uint256 max, uint256 seed)
        private
        view
        returns (uint256)
    {
        if (max == 0) {
            return 0;
        }
        uint256 _rand = uint256(
            keccak256(
                abi.encodePacked(
                    seed,
                    _balances[reg.financer()],
                    block.number,
                    block.difficulty
                )
            )
        );
        return _rand % (max + 1);
    }
}

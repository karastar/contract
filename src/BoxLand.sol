// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "./Comn.sol";
import "./ICoin.sol";


interface ILand is IERC721 {
    function mintFor(address account, uint8 _type) external returns (uint256);
}

/**
 * @title mystery box
 */
contract BoxLand is Comn {
    address internal _landAddr; // land address
    uint256 internal _balanceUMY; // balance for financer
    uint256 internal _balanceBNB; // balance for financer
    mapping(uint256 => uint256[]) internal _boxsets; // nft mysterybox sets
    mapping(uint256 => uint256[]) internal _nftIDs;  // boxid => nftid
    mapping(address => uint256) internal _prepayUMYs; // installment purchase advance
    uint256 internal _prepayUMYCount; // prepay umy amount
    mapping(address => Award) internal _awards; // get the award address
    address[] internal _awardAddrs;

    struct Award {
        address token_addr; // 1BTC,2ETH
        uint8 from_box; // 1UMY,2BNB
        uint128 nftid; // nft id
        uint128 amount;
    }

    /**
     * @dev open award
     */
    function openAward() public onlyMaster {
        require(_awardAddrs.length == 0);
        require(_boxsets[11][1] == 0);
        require(_boxsets[12][1] == 0);

        // from bnb
        // 1 btc
        ILand land = ILand(_landAddr);
        uint256 index = rand(_nftIDs[12].length - 1, 1);
        uint256 nftid = _nftIDs[12][index];
        address owner = land.ownerOf(nftid);
        _awards[owner] = Award(address(0x7130d2A12B9BCbFAe4f2634d864A1Ee1Ce3Ead9c), 2, uint128(nftid), 10 ** 18);
        _awardAddrs.push(owner);
        // 2 eth
        uint256 count = 0;
        uint256 pos = _nftIDs[12].length;
        while(count < 2 && pos > 0) {
            index = rand(_nftIDs[12].length - 1, index);
            nftid = _nftIDs[12][index];
            owner = land.ownerOf(nftid);
            if (_awards[owner].amount == 0) {
                _awards[owner] = Award(address(0x2170Ed0880ac9A755fd29B2688956BD959F933F8), 2, uint128(nftid), 10 ** 18);
                count += 1;
                _awardAddrs.push(owner);
            }
            pos -= 1;
        }

        // from umy, 2 eth
        count = 0;
        pos = _nftIDs[11].length;
        while(count < 2 && pos > 0) {
            index = rand(_nftIDs[11].length - 1, index);
            nftid = _nftIDs[11][index];
            owner = land.ownerOf(nftid);
            if (_awards[owner].amount == 0) {
                _awards[owner] = Award(address(0x2170Ed0880ac9A755fd29B2688956BD959F933F8), 1, uint128(nftid), 10 ** 18);
                count += 1;
                _awardAddrs.push(owner);
            }
            pos -= 1;
        }
    }

    /**
     * @dev get the award info for address
     */
    function awardOf(address account) public view returns(Award memory) {
        return _awards[account];
    }

    /**
     * @dev get the award info for address
     */
    function getAwards() public view returns(address[] memory) {
        return _awardAddrs;
    }

    /**
     * @dev withdraw the award token
     */
    function withdrawAward(bytes memory signature) public {
        verify(signature, msg.sender, 101, 1);
        Award storage award = _awards[msg.sender];
        require(award.amount > 0);
        if (ICoin(award.token_addr).transfer(msg.sender, award.amount)) {
            award.amount = 0;
        } else {
            revert("not sufficient funds");
        }
    }

    /**
     * @dev init set the mystery box
     */
    function setBox() public virtual onlyMaster {
        // money,amount,N,R,rate1,rate2
        // first
        if (_boxsets[11].length == 0) {
            _boxsets[11] = [(10**6) * 5000, 1000, 700, 300, 70, 30];
            _boxsets[12] = [(10**16) * 100, 2500, 1800, 700, 70, 30];
        }
    }
    
    /**
     * @dev set the box price
     */
    function setBoxPrice(uint256 boxid, uint256 price) public virtual onlyMaster {
        require(_boxsets[boxid].length > 0);
        _boxsets[boxid][0] = price;
    }

    /**
     * @dev get mystery box info
     */
    function getBox(uint256 id) public view virtual returns(uint256[] memory) {
        uint256[] memory sets = _boxsets[id];
        sets[2] = 0;
        sets[3] = 0;
        return sets;
    }

    /**
     * @dev get mystery box info
     */
    function getBoxM(uint256 id) public view virtual onlyMaster returns(uint256[] memory) {
        uint256[] memory sets = _boxsets[id];
        return sets;
    }
    
    /**
     * @dev set the land contract address
     */
    function setLandAddr(address value) public onlyMaster {
        _landAddr = value;
    }
    
    /**
     * @dev set the land contract address
     */
    function setLandAddr(address value) public onlyMaster {
        _landAddr = value;
    }
    
    /**
     * @dev get the land contract address
     */
    function getLandAddr() public view onlyMaster returns(address) {
        return _landAddr;
    }


    /**
     * @dev verify signature
     */
    function verify(bytes memory signature, address to, uint256 boxid, uint256 opennum) private view returns(bool) {
        bytes32 digest = keccak256(abi.encode(address(this), to, keccak256("openbox(uint256,uint256)"), boxid, opennum));
        address recoveredSigner = ECDSA.recover(digest, signature);
        require(recoveredSigner == reg.broker());
        return true;
    }

    /**
     * @dev open the box
     */
    function _open(uint256 boxid, uint256 opennum) private {
        uint256[] storage box = _boxsets[boxid];
        ILand land = ILand(_landAddr);
        // rate and amount, hight to low
        for(uint256 i = 0; i < opennum; i++) {
            uint256 grade = 0;
            uint256 x = rand(100, box[1]);
            // Fixed uneven probability distribution
            if (x <= box[4]) {
                if (box[1] % 3 == 0) {
                    if (box[3] > 0 && (box[1] / box[3]) < (100 / (box[5]))) {
                        x = box[5] + 1;
                    }
                }
            }
            // grade calculation
            if (x > box[4] && box[3] > 0) {  // R
                grade = 2;
                box[3] -= 1;
            } else if (box[2] > 0){  // N
                grade = 1;
                box[2] -= 1;
            }
            // low sell out, to hight
            if (grade == 0) {
                if (box[3] > 0) {
                    grade = 2;
                    box[3] -= 1;
                }
            }
            require(grade > 0);
            box[1] -= 1;
            // rand the type
            uint256 ltype = 0;
            if (grade == 1) {
                ltype = rand(1, i * 10 + 1) + 1;
            } else {
                ltype = rand(1, i * 10 + 2) + 3;
            }
            require(ltype > 0);
            uint256 nftid = land.mintFor(msg.sender, uint8(ltype));
            _nftIDs[boxid].push(nftid);
        }
    }

    /**
     * @dev open mystery box use bnb
     */
    function openByBNB(bytes memory signature, uint256 boxid, uint256 opennum) public payable virtual {
        require(opennum < 10);
        require(boxid % 10 == 2);
        verify(signature, msg.sender, boxid, opennum);
        uint256[] memory box = _boxsets[boxid];
        require(box[0] > 0 && box[1] >= opennum);
        require(box[0] * opennum == msg.value, "bid mistake");
        _open(boxid, opennum);
        _balanceBNB += msg.value;
    }

    /**
     * @dev open mystery box use umy
     */
    function openByUMY(bytes memory signature, uint256 boxid, uint256 opennum) public payable virtual {
        require(opennum < 10);
        require(boxid % 10 == 1);
        verify(signature, msg.sender, boxid, opennum);
        uint256[] memory box = _boxsets[boxid];
        require(box[0] > 0 && box[1] >= opennum);

        uint256 price = box[0] * opennum;
        if (ICoin(reg.umyAddr()).transferFrom(msg.sender, address(this), price)) {
            _open(boxid, opennum);
            _balanceUMY += price;
        } else {
            revert("the contract balancer enough");
        }
    }

    /**
     * @dev transfer the bnb sales amount
     */
    function withdrawBNB(uint256 amount) public onlyMaster virtual returns (bool) {
        address financer = reg.financer();
        require(amount <= _balanceBNB, "insufficient balance");
        _balanceBNB -= amount;
        if (!payable(financer).send(amount)) {
            _balanceBNB += amount;
            return false;
        }
        return true;
    }

    /**
     * @dev transfer the umy sales amount
     */
    function withdrawUMY(uint256 amount) public onlyMaster virtual returns (bool) {
        address financer = reg.financer();
        require(amount <= _balanceUMY, "insufficient balance");
        _balanceUMY -= amount;
        if (ICoin(reg.umyAddr()).transfer(financer, amount)) {
            return true;
        }
        return false;
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
                    _balanceBNB,
                    _balanceUMY,
                    block.number,
                    block.timestamp,
                    block.coinbase
                )
            )
        );
        return _rand % (max + 1);
    }
}
// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "./Comn.sol";
import "./INFT.sol";
import "./IPet.sol";
import "./ISale.sol";

/**
 * @title Sale the NFT
 */
contract Sale is Comn, ISale {
    mapping(uint256 => Selling) internal _sales;
    mapping(address => uint256[]) internal _ownpets;
    mapping(address => uint256) internal _balances;

    struct Selling {
        address owner;
        uint256 price;
    }

    event SellingSingle(uint256 id, uint256 price);
    event SellingBatch(uint256[] ids, uint256[] prices);
        
    /**
     * @dev sale the nft
     * onlyone
     */
    function sale(uint256 id, uint256 price) public virtual override {
        INFT nft = INFT(reg.nftAddr());
        address owner = nft.ownerOf(id);
        require(inNFTCters() || owner == msg.sender, "owner error");
        if (_sales[id].owner == address(0)) {
            require(nft.isLocked(id) == false);
            _ownpets[owner].push(id);
            nft.lockFor(id, true);
        }
        _sales[id] = Selling(owner, price);
        emit SellingSingle(id, price);
    }

    /**
     * @dev cancel the sale 
     * onlyone
     */
    function offSale(uint256 id) public virtual override {
        if (_sales[id].owner != address(0)) {
            INFT nft = INFT(reg.nftAddr());
            address owner = nft.ownerOf(id);
            require(inNFTCters() || owner == msg.sender, "owner error");
            delete _sales[id];
            arrayDel(_ownpets[owner], id);
            nft.lockFor(id, false);
        }
        emit SellingSingle(id, 0);
    }

     /**
     * @dev sale the nft
     * many
     */
    function saleBatch(uint256[] memory ids, uint256[] memory prices)
        public
        virtual
        override
    {
        require(ids.length == prices.length, "ids and prices length mismatch");
        INFT nft = INFT(reg.nftAddr());
        for (uint256 i = 0; i < ids.length; i++) {
            uint256 id = ids[i];
            address owner = nft.ownerOf(id);
            require(inNFTCters() || owner == msg.sender, "owner error");
            if (_sales[id].owner == address(0)) {  // a sale must be unlocked
                require(nft.isLocked(id) == false);
                _ownpets[owner].push(id);
                nft.lockFor(id, true);
            }
            _sales[id] = Selling(owner, prices[i]);
        }
        emit SellingBatch(ids, prices);
    }

    /**
     * @dev cancel the sale 
     * many
     */
    function offSaleBatch(uint256[] memory ids) public virtual override {
        INFT nft = INFT(reg.nftAddr());
        uint256[] memory prices = new uint256[](ids.length);
        for (uint256 i = 0; i < ids.length; i++) {
            uint256 id = ids[i];
            if (_sales[id].owner != address(0)) {
                address owner = nft.ownerOf(id);
                require(inNFTCters() || owner == msg.sender, "owner error");
                delete _sales[id];
                arrayDel(_ownpets[owner], id);
                nft.lockFor(id, false);
            }
            prices[i] = 0;
        }

        emit SellingBatch(ids, prices);
    }

    /**
     * @dev buy NFT
     * onlyone
     */
    function buy(uint256 id) public payable virtual {
        Selling memory item = _sales[id];
        require(item.price > 0, "not selling");
        require(msg.value == item.price, "bid mistake");
        INFT nft = INFT(reg.nftAddr());
        require(nft.ownerOf(id) == item.owner, "not selling");

        nft.transferFor(id, msg.sender);
        
        uint256 amount = (item.price * (100 - reg.saleFee())) / 100;
        _balances[item.owner] += amount; // income
        _balances[reg.financer()] += item.price - amount; // fee
    }

    
    /**
     * @dev buy NFT
     * many
     */
    function buyBatch(uint256[] memory ids) public payable virtual {
        uint256 priceAll = 0;
        INFT nft = INFT(reg.nftAddr());
        // check all NFT
        for (uint256 i = 0; i < ids.length; i++) {
            Selling memory item = _sales[ids[i]];
            require(item.price > 0, "not saleing");
            require(nft.ownerOf(ids[i]) == item.owner, "not selling");
            priceAll += item.price;
        }
        require(msg.value == priceAll, "bid mistake");

        // transfer
        uint256 rate = 100 - reg.saleFee();
        for (uint256 i = 0; i < ids.length; i++) {
            Selling memory item = _sales[ids[i]];
            nft.transferFor(ids[i], msg.sender);
            uint256 amount = (item.price * rate) / 100;
            _balances[item.owner] += amount; // income
            _balances[reg.financer()] += item.price - amount; // fee
        }
    }

    /**
     * @dev get the balance for salesman
     */
    function balanceOf(address account) public view override virtual returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev cash the balance
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
     * @dev get users's NFT on selling
     */
    function salesOf(address account)
        public
        view
        virtual
        returns (uint256[] memory)
    {
        return _ownpets[account];
    }

    /**
     * @dev get NFT prices
     */
    function priceOf(uint256 id) public view virtual returns (uint256) {
        return _sales[id].price;
    }
    
    /**
     * @dev get the NFT seller
     */ 
    function ownerOf(uint256 id) public view virtual returns (address) {
        return _sales[id].owner;
    }
    
    /**
     * @dev get NFT sales information
     */
    function saleInfo(uint256 id) public view virtual returns (Selling memory) {
        return _sales[id];
    }
}
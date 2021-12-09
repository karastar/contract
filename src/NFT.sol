// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "./Comn.sol";
import "./INFT.sol";
import "./IPet.sol";
import "./ISale.sol";

/**
 * @title karastar NFT
 * pet egg badge
 */
contract NFT is ERC721, Comn, INFT {
    uint256 internal _nftIds = 10000; // nft ID
    mapping(address => uint256[]) internal _ownpets; // user's pet
    mapping(uint256 => Genre) internal _genres; // nft genre
    mapping(uint256 => bool) internal _locked; // nft lock state
    uint256 internal _burnAmount; // nft brun amount

    modifier onlyBadgeCter() {
        require(
            reg.badgeAddr() == msg.sender
        );
        _;
    }

    constructor() ERC721("", "") {}

    /**
     * @dev See {IERC721Metadata-name}.
     */
    function name() public view virtual override returns (string memory) {
        return "KaraStar NFT";
    }

    /**
     * @dev See {IERC721Metadata-symbol}.
     */
    function symbol() public view virtual override returns (string memory) {
        return "KARAS";
    }

    /**
     * @dev generate NFT ID
     * chianid(8)+nftnum(8)+nfttype(8)+id(104)
     */
    function _newID(Genre gen) internal returns (uint256) {
        uint256 base = (((100 << 8) + 1) << 8) + uint256(gen);
        return (base << 104) + (++_nftIds);
    }

    /**
     * @dev mint a egg for user
     */
    function mintEgg(address account)
        public
        virtual
        override
        onlyEggCter
        returns (uint256)
    {
        uint256 id = _newID(Genre.Egg);
        _mint(account, id);
        _genres[id] = Genre.Egg;
        return id;
    }

    /**
     * @dev mint a pet for user
     */
    function mintPet(address account)
        public
        virtual
        override
        onlyPetCter
        returns (uint256)
    {
        uint256 id = _newID(Genre.Pet);
        _mint(account, id);
        _genres[id] = Genre.Pet;
        return id;
    }

    /**
     * @dev mint a badge for badge contract
     */
    function mintBadge(address account)
        public
        virtual
        override
        onlyBadgeCter
        returns (uint256)
    {
        uint256 id = _newID(Genre.Badge);
        _mint(account, id);
        _genres[id] = Genre.Badge;
        return id;
    }

    /**
     * @dev burn a pet for evolve
     */
    function burnFor(uint256 id)
        public
        virtual
        override
        onlyNFTCters
        returns (bool)
    {
        _locked[id] = false;
        _burn(id);
        return true;
    }

    /**
     * @dev transfer NFT for sale
     */
    function transferFor(uint256 id, address to)
        public
        virtual
        override
        onlySaleCter
        returns (bool)
    {   
        _locked[id] = false;
        _transfer(ownerOf(id), to, id);
        return true;
    }

    /**
     * @dev lock NFT for sale
     */
    function lockFor(uint256 id, bool locked)
        public
        virtual
        override
        onlyNFTCters
        returns (bool)
    {
        _locked[id] = locked;
        return true;
    }

    /**
     * @dev get NFT lock state
     */
    function isLocked(uint256 id) public view virtual override returns (bool) {
        return _locked[id];
    }

    /**
     * @dev get the maximum number of NFT
     */
    function amount() public view virtual override returns (uint256) {
        return _nftIds;
    }

    /**
     * @dev get all NFT of the user
     */
    function allsOf(address account)
        public
        view
        virtual
        returns (uint256[] memory)
    {
        return _ownpets[account];
    }

    /**
     * @dev get the user's NFT by gene
     */
    function gensOf(address account, Genre gen)
        public
        view
        virtual
        returns (uint256[] memory)
    {
        // calc array length
        uint256 count = 0;
        for (uint256 i = 0; i < _ownpets[account].length; i++) {
            uint256 id = _ownpets[account][i];
            if (_genres[id] == gen) {
                count += 1;
            }
        }
        // 
        uint256[] memory items = new uint256[](count);
        if (count > 0) {
            for (uint256 i = 0; i < _ownpets[account].length; i++) {
                uint256 id = _ownpets[account][i];
                if (_genres[id] == gen) {
                    count -= 1;
                    items[count] = id;
                }
            }
        }
        return items;
    }

    /**
     * @dev NFT URI address
     */
    function _baseURI() internal pure virtual override returns (string memory) {
        return "https://api.karastar.com/pet/item/";
    }

    /**
     * @dev See {IERC721Enumerable-totalSupply}.
     */
    function totalSupply() public view virtual returns (uint256) {
        return _nftIds - _burnAmount;
    }

    /**
     * @dev See {ERC721-_beforeTokenTransfer}.
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual override {
        //super._beforeTokenTransfer(from, to, tokenId);
        if (tokenId != 0) {
            require(_locked[tokenId] == false);
            if (from != address(0)) {
                // off sale state
                ISale(reg.saleAddr()).offSale(tokenId);
                arrayDel(_ownpets[from], tokenId);
            }

            if (to != address(0)) {
                _ownpets[to].push(tokenId);
            } else {
                _burnAmount += 1;
            }
        }
    }
}

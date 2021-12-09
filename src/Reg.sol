// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.0;

import "./IAdmin.sol";
import "./IReg.sol";
import "./ICoin.sol";
import "./ISale.sol";
import "./INFT.sol";

/**
 * @title Registery data
 */
contract Reg is IReg {
    IAdmin public constant admin =
        IAdmin(0x5418f11281cCF0c616Ca96865281944dfAA42173);

    uint256 internal _maxEvolveNum; // 
    uint256 internal _feeSale; // pet sale fee

    uint256[] internal _breedFees; // hatch fee
    uint256[] internal _geneNums; // gene number, every start 1, order same PetBody
    uint256[] internal _laySeconds; // hatch seconds
    uint256[] internal _loanFees; // loan fees

    address internal _umyAddr; // UMY contract address
    address internal _karaAddr; // KARA contract address
    address internal _priceAddr; // price oracle contract address

    address internal _nftAddr; // nft contract address
    address internal _petAddr; // pet contract address
    address internal _eggAddr; // egg contract address
    address internal _saleAddr; // sale contract address
    address internal _loanAddr; // loan contract address
    address internal _holdAddr; // hold contract address

    address internal _financer; // finance address
    address internal _broker; // transfer token address
    address internal _loanBroker; // loan transfer address

    mapping(uint256 => uint256[]) internal _petRandSets; // pet rand config, only this

    address internal _msboxAddr; // mysterybox contract address
    address internal _badgeAddr; // badge contract address

    modifier onlyMaster() {
        admin.mustMaster(msg.sender);
        _;
    }

    /**
     * @dev init the data
     * onlyone
     */
    function init() public onlyMaster {
        if (_financer == address(0)) {
            _maxEvolveNum = 60;
            _feeSale = 5;

            _breedFees = [150, 300, 450, 750, 1200, 1950, 3150];
            _geneNums = [0, 36, 24, 24, 36, 24, 36, 36];
            _laySeconds = [86400, 86400 * 2, 86400 * 2];

            // the address in next set
        }
        // add new for rand gene
        // price, minEvolve, maxEvolve, minBreed, maxBreed, minDeityBody, maxDeityBody, minDeity, maxDeity
        if (_petRandSets[1].length == 0) {
            _petRandSets[1] = [1 * (10**17), 20, 20, 2, 2, 0, 0, 0, 0];
            _petRandSets[2] = [3 * (10**17), 50, 50, 7, 7, 2, 2, 10, 20];
            _petRandSets[3] = [1 * (10**18), 80, 80, 7, 7, 2, 3, 20, 30];
            _petRandSets[4] = [3 * (10**18), 120, 120, 7, 7, 4, 4, 30, 50];
        }
    }

    function financer() external view override returns (address) {
        return _financer;
    }

    function broker() external view override returns (address) {
        return _broker;
    }

    function loanBroker() external view override returns (address) {
        return _loanBroker;
    }

    function evolveLimit() external view override returns (uint256) {
        return _maxEvolveNum;
    }

    function saleFee() external view override returns (uint256) {
        return _feeSale;
    }

    /**
     *@dev gain umy for reproduction times
     */
    function breedFee(uint256 breedNum)
        external
        view
        override
        returns (uint256)
    {
        require(breedNum < _breedFees.length, "breed is wrong");
        return _breedFees[breedNum];
    }

    function breedLimit() external view override returns (uint256) {
        return _breedFees.length;
    }

    /**
     *@dev get gene value
     */
    function geneNum(uint256 bodyNum) external view override returns (uint256) {
        require(bodyNum < _geneNums.length, "body is wrong");
        return _geneNums[bodyNum];
    }

    /**
     *@dev get a random pet sets
     */
    function petRandSets(uint256 grade)
        external
        view
        override
        returns (uint256[] memory)
    {
        require(_petRandSets[grade].length >= 9, "rand not set");
        return _petRandSets[grade];
    }

    function laySeconds() external view override returns (uint256[] memory) {
        return _laySeconds;
    }

    function priceAddr() external view override returns (address) {
        return _priceAddr;
    }

    function umyAddr() external view override returns (address) {
        return _umyAddr;
    }

    function karaAddr() external view override returns (address) {
        return _karaAddr;
    }

    function petAddr() external view override returns (address) {
        return _petAddr;
    }

    function eggAddr() external view override returns (address) {
        return _eggAddr;
    }

    function nftAddr() external view override returns (address) {
        return _nftAddr;
    }

    function saleAddr() external view override returns (address) {
        return _saleAddr;
    }

    function loanAddr() external view override returns (address) {
        return _loanAddr;
    }

    function holdAddr() external view override returns (address) {
        return _holdAddr;
    }

    function msboxAddr() external view override returns (address) {
        return _msboxAddr;
    }

    function badgeAddr() external view override returns (address) {
        return _badgeAddr;
    }

    /**
     *@dev whether in NFT and relative contract
     */
    function inNFTAddr(address addr) external view override returns (bool) {
        return
            addr == _nftAddr ||
            addr == _petAddr ||
            addr == _eggAddr ||
            addr == _loanAddr ||
            addr == _msboxAddr ||
            addr == _badgeAddr ||
            addr == _saleAddr;
    }

    function umyPrice() external view override returns (uint256) {
        return IPrice(_priceAddr).getUMY();
    }

    function karaPrice() external view override returns (uint256) {
        return IPrice(_priceAddr).getKARA();
    }

    function setEvolveLimit(uint256 value) public onlyMaster {
        _maxEvolveNum = value;
    }

    function setSaleFee(uint256 value) public onlyMaster {
        _feeSale = value > 100 ? 100 : (value < 0 ? 0 : value);
    }

    function setBreedFees(uint256[] memory nums) public onlyMaster {
        _breedFees = nums;
    }

    function setGeneNums(uint256[] memory nums) public onlyMaster {
        _geneNums = nums;
    }

    function setLaySeconds(uint256[] memory nums) public onlyMaster {
        _laySeconds = nums;
    }

    function setPetRandSets(uint256 grade, uint256[] memory nums)
        public
        onlyMaster
    {
        _petRandSets[grade] = nums;
    }

    function setPriceAddr(address value) public onlyMaster {
        admin.mustAudited(value);
        _priceAddr = value;
    }

    function setUMYAddr(address value) public onlyMaster {
        admin.mustAudited(value);
        _umyAddr = value;
    }

    function setKaraAddr(address value) public onlyMaster {
        admin.mustAudited(value);
        _karaAddr = value;
    }

    function setNFTAddr(address value) public onlyMaster {
        admin.mustAudited(value);
        _nftAddr = value;
    }

    function setPetAddr(address value) public onlyMaster {
        admin.mustAudited(value);
        _petAddr = value;
    }

    function setEggAddr(address value) public onlyMaster {
        admin.mustAudited(value);
        _eggAddr = value;
    }

    function setSaleAddr(address value) public onlyMaster {
        admin.mustAudited(value);
        _saleAddr = value;
    }

    function setLoanAddr(address value) public onlyMaster {
        admin.mustAudited(value);
        _loanAddr = value;
    }

    function setHoldAddr(address value) public onlyMaster {
        admin.mustAudited(value);
        _holdAddr = value;
    }

    function setMsboxAddr(address value) public onlyMaster {
        admin.mustAudited(value);
        _msboxAddr = value;
    }

    function setBadgeAddr(address value) public onlyMaster {
        admin.mustAudited(value);
        _badgeAddr = value;
    }

    function setFinancerAddr(address value) public onlyMaster {
        admin.mustAudited(value);
        _financer = value;
    }

    function setBrokerAddr(address value) public onlyMaster {
        admin.mustAudited(value);
        _broker = value;
    }

    function setLoanBrokerAddr(address value) public onlyMaster {
        admin.mustAudited(value);
        _loanBroker = value;
    }
}
// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "./Comn.sol";
import "./ICoin.sol";
import "./IHold.sol";

/**
 * @title Token transfer
 * @dev transfer the token for player
 */
contract ERC20Hold is Comn, IHold {
    uint256 karaPlayerBalance;
    uint256 karaMinerBalance;
    uint256 umyPlayerBalance;
    bool inited = false;
    mapping(uint256 => uint256) transferNonces;

    modifier onlyLoanCter() {
        require(
            reg.loanAddr() == msg.sender,
            "Ownable: caller is not the loan contract"
        );
        _;
    }

    modifier onlyLoanBroker() {
        require(
            reg.loanBroker() == msg.sender,
            "Ownable: caller is not the loan broker"
        );
        _;
    }

    /**
     * @dev proxy contract init
     */
    function init() public onlyMaster {
        if (!inited) {
            karaPlayerBalance = 10**12 * 5 * 20;
            karaMinerBalance = 10**12 * 5 * 29;
            umyPlayerBalance = 10**14 * 80;
            inited = true;
        }
    }

    /**
     * @dev verify signature
     */ 
    function verify(bytes memory signature, string memory fname, address to, uint256 amount, uint256 nonce) private view returns(bool) {
        require(transferNonces[nonce] == 0);  // check uniquid
        bytes32 digest = keccak256(abi.encode(address(this), to, keccak256(abi.encodePacked(fname, "(uint256,uint256)")), amount, nonce));
        address recoveredSigner = ECDSA.recover(digest, signature);
        require(recoveredSigner == reg.broker());
        return true;
    }

    /**
     * @dev get the transfer nonce is used ?
     */ 
    function transferNonceOf(uint256 nonce) public view returns(uint256) {
        return transferNonces[nonce];
    }

    /**
     * @dev umy for user, must check signature
     */
    function transferUMYToPlayer(bytes memory signature, uint256 amount, uint256 nonce)
        public
        returns (bool)
    {   
        if (umyPlayerBalance >= amount) {
            verify(signature, "transferUMYToPlayer", msg.sender, amount, nonce);
            if (ICoin(reg.umyAddr()).transfer(msg.sender, amount)) {
                umyPlayerBalance -= amount;
                transferNonces[nonce] = amount;
                return true;
            }
        }
        revert("transfer error");
    }

    /**
     * @dev kara for user, must check signature
     */
    function transferKARAToPlayer(bytes memory signature, uint256 amount, uint256 nonce)
        public
        returns (bool)
    {
        if (karaPlayerBalance >= amount) {
            verify(signature, "transferKARAToPlayer", msg.sender, amount, nonce);
            if (ICoin(reg.karaAddr()).transfer(msg.sender, amount)) {
                karaPlayerBalance -= amount;
                transferNonces[nonce] = amount;
                return true;
            }
        }
        revert("transfer error");
    }

    /**
     * @dev kara for miner, must check signature
     */
    function transferKARAToMiner(bytes memory signature, uint256 amount, uint256 nonce)
        public
        returns (bool)
    {
        if (karaMinerBalance >= amount) {
            verify(signature, "transferKARAToMiner", msg.sender, amount, nonce);
            if (ICoin(reg.karaAddr()).transfer(msg.sender, amount)) {
                karaMinerBalance -= amount;
                transferNonces[nonce] = amount;
                return true;
            }
        }
        revert("transfer error");
    }

    /**
     * @dev gas for user, must check signature
     */
    function transferGasToPlayer(bytes memory signature, uint256 amount, uint256 nonce)
        public
        returns (bool)
    {
        if (address(this).balance >= amount) {
            verify(signature, "transferGasToPlayer", msg.sender, amount, nonce);
            if (payable(msg.sender).send(amount)) {
                transferNonces[nonce] = amount;
                return true;
            }
        }
        revert("transfer error");
    }

    /**
     * @dev transfer to multi players, for loan contracter
     */
    function transferUMYBatch(address[] memory tos, uint256[] memory amounts, uint256 nonce)
        public
        override
        onlyLoanCter
        returns (bool)
    {
        require(tos.length == amounts.length);
        require(transferNonces[nonce] == 0);
        for (uint256 i = 0; i < tos.length; ++i) {
            require(umyPlayerBalance >= amounts[i]);
            if (!ICoin(reg.umyAddr()).transfer(tos[i], amounts[i])) {
                revert("transfer error");
            }
            umyPlayerBalance -= amounts[i];
            transferNonces[nonce] += amounts[i];
        }
        return true;
    }
}

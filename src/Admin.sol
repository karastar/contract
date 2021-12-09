// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.0;
import "./IAdmin.sol";

/**
 * @title Karastar Admin
 * @dev Authorization management, does not require proxy, is deployed first.
 */
contract Admin is IAdmin {
    address public master = 0x9431670006EEcE8e493cF17016cDE08bDA23Eb64; // master
    address[] public auditors = [
        0x9431670006EEcE8e493cF17016cDE08bDA23Eb64,
        0x316f6D807BFF911A13cF6b2d9bB9CDde2F8231c6,
        0x351B88B67ff1C30DaAc542Fe951Dda508647f687
    ]; // auditors

    bool public mustAudit = false; // must audit

    mapping(address => mapping(address => address)) _transAuditor; // transfer admin (admin=>(from=>to))
    mapping(address => address) _transMaster; // transfer master(admin=>to)

    mapping(address => address[]) _newAddress; // audit for new address(new address=>admin)
    address[] _lastAddress; // audited address

    /**
     * @dev Throws if called by any account other than the master.
     */
    modifier onlyMaster() {
        require(master == msg.sender, "Ownable: caller is not the master");
        _;
    }

    /**
     * @dev Throws if called by any account other than the auditor.
     */
    modifier onlyAuditor() {
        require(
            _addressOf(auditors, msg.sender) > -1,
            "Ownable: caller is not the auditor"
        );
        _;
    }

    /**
     * @dev Open the audit
     */
    function openAudit() public onlyMaster {
        mustAudit = true;
    }

    /**
     * @dev Transfer of authority.
     * At least two people agreed
     */
    function transferAdmin(address from, address to) public onlyAuditor {
        int256 index = _addressOf(auditors, from);
        require(index >= 0, "from error");

        _transAuditor[msg.sender][from] = to;
        for (uint256 i = 0; i < auditors.length; i++) {
            if (
                auditors[i] != msg.sender &&
                _transAuditor[auditors[i]][from] == to
            ) {
                // audited
                auditors[uint256(index)] = to;
                delete _transAuditor[auditors[i]][from];
                delete _transAuditor[msg.sender][from];
            }
        }
    }

    /**
     * @dev Transfer of master.
     * At least two people agreed, one of them must be the original master user
     * Master's secrect key cannot be lost
     */
    function transferMaster(address to) public onlyAuditor {
        _transMaster[msg.sender] = to;
        if (_transMaster[master] == to) {
            // audited
            int256 index = _addressOf(auditors, master);
            if (index > -1) {
                auditors[uint256(index)] = to;
            }
            master = to;
        }
    }

    /**
     * @dev Allows the agent to upgrade to the new address
     */
    function updateNew(address[] memory to) public onlyAuditor {
        for (uint256 i = 0; i < to.length; i++) {
            if (_addressOf(_newAddress[to[i]], msg.sender) < 0) {
                _newAddress[to[i]].push(msg.sender);
            }
        }
        _lastAddress = to;
    }

    /**
     * @dev Throws If fail the audit.
     */
    function mustAudited(address to) override public view {
        if (mustAudit) {
            require(
                _newAddress[to].length > 1 && _addressOf(_lastAddress, to) > -1,
                "must be audited"
            );
        }
    }

    /**
     * @dev Throws if called by any account other than the master.
     */
    function mustMaster(address addr) override public view {
        require(master == addr, "caller is not the master");
    }

    /**
     * @dev Whether  the master.
     */
    function isMaster(address addr) override public view returns (bool) {
        return master == addr;
    }

    /**
     * @dev array indexOf, same as javascript
     */
    function _addressOf(address[] memory arr, address addr)
        internal
        pure
        returns (int256)
    {
        for (uint256 i = 0; i < arr.length; i++) {
            if (arr[i] == addr) {
                return int256(i);
            }
        }
        return -1;
    }
}
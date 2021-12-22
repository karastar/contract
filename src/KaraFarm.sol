// SPDX-License-Identifier: MIT
pragma solidity ^0.6.2;

import "@pancakeswap/pancake-swap-lib/contracts/math/SafeMath.sol";
import "@pancakeswap/pancake-swap-lib/contracts/token/BEP20/IBEP20.sol";
import "@pancakeswap/pancake-swap-lib/contracts/token/BEP20/SafeBEP20.sol";
import "@pancakeswap/pancake-swap-lib/contracts/access/Ownable.sol";

// Have fun reading it. Hopefully it's bug-free. God bless.
contract KaraFarm is Ownable {
    using SafeMath for uint256;
    using SafeBEP20 for IBEP20;

    // Info of each user.
    struct UserInfo {
        uint256 amount;     // How many LP tokens the user has provided.
        uint256 rewardDebt; // Reward debt. See explanation below.
        uint256 depositTime; // deposit time
        //
        // We do some fancy math here. Basically, any point in time, the amount of KARAs
        // entitled to a user but is pending to be distributed is:
        //
        //   pending reward = (user.amount * pool.accKARAPerShare) - user.rewardDebt
        //
        // Whenever a user deposits or withdraws LP tokens to a pool. Here's what happens:
        //   1. The pool's `accKARAPerShare` (and `lastRewardBlock`) gets updated.
        //   2. User receives the pending reward sent to his/her address.
        //   3. User's `amount` gets updated.
        //   4. User's `rewardDebt` gets updated.
    }

    // Info of each pool.
    struct PoolInfo {
        IBEP20 lpToken;           // Address of LP token contract.
        uint256 allocPoint;       // How many allocation points assigned to this pool. KARAs to distribute per block.
        uint256 lastRewardBlock;  // Last block number that KARAs distribution occurs.
        uint256 accKARAPerShare; // Accumulated KARAs per share, times 1e12. See below.
    }

    // The KARA TOKEN!
    IBEP20 public kara;
    // Dev address.
    // address public devaddr;
    address public rewardPool;
    // dev address
    address public devAddress;
    // KAAR tokens created per block.
    uint256 public karaPerBlock;

    // Info of each pool.
    PoolInfo[] public poolInfo;
    // Info of each user that stakes LP tokens.
    mapping (uint256 => mapping (address => UserInfo)) public userInfo;
    // Total allocation points. Must be the sum of all allocation points in all pools.
    uint256 public totalAllocPoint = 0;
    // The block number when KARA mining starts.
    uint256 public startBlock;

    event Deposit(address indexed user, uint256 indexed pid, uint256 amount);
    event Withdraw(address indexed user, uint256 indexed pid, uint256 amount);
    event EmergencyWithdraw(address indexed user, uint256 indexed pid, uint256 amount);

    constructor(
        IBEP20 _kara,
        IBEP20 _firstPoolLp,
        address _rewardPool,
        address _devAddress,
        uint256 _karaPerBlock,
        uint256 _startBlock
    ) public {
        kara = _kara;
        // devaddr = _devaddr;
        rewardPool = _rewardPool;
        devAddress = _devAddress;
        karaPerBlock = _karaPerBlock;
        startBlock = _startBlock < block.number ? block.number : _startBlock;

        // staking pool
        poolInfo.push(PoolInfo({
            lpToken: kara,
            allocPoint: 0,
            lastRewardBlock: startBlock,
            accKARAPerShare: 0
        }));

        // first LP pool
        poolInfo.push(PoolInfo({
            lpToken: _firstPoolLp,
            allocPoint: 100,
            lastRewardBlock: startBlock,
            accKARAPerShare: 0
        }));

        totalAllocPoint = 100;
    }

    function poolLength() external view returns (uint256) {
        return poolInfo.length;
    }

    // Add a new lp to the pool. Can only be called by the owner.
    // XXX DO NOT add the same LP token more than once. Rewards will be messed up if you do.
    function add(uint256 _allocPoint, IBEP20 _lpToken, bool _withUpdate) public onlyOwner {
        if (_withUpdate) {
            massUpdatePools();
        }
        uint256 lastRewardBlock = block.number > startBlock ? block.number : startBlock;
        totalAllocPoint = totalAllocPoint.add(_allocPoint);
        poolInfo.push(PoolInfo({
            lpToken: _lpToken,
            allocPoint: _allocPoint,
            lastRewardBlock: lastRewardBlock,
            accKARAPerShare: 0
        }));
    }

    // Update the given pool's KARA allocation point. Can only be called by the owner.
    function set(uint256 _pid, uint256 _allocPoint, bool _withUpdate) public onlyOwner {
        if (_withUpdate) {
            massUpdatePools();
        }
        uint256 prevAllocPoint = poolInfo[_pid].allocPoint;
        poolInfo[_pid].allocPoint = _allocPoint;
        if (prevAllocPoint != _allocPoint) {
            totalAllocPoint = totalAllocPoint.sub(prevAllocPoint).add(_allocPoint);
        }
    }

    // Return reward multiplier over the given _from to _to block.
    function getMultiplier(uint256 _from, uint256 _to) public pure returns (uint256) {
        return _to.sub(_from); 
    }

    // View function to see pending KARAs on frontend.
    function pendingKARA(uint256 _pid, address _user) external view returns (uint256) {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][_user];
        uint256 accKARAPerShare = pool.accKARAPerShare;
        uint256 lpSupply = pool.lpToken.balanceOf(address(this));
        if (block.number > pool.lastRewardBlock && lpSupply != 0) {
            uint256 multiplier = getMultiplier(pool.lastRewardBlock, block.number);
            uint256 karaReward = multiplier.mul(karaPerBlock).mul(pool.allocPoint).div(totalAllocPoint);
            accKARAPerShare = accKARAPerShare.add(karaReward.mul(1e24).div(lpSupply));
        }
        return user.amount.mul(accKARAPerShare).div(1e24).sub(user.rewardDebt);
    }

    // Update reward variables for all pools. Be careful of gas spending!
    function massUpdatePools() public {
        uint256 length = poolInfo.length;
        for (uint256 pid = 0; pid < length; ++pid) {
            updatePool(pid);
        }
    }


    // Update reward variables of the given pool to be up-to-date.
    function updatePool(uint256 _pid) public {
        PoolInfo storage pool = poolInfo[_pid];
        if (block.number <= pool.lastRewardBlock) {
            return;
        }
        uint256 lpSupply = pool.lpToken.balanceOf(address(this));
        if (lpSupply == 0) {
            pool.lastRewardBlock = block.number;
            return;
        }
        uint256 multiplier = getMultiplier(pool.lastRewardBlock, block.number);
        uint256 karaReward = multiplier.mul(karaPerBlock).mul(pool.allocPoint).div(totalAllocPoint);
        // kara.mint(devaddr, karaReward.div(10));
        pool.accKARAPerShare = pool.accKARAPerShare.add(karaReward.mul(1e24).div(lpSupply));
        pool.lastRewardBlock = block.number;
    }

    // Deposit LP tokens to KaraFarm for KARA allocation.
    function deposit(uint256 _pid, uint256 _amount) public {

        require (_pid != 0, 'deposit KARA by staking');

        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        updatePool(_pid);
        if (user.amount > 0) {
            uint256 pending = user.amount.mul(pool.accKARAPerShare).div(1e24).sub(user.rewardDebt);
            if(pending > 0) {
                safeKARATransfer(msg.sender, pending);
            }
        }
        if (_amount > 0) {
            pool.lpToken.safeTransferFrom(address(msg.sender), address(this), _amount);
            if (user.amount == 0) {
                user.depositTime = block.timestamp;
            }  
            user.amount = user.amount.add(_amount);

        }
        user.rewardDebt = user.amount.mul(pool.accKARAPerShare).div(1e24);
        emit Deposit(msg.sender, _pid, _amount);
    }

    // Withdraw LP tokens from KaraFarm
    function withdraw(uint256 _pid, uint256 _amount) public {

        require (_pid != 0, 'withdraw KARA by unstaking');
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        require(user.amount >= _amount, "withdraw: not good");

        updatePool(_pid);
        uint256 pending = user.amount.mul(pool.accKARAPerShare).div(1e24).sub(user.rewardDebt);
        if(pending > 0) {
            safeKARATransfer(msg.sender, pending);
        }
        if(_amount > 0) {
            user.amount = user.amount.sub(_amount);
            uint256 feeAmount = _amount.mul(getWithdrawFeeRate(_pid)).div(1000);
            pool.lpToken.safeTransfer(address(msg.sender), _amount.sub(feeAmount));
            if (feeAmount > 0) {
                pool.lpToken.safeTransfer(devAddress, feeAmount);
            }
        }
        user.rewardDebt = user.amount.mul(pool.accKARAPerShare).div(1e24);
        emit Withdraw(msg.sender, _pid, _amount);
    }

    function getWithdrawFeeRate(uint256 _pid) public view returns(uint256) {
        UserInfo storage user = userInfo[_pid][msg.sender];
        uint256 duration = block.timestamp.sub(user.depositTime);
        if (duration <= 3600 * 24 * 7) {
            return 5;
        } else if (duration <= 3600 * 24 * 14) {
            return 4;
        } else if (duration <= 3600 * 24 * 30) {
            return 3;
        } else if (duration <= 3600 * 24 * 60) {
            return 2;
        } else {
            return 0;
        }
        
    }

    // Stake KARA tokens to KaraFarm
    function enterStaking(uint256 _amount) public {
        PoolInfo storage pool = poolInfo[0];
        UserInfo storage user = userInfo[0][msg.sender];
        updatePool(0);
        if (user.amount > 0) {
            uint256 pending = user.amount.mul(pool.accKARAPerShare).div(1e24).sub(user.rewardDebt);
            if(pending > 0) {
                safeKARATransfer(msg.sender, pending);
            }
        }
        if(_amount > 0) {
            pool.lpToken.safeTransferFrom(address(msg.sender), address(this), _amount);
            user.amount = user.amount.add(_amount);
        }
        user.rewardDebt = user.amount.mul(pool.accKARAPerShare).div(1e24);

        emit Deposit(msg.sender, 0, _amount);
    }

    // Withdraw KARA tokens from STAKING.
    function leaveStaking(uint256 _amount) public {
        PoolInfo storage pool = poolInfo[0];
        UserInfo storage user = userInfo[0][msg.sender];
        require(user.amount >= _amount, "withdraw: not good");
        updatePool(0);
        uint256 pending = user.amount.mul(pool.accKARAPerShare).div(1e24).sub(user.rewardDebt);
        if(pending > 0) {
            safeKARATransfer(msg.sender, pending);
        }
        if(_amount > 0) {
            user.amount = user.amount.sub(_amount);
            pool.lpToken.safeTransfer(address(msg.sender), _amount);
        }
        user.rewardDebt = user.amount.mul(pool.accKARAPerShare).div(1e24);

        emit Withdraw(msg.sender, 0, _amount);
    }

    // Withdraw without caring about rewards. EMERGENCY ONLY.
    function emergencyWithdraw(uint256 _pid) public {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        pool.lpToken.safeTransfer(address(msg.sender), user.amount);
        emit EmergencyWithdraw(msg.sender, _pid, user.amount);
        user.amount = 0;
        user.rewardDebt = 0;
    }

    // Safe KARA transfer function, just in case if rounding error causes pool to not have enough KARAs.
    function safeKARATransfer(address _to, uint256 _amount) internal {
        // send from reward pool
        uint256 karaBal = kara.balanceOf(address(rewardPool));
        if (_amount > karaBal) {
            kara.safeTransferFrom(rewardPool, _to, karaBal);
        } else {
            kara.safeTransferFrom(rewardPool, _to, _amount);
        }
    }

    // Update dev address by the previous dev.
    /*function dev(address _devaddr) public {
        require(msg.sender == devaddr, "dev: wut?");
        devaddr = _devaddr;
    }*/
}
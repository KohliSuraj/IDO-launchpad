// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

// TODO
// oversubscribed logic
// integration of ERC20 token contract via an exchange??
// test with proper exchange rate -> token allocation
// token withdrawal

contract Pool {
    using SafeMath for uint256;

    enum PoolStatus {
        UPCOMING,
        ONGOING,
        FINISHED
    }

    address public launchpadAddress;
    address public owner;
    uint256 public hardCap;

    uint256 public startTime;
    uint256 public endTime;

    IERC20 projectTokenAddress;
    PoolStatus public status;
    uint256 public exchangeRate;
    uint256 public totalRaised;

    // user mapped to whitelist
    mapping(address => bool) public whitelist;

    // investor mapped to balance
    mapping(address => uint256) public balanceOf;

    // investor mapped to token balance
    mapping(address => uint256) public tokenBalanceOf;

    // modifiers
    modifier onlyPoolOwner() {
        require(owner == msg.sender, "Not owner of Pool");
        _;
    }

    modifier canInvest() {
        require(
            whitelist[msg.sender] == true,
            "User not whitelisted for given Pool"
        );
        _;
    }

    modifier poolExists() {
        require(owner != address(0), "Pool doesnt exist");
        _;
    }

    modifier poolIsOnGoing() {
        require(status == PoolStatus.ONGOING, "Pool is not ONGOING");
        _;
    }

    modifier nonZero(uint256 _value) {
        require(_value > 0, "sender must send some ETH");
        _;
    }

    event PoolIsUpcoming();
    event PoolIsOngoing();
    event PoolIsFinished();

    constructor(
        address _poolOwner,
        uint256 _hardCap,
        uint256 _startTime,
        uint256 _endTime,
        IERC20 _projectTokenAddress,
        uint256 _exchangeRate
    ) {
        launchpadAddress = msg.sender;
        owner = _poolOwner;
        hardCap = _hardCap;

        startTime = _startTime;
        endTime = _endTime;

        projectTokenAddress = _projectTokenAddress;
        exchangeRate = _exchangeRate;

        emit PoolIsUpcoming();
    }

    // add users to pool whitelist
    function addAddressesToWhitelist(address[] memory _users)
        external
        onlyPoolOwner
    {
        require(_users.length > 0, "users list is empty");

        for (uint256 i = 0; i < _users.length; ++i) {
            whitelist[_users[i]] = true;
        }
    }

    // TESTING FUNCTION TO BE REMOVED
    function test() external {
        status = PoolStatus.ONGOING;
    }

    function updateStatus() external onlyPoolOwner {
        // update status of Pool depending on the block timestamps
        if (
            startTime < block.timestamp &&
            endTime > block.timestamp &&
            status == PoolStatus.UPCOMING
        ) {
            status = PoolStatus.ONGOING;
            emit PoolIsOngoing();
        } else if (endTime < block.timestamp && status == PoolStatus.ONGOING) {
            status == PoolStatus.FINISHED;
            emit PoolIsFinished();
        }
    }

    function invest()
        external
        payable
        poolExists
        poolIsOnGoing
        canInvest
        nonZero(msg.value)
    {
        uint256 _value = msg.value;

        // check Pool is not over subscribed
        totalRaised = totalRaised.add(_value);
        require(totalRaised <= hardCap, "Pool is oversubscribed");

        // store ETH for investor
        balanceOf[msg.sender] = balanceOf[msg.sender].add(_value);

        // track investor's token
        uint256 _tokenValue = _value * exchangeRate;
        tokenBalanceOf[msg.sender] = tokenBalanceOf[msg.sender].add(
            _tokenValue
        );
    }
}

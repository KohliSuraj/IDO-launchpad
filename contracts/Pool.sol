// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract Pool {
    using SafeMath for uint256;

    enum PoolStatus {
        UPCOMING,
        ONGOING,
        FINISHED
    }

    address private _launchpadAddress;
    address private _owner;
    uint256 private _hardCap;

    uint256 private _startTime;
    uint256 private _endTime;

    IERC20 private _projectTokenAddress;
    PoolStatus private _status;
    uint256 private _exchangeRate;
    uint256 private _totalRaised;

    // user mapped to whitelist
    mapping(address => bool) private _whitelist;

    // investor mapped to balance
    mapping(address => uint256) private _balanceOf;

    // investor mapped to token balance
    mapping(address => uint256) private _tokenBalanceOf;

    // modifiers
    modifier onlyPoolOwner() {
        require(_owner == msg.sender, "Not owner of Pool");
        _;
    }

    modifier whitelistedUser() {
        require(
            _whitelist[msg.sender] == true,
            "User not whitelisted for given Pool"
        );
        _;
    }

    modifier poolExists() {
        require(_owner != address(0), "Pool doesnt exist");
        _;
    }

    modifier poolIsOnGoing() {
        require(_status == PoolStatus.ONGOING, "Pool is not ONGOING");
        _;
    }

    modifier poolIsFinished() {
        require(_status == PoolStatus.FINISHED, "Pool is not FINISHED");
        _;
    }

    modifier nonZero(uint256 value) {
        require(value > 0, "sender must send some ETH");
        _;
    }

    event PoolIsUpcoming();
    event PoolIsOngoing();
    event PoolIsFinished();

    constructor(
        address poolOwner_,
        uint256 hardCap_,
        uint256 startTime_,
        uint256 endTime_,
        IERC20 projectTokenAddress_,
        uint256 exchangeRate_
    ) {
        _launchpadAddress = msg.sender;
        _owner = poolOwner_;
        _hardCap = hardCap_;

        _startTime = startTime_;
        _endTime = endTime_;

        _projectTokenAddress = projectTokenAddress_;
        _exchangeRate = exchangeRate_;

        emit PoolIsUpcoming();
    }

    // public getters
    function owner() public view returns (address) {
        return _owner;
    }

    function startTime() public view returns (uint256) {
        return _startTime;
    }

    function endTime() public view returns (uint256) {
        return _endTime;
    }

    function hardCap() public view returns (uint256) {
        return _hardCap;
    }

    function status() public view returns (uint256) {
        return uint256(_status);
    }

    function totalRaised() public view returns (uint256) {
        return _totalRaised;
    }

    function exchangeRate() public view returns (uint256) {
        return _exchangeRate;
    }

    function isWhitelisted(address addr_) public view returns (bool) {
        return _whitelist[addr_];
    }

    function balanceOf(address addr_) public view returns (uint256) {
        return _balanceOf[addr_];
    }

    function tokenBalanceOf(address addr_) public view returns (uint256) {
        return _tokenBalanceOf[addr_];
    }

    // Pool must be created i.e. Pool contract must exist
    function addAddressesToWhitelist(address[] memory users)
        external
        poolExists
        onlyPoolOwner
        returns (bool)
    {
        require(users.length > 0, "users list is empty");

        for (uint256 i = 0; i < users.length; ++i) {
            _whitelist[users[i]] = true;
        }
        return true;
    }

    function updateStatus() external onlyPoolOwner returns (bool) {
        // update status of Pool depending on the block timestamps
        if (
            _startTime < block.timestamp &&
            _endTime > block.timestamp &&
            _status == PoolStatus.UPCOMING
        ) {
            _status = PoolStatus.ONGOING;
            emit PoolIsOngoing();
            return true;
        } else if (
            _endTime < block.timestamp && _status == PoolStatus.ONGOING
        ) {
            _status = PoolStatus.FINISHED;
            emit PoolIsFinished();
            return true;
        }
        return false;
    }

    function invest()
        external
        payable
        poolExists
        poolIsOnGoing
        whitelistedUser
        nonZero(msg.value)
        returns (bool)
    {
        uint256 value = msg.value;
        uint256 tokenValue = value * _exchangeRate;

        // check project token balance, this contract must have allowance to spend atleast tokenValue
        require(
            (IERC20(_projectTokenAddress).allowance(_owner, address(this))) >=
                tokenValue,
            "Not enough allowance for project tokens"
        );

        // check Pool is not over subscribed
        require(_totalRaised.add(value) <= _hardCap, "Pool is oversubscribed");

        _totalRaised = _totalRaised.add(value);
        _balanceOf[msg.sender] = _balanceOf[msg.sender].add(value);
        _tokenBalanceOf[msg.sender] = _tokenBalanceOf[msg.sender].add(
            tokenValue
        );
        return true;
    }

    // once pool has ended
    // investor can withdraw all tokens present in _tokenBalanceOf[investor]
    function withdraw() external poolIsFinished whitelistedUser returns (bool) {
        uint256 tokenBalance = _tokenBalanceOf[msg.sender];
        require(tokenBalance > 0, "No amount present to withdraw");

        // check spending allowance of this contract for pool owners tokens
        require(
            (IERC20(_projectTokenAddress).allowance(_owner, address(this))) >=
                tokenBalance,
            "Not enough allowance for project tokens"
        );

        _tokenBalanceOf[msg.sender] = 0;

        IERC20(_projectTokenAddress).transferFrom(
            _owner,
            msg.sender,
            tokenBalance
        );

        return true;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

import "./Pool.sol";

contract IDOLaunchpad {
    using SafeMath for uint256;

    string private _name;
    uint256 private _nextPoolId;

    // pool id mapped to pool address
    mapping(uint256 => address) private pools;

    event PoolCreated(uint256 poolId, address poolOwner);

    constructor(string memory name_) {
        _name = name_;
    }

    function name() public view returns (string memory) {
        return _name;
    }

    function getPoolAddress(uint256 poolId) public view returns (address) {
        return pools[poolId];
    }

    // user role --> Adminstrator, Pool owner, Investor

    // exchange rate is basically the rate at which tokens are offered per 1 eth
    function createPool(
        uint256 hardCap,
        uint256 startTime,
        uint256 endTime,
        IERC20 projectTokenAddress,
        uint256 exchangeRate
    ) external returns (address poolAddress) {
        require(startTime >= block.timestamp, "start time is in the past");
        require(endTime >= startTime, "end time is less than the start time");
        require(hardCap > 0, "harcap cannot be 0");

        address poolOwner = msg.sender;

        Pool pool = new Pool(
            poolOwner,
            hardCap,
            startTime,
            endTime,
            projectTokenAddress,
            exchangeRate
        );
        poolAddress = address(pool);

        // index starting from 1
        _nextPoolId = _nextPoolId.add(1);
        pools[_nextPoolId] = poolAddress;
        emit PoolCreated(_nextPoolId, poolOwner);
    }
}

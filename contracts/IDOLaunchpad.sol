// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

import "./Pool.sol";

contract IDOLaunchpad {
    using SafeMath for uint256;

    string public name = "IDO Launchpad";
    uint256 public nextPoolId;

    // pool id mapped to pool address
    mapping(uint256 => address) public pools;

    event PoolCreated(uint256 poolId, address poolOwner);

    // user role --> Adminstrator, Pool owner, Investor

    // exchange rate is basically the rate at which tokens are offered per 1 eth
    function createPool(
        uint256 _hardCap,
        uint256 _startTime,
        uint256 _endTime,
        IERC20 _projectTokenAddress,
        uint256 _exchangeRate
    ) external returns (address _poolAddress) {
        require(_startTime >= block.timestamp, "start time is in the past");
        require(_endTime >= _startTime, "end time is less than the start time");
        require(_hardCap > 0, "harcap cannot be 0");

        address _poolOwner = msg.sender;

        Pool _pool = new Pool(
            _poolOwner,
            _hardCap,
            _startTime,
            _endTime,
            _projectTokenAddress,
            _exchangeRate
        );
        _poolAddress = address(_pool);

        // index starting from 1
        nextPoolId = nextPoolId.add(1);
        pools[nextPoolId] = _poolAddress;
        emit PoolCreated(nextPoolId, _poolOwner);
    }
}

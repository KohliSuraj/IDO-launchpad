// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
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

    // who can call this function?? --> anyone
    // what amount will pool owner invest in this? --> None
    function createPool(
        uint256 _hardCap,
        uint256 _startDateTime,
        uint256 _endDateTime,
        uint256 _exchangeRate
    ) external returns (address _poolAddress) {
        // project token address --> this is the IERC20 token --> ONLY IERC20 Token Owner can create POOL FOR THIS IERC20 TOKEN
        // how will this code validate the the msg.sender has access to the IERC20 projectTokenAddress
        ERC20 token = ERC20(address(0));

        address _poolOwner = msg.sender;

        Pool _pool = new Pool(_poolOwner, _hardCap, _startDateTime, _endDateTime, token, _exchangeRate);
        _poolAddress = address(_pool);

        // index starting from 1
        nextPoolId = nextPoolId.add(1);
        pools[nextPoolId] = _poolAddress;
        emit PoolCreated(nextPoolId, _poolOwner);
    }
}

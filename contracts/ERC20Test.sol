// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract ERC20Test is ERC20('TEST TOKEN', 'TST') {
    constructor() {
        // if 1 token is 1000000000000000000 token bits
        // we are minting 1,000,000 tokens i.e. 1000000000000000000000000
        _mint(msg.sender, 1000000000000000000000000);
    }
}

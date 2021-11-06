# IDO-launchpad

## Intro
IDO Launchpad

There are three user roles: Administrator, Pool Owner, and Investor
 
This code implements an IDO Launchpad which enables:

- Administrator to control the IDO Launchpad
- Pool Owners to create new pools to raise investments
  - A Pool has a start / end date
  - A pool points to the project / ERC20 token which is raising investment
  - A pool by default is in status UPCOMING
  - Once the pool starts, it transitions to status ONGOING
- Allows Pool Owners to manage a users whitelist (i.e. potential investor)
- Whitelisted users can invest in any of the Pool
- Once, the Pool is FINISHED then investors can withdraw tokens

## Test the app

You can test the app by running following commands:
- `yarn install`
- `yarn devnet`
- `yarn test`

## Commands

* `yarn install` - install dependencies
* `yarn devnet` - run a local [ganache](https://www.trufflesuite.com/ganache) instance to deploy the contracts
* `yarn compile` - compile the code
* `yarn test` - run the tests
* `yarn deploy` - deploy compiled code to local testnet
* `yarn clean` - cleans the contract build files
* `yarn console` - opens truffle console

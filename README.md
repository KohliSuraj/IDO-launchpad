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

## Assumptions

- All amounts are 18 decimals

- Exchange rate is basically the rate at which tokens are offered per 1 eth
  - e.g. for an exchange rate of 10,000
  - investor will get 10,000 tokens for 1 eth
  - investor will get 100 tokens for 0.01 eth
  - investor will get 1 token for 0.0001 eth

- Anyone can be a Pool Owner as long as they provide a valid ERC20 project address
  - This can be restricted by adding a new whitelist in IDO Launchpad contract
  - Also, allowance check of a certain amount of tokens at Pool Creation can also be implemented

- The Allowance of ERC20 tokens to the Pool Contract is verified at the time the investor makes the investment
  - As of now, there is no check to verify if Project Owner makes allowance '0', after investments into the Pool
  
- At withdrawal, the investor can withdraw full token balance (no option for partial withdrawal)

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

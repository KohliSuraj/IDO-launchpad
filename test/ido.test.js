const web3 = require('web3')

const chai = require('chai')
const chaiAsPromised = require('chai-as-promised')
chai.use(chaiAsPromised)
const should = chai.should()

const IDOLaunchpad = artifacts.require('./IDOLaunchpad')
const Pool = artifacts.require('./Pool')
const ERC20Test = artifacts.require('./ERC20Test')

const getString = async (val) => await val.toString()
const getEtherValue = (val) => web3.utils.toWei(val.toString(), 'ether')
const getTime = (futureSeconds) => Number.parseInt((Date.now() + (1000 * futureSeconds)) / 1000).toString()

contract('IDO Launchpad', accounts => {
    let ido
    let erc20
    //  this is what's minted by the ERC20Test contract
    const erc20Balance = '1000000000000000000000000'
    let erc20address

    let administrator = accounts[9]
    let poolOwner = accounts[1]
    let investor = accounts[2]

    let poolId
    let poolAddress
    let poolInstance
    let startTime
    let endTime
    // 10,000 tokens for each ether
    const exchangeRate = 10000

    before(async () => {
        ido = await IDOLaunchpad.new("IDO Launchpad", { from: administrator })
        erc20 = await ERC20Test.new({ from: poolOwner })
        erc20address = erc20.address
        console.log('Deploying IDO and ERC20 contracts')
    })

    it('has default values', async () => {
        await ido.name().should.eventually.eq('IDO Launchpad')
        await ido.admin().should.eventually.eq(administrator)

        getString(await erc20.balanceOf(poolOwner)).should.eventually.eq(erc20Balance)
        getString(await erc20.name()).should.eventually.eq('TEST TOKEN')
        getString(await erc20.symbol()).should.eventually.eq('TST')
    })

    it('can create a new Pool', async () => {
        // Pool is in ONGOING status for 4 seconds
        startTime = getTime(1)
        endTime = getTime(5)
        const txnReceipt = await ido.createPool(getEtherValue(10), startTime, endTime, erc20address, exchangeRate, { from: poolOwner })
        const args = txnReceipt.logs[0].args

        poolId = args['0'].toNumber()
        poolId.should.eq(1)

        const _poolOwner = args['1']
        _poolOwner.should.eq(poolOwner)

        poolAddress = await ido.getPoolAddress(poolId)
    })

    describe('Once Pool Created', () => {

        before(async () => {
            poolInstance = await Pool.at(poolAddress)
            await poolInstance.owner().should.eventually.eq(poolOwner)
            await erc20.approve(poolAddress, erc20Balance, { from: poolOwner })
            console.log('Saving pool instance and giving allowance for future use')
        })

        it('check erc20 token allowance', async () => {
            getString(await erc20.balanceOf(poolOwner)).should.eventually.eq(erc20Balance)
            getString(await erc20.allowance(poolOwner, poolAddress)).should.eventually.eq(erc20Balance)
        })

        it('can access newly deployed Pool Contract', async () => {
            getString(await poolInstance.hardCap()).should.eventually.eq(getEtherValue(10))
            getString(await poolInstance.startTime()).should.eventually.eq(startTime)
            getString(await poolInstance.endTime()).should.eventually.eq(endTime)
            getString(await poolInstance.exchangeRate()).should.eventually.eq(exchangeRate.toString())
            getString(await poolInstance.status()).should.eventually.eq(Pool.PoolStatus.UPCOMING.toString())
        })

        it('can add addresses to whitelist', async () => {
            // rejected, since only pool owner can call this function
            await poolInstance.addAddressesToWhitelist([investor], { from: investor }).should.be.rejected
            await poolInstance.isWhitelisted(investor).should.eventually.eq(false)

            await poolInstance.addAddressesToWhitelist([investor, accounts[3]], { from: poolOwner })
            await poolInstance.isWhitelisted(investor).should.eventually.eq(true)
            await poolInstance.isWhitelisted(accounts[3]).should.eventually.eq(true)
        })

        it('can change status of pool to ONGOING', async () => {
            // rejected, since pool has status UPCOMING
            await poolInstance.invest({ value: getEtherValue(0.1) }).should.be.rejected

            console.log("Test case waiting for Pool to reach status ONGOING");
            // sleep so that the pool start time is in the past
            await new Promise(r => setTimeout(r, 1000))

            await poolInstance.updateStatus().should.be.rejected
            await poolInstance.updateStatus({ from: poolOwner })
            getString(await poolInstance.status()).should.eventually.eq(Pool.PoolStatus.ONGOING.toString())
        })

        it('cannot invest in Pool if user is not whitelisted', async () => {
            await poolInstance.invest({ value: getEtherValue(1) }).should.be.rejected
            await poolInstance.invest({ value: getEtherValue(1), from: poolOwner }).should.be.rejected
            getString(await poolInstance.totalRaised()).should.eventually.eq('0')
        })

        it('can invest in Pool', async () => {
            await poolInstance.invest({ value: getEtherValue(1), from: investor })
            getString(await poolInstance.totalRaised()).should.eventually.eq(getEtherValue(1))
            getString(await poolInstance.balanceOf(investor)).should.eventually.eq(getEtherValue(1))
            getString(await poolInstance.tokenBalanceOf(investor)).should.eventually.eq(getEtherValue(1 * exchangeRate))
        })

        it('cannot invest 0 value in Pool', async () => {
            await poolInstance.invest({ value: getEtherValue(0), from: investor }).should.be.rejected
        })

        it('cannot invest in Pool if its being oversubscribed', async () => {
            //  hardcap is 10
            await poolInstance.invest({ value: getEtherValue(20), from: investor }).should.be.rejected
        })

        it('can invest in Pool (fractional value)', async () => {
            await poolInstance.invest({ value: getEtherValue(0.0001), from: accounts[3] })

            getString(await poolInstance.totalRaised()).should.eventually.eq(getEtherValue(1 + 0.0001))
            getString(await poolInstance.balanceOf(accounts[3])).should.eventually.eq(getEtherValue(0.0001))
            getString(await poolInstance.tokenBalanceOf(accounts[3])).should.eventually.eq(getEtherValue(0.0001 * exchangeRate))
        })

        describe('Once Invested', () => {
            it('investor cannot withdraw if pool not FINISHED', async () => {
                await poolInstance.withdraw().should.be.rejected
            })

            it('Pool contract status changes to FINISHED after expiry', async () => {
                // sleep so that the pool end time is in the past
                console.log("Test case waiting for Pool to reach status FINISHED");
                await new Promise(r => setTimeout(r, 5000))

                await poolInstance.updateStatus({ from: poolOwner })
                getString(await poolInstance.status()).should.eventually.eq(Pool.PoolStatus.FINISHED.toString())
            })

            it('only whitelisted user can withdraw', async () => {
                getString(await poolInstance.tokenBalanceOf(investor)).should.eventually.eq(getEtherValue(1 * exchangeRate))
                await poolInstance.withdraw().should.be.rejected

                // token balance is 0 before withdrawing
                getString(await erc20.balanceOf(investor)).should.eventually.eq(getEtherValue(0))
                await poolInstance.withdraw({ from: investor })
                // token balance is 10,000 tokens after withdrawing
                getString(await erc20.balanceOf(investor)).should.eventually.eq(getEtherValue(10000))
            })

            it('investor can withdraw only once, since transfer is already made and balance is 0', async () => {
                getString(await erc20.balanceOf(investor)).should.eventually.eq(getEtherValue(10000))
                getString(await poolInstance.tokenBalanceOf(investor)).should.eventually.eq(getEtherValue(0))
                await poolInstance.withdraw({ from: investor }).should.be.rejected
            })

        })
    })

})
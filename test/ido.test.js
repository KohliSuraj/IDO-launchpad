const web3 = require('web3');

const chai = require('chai');
const chaiAsPromised = require("chai-as-promised");
//
// const BN = web3.utils.toBN;
// chai.use(require('bn-chai')(BN));
chai.use(chaiAsPromised);
//
const should = chai.should();

const IDOLaunchpad = artifacts.require("./IDOLaunchpad");
const Pool = artifacts.require("./Pool");

const getString = async (val) => await val.toString()
const getEther = (val) => web3.utils.toWei(val.toString(), 'ether')
const getTime = (futureSeconds) => Number.parseInt((Date.now() + (1000 * futureSeconds)) / 1000).toString()

contract('IDO Launchpad', accounts => {
    let ido
    let administrator = accounts[9]
    let poolOwner = accounts[1]
    let whitelistedUser = accounts[2]
    let poolId
    let poolAddress
    let poolInstance
    let startTime
    let endTime

    beforeEach(async () => {
        ido = await IDOLaunchpad.new({ from: administrator })
    })

    it('has default values', async () => {
        await ido.name().should.eventually.eq('IDO Launchpad')
    })

    it('can create a new Pool', async () => {
        startTime = getTime(1)
        endTime = getTime(240)
        const txnReceipt = await ido.createPool(getEther(1), startTime, endTime, 1, { from: poolOwner })
        const args = txnReceipt.logs[0].args

        poolId = args['0'].toNumber()
        poolId.should.eq(1)

        const _poolOwner = args['1']
        _poolOwner.should.eq(poolOwner)

        poolAddress = await ido.pools(poolId)
    })

    describe("Once Pool Created", () => {

        beforeEach(async () => {
            poolInstance = await Pool.at(poolAddress);
            await poolInstance.owner().should.eventually.eq(poolOwner)
        })

        it('can access newly deployed Pool Contract', async () => {
            getString(await poolInstance.hardCap()).should.eventually.eq(getEther(1))
            getString(await poolInstance.startTime()).should.eventually.eq(startTime)
            getString(await poolInstance.endTime()).should.eventually.eq(endTime)
            getString(await poolInstance.exchangeRate()).should.eventually.eq('1')
            getString(await poolInstance.status()).should.eventually.eq(Pool.PoolStatus.UPCOMING.toString())
        })

        it('can add addresses to whitelist', async () => {
            // rejected, since only pool owner can call this function
            await poolInstance.addAddressesToWhitelist([whitelistedUser], { from: whitelistedUser }).should.be.rejected
            await poolInstance.whitelist(whitelistedUser).should.eventually.eq(false)

            await poolInstance.addAddressesToWhitelist([whitelistedUser], { from: poolOwner })
            await poolInstance.whitelist(whitelistedUser).should.eventually.eq(true)
        })

        it('can change status of pool to ONGOING', async () => {
            // rejected, since pool has status UPCOMING
            await poolInstance.invest({ value: getEther(0.1) }).should.be.rejected

            // sleep so that the pool start time is in the past
            await new Promise(r => setTimeout(r, 1000));

            await poolInstance.updateStatus().should.be.rejected
            await poolInstance.updateStatus({ from: poolOwner })
            getString(await poolInstance.status()).should.eventually.eq(Pool.PoolStatus.ONGOING.toString())
        })

        it('can invest in Pool', async () => {
            // rejected, since only whitelisted user can invest
            await poolInstance.invest({ value: getEther(0.1) }).should.be.rejected
            await poolInstance.invest({ value: getEther(0.1), from: poolOwner }).should.be.rejected

            getString(await poolInstance.totalRaised()).should.eventually.eq('0')
            await poolInstance.invest({ value: getEther(0.1), from: whitelistedUser })
            getString(await poolInstance.totalRaised()).should.eventually.eq(getEther(0.1))
        })

        it('cannot invest in Pool if oversubscribed', async () => {
            await poolInstance.invest({ value: getEther(1), from: whitelistedUser }).should.be.rejected
        })
    })

})
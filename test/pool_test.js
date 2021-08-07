const Pin = artifacts.require('dummy/Pin.sol');
const Zrx = artifacts.require('dummy/Zrx.sol');
const Exc = artifacts.require('Exc.sol');
const Fac = artifacts.require('Factory.sol')
const Pool = artifacts.require('Pool.sol')

const SIDE = {
    BUY: 0,
    SELL: 1
};

contract('Pool', (accounts) => {
    let pin, zrx, exc;
    const [trader1, trader2] = [accounts[1], accounts[2]];
    const [PIN, ZRX] = ['PIN', 'ZRX']
        .map(ticker => web3.utils.fromAscii(ticker));

    beforeEach(async() => {
        ([pin, zrx] = await Promise.all([
            Pin.new(),
            Zrx.new()
        ]));
        exc = await Exc.new();
        fac = await Fac.new()
    });

    it('create the pair and deposit into pool', async () => {
        let event = await fac.createPair(
            pin.address,
            zrx.address,
            pin.address,
            exc.address,
            PIN,
            ZRX
        );
        let log = event.logs[0];
        let poolAd = log.args.pair;
        const pool = await Pool.at(poolAd);
        // give both traders a bunch of shit
        await pin.mint(trader1, 10000);
        await pin.approve(pool.address, 10000, {from: trader1});

        await zrx.mint(trader1, 10000);
        await zrx.approve(pool.address, 10000, {from: trader1});

        await pool.deposit(10000, 10000, {from: trader1});

        const buyOrders = await exc.getOrders(ZRX, 0);
        const sellOrders = await exc.getOrders(ZRX, 1);
        assert.equal(buyOrders.length, 1);
        assert.equal(sellOrders.length, 1);
        const poolPINBal = await exc.traderBalances.call(pool.address, PIN);
        const poolZRXBal = await exc.traderBalances.call(pool.address, ZRX);
        assert.equal(parseInt(poolPINBal), 10000);
        assert.equal(parseInt(poolZRXBal), 10000);
    });

    it('deposit into pool then make market order against pool limit order', async () => {
        let event = await fac.createPair(
            pin.address,
            zrx.address,
            pin.address,
            exc.address,
            PIN,
            ZRX
        );
        let log = event.logs[0];
        let poolAd = log.args.pair;
        const pool = await Pool.at(poolAd);
        // give both traders a bunch of shit
        await pin.mint(trader1, 10000);
        await pin.approve(pool.address, 10000, {from: trader1});

        await zrx.mint(trader1, 10000);
        await zrx.approve(pool.address, 10000, {from: trader1});

        await pin.mint(trader2, 10000);
        await pin.approve(exc.address, 10000, {from: trader2});

        await zrx.mint(trader2, 10000);
        await zrx.approve(exc.address, 10000, {from: trader2});
        
        await pool.deposit(10000, 10000, {from: trader1});
        await exc.deposit(10000, PIN, {from: trader2});

        let sellOrders = await exc.getOrders(ZRX, 1);
        assert.equal(sellOrders[0].amount, 10000);
        await exc.makeMarketOrder(ZRX, 5000, 0, {from: trader2});
        sellOrders = await exc.getOrders(ZRX, 1);
        assert.equal(sellOrders[0].filled, 5000);
    });

    it('deposit into pool then withdraw', async () => {
        let event = await fac.createPair(
            pin.address,
            zrx.address,
            pin.address,
            exc.address,
            PIN,
            ZRX
        );
        let log = event.logs[0];
        let poolAd = log.args.pair;
        const pool = await Pool.at(poolAd);
        // give both traders a bunch of shit
        await pin.mint(trader1, 10000);
        await pin.approve(pool.address, 10000, {from: trader1});

        await zrx.mint(trader1, 10000);
        await zrx.approve(pool.address, 10000, {from: trader1});

        await pool.deposit(10000, 10000, {from: trader1});
        let buyOrders = await exc.getOrders(ZRX, 0);
        const sellOrders = await exc.getOrders(ZRX, 1);
        assert.equal(buyOrders.length, 1);
        assert.equal(sellOrders.length, 1);
        const firstPrice = buyOrders[0].price;

        await pool.withdraw(5000, 0, {from: trader1});
        buyOrders = await exc.getOrders(ZRX, 0);
        assert(firstPrice != buyOrders[0].price);
    });
});
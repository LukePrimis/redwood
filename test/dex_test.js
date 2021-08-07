const { expectRevert } = require('@openzeppelin/test-helpers');
const Pin = artifacts.require('dummy/Pin.sol');
const Zrx = artifacts.require('dummy/Zrx.sol');
const Exc = artifacts.require('Exc.sol');

const SIDE = {
    BUY: 0,
    SELL: 1
};

contract('Exc', (accounts) => {
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
    });

    it('add a token to exchange', async () => {
        await exc.addToken(PIN, pin.address);
        let tokenList = await exc.getTokens();
        assert.equal(tokenList.length, 1);
    });

    it('add multiple tokens to exchange', async () => {
        await exc.addToken(PIN, pin.address);
        await exc.addToken(ZRX, zrx.address);
        let tokenList = await exc.getTokens();
        assert(tokenList.length, 2);
    })

    it('deposit single token', async () => {
        await exc.addToken(PIN, pin.address);
        await pin.mint(trader1, 10000);
        await pin.approve(exc.address, 10000, {from: trader1});
        await exc.deposit(10000, PIN, {from: trader1});
        const pinBalance = await exc.traderBalances.call(trader1, PIN);
        assert.equal(parseInt(pinBalance), 10000);
    })

    it('multiple deposit tokens and traders single token', async () => {
        await exc.addToken(PIN, pin.address);
        await exc.addToken(ZRX, zrx.address);

        await pin.mint(trader1, 10000);
        await pin.approve(exc.address, 10000, {from: trader1});
        await exc.deposit(2000, PIN, {from: trader1});

        await zrx.mint(trader2, 10000);
        await zrx.approve(exc.address, 10000, {from: trader2});
        await exc.deposit(2000, ZRX, {from: trader2});

        await zrx.mint(trader1, 10000);
        await zrx.approve(exc.address, 10000, {from: trader1});
        await exc.deposit(3500, ZRX, {from: trader1});
        await exc.deposit(1000, PIN, {from: trader1});
        
        const pinBalance1 = await exc.traderBalances.call(trader1, PIN);
        const zrxBalance1 = await exc.traderBalances.call(trader1, ZRX);
        const zrxbalance2 = await exc.traderBalances.call(trader2, ZRX);
        assert.equal(parseInt(pinBalance1), 3000);
        assert.equal(parseInt(zrxBalance1), 3500);
        assert.equal(parseInt(zrxbalance2), 2000);
    })

    it('withdrawal', async() => {
        await exc.addToken(PIN, pin.address);
        await exc.addToken(ZRX, zrx.address);

        await pin.mint(trader1, 10000);
        await pin.approve(exc.address, 10000, {from: trader1});
        await exc.deposit(2000, PIN, {from: trader1});

        await zrx.mint(trader2, 10000);
        await zrx.approve(exc.address, 10000, {from: trader2});
        await exc.deposit(2000, ZRX, {from: trader2});

        await zrx.mint(trader1, 10000);
        await zrx.approve(exc.address, 10000, {from: trader1});
        await exc.deposit(3500, ZRX, {from: trader1});
        await exc.deposit(1000, PIN, {from: trader1});

        await exc.withdraw(2000, PIN, {from: trader1});
        await exc.withdraw(500, ZRX, {from: trader2})
     
        const pinBalance1 = await exc.traderBalances.call(trader1, PIN);
        const zrxbalance2 = await exc.traderBalances.call(trader2, ZRX);
        assert.equal(parseInt(pinBalance1), 1000);
        assert.equal(parseInt(zrxbalance2), 1500);
    });

    it('make multiple limit orders', async () => {
        await exc.addToken(PIN, pin.address);
        await exc.addToken(ZRX, zrx.address);
        
        await pin.mint(trader1, 10000);
        await pin.approve(exc.address, 10000, {from: trader1});

        await pin.mint(trader2, 10000);
        await pin.approve(exc.address, 10000, {from: trader2});
       
        await exc.deposit(10000, PIN, {from: trader1});
        await exc.makeLimitOrder(ZRX, 100, 10, 0, {from: trader1});

        await exc.deposit(10000, PIN, {from: trader2});
        await exc.makeLimitOrder(ZRX, 100, 9, 0, {from: trader2});

        const orders = await exc.getOrders(ZRX, 0);
        assert.equal(orders.length, 2);
        assert.equal(orders[0].price, 10);
    });

    it('make multiple limit orders then delete one', async () => {
        await exc.addToken(PIN, pin.address);
        await exc.addToken(ZRX, zrx.address);
        
        await pin.mint(trader1, 10000);
        await pin.approve(exc.address, 10000, {from: trader1});

        await pin.mint(trader2, 10000);
        await pin.approve(exc.address, 10000, {from: trader2});
       
        await exc.deposit(10000, PIN, {from: trader1});
        await exc.makeLimitOrder(ZRX, 100, 10, 0, {from: trader1});

        await exc.deposit(10000, PIN, {from: trader2});
        await exc.makeLimitOrder(ZRX, 100, 9, 0, {from: trader2});

        await exc.deleteLimitOrder(0, ZRX, 0, {from: trader1});
        const orders = await exc.getOrders(ZRX, 0);
        assert.equal(orders.length, 1);
    });

    it('make multiple limit orders then delete both', async () => {
        await exc.addToken(PIN, pin.address);
        await exc.addToken(ZRX, zrx.address);
        
        await pin.mint(trader1, 10000);
        await pin.approve(exc.address, 10000, {from: trader1});

        await pin.mint(trader2, 10000);
        await pin.approve(exc.address, 10000, {from: trader2});
       
        await exc.deposit(10000, PIN, {from: trader1});
        await exc.makeLimitOrder(ZRX, 100, 10, 0, {from: trader1});

        await exc.deposit(10000, PIN, {from: trader2});
        await exc.makeLimitOrder(ZRX, 100, 9, 0, {from: trader2});

        await exc.deleteLimitOrder(0, ZRX, 0, {from: trader1});
        await exc.deleteLimitOrder(1, ZRX, 0, {from: trader2});
        const orders = await exc.getOrders(ZRX, 0);
        assert.equal(orders.length, 0);
    });

    it('no deleting limit order if not original trader', async () => {
        await exc.addToken(PIN, pin.address);
        await exc.addToken(ZRX, zrx.address);
        
        await pin.mint(trader1, 10000);
        await pin.approve(exc.address, 10000, {from: trader1});

        await pin.mint(trader2, 10000);
        await pin.approve(exc.address, 10000, {from: trader2});
       
        await exc.deposit(10000, PIN, {from: trader1});
        await exc.makeLimitOrder(ZRX, 100, 10, 0, {from: trader1});

        await expectRevert(exc.deleteLimitOrder(0, ZRX, 0, {from: trader2}), 'deleter was not trader');
    });

    it('no limit order with insufficient funds', async () => {
        await exc.addToken(PIN, pin.address);
        await exc.addToken(ZRX, zrx.address);
        await expectRevert(exc.makeLimitOrder(ZRX, 100, 10, 0, {from: trader1}), 'insufficient funds to buy');
    });

    it('make market order against one limit', async () => {
        await exc.addToken(PIN, pin.address);
        await exc.addToken(ZRX, zrx.address);
        
        await pin.mint(trader1, 10000);
        await pin.approve(exc.address, 10000, {from: trader1});

        await zrx.mint(trader2, 10000);
        await zrx.approve(exc.address, 10000, {from: trader2});
       
        await exc.deposit(10000, PIN, {from: trader1});
        await exc.makeLimitOrder(ZRX, 100, 10, 0, {from: trader1});

        await exc.deposit(10000, ZRX, {from: trader2});
        await exc.makeMarketOrder(ZRX, 100, 1, {from: trader2});

        const pinBalance1 = await exc.traderBalances.call(trader1, PIN);
        const zrxBalance1 = await exc.traderBalances.call(trader1, ZRX);
        const zrxbalance2 = await exc.traderBalances.call(trader2, ZRX);
        assert.equal(pinBalance1, 9000);
        assert.equal(zrxBalance1, 100);
        assert.equal(zrxbalance2, 9900);
    });

    it('make market order against multiple limits', async () => {
        await exc.addToken(PIN, pin.address);
        await exc.addToken(ZRX, zrx.address);
        
        await pin.mint(trader1, 10000);
        await pin.approve(exc.address, 10000, {from: trader1});

        await zrx.mint(trader2, 10000);
        await zrx.approve(exc.address, 10000, {from: trader2});
       
        await exc.deposit(10000, PIN, {from: trader1});
        await exc.makeLimitOrder(ZRX, 2, 10, 0, {from: trader1});
        await exc.makeLimitOrder(ZRX, 8, 11, 0, {from: trader1});
        await exc.makeLimitOrder(ZRX, 90, 10, 0, {from: trader1});

        await exc.deposit(10000, ZRX, {from: trader2});
        await exc.makeMarketOrder(ZRX, 100, 1, {from: trader2});

        const orders = await exc.getOrders(ZRX, 0);
        assert.equal(orders.length, 0);
        const pinBalance1 = await exc.traderBalances.call(trader1, PIN);
        const zrxBalance1 = await exc.traderBalances.call(trader1, ZRX);
        const zrxbalance2 = await exc.traderBalances.call(trader2, ZRX);
        assert.equal(pinBalance1, 8992);
        assert.equal(zrxBalance1, 100);
        assert.equal(zrxbalance2, 9900);
    });
});
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
    console.log(trader1);
    const [PIN, ZRX] = ['PIN', 'ZRX']
        .map(ticker => web3.utils.fromAscii(ticker));

    beforeEach(async() => {
        ([pin, zrx] = await Promise.all([
            Pin.new(),
            Zrx.new()
        ]));
        exc = await Exc.new();
    });

    it('add PIN and ZRX to exchange', async () => {
        let event = await exc.addToken(PIN, pin.address);
        let tokenList = await exc.getTokens();
        console.log(tokenList);
        assert(tokenList.length, 1);
        assert(tokenList[0].ticker, PIN);
    });

    it('add ZRX to exchange', async () => {
        let event = await exc.addToken(ZRX, zrx.address);
        let tokenList = await exc.getTokens();
        console.log(tokenList);
        assert(tokenList.length, 2);
    })

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

        await exc.deleteLimitOrder(0, ZRX, 0, {from: trader1});
        // await exc.withdraw(100, PIN, {sender: accounts[0]});
        // assert(exc.traderBalances[accounts[0]][PIN], 100);
    });
});
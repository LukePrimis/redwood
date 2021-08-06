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

    it('add PIN to exchange', async () => {
        let event = await exc.addToken(PIN, pin.address);
        let tokenList = await exc.getTokens();
        assert(tokenList.length, 1);
        assert(tokenList[0].ticker, PIN);
    });

    it('add ZRX to exchange', async () => {
        let event = await exc.addToken(ZRX, zrx.address);
        let tokenList = await exc.getTokens();
        assert(tokenList.length, 2);
    })

    it('make multiple limit orders', async () => {
        await pin.mint(trader1, 10000);
        let b = await pin.balanceOf(trader1);
        assert(b, 10000);
    });
});
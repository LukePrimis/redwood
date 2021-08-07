pragma solidity 0.5.3;

import './Exc.sol';
import './IExc.sol';
// import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/solc-0.6/contracts/math/SafeMath.sol";
import '../contracts/libraries/math/SafeMath.sol';
import '../contracts/libraries/token/ERC20/IERC20.sol';

contract Pool {
    using SafeMath for uint;
    
    /// @notice some parameters for the pool to function correctly
    address private factory;
    address private tokenP;
    address private token1;
    address private dex;
    bytes32 private tokenPT;
    bytes32 private token1T;
    
    uint private totalPine;
    uint private totalToken;
    
    uint private lastSellOrderID;
    uint private lastBuyOrderID;
    bool private orderPlaced;
    
    // todo: create wallet data structures
    mapping(address => mapping(bytes32 => uint)) public traderBalances;

    // todo: fill in the initialize method, which should simply set the parameters of the contract correctly. To be called once
    // upon deployment by the factory.
    //whichP => which is pine
    function initialize(address _token0, address _token1, address _dex, uint whichP, bytes32 _tickerQ, bytes32 _tickerT)
    external {
        tokenP = _token0;
        token1 = _token1;
        dex = _dex;
        tokenPT = _tickerQ;
        token1T = _tickerT;
        totalPine = 0;
        totalToken = 0;
        lastSellOrderID = 0;
        lastBuyOrderID = 0;
        orderPlaced = false;
        IExc(dex).addToken(token1T, token1);
        IExc(dex).addToken(tokenPT, tokenP);
    }
    
    // todo: implement wallet functionality and trading functionality
    // deposit and withdraw
    // look at prices of tokens in pool (changes as people come in and out)
    // everytime price changes we have to adjust limit orders for the change in price (helper)
    
    // todo: implement withdraw and deposit functions so that a single deposit and a single withdraw can unstake
    // both tokens at the same time
    function deposit(uint tokenAmount, uint pineAmount) external {
        if (tokenAmount > 0) {
            IERC20(token1).transferFrom(msg.sender, address(this), tokenAmount);
            IERC20(token1).approve(dex, tokenAmount);
            IExc(dex).deposit(tokenAmount, token1T);
            traderBalances[msg.sender][token1T] = traderBalances[msg.sender][token1T].add(tokenAmount);
            totalToken = totalToken.add(tokenAmount);
        }
        if (pineAmount > 0) {
            IERC20(tokenP).transferFrom(msg.sender, address(this), pineAmount);
            IERC20(tokenP).approve(dex, pineAmount);
            IExc(dex).deposit(pineAmount, tokenPT);
            traderBalances[msg.sender][tokenPT] = traderBalances[msg.sender][tokenPT].add(pineAmount);
            totalPine = totalPine.add(pineAmount);
        }
        if (orderPlaced) {
            IExc(dex).deleteLimitOrder(lastSellOrderID, token1T, IExc.Side.SELL);
            IExc(dex).deleteLimitOrder(lastBuyOrderID, token1T, IExc.Side.BUY);
        }
        uint newPrice = totalPine.div(totalToken > 0 ? totalToken : 1);
        if (totalToken > 0) {
            lastSellOrderID = IExc(dex).getNextOrderID();
            IExc(dex).makeLimitOrder(token1T, totalToken, newPrice, IExc.Side.SELL);
            orderPlaced = true;
        } 
        if (totalPine > 0) {
            lastBuyOrderID = IExc(dex).getNextOrderID();
            IExc(dex).makeLimitOrder(token1T, totalPine.div(newPrice), newPrice, IExc.Side.BUY);
            orderPlaced = true;
        }
    }

    function withdraw(uint tokenAmount, uint pineAmount) external{
        require(traderBalances[msg.sender][tokenPT] >= pineAmount, "insufficient PIN to withdraw");
        require(traderBalances[msg.sender][token1T] >= tokenAmount, "insufficient token to withdraw");
        if (pineAmount > 0) {
            IExc(dex).withdraw(pineAmount, tokenPT);
            IERC20(tokenP).transfer(msg.sender, pineAmount);
            traderBalances[msg.sender][tokenPT] = traderBalances[msg.sender][tokenPT].sub(pineAmount);
            totalPine = totalPine.sub(pineAmount);
        } 
        if (tokenAmount > 0) {
            IExc(dex).withdraw(tokenAmount, token1T);
            IERC20(token1).transfer(msg.sender, tokenAmount);
            traderBalances[msg.sender][token1T] = traderBalances[msg.sender][token1T].sub(tokenAmount);
            totalToken = totalToken.sub(tokenAmount);
        } 
        if (orderPlaced) {
            IExc(dex).deleteLimitOrder(lastSellOrderID, token1T, IExc.Side.SELL);
            IExc(dex).deleteLimitOrder(lastBuyOrderID, token1T, IExc.Side.BUY);
        }
        uint newPrice = totalPine.div(totalToken > 0 ? totalToken : 1);
        if (totalToken > 0) {
            lastSellOrderID = IExc(dex).getNextOrderID();
            IExc(dex).makeLimitOrder(token1T, totalToken, newPrice, IExc.Side.SELL);
            orderPlaced = true;
        } 
        if (totalPine > 0) {
            lastBuyOrderID = IExc(dex).getNextOrderID();
            IExc(dex).makeLimitOrder(token1T, totalPine.div(newPrice), newPrice, IExc.Side.BUY);
            orderPlaced = true;
        }
    }
    
    function testing(uint testMe) public view returns (uint) {
        if (testMe == 1) {
            return 5;
        } else {
            return 3;
        }
    }
}
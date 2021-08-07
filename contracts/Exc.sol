pragma solidity 0.5.3;
pragma experimental ABIEncoderV2;

/// @notice these commented segments will differ based on where you're deploying these contracts. If you're deploying
/// on remix, feel free to uncomment the github imports, otherwise, use the uncommented imports

// import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/solc-0.6/contracts/token/ERC20/IERC20.sol";
// import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/solc-0.6/contracts/math/SafeMath.sol";
import '../contracts/libraries/token/ERC20/IERC20.sol';
import '../contracts/libraries/math/SafeMath.sol';
import "./IExc.sol";

contract Exc is IExc{
    /// @notice simply notes that we are using SafeMath for uint, since Solidity's math is unsafe. For all the math
    /// you do, you must use the methods specified in SafeMath (found at the github link above), instead of Solidity's
    /// built-in operators.
    using SafeMath for uint;
    
    /// @notice these declarations are incomplete. You will still need a way to store the orderbook, the balances
    /// of the traders, and the IDs of the next trades and orders. Reference the NewTrade event and the IExc
    /// interface for more details about orders and sides.
    mapping(bytes32 => Token) public tokens;
    bytes32[] public tokenList;
    // address private factory;
    bytes32 constant PIN = bytes32('PIN');
    //trader, token to the amount
    // mapping(address => mapping(bytes32 => uint)) public balances;
    //token to a side, to an order
    mapping(bytes32 => mapping(uint => Order[])) public orderbook;
    //ids of next trades and orders
    uint nextTradeID;
    uint nextOrderID;
    
    // for testing bubblesort
    mapping(uint => uint[]) public testmap;

    /// @notice, this is the more standardized form of the main wallet data structure, if you're using something a bit
    /// different, implementing a function that just takes in the address of the trader and then the ticker of a
    /// token instead would suffice
    mapping(address => mapping(bytes32 => uint)) public traderBalances;

    /// @notice an event representing all the needed info regarding a new trade on the exchange
    event NewTrade(
        uint tradeId,
        uint orderId,
        bytes32 indexed ticker,
        address indexed trader1,
        address indexed trader2,
        uint amount,
        uint price,
        uint date
    );
    
    event NewLimitOrder(
        address trader, 
        bytes32 ticker,
        uint side,
        uint amount,
        uint price
    );

    function getNextOrderID() external view returns (uint) {
        return nextOrderID;
    }
    
    modifier coinValid (bytes32 _ticker) {
        require(_ticker != PIN, "Ticker was PIN");
        bool tickerFound = false;
        for (uint i = 0; i < tokenList.length && !tickerFound; i++) {
            if (tokenList[i] == _ticker) {
                tickerFound = true;
            }
        }
        require(tickerFound, "Tokenlist didn't have ticker");
        _;
    }

    // todo: implement getOrders, which simply returns the orders for a specific token on a specific side
    function getOrders(
      bytes32 ticker, 
      Side side) 
      external 
      view
      returns(Order[] memory) {
          return orderbook[ticker][uint(side)];
    }

    // todo: implement getTokens, which simply returns an array of the tokens currently traded on in the exchange
    function getTokens() 
      external 
      view 
      returns(Token[] memory) {
          Token[] memory rTokens =  new Token[](tokenList.length);
          for(uint i=0; i<tokenList.length; i++) {
              bytes32 b = tokenList[i];
              rTokens[i] = tokens[b];
          }
        return rTokens;
    }
    
    // todo: implement addToken, which should add the token desired to the exchange by interacting with tokenList and tokens
    function addToken(
        bytes32 ticker,
        address tokenAddress)
        external {
            //TODO: check if it already contains?
            if (tokens[ticker].tokenAddress == address(0)) {
                Token memory tk = Token(ticker, tokenAddress);
                tokenList.push(ticker);
                tokens[ticker] = tk;
            }
    }
    
    // todo: implement deposit, which should deposit a certain amount of tokens from a trader to their on-exchange wallet,
    // based on the wallet data structure you create and the IERC20 interface methods. Namely, you should transfer
    // tokens from the account of the trader on that token to this smart contract, and credit them appropriately
    event Deposit (
        bytes32 ticker, 
        address token, 
        address trader, 
        uint amount
    );

    function deposit(
        uint amount,
        bytes32 ticker)
        external {
            Token memory tk = tokens[ticker];
            emit Deposit(ticker, tk.tokenAddress, msg.sender, amount);
            IERC20(tk.tokenAddress).transferFrom(msg.sender, address(this), amount);
            traderBalances[msg.sender][ticker] = traderBalances[msg.sender][ticker].add(amount);
        }
    
    // todo: implement withdraw, which should do the opposite of deposit. The trader should not be able to withdraw more than
    // they have in the exchange.
    function withdraw(
        uint amount,
        bytes32 ticker)
        external {
            require(traderBalances[msg.sender][ticker] >= amount);
            Token memory tk = tokens[ticker];
            IERC20(tk.tokenAddress).transfer(msg.sender, amount);
            traderBalances[msg.sender][ticker] = traderBalances[msg.sender][ticker].sub(amount);
    }
    
    // todo: implement makeLimitOrder, which creates a limit order based on the parameters provided. This method should only be
    // used when the token desired exists and is not pine. This method should not execute if the trader's token or pine balances
    // are too low, depending on side. This order should be saved in the orderBook
    
    // todo: implement a sorting algorithm for limit orders, based on best prices for market orders having the highest priority.
    // i.e., a limit buy order with a high price should have a higher priority in the orderbook.
    function makeLimitOrder(
        bytes32 ticker,
        uint amount,
        uint price,
        Side side)
        external coinValid(ticker) {
            if(side == Side.SELL) {
                require(traderBalances[msg.sender][ticker] >= amount, "insuffucient funds to sell");
            } else {
                require(traderBalances[msg.sender]["PIN"] >= amount.mul(price), "insufficient funds to buy");
            }
            // bool tickerFound = false;
            // for (uint i = 0; i < tokenList.length && !tickerFound; i++) {
            //     if (tokenList[i] == ticker) {
            //         tickerFound = true;
            //     }
            // }
            
            // require(tickerFound && ticker != "PIN", "Tokenlist didn't have ticker or token was PIN");
            Order memory lmo = Order(nextOrderID, msg.sender, side, ticker, amount, 0, price, now);
            nextOrderID++;
            orderbook[ticker][uint(side)].push(lmo);
            emit NewLimitOrder(msg.sender, ticker, uint(side), amount, price);
            bubblesort(orderbook[ticker][uint(side)]);
    }
    
    // todo: implement deleteLimitOrder, which will delete a limit order from the orderBook as long as the same trader is deleting
    // it.
        function deleteLimitOrder(
        uint id,
        bytes32 ticker,
        Side side) external coinValid(ticker) returns (bool)  {
            uint length = orderbook[ticker][uint(side)].length;
            for (uint i = 0; i < length; i++) {
                if (orderbook[ticker][uint(side)][i].id == id) {
                    require(msg.sender == orderbook[ticker][uint(side)][i].trader, "deleter was not trader");
                    // if the one to remove is the last, just pop. otherwise, swap last and the one to delete, then pop
                    if (i != length - 1) {
                        orderbook[ticker][uint(side)][i] = orderbook[ticker][uint(side)][length - 1];
                    }
                    orderbook[ticker][uint(side)].pop();
                    bubblesort(orderbook[ticker][uint(side)]);
                    return true;
                }
            }
            return false;
    }
    
    // todo: implement makeMarketOrder, which will execute a market order on the current orderbook. The market order need not be
    // added to the book explicitly, since it should execute against a limit order immediately. Make sure you are getting rid of
    // completely filled limit orders!
    
    // todo: what if someone deposits, makes limit order, then withdraws? how to handle?
    event MarketOrder(
        bytes32 ticker, 
        uint amount, 
        uint side, 
        address trader
    );

    event Removing(
        uint removing
    );

    function makeMarketOrder(
        bytes32 ticker,
        uint amount,
        Side side)
        external  coinValid(ticker) {
        emit MarketOrder(ticker, amount, uint(side), msg.sender);
        require(ticker != "PIN", "Cannot make market order for PIN");
        require(tokens[ticker].tokenAddress != address(0), "Token not in exchange");
        if (side == Side.SELL) {
            require(traderBalances[msg.sender][ticker] >= amount, "insufficient funds to sell");
            uint amountToFill = amount;
            uint ordersFilled = 0;
            uint len = orderbook[ticker][uint(Side.BUY)].length;
            while (amountToFill > 0) {
                require(ordersFilled <= len - 1, "insufficient SELL limit orders to fill BUY market order");
                Order storage highestPriority = orderbook[ticker][uint(Side.BUY)][ordersFilled];
                if (highestPriority.amount > amountToFill) {
                    // decrease remaining amount of order by the amount we are filing
                    highestPriority.amount = highestPriority.amount.sub(amountToFill);
                    highestPriority.filled = highestPriority.filled.add(amountToFill);
                    // orderbook[ticker][uint(Side.BUY)][len - 1].amount = orderbook[ticker][uint(Side.BUY)][len - 1].amount.sub(amountToFill);
                    
                    // give buyer their new coins, take away coins from seller
                    traderBalances[highestPriority.trader][ticker] = traderBalances[highestPriority.trader][ticker].add(amountToFill);
                    traderBalances[msg.sender][ticker] = traderBalances[msg.sender][ticker].sub(amountToFill);
                    
                    // give seller their new PIN, take away PIN from buyer
                    uint totalPrice = amountToFill.mul(highestPriority.price);
                    traderBalances[highestPriority.trader][PIN] = traderBalances[highestPriority.trader][PIN].sub(totalPrice);
                    traderBalances[msg.sender][PIN] = traderBalances[msg.sender][PIN].add(totalPrice);
                    
                    amountToFill = 0;
                    emit NewTrade(nextTradeID, highestPriority.id, ticker, highestPriority.trader, msg.sender, amountToFill, highestPriority.price, now);
                    nextTradeID++;
                }
                else {
                    // give buyer their new coins, take away coins from seller
                    traderBalances[highestPriority.trader][ticker] = traderBalances[highestPriority.trader][ticker].add(highestPriority.amount);
                    traderBalances[msg.sender][ticker] = traderBalances[msg.sender][ticker].sub(highestPriority.amount);
                    
                    // give seller their new PIN, take away PIN from buyer
                    uint totalPrice = highestPriority.amount.mul(highestPriority.price);
                    traderBalances[highestPriority.trader][PIN] = traderBalances[highestPriority.trader][PIN].sub(totalPrice);
                    traderBalances[msg.sender][PIN] = traderBalances[msg.sender][PIN].add(totalPrice);
                    
                    // decrease the amount we have left to fill
                    amountToFill = amountToFill.sub(highestPriority.amount);
                    
                    ordersFilled = ordersFilled.add(1);
                    emit NewTrade(nextTradeID, highestPriority.id, ticker, highestPriority.trader, msg.sender, highestPriority.amount, highestPriority.price, now);
                    nextTradeID++;
                }
            }
            emit Removing(ordersFilled);
            for (uint i = 0; i < ordersFilled; i++) {
                if (i != orderbook[ticker][uint(Side.BUY)].length - 1 && orderbook[ticker][uint(Side.BUY)].length > 1) {
                    Order memory temp = orderbook[ticker][uint(Side.BUY)][orderbook[ticker][uint(Side.BUY)].length - 1];
                    orderbook[ticker][uint(Side.BUY)][i] = temp;
                }
                orderbook[ticker][uint(Side.BUY)].pop();
            }
            bubblesort(orderbook[ticker][uint(Side.BUY)]);
        } else {
            uint amountToFill = amount;
            uint ordersFilled = 0;
            uint len = orderbook[ticker][uint(Side.SELL)].length;
            while (amountToFill > 0) {
                require(ordersFilled <= len - 1, "insufficient SELL limit orders to fill BUY market order");
                Order storage highestPriority = orderbook[ticker][uint(Side.SELL)][ordersFilled];
                if (highestPriority.amount > amountToFill) {
                    // decrease remaining amount of order by the amount we are filing
                    highestPriority.amount = highestPriority.amount.sub(amountToFill);
                    highestPriority.filled = highestPriority.filled.add(amountToFill);
                    // orderbook[ticker][uint(Side.BUY)][len - 1].amount = orderbook[ticker][uint(Side.BUY)][len - 1].amount.sub(amountToFill);
                    
                    // give buyer their new coins, take away coins from seller
                    traderBalances[highestPriority.trader][ticker] = traderBalances[highestPriority.trader][ticker].sub(amountToFill);
                    traderBalances[msg.sender][ticker] = traderBalances[msg.sender][ticker].add(amountToFill);
                    
                    // give seller their new PIN, take away PIN from buyer
                    uint totalPrice = amountToFill.mul(highestPriority.price);
                    traderBalances[highestPriority.trader][PIN] = traderBalances[highestPriority.trader][PIN].add(totalPrice);
                    traderBalances[msg.sender][PIN] = traderBalances[msg.sender][PIN].sub(totalPrice);
                    
                    amountToFill = 0;
                    emit NewTrade(nextTradeID, highestPriority.id, ticker, highestPriority.trader, msg.sender, amountToFill, highestPriority.price, now);
                    nextTradeID++;
                }
                else {
                    // give buyer their new coins, take away coins from seller
                    traderBalances[highestPriority.trader][ticker] = traderBalances[highestPriority.trader][ticker].sub(highestPriority.amount);
                    traderBalances[msg.sender][ticker] = traderBalances[msg.sender][ticker].add(highestPriority.amount);
                    
                    // give seller their new PIN, take away PIN from buyer
                    uint totalPrice = highestPriority.amount.mul(highestPriority.price);
                    traderBalances[highestPriority.trader][PIN] = traderBalances[highestPriority.trader][PIN].add(totalPrice);
                    traderBalances[msg.sender][PIN] = traderBalances[msg.sender][PIN].sub(totalPrice);
                    
                    // decrease the amount we have left to fill
                    amountToFill = amountToFill.sub(highestPriority.amount);
                    
                    ordersFilled = ordersFilled.add(1);
                    emit NewTrade(nextTradeID, highestPriority.id, ticker, highestPriority.trader, msg.sender, highestPriority.amount, highestPriority.price, now);
                    nextTradeID++;
                }
            }
            emit Removing(ordersFilled);
            for (uint i = 0; i < ordersFilled; i++) {
                if (i != orderbook[ticker][uint(Side.SELL)].length - 1 && orderbook[ticker][uint(Side.SELL)].length > 1) {
                    Order memory temp = orderbook[ticker][uint(Side.SELL)][orderbook[ticker][uint(Side.SELL)].length - 1];
                    orderbook[ticker][uint(Side.SELL)][i] = temp;
                }
                orderbook[ticker][uint(Side.SELL)].pop();
            }
            bubblesort(orderbook[ticker][uint(Side.SELL)]);
        }
    }
    
    //todo: add modifiers for methods as detailed in handout
    
    function bubblesort(Order[] storage arr) internal {
        if (arr.length > 0) {
            Side side = arr[0].side;
            if (side == Side.SELL) {
                for (uint i = 0; i < arr.length; i++) {
                    bool swapped = false;
                    for (uint j = 0; j < arr.length - 1; j++) {
                        if (arr[j].price > arr[j + 1].price) {
                            Order memory temp = arr[j];
                            arr[j] = arr[j + 1];
                            arr[j + 1] = temp;
                            swapped = true;
                        }
                    }
                    if (!swapped) {
                        break;
                    }
                }
            }
            else {
                for (uint i = 0; i < arr.length; i++) {
                    bool swapped = false;
                    for (uint j = 0; j < arr.length - 1; j++) {
                        if (arr[j].price < arr[j + 1].price) {
                            Order memory temp = arr[j];
                            arr[j] = arr[j + 1];
                            arr[j + 1] = temp;
                            swapped = true;
                        }
                    }
                    if (!swapped) {
                        break;
                    }
                }   
            }
        }
    }
}
 
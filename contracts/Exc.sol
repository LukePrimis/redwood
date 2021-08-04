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
            Token memory tk = Token(ticker, tokenAddress);
            tokenList.push(ticker);
            tokens[ticker] = tk;
    }
    
    // todo: implement deposit, which should deposit a certain amount of tokens from a trader to their on-exchange wallet,
    // based on the wallet data structure you create and the IERC20 interface methods. Namely, you should transfer
    // tokens from the account of the trader on that token to this smart contract, and credit them appropriately
    function deposit(
        uint amount,
        bytes32 ticker)
        external {
            Token memory tk = tokens[ticker];
            IERC20(tk.tokenAddress).transferFrom(msg.sender, address(this), amount);
            traderBalances[address(this)][ticker] += amount;
            traderBalances[msg.sender][ticker] -= amount;
        }
    
    // todo: implement withdraw, which should do the opposite of deposit. The trader should not be able to withdraw more than
    // they have in the exchange.
    function withdraw(
        uint amount,
        bytes32 ticker)
        external {
            require(traderBalances[address(this)][ticker] >= amount);
            Token memory tk = tokens[ticker];
            IERC20(tk.tokenAddress).transfer(msg.sender, amount);
            traderBalances[address(this)][ticker] -= amount;
            traderBalances[msg.sender][ticker] += amount;
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
        external {
            //ask abt how side works in makeLimitOrder
            if(side == Side.SELL) {
                require(traderBalances[msg.sender][ticker] >= amount);
            } else {
                //require(balances[msg.sender][PIN] >= amount)
                //converting amount to pine
                require(traderBalances[msg.sender]["PIN"] >= amount.mul(price));
            }
            bool tickerFound = false;
            for (uint i = 0; i < tokenList.length && !tickerFound; i++) {
                if (tokenList[i] == ticker) {
                    tickerFound = true;
                }
            }
            
            require(tickerFound && ticker != "PIN", "Tokenlist didn't have ticker or token was PIN");
            Order memory lmo = Order(nextOrderID, msg.sender, side, ticker, amount, 0, price, now);
            nextOrderID++;
            orderbook[ticker][uint(side)].push(lmo);
            quicksort(orderbook[ticker][uint(side)], 0, uint32(orderbook[ticker][uint(side)].length - 1));
    }
    
    // todo: implement deleteLimitOrder, which will delete a limit order from the orderBook as long as the same trader is deleting
    // it.
        function deleteLimitOrder(
        uint id,
        bytes32 ticker,
        Side side) external returns (bool) {
            // todo do we need to check this shit
            // require(side == Side.SELL || side == Side.BUY, "Side was not BUY or SELL");
            // require()
            uint length = orderbook[ticker][uint(side)].length;
            for (uint i = 0; i < length; i++) {
                if (orderbook[ticker][uint(side)][i].id == id) {
                    require(msg.sender == orderbook[ticker][uint(side)][i].trader, "deleter was not trader");
                    orderbook[ticker][uint(side)][i] = orderbook[ticker][uint(side)][length - 1];
                    orderbook[ticker][uint(side)].pop();
                    quicksort(orderbook[ticker][uint(side)], 0, uint32(length - 1));
                    return true;
                }
            }
            return false;
    }
    
    // todo: implement makeMarketOrder, which will execute a market order on the current orderbook. The market order need not be
    // added to the book explicitly, since it should execute against a limit order immediately. Make sure you are getting rid of
    // completely filled limit orders!
    
    //taking best order and 
    //manually 
    
    // todo: what if someone deposits, makes limit order, then withdraws? how to handle?

    function makeMarketOrder(
        bytes32 ticker,
        uint amount,
        Side side)
        external {
        if (side == Side.SELL) {
            require(traderBalances[msg.sender][ticker] >= amount, "insufficient funds to sell");
            uint amountToFill = amount;
            while (amountToFill > 0) {
                uint len = orderbook[ticker][uint(Side.BUY)].length;
                Order memory lastOrder = orderbook[ticker][uint(Side.BUY)][len - 1];
                if (lastOrder.amount > amountToFill) {
                    // decrease remaining amount of order by the amount we are filing
                    orderbook[ticker][uint(Side.BUY)][len - 1].amount -= amountToFill;
                    
                    // give buyer their new coins, take away coins from seller
                    traderBalances[lastOrder.trader][ticker] += amountToFill;
                    traderBalances[msg.sender][ticker] -= amountToFill;
                    
                    // give seller their new PIN, take away PIN from buyer
                    uint totalPrice = amountToFill.mul(lastOrder.price);
                    traderBalances[msg.sender]["PIN"] += totalPrice;
                    traderBalances[lastOrder.trader]["PIN"] -= totalPrice;
                    
                    amountToFill = 0;
                }
                else {
                    // give buyer their new coins, take away coins from seller
                    traderBalances[lastOrder.trader][ticker] += lastOrder.amount;
                    traderBalances[msg.sender][ticker] -= lastOrder.amount;
                    
                    // give seller their new PIN, take away PIN from buyer
                    uint totalPrice = (lastOrder.amount).mul(lastOrder.price);
                    traderBalances[msg.sender]["PIN"] += totalPrice;
                    traderBalances[lastOrder.trader]["PIN"] -= totalPrice;
                    
                    // decrease the amount we have left to fill
                    amountToFill -= lastOrder.amount;
                    
                    // remove the completely filled BUY limit order
                    orderbook[ticker][uint(Side.BUY)].pop();
                }
            }
        } else {
            uint amountToFill = amount;
            while (amountToFill > 0) {
                uint len = orderbook[ticker][uint(Side.SELL)].length;
                Order memory lastOrder = orderbook[ticker][uint(Side.SELL)][len - 1];
                if (lastOrder.amount > amountToFill) {
                    uint totalPrice = amountToFill.mul(lastOrder.price);
                    require(traderBalances[msg.sender]["PIN"] >= totalPrice, "insufficient funds to purchase token");
                    // take away amoiunt we are filling from order
                    orderbook[ticker][uint(Side.SELL)][len - 1].amount -= amountToFill;

                    // take away PIN from buyer, and give PIN to seller
                    traderBalances[msg.sender]["PIN"] -= totalPrice;
                    traderBalances[lastOrder.trader]["PIN"] += totalPrice;
                    
                    // give token to buyer, take away token from seller
                    traderBalances[msg.sender][ticker] += amountToFill;
                    traderBalances[lastOrder.trader][ticker] -= amountToFill;
                    
                    amountToFill = 0;
                } 
                else {
                    uint totalPrice = (lastOrder.amount).mul(lastOrder.price);
                    require(traderBalances[msg.sender]["PIN"] >= totalPrice, "insufficient funds to purchase token");

                    // take away PIN from buyer, and give PIN to seller
                    traderBalances[msg.sender]["PIN"] -= totalPrice;
                    traderBalances[lastOrder.trader]["PIN"] += totalPrice;
                    
                    // give token to buyer, take away token from seller
                    traderBalances[msg.sender][ticker] += lastOrder.amount;
                    traderBalances[lastOrder.trader][ticker] -= lastOrder.amount;
                    
                    amountToFill -= lastOrder.amount;
                    orderbook[ticker][uint(Side.SELL)].pop();
                }
            }
    }
}
    
    //todo: add modifiers for methods as detailed in handout
    
    // do we need to use memory?
    function quicksort(Order[] memory arr, uint32 left, uint32 right) internal returns (Order[] memory){
        if (left >= right) {
            return arr;
        }
        
        uint32 pivot = left + ((right - left) / 2);
        uint32 sortedPivotIndex = 0;
        (arr[pivot], arr[right]) = (arr[right], arr[pivot]);
        
        bool pivotSet = false;
        while (!pivotSet) {
            uint32 itemFromLeft = left;
            while (arr[itemFromLeft].price < arr[right].price && itemFromLeft < right) itemFromLeft++;
            uint32 itemFromRight = right;
            while (arr[itemFromRight].price >= arr[right].price && itemFromRight > left) itemFromRight--;
            if (itemFromRight <= itemFromLeft) {
                if (itemFromLeft != right) {
                    (arr[itemFromLeft], arr[right]) = (arr[right], arr[itemFromLeft]);
                }
                sortedPivotIndex = itemFromLeft;
                pivotSet = true;
            }
            else {
                (arr[itemFromLeft], arr[itemFromRight]) = (arr[itemFromRight], arr[itemFromLeft]);
            }
        }
        Order[] memory arr2;
        if (sortedPivotIndex == 0) {
            arr2 = arr;
        }
        else {
            arr2 = quicksort(arr, left, sortedPivotIndex - 1);
        }
        return quicksort(arr2, sortedPivotIndex + 1, right);
    }
    
    function sort(uint[] calldata arr) external returns (uint[] memory) {
        return quicksortInt(arr, uint32(0), uint32(arr.length - 1));
    }
    
    function quicksortInt(uint[] memory arr, uint left, uint right) internal returns (uint[] memory){
        if (left >= right) {
            return arr;
        }
        
        uint pivot = left.add((right.sub(left)).div(2));
        uint sortedPivotIndex = 0;
        (arr[pivot], arr[right]) = (arr[right], arr[pivot]);
        
        bool pivotSet = false;
        while (!pivotSet) {
            uint itemFromLeft = left;
            while (arr[itemFromLeft] < arr[right] && itemFromLeft < right) itemFromLeft = itemFromLeft.add(1);
            uint itemFromRight = right;
            while (arr[itemFromRight] >= arr[right] && itemFromRight > left) itemFromRight = itemFromRight.sub(1);
            if (itemFromRight <= itemFromLeft) {
                if (itemFromLeft != right) {
                    (arr[itemFromLeft], arr[right]) = (arr[right], arr[itemFromLeft]);
                }
                sortedPivotIndex = itemFromLeft;
                pivotSet = true;
            }
            else {
                (arr[itemFromLeft], arr[itemFromRight]) = (arr[itemFromRight], arr[itemFromLeft]);
            }
        }
        uint[] memory arr2;
        if (sortedPivotIndex == 0) {
            arr2 = arr;
        }
        else {
            arr2 = quicksortInt(arr, left, sortedPivotIndex.sub(1));
        }
        return quicksortInt(arr2, sortedPivotIndex.add(1), right);
    }
    
    function getpin() external returns (bytes32) {
        return "PIN";
    }
    
    function testmath(uint inp) external returns (uint) {
        uint t = inp;
        t = t.mul(10);
        return t;
    }
}
 
pragma solidity 0.5.3;
pragma experimental ABIEncoderV2;

/// @notice these commented segments will differ based on where you're deploying these contracts. If you're deploying
/// on remix, feel free to uncomment the github imports, otherwise, use the uncommented imports

// import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/solc-0.6/contracts/token/ERC20/IERC20.sol";
// import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/solc-0.6/contracts/math/SafeMath.sol";
import '../contracts/libraries/token/ERC20/ERC20.sol';
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
    address private factory;
    bytes32 constant PIN = bytes32('PIN');
    //trader, token to the amount
    mapping(address => mapping(bytes32 => uint)) public balances;
    //token to a side, to an order
    mapping(bytes32 => mapping(uint => Order[])) public orderbook;
    //ids of next trades and orders
    uint nextTradeID
    uint nextOrderID
    
    
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
    
    /// @notice a constructor for this smart contract, used during deployment. No need to edit
    /// @param fac the address of the factory contract
    constructor(address fac) public {
        factory = fac;
    }
    
    // todo: implement getOrders, which simply returns the orders for a specific token on a specific side
    function getOrders(
      bytes32 ticker, 
      Side side) 
      external 
      view
      returns(Order[] memory) {
          return orderbook[ticker][side.uint];
    }

    // todo: implement getTokens, which simply returns an array of the tokens currently traded on in the exchange
    function getTokens() 
      external 
      view 
      returns(Token[] memory) {
          ar rTokens = Token[];
          for(uint i=0; i<tokenList.length; i++) {
              bytes32 b = tokenList[i]
              Token tk = tokens[b]
              rTokens.push(tk)
          }
        return rTokens
    }
    
    // todo: implement addToken, which should add the token desired to the exchange by interacting with tokenList and tokens
    function addToken(
        bytes32 ticker,
        address tokenAddress)
        external {
            //TODO: check if it already contains?
            Token tk = Token(ticker, tokenAddress)
            tokenList.push(ticker)
            tokens.add(ticker, tk)
    }
    
    // todo: implement deposit, which should deposit a certain amount of tokens from a trader to their on-exchange wallet,
    // based on the wallet data structure you create and the IERC20 interface methods. Namely, you should transfer
    // tokens from the account of the trader on that token to this smart contract, and credit them appropriately
    function deposit(
        uint amount,
        bytes32 ticker)
        external {
            Token tk = tokens[ticker]
            IERC20(tk.tokenAddress).transferFrom(msg.sender, address(this), amount)
            balances[address(this)][ticker] += amount
            balances[msg.sender][ticker] -= amount
        }
    
    // todo: implement withdraw, which should do the opposite of deposit. The trader should not be able to withdraw more than
    // they have in the exchange.
    function withdraw(
        uint amount,
        bytes32 ticker)
        external {
            require(balances[address(this)][ticker] >= amount)
            Token tk = tokens[ticker]
            IERC20(tk.tokenAddress).transferFrom(address(this), msg.sender, amount)
            balances[address(this)][ticker] -= amount
            balances[msg.sender][ticker] += amount
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
            if(side == SELL) {
            require(balances[msg.sender][ticker] >= amount)
            } else {
                //require(balances[msg.sender][PIN] >= amount)
                //converting amount to pine
                require(balances[msg.sender]["PIN"] >= amount.mul(price))
            }
            require(tokenList.contains(ticker) && ticker != "PIN")
            Order lmo = Order(nextOrderID, msg.sender, side, ticker, amount, 0, price, now)
            
    }
    
    // todo: implement deleteLimitOrder, which will delete a limit order from the orderBook as long as the same trader is deleting
    // it.
        function deleteLimitOrder(
        uint id,
        bytes32 ticker,
        Side side) external returns (bool) {
    }
    
    // todo: implement makeMarketOrder, which will execute a market order on the current orderbook. The market order need not be
    // added to the book explicitly, since it should execute against a limit order immediately. Make sure you are getting rid of
    // completely filled limit orders!
    
    //taking best order and 
    //manually 
    function makeMarketOrder(
        bytes32 ticker,
        uint amount,
        Side side)
        external {
       
    }
    
    //todo: add modifiers for methods as detailed in handout

}
pragma solidity 0.5.3;

import './Pool.sol';

contract Factory {
    
    // @notice some structures to keep track of what pairs have been created
    mapping(address => mapping(address => address)) public getPair;
    address[] public allPairs;
    
    // @notice an event indicating when a pair has been created
    event PairCreated(address indexed token0, address indexed token1, address pair, uint);
    
    function createPair(
        address tokenA,
        address tokenB,
        address quoting, address dex,
        bytes32 tickerQ,
        bytes32 tickerT) external returns (address pair) {
        // todo: fill in the require conditions
        require(?, 'First token in pair is not quote token');
        require(?, 'Identical addresses');
        (address token0, address token1) = tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);
        uint whichP = tokenA < tokenB ? 1 : 2;
        require(?, 'Zero address error');
        require(?, 'Pair already exists');
        
        // todo: fill in the rest of the createPair method. To do this, you will need to deploy a smart contract using
        // a create2 opcode in assembly. This is probably beyond the scope of this project, so exact details will be
        // released on Piazza a few days after project release. Before that, you are encouraged to try your hand at
        // making the code yourself. You will also want to initialize the pool properly, and record the pair created 
        // properly in this contract.
    }
    
}
# LiquidityFetcher

## Overview

LiquidityFetcher is a smart contract that retrieves liquidity position details for Uniswap V2 and Uniswap V3 pools. It provides functions to fetch a user's liquidity position in Uniswap V2 pools, details of Uniswap V3 positions by token ID, and calculates impermanent loss.

## Features

Fetch liquidity positions for Uniswap V2 pools.

Fetch liquidity positions for Uniswap V3 positions.

Retrieve the pool address for Uniswap V3 positions.

Calculate impermanent loss.

## Dependencies

This contract requires the following interfaces:

UniswapV2Interfaces.sol

UniswapV3Interfaces.sol

IERC721.sol

## Constructor

```angular2html
constructor(address _uniswapV3PositionManager, address _uniswapV3Factory)
```

_uniswapV3PositionManager: Address of the Uniswap V3 Nonfungible Position Manager.

_uniswapV3Factory: Address of the Uniswap V3 Factory.

## Functions

### getUniswapV2Position

```
function getUniswapV2Position(address uniswapV2Pair, address user)
external view returns (uint256 token0Amount, uint256 token1Amount)
```

Retrieves liquidity details for a user in a Uniswap V2 pool.

Requires the address of the Uniswap V2 pair contract and the user's address.

### getUniswapV3Position

```
function getUniswapV3Position(uint256 tokenId)
external view returns (
address token0,
address token1,
uint24 fee,
int24 tickLower,
int24 tickUpper,
uint128 liquidity,
uint128 tokensOwed0,
uint128 tokensOwed1,
address owner,
int24 currentTick
)
```

Retrieves details of a Uniswap V3 liquidity position using a token ID.

Returns position details, including tokens, fee tier, liquidity, and owed tokens.

### getPoolAddressForUniswapV3

```
function getPoolAddressForUniswapV3(address token0, address token1, uint24 fee)
public view returns (address poolAddress)
```

Retrieves the pool address for a given Uniswap V3 token pair and fee tier.

### calculateImpermanentLoss

```
function calculateImpermanentLoss(uint256 initialPrice, uint256 currentPrice)
public pure returns (int256 impermanentLoss)
```

Calculates impermanent loss based on the initial and current price of Token X in terms of Token Y.

Returns the impermanent loss as a percentage scaled by 1e18.

### sqrt

```
function sqrt(uint256 x) internal pure returns (uint256 y)
```

Computes the square root of a given number using the Babylonian method.

## Usage

Deploy the contract by providing the Uniswap V3 Position Manager and Factory addresses.

Call getUniswapV2Position to get the user's token holdings in a Uniswap V2 pool.

Call getUniswapV3Position with a valid token ID to retrieve liquidity details for a Uniswap V3 position.

Call calculateImpermanentLoss to estimate impermanent loss based on price changes.

## License

This contract is licensed under the MIT License.

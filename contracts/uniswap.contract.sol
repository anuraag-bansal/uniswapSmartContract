// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "contracts/UniswapV2Interfaces.sol";
import "contracts/UniswapV3Interfaces.sol";
import "contracts/IERC721.sol";

/**
 * @title LiquidityFetcher
 * @dev A contract to fetch liquidity position details for Uniswap V2 and V3 pools.
 */
contract LiquidityFetcher {
    address public immutable uniswapV3PositionManager;
    address public immutable uniswapV3Factory;

    /**
    * @dev Constructor to initialize the contract with Uniswap V3 position manager and factory addresses.
     * @param _uniswapV3PositionManager Address of the Uniswap V3 Nonfungible Position Manager.
     * @param _uniswapV3Factory Address of the Uniswap V3 Factory.
     */
    constructor(address _uniswapV3PositionManager,address _uniswapV3Factory) {
        uniswapV3PositionManager = _uniswapV3PositionManager;
        uniswapV3Factory = _uniswapV3Factory;
    }

    /**
     * @notice Fetches position details for a user in a Uniswap V2 pool.
     * @param uniswapV2Pair Address of the Uniswap V2 pair contract.
     * @param user Address of the user whose position is being queried.
     * @return token0Amount Amount of Token0 the user owns in the pool.
     * @return token1Amount Amount of Token1 the user owns in the pool.
     */
    function getUniswapV2Position(
        address uniswapV2Pair,
        address user
    ) external view returns (uint256 token0Amount, uint256 token1Amount) {
        require(uniswapV2Pair != address(0), "Invalid pair address");
        require(user != address(0), "Invalid user address");
        IUniswapV2Pair pair = IUniswapV2Pair(uniswapV2Pair);

        // Get the reserves of token0 and token1 in the pool
        (uint256 reserve0, uint256 reserve1, ) = pair.getReserves();

        // Get user's LP token balance
        uint256 userLPBalance = pair.balanceOf(user);
        require(userLPBalance>0,"No lp tokens found");

        // Get the total supply of LP tokens
        uint256 totalSupply = pair.totalSupply();
        require(totalSupply > 0, "Total supply is zero");

        // Calculate user's share of token0 and token1
        token0Amount = (reserve0 * userLPBalance) / totalSupply;
        token1Amount = (reserve1 * userLPBalance) / totalSupply;

        return (token0Amount, token1Amount);
    }

    /**
     * @notice Fetches position details for a Uniswap V3 position by token ID.
     * @param tokenId The ID of the Uniswap V3 position.
     * @return token0 Address of token0 in the position.
     * @return token1 Address of token1 in the position.
     * @return fee Fee tier of the position.
     * @return tickLower Lower tick of the position.
     * @return tickUpper Upper tick of the position.
     * @return liquidity Liquidity of the position.
     * @return tokensOwed0 Tokens owed in token0.
     * @return tokensOwed1 Tokens owed in token1.
     * @return owner Address of the position owner.
     * @return currentTick Current tick of the pool.
     */
    function getUniswapV3Position(
        uint256 tokenId
    ) external view returns (
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
    ) {
        INonfungiblePositionManager.Position memory position = INonfungiblePositionManager(uniswapV3PositionManager).positions(tokenId);

        owner = IERC721(uniswapV3PositionManager).ownerOf(tokenId);
        // Get the pool address for the Uniswap V3 position
        address poolAddress = getPoolAddressForUniswapV3(position.token0, position.token1, position.fee);

        // Fetch the current tick using the `slot0` method
        (, currentTick, , , , , ) = IUniswapV3Pool(poolAddress).slot0();

        // Return position details
        return (
            position.token0,
            position.token1,
            position.fee,
            position.tickLower,
            position.tickUpper,
            position.liquidity,
            position.tokensOwed0,
            position.tokensOwed1,
            owner,
            currentTick
        );
    }

    /**
     * @notice Retrieves the pool address for a given token pair and fee tier in Uniswap V3.
     * @param token0 Address of token0.
     * @param token1 Address of token1.
     * @param fee Fee tier of the pool.
     * @return poolAddress Address of the pool.
     */
    function getPoolAddressForUniswapV3(
        address token0,
        address token1,
        uint24 fee
    ) public view returns (address poolAddress) {
        // Get the pool address directly from the Uniswap V3 factory
        poolAddress = IUniswapV3Factory(uniswapV3Factory).getPool(token0, token1, fee);
        require(poolAddress != address(0), "Pool does not exist");
    }

    /**
   * @notice Calculates the impermanent loss (IL) for a Uniswap position.
     * @param initialPrice The initial price of Token X in terms of Token Y.
     * @param currentPrice The current price of Token X in terms of Token Y.
     * @return impermanentLoss The impermanent loss as a percentage (scaled by 1e18).
     */
    function calculateImpermanentLoss(
        uint256 initialPrice, // Initial price of Token X in terms of Token Y
        uint256 currentPrice // Current price of Token X in terms of Token Y
    ) public pure returns (int256 impermanentLoss) {
        require(initialPrice > 0, "Invalid initial price");
        require(currentPrice > 0, "Invalid current price");

        if(initialPrice == currentPrice) {
            return 0;
        }

        // Calculate the price ratio r = P_current / P_initial
        uint256 priceRatio = (currentPrice * 1e18) / initialPrice; // Scale by 1e18 for precision

        // Calculate sqrt(r)
        uint256 sqrtPriceRatio = sqrt(priceRatio) * 1e9;

        // Impermanent loss formula: IL = 1 - (2 * sqrt(r) / (1 + r))
        uint256 numerator = 2 * sqrtPriceRatio;
        uint256 denominator = 1e18 + priceRatio; // Scale denominator by 1e18
        uint256 fraction = (numerator * 1e18) / denominator; // Scale fraction by 1e18

        impermanentLoss = int256(1e18 - fraction); // IL scaled by 1e18 (percentage)
    }

    /**
     * @notice Calculates the square root of a number using the Babylonian method.
     * @param x The input number.
     * @return y The square root of the input number.
     */
    function sqrt(uint256 x) internal pure returns (uint256 y) {
        if (x == 0) return 0;
        uint256 z = (x + 1) / 2;
        y = x;
        while (z < y) {
            y = z;
            z = (x / z + z) / 2;
        }
    }
}

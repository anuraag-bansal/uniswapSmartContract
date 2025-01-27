// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IUniswapV2Pair {
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
}

interface IUniswapV3Pool {
    function slot0()
    external
    view
    returns (
        uint160 sqrtPriceX96,
        int24 tick,
        uint16 observationIndex,
        uint16 observationCardinality,
        uint16 observationCardinalityNext,
        uint8 feeProtocol,
        bool unlocked
    );
}

interface IUniswapV3Factory {
    function getPool(address token0, address token1, uint24 fee) external view returns (address);
}

interface INonfungiblePositionManager {
    struct Position {
        uint96 nonce;
        address operator;
        address token0;
        address token1;
        uint24 fee;
        int24 tickLower;
        int24 tickUpper;
        uint128 liquidity;
        uint256 feeGrowthInside0LastX128;
        uint256 feeGrowthInside1LastX128;
        uint128 tokensOwed0;
        uint128 tokensOwed1;
    }

    function positions(uint256 tokenId) external view returns (Position memory);
}

interface IERC721 {
    function ownerOf(uint256 tokenId) external view returns (address);
}

contract LiquidityFetcher {
    address public immutable uniswapV3PositionManager;
    address public immutable uniswapV3Factory;

    constructor(address _uniswapV3PositionManager,address _uniswapV3Factory) {
        uniswapV3PositionManager = _uniswapV3PositionManager;
        uniswapV3Factory = _uniswapV3Factory;
    }

    // Fetch position details for Uniswap V2
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

    // Fetch position details for Uniswap V3
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
        uint128 tokensOwed1
    ) {
        INonfungiblePositionManager.Position memory position = INonfungiblePositionManager(uniswapV3PositionManager).positions(tokenId);

        // Return position details
        return (
            position.token0,
            position.token1,
            position.fee,
            position.tickLower,
            position.tickUpper,
            position.liquidity,
            position.tokensOwed0,
            position.tokensOwed1
        );
    }

    function ownerOf(uint256 tokenId) external view returns (address) {
        // Use the ERC721 ownerOf function to fetch the token owner
        return IERC721(uniswapV3PositionManager).ownerOf(tokenId);
    }

    function getPoolAddressForUniswapV3(
        address token0,
        address token1,
        uint24 fee
    ) public view returns (address poolAddress) {
        // Get the pool address directly from the Uniswap V3 factory
        poolAddress = IUniswapV3Factory(uniswapV3Factory).getPool(token0, token1, fee);
        require(poolAddress != address(0), "Pool does not exist");
    }

    function getCurrentTick(
        address token0,
        address token1,
        uint24 fee
    ) external view returns (int24 currentTick) {
        address poolAddress = getPoolAddressForUniswapV3(token0, token1, fee);
        (, currentTick, , , , , ) = IUniswapV3Pool(poolAddress).slot0();
    }

    //  // Uniswap V2: Calculate impermanent loss based on price ratio
    // function calculateImpermanentLossForV2(uint256 initialPrice, uint256 currentPrice)
    //     public
    //     pure
    //     returns (uint256 il)
    // {
    //     require(initialPrice > 0 && currentPrice > 0, "Prices must be greater than zero");

    //     if(initialPrice == currentPrice) {
    //         il = 0;
    //         return il;
    //     }

    //     // Calculate the square root of the price ratio
    //     uint256 priceRatio = (currentPrice * 1e18) / initialPrice;
    //     uint256 sqrtPriceRatio = sqrt(priceRatio);

    //     // Calculate impermanent loss formula
    //     // IL = 2 * sqrt(priceRatio) / (1 + priceRatio) - 1
    //     uint256 numerator = 2 * sqrtPriceRatio;
    //     uint256 denominator = (1e18 + priceRatio); // 1e18 is used to scale denominator
    //     uint256 ilScaled = (numerator * 1e18) / denominator; // Scale IL to 1e18
    //     if (ilScaled > 1e18) ilScaled = 1e18; // IL cannot exceed 100%

    //     il = 1e18 - ilScaled; // Impermanent loss
    // }

    // function calculateImpermanentLossForV3(
    //     uint256 p0, // Initial price
    //     uint256 pt, // Current price
    //     uint256 pMin, // Minimum price
    //     uint256 pMax // Maximum price
    // ) public pure returns (uint256 il) {
    //     require(p0 > 0 && pt > 0, "Prices must be greater than zero");
    //     require(pMin < pMax, "Invalid range");

    //     if (pt <= pMin) {
    //         // Price is below the range: all assets are in tokenX
    //         return 0; // No impermanent loss as you're fully in tokenX
    //     } else if (pt >= pMax) {
    //         // Price is above the range: all assets are in tokenY
    //         return 0; // No impermanent loss as you're fully in tokenY
    //     } else {
    //         // Price is within the range: Calculate IL

    //         // Calculate square roots of prices
    //         uint256 sqrtP0 = sqrt(p0);
    //         uint256 sqrtPt = sqrt(pt);
    //         uint256 sqrtPMin = sqrt(pMin);
    //         uint256 sqrtPMax = sqrt(pMax);

    //         // Calculate liquidity at the initial price
    //         uint256 L0 = (sqrtPMax * 1e18) / (sqrtPMax - sqrtPMin);

    //         // Calculate the value of the position in the pool
    //         uint256 valueInPool = (L0 * (sqrtPt - sqrtPMin)) / sqrtPt;

    //         // Calculate value if held
    //         uint256 valueIfHeld = (L0 * sqrtP0) / 1e18;

    //         // Calculate impermanent loss
    //         if (valueIfHeld > valueInPool) {
    //             uint256 loss = valueIfHeld - valueInPool;
    //             il = (loss * 1e18) / valueIfHeld; // Return as a percentage (scaled)
    //         } else {
    //             il = 0;
    //         }
    //     }
    // }


    // // function sqrt(uint256 x) internal pure returns (uint256 y) {
    // //     uint256 z = (x + 1) / 2;
    // //     y = x;
    // //     while (z < y) {
    // //         y = z;
    // //         z = (x / z + z) / 2;
    // //     }
    // // }

    // function sqrt(uint y) internal pure returns (uint z) {
    //     if (y > 3) {
    //         z = y;
    //         uint x = y / 2 + 1;
    //         while (x < z) {
    //             z = x;
    //             x = (y / x + x) / 2;
    //         }
    //     } else if (y != 0) {
    //         z = 1;
    //     }
    // }
}

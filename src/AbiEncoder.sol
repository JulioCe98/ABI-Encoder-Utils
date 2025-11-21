// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

contract AbiEncoder {
    /**
     * Creates a unique pool id
     * @param tokenA_ First token address
     * @param tokenB_ Second token address
     * @param fee_  Pool fee ( in basis points )
     * @return poolId Unique identifier of the pool
     */
    function createPoolId(
        address tokenA_,
        address tokenB_,
        uint24 fee_
    ) external view returns (bytes32 poolId) {
        (address token0, address token1) = this.sortTokens(tokenA_, tokenB_);

        poolId = keccak256(abi.encodePacked(token0, token1, fee_));
    }

    /**
     * Encodes data for a trading position
     * @param user_  User address
     * @param tokenIn_  Input token
     * @param tokenOut_  Output token
     * @param amountIn_  Input amount
     * @param minAmountOut_  Min output amount
     * @return positionId Position id
     * @return encodedData Encoded position data
     */
    function encodeTrandingPosition(
        address user_,
        address tokenIn_,
        address tokenOut_,
        uint256 amountIn_,
        uint256 minAmountOut_
    ) external pure returns (bytes32 positionId, bytes memory encodedData) {
        encodedData = abi.encodePacked(
            user_,
            tokenIn_,
            tokenOut_,
            amountIn_,
            minAmountOut_
        );

        positionId = keccak256(encodedData);
    }

    /**
     * Encodes parameters for a swap on a DEX
     * @param path_ Array of tokens for the swap
     * @param amounts_ Array of amounts
     * @param deadline_ Transaction deadline
     * @return swapData Encoded swap data
     */
    function encodeSwapData(
        address[] calldata path_,
        uint256[] calldata amounts_,
        uint256 deadline_
    ) external pure returns (bytes memory swapData) {
        require(path_.length == amounts_.length, "Arrays length mismatch");

        bytes memory pathData;
        for (uint i = 0; i < path_.length; i++) {
            pathData = abi.encodePacked(pathData, path_[i]);
        }

        bytes memory amountsData;
        for (uint i = 0; i < amounts_.length; i++) {
            amountsData = abi.encodePacked(amountsData, amounts_[i]);
        }

        // Combine everything
        swapData = abi.encodePacked(pathData, amountsData, deadline_);
    }

    /**
     * Sort tokens by orden lexicographic
     * @param tokenA_ First token address
     * @param tokenB_  Second token address
     * @return token0 Lower token address
     * @return token1 Highter token addres
     */
    function sortTokens(
        address tokenA_,
        address tokenB_
    ) external pure returns (address token0, address token1) {
        require(tokenA_ != tokenB_, "IDENTICAL_ADDRESSES");
        require(tokenA_ != address(0) && tokenB_ != address(0), "ZERO_ADDRESS");

        (token0, token1) = tokenA_ < tokenB_
            ? (tokenA_, tokenB_)
            : (tokenB_, tokenA_);
    }

    /**
     * Encodes data for a limit order
     * @param maker_ Maker address
     * @param taker_ Taker address
     * @param tokenIn_ Input token
     * @param tokenOut_ Output token
     * @param amountIn_ Input amount
     * @param amountOut_ Output amount
     * @param nonce_ Unique nonce
     * @return orderHash Order hash
     * @return orderData Encoded order data
     */
    function encodeLimitOrder(
        address maker_,
        address taker_,
        address tokenIn_,
        address tokenOut_,
        uint256 amountIn_,
        uint256 amountOut_,
        uint256 nonce_
    ) external pure returns (bytes32 orderHash, bytes memory orderData) {
        orderData = abi.encodePacked(
            maker_,
            taker_,
            tokenIn_,
            tokenOut_,
            amountIn_,
            amountOut_,
            nonce_,
            "LIMIT_ORDER"
        );

        // Create the order hash
        orderHash = keccak256(orderData);
    }

    /**
     * Encodes data for a yield farming position
     * @param user_ User address
     * @param poolId_ Pool identifier
     * @param amount_ Staked amount
     * @param startTime_ Start time
     * @return positionId Position identifier
     */
    function encodeYieldPosition(
        address user_,
        bytes32 poolId_,
        uint256 amount_,
        uint256 startTime_
    ) external pure returns (bytes32 positionId) {
        positionId = keccak256(
            abi.encodePacked(
                user_,
                poolId_,
                amount_,
                startTime_,
                "YIELD_POSITION"
            )
        );
    }

    /**
     * Encodes data for a flash loan
     * @param token_ Flash loan token
     * @param amount_ Loan amount
     * @param callbackData_ Callback data
     * @return flashData Encoded flash loan data
     */
    function encodeFlashLoanData(
        address token_,
        uint256 amount_,
        bytes calldata callbackData_
    ) external pure returns (bytes memory flashData) {
        flashData = abi.encodePacked(
            token_,
            amount_,
            callbackData_,
            "FLASH_LOAN"
        );
    }

    /**
     * Encodes parameters for a staking pool
     * @param token_ Token address
     * @param rewardRate_ Reward rate
     * @param lockPeriod_ Lock period
     * @param maxStakers_ Maximum number of stakers
     * @return poolConfig Encoded configuration data
     */
    function encodeStakingPoolConfig(
        address token_,
        uint256 rewardRate_,
        uint256 lockPeriod_,
        uint256 maxStakers_
    ) external view returns (bytes memory poolConfig) {
        poolConfig = abi.encodePacked(
            token_,
            rewardRate_,
            lockPeriod_,
            maxStakers_,
            block.timestamp
        );
    }

    /**
     * Creates a unique hash for an user across multiple pools
     * @param user_ User address
     * @param poolIds_ Array of pool identifiers
     * @return userHash Unique user hash
     */
    function createUserMultiPoolHash(
        address user_,
        bytes32[] calldata poolIds_
    ) external pure returns (bytes32 userHash) {
        bytes memory data = abi.encodePacked(user_);

        for (uint i = 0; i < poolIds_.length; i++) {
            data = abi.encodePacked(data, poolIds_[i]);
        }

        data = abi.encodePacked(data, "MULTI_POOL_USER");
        userHash = keccak256(data);
    }

    /**
     * Encodes data for a yield farming strategy
     * @param strategyName_ Name of the strategy
     * @param pools_ Array of involved pools
     * @param weights_ Array of weights for each pool
     * @return strategyData Encoded strategy data
     */
    function encodeYieldStrategy(
        string calldata strategyName_,
        address[] calldata pools_,
        uint256[] calldata weights_
    ) external pure returns (bytes memory strategyData) {
        require(pools_.length == weights_.length, "Arrays length mismatch");

        // Encode strategy name
        bytes memory nameData = abi.encodePacked(strategyName_);

        // Encode pools
        bytes memory poolsData;
        for (uint i = 0; i < pools_.length; i++) {
            poolsData = abi.encodePacked(poolsData, pools_[i]);
        }

        // Encode weights
        bytes memory weightsData;
        for (uint i = 0; i < weights_.length; i++) {
            weightsData = abi.encodePacked(weightsData, weights_[i]);
        }

        // Combine everything
        strategyData = abi.encodePacked(
            nameData,
            poolsData,
            weightsData,
            "YIELD_STRATEGY"
        );
    }

    /**
     * Demostrates encoding data for a cross-chain bridge
     * @param sourceChain_ Source chain
     * @param targetChain_ Target chain
     * @param token_ Token to transfer
     * @param amount_ Amount
     * @param recipient_ Recipient
     * @return bridgeData Encoded bridge data
     */
    function encodeCrossChainBridgeData(
        uint256 sourceChain_,
        uint256 targetChain_,
        address token_,
        uint256 amount_,
        address recipient_
    ) external pure returns (bytes memory bridgeData) {
        bridgeData = abi.encodePacked(
            sourceChain_,
            targetChain_,
            token_,
            amount_,
            recipient_,
            "CROSS_CHAIN_BRIDGE"
        );
    }

    /**
     * Creates a unique identifier for a DeFi transaction
     * @param txType_ Transaction type
     * @param user_ User
     * @param timestamp_ Timestamp
     * @param nonce_ Unique nonce
     * @return txId Unique transaction identifier
     */
    function createDeFiTransactionId(
        string calldata txType_,
        address user_,
        uint256 timestamp_,
        uint256 nonce_
    ) external pure returns (bytes32 txId) {
        txId = keccak256(
            abi.encodePacked(txType_, user_, timestamp_, nonce_, "DEFI_TX")
        );
    }

    /**
     * Encodes data for a stop loss order
     * @param user_ User address
     * @param token_ Token to sell
     * @param amount_ Amount to sell
     * @param stopPrice_ Stop loss price
     * @param triggerPrice_ Trigger price
     * @return stopLossData Encoded order data
     */
    function encodeStopLossOrder(
        address user_,
        address token_,
        uint256 amount_,
        uint256 stopPrice_,
        uint256 triggerPrice_
    ) external pure returns (bytes memory stopLossData) {
        stopLossData = abi.encodePacked(
            user_,
            token_,
            amount_,
            stopPrice_,
            triggerPrice_,
            "STOP_LOSS_ORDER"
        );
    }

    /**
     * Encodes data for a take profit order
     * @param user_ User address
     * @param token_ Token to sell
     * @param amount_ Amount to sell
     * @param takeProfitPrice_ Take profit price
     * @return takeProfitData Encoded order data
     */
    function encodeTakeProfitOrder(
        address user_,
        address token_,
        uint256 amount_,
        uint256 takeProfitPrice_
    ) external pure returns (bytes memory takeProfitData) {
        takeProfitData = abi.encodePacked(
            user_,
            token_,
            amount_,
            takeProfitPrice_,
            "TAKE_PROFIT_ORDER"
        );
    }

    /**
     * Encodes data for a trailing stop order
     * @param user_ User address
     * @param token_ Token to sell
     * @param amount_ Amount to sell
     * @param trailingPercent_ Trailing percentage
     * @param activationPrice_ Activation price
     * @return trailingStopData Encoded order data
     */
    function encodeTrailingStopOrder(
        address user_,
        address token_,
        uint256 amount_,
        uint256 trailingPercent_,
        uint256 activationPrice_
    ) external pure returns (bytes memory trailingStopData) {
        trailingStopData = abi.encodePacked(
            user_,
            token_,
            amount_,
            trailingPercent_,
            activationPrice_,
            "TRAILING_STOP_ORDER"
        );
    }
}

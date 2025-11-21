// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import "forge-std/Test.sol";
import {AbiEncoder} from "../src/AbiEncoder.sol";

contract AbiEncoderTest is Test {
    AbiEncoder abiEncoderDemo;

    function setUp() public {
        abiEncoderDemo = new AbiEncoder();
    }

    function testCreatePoolId() public view {
        address tokenA = vm.addr(0x1234);
        address tokenB = vm.addr(0x5678);
        bytes32 poolIdOne = abiEncoderDemo.createPoolId(tokenA, tokenB, 3000);
        bytes32 poolIdTwo = abiEncoderDemo.createPoolId(tokenB, tokenA, 3000);
        assertEq(poolIdOne, poolIdTwo, "Pool ids mismatch");
    }

    function testCreatePoolIdDifferentData() public view {
        address tokenA = vm.addr(0x1234);
        address tokenB = vm.addr(0x5678);

        bytes32 poolIdOne = abiEncoderDemo.createPoolId(tokenA, tokenB, 3000);
        bytes32 poolIdTwo = abiEncoderDemo.createPoolId(tokenA, tokenB, 1000);
        assertTrue(poolIdOne != poolIdTwo, "Pool ids match");
    }

    function testEncodeTrandingPosition() public view {
        address tokenA = vm.addr(0x1234);
        address tokenB = vm.addr(0x5678);
        uint256 amountIn = 1 ether;
        uint256 minAmountOut = 0;

        bytes memory encodedDataExpected = abi.encodePacked(
            address(this),
            tokenA,
            tokenB,
            amountIn,
            minAmountOut
        );

        bytes32 positionIdExpected = keccak256(encodedDataExpected);

        (bytes32 positionId, bytes memory encodedData) = abiEncoderDemo
            .encodeTrandingPosition(
                address(this),
                tokenA,
                tokenB,
                amountIn,
                minAmountOut
            );

        assertEq(positionId, positionIdExpected, "Position id mismatch");
        assertEq(encodedData, encodedDataExpected, "Encoded data mismatch");
    }

    function testEncodeSwapData() public view {
        address tokenA = vm.addr(0x1234);
        address tokenB = vm.addr(0x5678);

        address[] memory path = new address[](2);
        path[0] = tokenA;
        path[1] = tokenB;

        uint256[] memory amounts = new uint256[](2);
        amounts[0] = 1 ether;
        amounts[1] = 2 ether;

        uint deadline = block.timestamp;

        bytes memory pathDataExpected;
        for (uint i = 0; i < path.length; i++) {
            pathDataExpected = abi.encodePacked(pathDataExpected, path[i]);
        }

        bytes memory amountsDataExpected;
        for (uint i = 0; i < amounts.length; i++) {
            amountsDataExpected = abi.encodePacked(
                amountsDataExpected,
                amounts[i]
            );
        }
        bytes memory swapDataExpected = abi.encodePacked(
            pathDataExpected,
            amountsDataExpected,
            deadline
        );

        bytes memory swapData = abiEncoderDemo.encodeSwapData(
            path,
            amounts,
            deadline
        );

        assertEq(swapData, swapDataExpected, "Data mismatch");
    }

    function testEncodeSwapDataInvalidArraysLength() public {
        address tokenA = vm.addr(0x1234);
        address tokenB = vm.addr(0x5678);

        address[] memory path = new address[](2);
        path[0] = tokenA;
        path[1] = tokenB;

        uint256[] memory amounts = new uint256[](1);
        amounts[0] = 1 ether;

        uint deadline = block.timestamp;

        vm.expectRevert("Arrays length mismatch");
        abiEncoderDemo.encodeSwapData(path, amounts, deadline);
    }

    function testSortTokens() public view {
        address tokenA = vm.addr(0x1234);
        address tokenB = vm.addr(0x5678);

        (address token0, address token1) = abiEncoderDemo.sortTokens(
            tokenA,
            tokenB
        );
        (address token0Variated, address token1Variated) = abiEncoderDemo
            .sortTokens(tokenB, tokenA);

        assertEq(token0, token0Variated, "Sort mismatch");
        assertEq(token1, token1Variated, "Sort mismatch");
    }

    function testSortTokensIdenticalAddresses() public {
        address tokenA = vm.addr(0x1234);

        vm.expectRevert("IDENTICAL_ADDRESSES");
        abiEncoderDemo.sortTokens(tokenA, tokenA);
    }

    function testSortTokensZeroAddress() public {
        address tokenA = vm.addr(0x1234);
        address tokenB = address(0);

        vm.expectRevert("ZERO_ADDRESS");
        abiEncoderDemo.sortTokens(tokenA, tokenB);

        tokenA = address(0);
        tokenB = vm.addr(0x5678);

        vm.expectRevert("ZERO_ADDRESS");
        abiEncoderDemo.sortTokens(tokenA, tokenB);
    }

    function testEncodeLimitOrder() public view {
        address maker = vm.addr(1);
        address taker = vm.addr(2);
        address tokenIn = vm.addr(3);
        address tokenOut = vm.addr(4);
        uint256 amountIn = 1 ether;
        uint256 amountOut = 1 ether;
        uint256 nonce = 1000;

        bytes memory orderDataExpected = abi.encodePacked(
            maker,
            taker,
            tokenIn,
            tokenOut,
            amountIn,
            amountOut,
            nonce,
            "LIMIT_ORDER"
        );

        bytes32 orderHashExpected = keccak256(orderDataExpected);

        (bytes32 orderHash, bytes memory orderData) = abiEncoderDemo
            .encodeLimitOrder(
                maker,
                taker,
                tokenIn,
                tokenOut,
                amountIn,
                amountOut,
                nonce
            );
        assertEq(orderHash, orderHashExpected, "Order hash mismatch");
        assertEq(orderData, orderDataExpected, "Order data mismatch");
    }

    function testEncodeYieldPosition() public view {
        address tokenA = vm.addr(0x1234);
        address tokenB = vm.addr(0x5678);
        bytes32 poolId = abiEncoderDemo.createPoolId(tokenA, tokenB, 3000);

        address user = vm.addr(1);
        uint256 amount = 1 ether;
        uint256 startTime = block.timestamp;

        bytes32 positionIdExpected = keccak256(
            abi.encodePacked(user, poolId, amount, startTime, "YIELD_POSITION")
        );

        bytes32 positionId = abiEncoderDemo.encodeYieldPosition(
            user,
            poolId,
            amount,
            startTime
        );

        assertEq(positionId, positionIdExpected, "position id mismatch");
    }

    function testEncodeFlashLoanData() public view {
        address token = vm.addr(1);
        uint256 amount = 1 ether;
        bytes memory callbackData;

        bytes memory flashDataExpected = abi.encodePacked(
            token,
            amount,
            callbackData,
            "FLASH_LOAN"
        );

        bytes memory flashData = abiEncoderDemo.encodeFlashLoanData(
            token,
            amount,
            callbackData
        );

        assertEq(flashData, flashDataExpected, "Flash data mismatch");
    }

    function testEncodeStakingPoolConfig() public view {
        address token = vm.addr(1);
        uint256 rewardRate = 10;
        uint256 lockPeriod = 100;
        uint256 maxStakers = 11000;

        bytes memory poolConfigExpected = abi.encodePacked(
            token,
            rewardRate,
            lockPeriod,
            maxStakers,
            block.timestamp
        );

        bytes memory poolConfig = abiEncoderDemo.encodeStakingPoolConfig(
            token,
            rewardRate,
            lockPeriod,
            maxStakers
        );

        assertEq(poolConfig, poolConfigExpected, "Pool config data mismatch");
    }

    function testCreateUserMultiPoolHash() public view {
        address user = vm.addr(1);

        address tokenA = vm.addr(0x1234);
        address tokenB = vm.addr(0x5678);
        bytes32 poolId = abiEncoderDemo.createPoolId(tokenA, tokenB, 3000);

        address tokenC = vm.addr(0x1111);
        address tokenD = vm.addr(0x2222);
        bytes32 poolIdTwo = abiEncoderDemo.createPoolId(tokenC, tokenD, 2000);

        bytes32[] memory poolIds = new bytes32[](2);
        poolIds[0] = poolId;
        poolIds[1] = poolIdTwo;

        bytes memory data = abi.encodePacked(user);

        for (uint i = 0; i < poolIds.length; i++) {
            data = abi.encodePacked(data, poolIds[i]);
        }

        data = abi.encodePacked(data, "MULTI_POOL_USER");
        bytes32 userHashExpected = keccak256(data);

        bytes32 userHash = abiEncoderDemo.createUserMultiPoolHash(
            user,
            poolIds
        );

        assertEq(userHash, userHashExpected, "User hash mismatch");
    }

    function testEncodeYieldStrategy() public view {
        string memory strategyName = "strategy";
        address[] memory pools = new address[](2);
        pools[0] = vm.addr(1);
        pools[1] = vm.addr(11);

        uint256[] memory weights = new uint256[](2);
        weights[0] = 1000;
        weights[1] = 1000;

        // Encode strategy name
        bytes memory nameData = abi.encodePacked(strategyName);

        // Encode pools
        bytes memory poolsData;
        for (uint i = 0; i < pools.length; i++) {
            poolsData = abi.encodePacked(poolsData, pools[i]);
        }

        // Encode weights
        bytes memory weightsData;
        for (uint i = 0; i < weights.length; i++) {
            weightsData = abi.encodePacked(weightsData, weights[i]);
        }

        bytes memory strategyDataExpected = abi.encodePacked(
            nameData,
            poolsData,
            weightsData,
            "YIELD_STRATEGY"
        );

        bytes memory strategyData = abiEncoderDemo.encodeYieldStrategy(
            strategyName,
            pools,
            weights
        );

        assertEq(strategyData, strategyDataExpected, "Strategy data mismatch");
    }

    function testEncodeYieldStrategyArraysMismatch() public {
        string memory strategyName = "strategy";
        address[] memory pools = new address[](2);
        pools[0] = vm.addr(1);
        pools[1] = vm.addr(11);

        uint256[] memory weights = new uint256[](1);
        weights[0] = 1000;

        vm.expectRevert("Arrays length mismatch");
        abiEncoderDemo.encodeYieldStrategy(strategyName, pools, weights);
    }

    function testEncodeCrossChainBridgeData() public view {
        uint256 sourceChain = 11000;
        uint256 targetChain = 2000;
        address token = vm.addr(1);
        uint256 amount = 2000;
        address recipient = vm.addr(2);

        bytes memory bridgeDataExpected = abi.encodePacked(
            sourceChain,
            targetChain,
            token,
            amount,
            recipient,
            "CROSS_CHAIN_BRIDGE"
        );

        bytes memory bridgeData = abiEncoderDemo.encodeCrossChainBridgeData(
            sourceChain,
            targetChain,
            token,
            amount,
            recipient
        );

        assertEq(bridgeData, bridgeDataExpected, "Bridge data mismatch");
    }

    function testCreateDeFiTransactionId() public view {
        string memory txType = "tx";
        address user = vm.addr(1);
        uint256 timestamp = block.timestamp;
        uint256 nonce = 1;

        bytes32 txIdExpected = keccak256(
            abi.encodePacked(txType, user, timestamp, nonce, "DEFI_TX")
        );

        bytes32 txId = abiEncoderDemo.createDeFiTransactionId(
            txType,
            user,
            timestamp,
            nonce
        );

        assertEq(txId, txIdExpected, "Tx ID mismatch");
    }

    function testEncodeStopLossOrder() public view {
        address user = vm.addr(1);
        address token = vm.addr(2);
        uint256 amount = 1 ether;
        uint256 stopPrice = 11000;
        uint256 triggerPrice = 2000;

        bytes memory stopLossDataExpected = abi.encodePacked(
            user,
            token,
            amount,
            stopPrice,
            triggerPrice,
            "STOP_LOSS_ORDER"
        );
        bytes memory stopLossData = abiEncoderDemo.encodeStopLossOrder(
            user,
            token,
            amount,
            stopPrice,
            triggerPrice
        );

        assertEq(stopLossData, stopLossDataExpected, "SL data mismatch");
    }

    function testEncodeTakeProfitOrder() public view {
        address user = vm.addr(1);
        address token = vm.addr(2);
        uint256 amount = 1 ether;
        uint256 takeProfitPrice = 1000;

        bytes memory takeProfitDataExpected = abi.encodePacked(
            user,
            token,
            amount,
            takeProfitPrice,
            "TAKE_PROFIT_ORDER"
        );

        bytes memory takeProfitData = abiEncoderDemo.encodeTakeProfitOrder(
            user,
            token,
            amount,
            takeProfitPrice
        );

        assertEq(takeProfitData, takeProfitDataExpected, "TP data mismatch");
    }

    function testEncodeTrailingStopOrder() public view {
        address user = vm.addr(1);
        address token = vm.addr(2);
        uint256 amount = 1 ether;
        uint256 trailingPercent = 10;
        uint256 activationPrice = 1100;

        bytes memory trailingStopDataExpected = abi.encodePacked(
            user,
            token,
            amount,
            trailingPercent,
            activationPrice,
            "TRAILING_STOP_ORDER"
        );

        bytes memory trailingStopData = abiEncoderDemo.encodeTrailingStopOrder(
            user,
            token,
            amount,
            trailingPercent,
            activationPrice
        );

        assertEq(
            trailingStopData,
            trailingStopDataExpected,
            "Trailing stop data mismatch"
        );
    }
}

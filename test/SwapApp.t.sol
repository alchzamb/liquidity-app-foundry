// SPDX-License-Identifier: MIT
// For testing in Arbitrum forked: forge test -vvvv --fork-url https://arb1.arbitrum.io/rpc --match-test

pragma solidity 0.8.24;

import "forge-std/Test.sol";
import "../src/SwapApp.sol";
import "../src/interfaces/IFactory.sol";

contract SwappAppTest is Test {
    //Objeto del contrato:
    SwapApp app;
    //Dirección del Router "V2Router02 Contract Address"
    address uniswapV2SwappRouterAddress = 0x4752ba5DBc23f44D87826276BF6Fd6b1C372aD24;

    address uniswapV2FactoryAddress = 0xf1D7CC64Fb4452F05c498126312eBE29f30Fbcf9;
    //Address con fondos para hacer el swap (user)
    address user = 0xF977814e90dA44bFA03b6295A0616a897441aceC; //address con USDT en Arbitrum Mainnet
    //Address del token Token USD₮0 (USD₮0) balance = 120,000,000.000053 USD₮0
    address USDT = 0xFd086bC7CD5C481DCC9C85ebE478A1C0b69FCbb9; //USDT address in Arbitrum Mainnet
    address DAI = 0xDA10009cBd5D07dd0CeCc66161FC93D7c9000da1; //dirección del token DAI en Arbitrum Mainnet

    function setUp() public {
        app = new SwapApp(uniswapV2SwappRouterAddress, uniswapV2FactoryAddress, USDT, DAI);
    }

    function testHasBeenDeployedCorrectly() public view {
        assert(app.V2Router02Address() == uniswapV2SwappRouterAddress);
    }

    function testSwapTokensCorrectly() public {
        vm.startPrank(user);
        uint256 amountIn = 5 * 1e6;
        uint256 amountOutMin = 4 * 1e18;
        IERC20(USDT).approve(address(app), amountIn);
        uint256 deadline = 1738499328 + 1000000000;
        address[] memory path = new address[](2);
        path[0] = USDT;
        path[1] = DAI;

        uint256 usdtBalanceBefore = IERC20(USDT).balanceOf(user);
        uint256 daiBalanceBefore = IERC20(DAI).balanceOf(user);
        app.swapTokens(amountIn, amountOutMin, path, user, deadline);
        uint256 usdtBalanceAfter = IERC20(USDT).balanceOf(user);
        uint256 daiBalanceAfter = IERC20(DAI).balanceOf(user);

        assert(usdtBalanceAfter == usdtBalanceBefore - amountIn);
        assert(daiBalanceAfter > daiBalanceBefore);

        vm.stopPrank();
    }

    function testCanAddLiquidityCorrectly() public {
        vm.startPrank(user);

        uint256 amountIn_ = 6 * 1e6; //6 USDT
        uint256 amountOutMin_ = 2 * 1e18; //2 DAI
        address[] memory path_ = new address[](2);
        path_[0] = USDT;
        path_[1] = DAI;
        uint256 amountAMin_ = 0;
        uint256 amountBMin_ = 0;
        uint256 deadline_ = 1738499328 + 1000000000;

        IERC20(USDT).approve(address(app), amountIn_);
        app.addLiquidity(amountIn_, amountOutMin_, path_, amountAMin_, amountBMin_, deadline_);

        vm.stopPrank();
    }

    function testCanRemoveLiquidityCorrectly() public {
        // 1._ Añadir liquidez primero
        vm.startPrank(user);

        uint256 amountIn_ = 6 * 1e6;
        uint256 amountOutMin_ = 2 * 1e18;
        address[] memory path_ = new address[](2);
        path_[0] = USDT;
        path_[1] = DAI;
        uint256 amountAMin_ = 0;
        uint256 amountBMin_ = 0;
        uint256 deadline_ = 1738499328 + 1000000000;

        IERC20(USDT).approve(address(app), amountIn_);
        app.addLiquidity(amountIn_, amountOutMin_, path_, amountAMin_, amountBMin_, deadline_);

        // 2._ Obtenemos la dirección del token LP y el balance real del usuario
        address lpTokenAddress = IFactory(uniswapV2FactoryAddress).getPair(USDT, DAI);
        uint256 liquidityAmount_ = IERC20(lpTokenAddress).balanceOf(user);
        assertGt(liquidityAmount_, 0); // sanity check: sí recibimos LP tokens

        // 3._ El usuario aprueba a SwapApp para gastar sus LP tokens (igual que con USDT)
        IERC20(lpTokenAddress).approve(address(app), liquidityAmount_);

        uint256 usdtBefore = IERC20(USDT).balanceOf(user);
        uint256 daiBefore = IERC20(DAI).balanceOf(user);

        // 4._ Quitamos liquidez a través de SwapApp
        app.removeLiquidity(liquidityAmount_, amountAMin_, amountBMin_, user, deadline_);

        // 5._ Verificamos que recuperamos USDT y DAI, y que ya no tenemos LP tokens
        assertGt(IERC20(USDT).balanceOf(user), usdtBefore);
        assertGt(IERC20(DAI).balanceOf(user), daiBefore);
        assertEq(IERC20(lpTokenAddress).balanceOf(user), 0);

        vm.stopPrank();
    }
}

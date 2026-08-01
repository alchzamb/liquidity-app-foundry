// SPDX-License-Identifier: MIT

pragma solidity 0.8.24;
//Las funciones de uniswap v2 las añadí de aquí:
//https://docs.quickswap.exchange/technical-reference/smart-contracts/v2/router02

interface IV2Router02 {
    function swapExactTokensForTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint256 amountADesired, //cantidad de liquidez que aportamos del token A
        uint256 amountBDesired, //cantidad de liquidez que aportamos del token B
        uint256 amountAMin, //limita la cantidad mínima que podemos permitir antes de que la transacción revierta
        uint256 amountBMin, //VENTANA: "nunca recibas menos de lo que estás dispuesto a aceptar"
        address to, //es quien recibe el reward, es decir los liquidity tokens
        uint256 deadline //protege contra el tiempo: limita cuánto puede "envejecer" tu transacción antes de ejecutarse
        //OJO con el deadline, para evitar ataques de front-running y manipulación del precio de las pools
    ) external returns (uint256 amountA, uint256 amountB, uint256 liquidity);

    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint256 liquidity, //cantidad de LP tokens que quemas para recuperar tus tokens
        uint256 amountAMin, //límite mínimo de tokenA que aceptas recibir antes de que revierta
        uint256 amountBMin, //VENTANA: "nunca aceptes menos de lo que estás dispuesto a recibir"
        address to, //es quien recibe los tokens subyacentes (tokenA y tokenB) de vuelta
        uint256 deadline //protege contra el tiempo: limita cuánto puede "envejecer" tu transacción antes de ejecutarse
        //OJO con el deadline, para evitar ataques de front-running y manipulación del precio de las pools
    ) external returns (uint256 amountA, uint256 amountB);
}

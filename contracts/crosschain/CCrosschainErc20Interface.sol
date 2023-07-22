// SPDX-License-Identifier: BSD-3-Clause
pragma solidity ^0.8.10;

import "../compound/ComptrollerInterface.sol";
import "../compound/InterestRateModel.sol";
import "../compound/EIP20NonStandardInterface.sol";
import "../compound/ErrorReporter.sol";
import "../compound/CTokenInterfaces.sol";


abstract contract CCrosschainErc20Interface is CErc20Storage {

    /*** User Interface ***/

    function mint(address to, uint mintAmount) virtual external returns (uint);
    function redeem(uint redeemTokens) virtual external returns (uint);
    function redeemUnderlying(uint redeemAmount) virtual external returns (uint);
    function borrow(uint borrowAmount) virtual external returns (uint);
    function repayBorrow(address to, uint repayAmount) virtual external returns (uint);
    function repayBorrowBehalf(address to, address borrower, uint repayAmount) virtual external returns (uint);
    function liquidateBorrow(address borrower, uint repayAmount, CTokenInterface cTokenCollateral) virtual external returns (uint);
    function sweepToken(EIP20NonStandardInterface token) virtual external;


    /*** Admin Functions ***/

    function _addReserves(uint addAmount) virtual external returns (uint);
}

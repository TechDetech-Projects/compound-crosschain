// SPDX-License-Identifier: BSD-3-Clause
pragma solidity ^0.8.10;

import "@axelar-network/axelar-gmp-sdk-solidity/contracts/executable/AxelarExecutable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "../compound/CToken.sol";
import "./CCrosschainErc20Interface.sol";

interface CompLike {
    function delegate(address delegatee) external;
}

/**
 * @title Compound's CErc20 Contract
 * @notice CTokens which wrap an EIP-20 underlying
 * @author Compound
 */
contract CCrosschainErc20 is CToken, CCrosschainErc20Interface, AxelarExecutable {
    string chain;
    string underlyingSatellite;
    bytes32 internal constant SELECTOR_MINT= keccak256('mint');
    bytes32 internal constant SELECTOR_REPAY_BORROW = keccak256('repayBorrow');
    bytes32 internal constant SELECTOR_REPAY_BORROW_BEHALF = keccak256('repayBorrowBehalf');
    bytes32 internal constant SELECTOR_ADD_RESERVES = keccak256('_addReserves');
    bytes32 internal constant SELECTOR_UPDATE_TRANSFER_OUT = keccak256('updateTransferOut');

    uint underlyingBalance = 0;
    uint priorUnderlyingBalance = 0;

      modifier onlySelf() {
        require(msg.sender == address(this), 'Function must be called by the same contract only');
        _;
    }

    /**
     * @notice Initialize the new money market
     * @param underlyingSatellite_ The address of the underlying asset
     * @param comptroller_ The address of the Comptroller
     * @param interestRateModel_ The address of the interest rate model
     * @param initialExchangeRateMantissa_ The initial exchange rate, scaled by 1e18
     * @param name_ ERC-20 name of this token
     * @param symbol_ ERC-20 symbol of this token
     * @param decimals_ ERC-20 decimal precision of this token
     */
    constructor(
        address gateway_,
        string memory chain_,
        string memory underlyingSatellite_,
        ComptrollerInterface comptroller_,
        InterestRateModel interestRateModel_,
        uint initialExchangeRateMantissa_,
        string memory name_,
        string memory symbol_,
        uint8 decimals_
    ) AxelarExecutable(gateway_) {
        initialize(
            comptroller_,
            interestRateModel_,
            initialExchangeRateMantissa_,
            name_,
            symbol_,
            decimals_
        );
        chain = chain_;
        underlyingSatellite = underlyingSatellite_;
    }

    function _setUnderlyingSatellite(string memory underlyingSatellite_) public {
        require(msg.sender == admin, "Only admin may change underlying satellite contract.");
        underlyingSatellite = underlyingSatellite_;
    }

    /*** User Interface ***/

    /**
     * @notice Sender supplies assets into the market and receives cTokens in exchange
     * @dev Accrues interest whether or not the operation succeeds, unless reverted
     * @param mintAmount The amount of the underlying asset to supply
     * @return uint 0=success, otherwise a failure (see ErrorReporter.sol for details)
     */
    function mint(address to,uint mintAmount) external override onlySelf returns (uint) {
        accrueInterest();
        mintFresh(to, mintAmount);
        return NO_ERROR;
    }

    /**
     * @notice Sender redeems cTokens in exchange for the underlying asset
     * @dev Accrues interest whether or not the operation succeeds, unless reverted
     * @param redeemTokens The number of cTokens to redeem into underlying
     * @return uint 0=success, otherwise a failure (see ErrorReporter.sol for details)
     */
    function redeem(uint redeemTokens) external override returns (uint) {
        redeemInternal(redeemTokens);
        return NO_ERROR;
    }

    /**
     * @notice Sender redeems cTokens in exchange for a specified amount of underlying asset
     * @dev Accrues interest whether or not the operation succeeds, unless reverted
     * @param redeemAmount The amount of underlying to redeem
     * @return uint 0=success, otherwise a failure (see ErrorReporter.sol for details)
     */
    function redeemUnderlying(
        uint redeemAmount
    ) external override returns (uint) {
        redeemUnderlyingInternal(redeemAmount);
        return NO_ERROR;
    }

    /**
     * @notice Sender borrows assets from the protocol to their own address
     * @param borrowAmount The amount of the underlying asset to borrow
     * @return uint 0=success, otherwise a failure (see ErrorReporter.sol for details)
     */
    function borrow(uint borrowAmount) external override returns (uint) {
        borrowInternal(borrowAmount);
        return NO_ERROR;
    }

    /**
     * @notice Sender repays their own borrow
     * @param repayAmount The amount to repay, or -1 for the full outstanding amount
     * @return uint 0=success, otherwise a failure (see ErrorReporter.sol for details)
     */
    function repayBorrow(address to, uint repayAmount) external override onlySelf returns (uint) {
        accrueInterest();
        repayBorrowFresh(to, to, repayAmount);
        return NO_ERROR;
    }

    /**
     * @notice Sender repays a borrow belonging to borrower
     * @param borrower the account with the debt being payed off
     * @param repayAmount The amount to repay, or -1 for the full outstanding amount
     * @return uint 0=success, otherwise a failure (see ErrorReporter.sol for details)
     */
    function repayBorrowBehalf(
        address to,
        address borrower,
        uint repayAmount
    ) external override onlySelf returns (uint) {
        accrueInterest();
        repayBorrowFresh(to, borrower, repayAmount);
        return NO_ERROR;
    }

    /**
     * @notice The sender liquidates the borrowers collateral.
     *  The collateral seized is transferred to the liquidator.
     * @param borrower The borrower of this cToken to be liquidated
     * @param repayAmount The amount of the underlying borrowed asset to repay
     * @param cTokenCollateral The market in which to seize collateral from the borrower
     * @return uint 0=success, otherwise a failure (see ErrorReporter.sol for details)
     */
    function liquidateBorrow(
        address borrower,
        uint repayAmount,
        CTokenInterface cTokenCollateral
    ) external override returns (uint) {
        liquidateBorrowInternal(borrower, repayAmount, cTokenCollateral);
        return NO_ERROR;
    }

    /**
     * @notice A public function to sweep accidental ERC-20 transfers to this contract. Tokens are sent to admin (timelock)
     * @param token The address of the ERC-20 token to sweep
     */
    function sweepToken(EIP20NonStandardInterface token) external override {
        require(
            msg.sender == admin,
            "CErc20::sweepToken: only admin can sweep tokens"
        );
        require(
            address(token) != underlying,
            "CErc20::sweepToken: can not sweep underlying token"
        );
        uint256 balance = token.balanceOf(address(this));
        token.transfer(admin, balance);
    }

    /**
     * @notice The sender adds to reserves.
     * @param addAmount The amount fo underlying token to add as reserves
     * @return uint 0=success, otherwise a failure (see ErrorReporter.sol for details)
     */
    function _addReserves(uint addAmount) external override onlySelf returns (uint) {
        return _addReservesInternal(addAmount); 
    }

    /*** Safe Token ***/

    /**
     * @notice Gets balance of this contract in terms of the underlying
     * @dev This excludes the value of the current message, if any
     * @return The quantity of underlying tokens owned by this contract
     */
    function getCashPrior() internal view virtual override returns (uint) {
        return priorUnderlyingBalance;
    }

    /**
     * @dev Similar to EIP20 transfer, except it handles a False result from `transferFrom` and reverts in that case.
     *      This will revert due to insufficient balance or insufficient allowance.
     *      This function returns the actual amount received,
     *      which may be less than `amount` if there is a fee attached to the transfer.
     *
     *      Note: This wrapper safely handles non-standard ERC-20 tokens that do not return a value.
     *            See here: https://medium.com/coinmonks/missing-return-value-bug-at-least-130-tokens-affected-d67bf08521ca
     */
    function doTransferIn(
        address,
        uint amount
    ) internal virtual override returns (uint) {
        priorUnderlyingBalance = underlyingBalance;
        underlyingBalance += amount;
        return amount;
    }

    /**
     * @dev Similar to EIP20 transfer, except it handles a False success from `transfer` and returns an explanatory
     *      error code rather than reverting. If caller has not called checked protocol's balance, this may revert due to
     *      insufficient cash held in this contract. If caller has checked protocol's balance prior to this call, and verified
     *      it is >= amount, this should not revert in normal conditions.
     *
     *      Note: This wrapper safely handles non-standard ERC-20 tokens that do not return a value.
     *            See here: https://medium.com/coinmonks/missing-return-value-bug-at-least-130-tokens-affected-d67bf08521ca
     */
    function doTransferOut(
        address payable to,
        uint amount
    ) internal virtual override {
        bytes memory params = abi.encode(to,amount);
        bytes memory payload = abi.encode('doTranferOut', params);
        gateway.callContract(chain, underlyingSatellite, payload);
    }

    function updateTransferOut(uint amount) external onlySelf {
        priorUnderlyingBalance = underlyingBalance;
        underlyingBalance -= amount;
    }


    /**
     * @notice Admin call to delegate the votes of the COMP-like underlying
     * @param compLikeDelegatee The address to delegate votes to
     * @dev CTokens whose underlying are not CompLike should revert here
     */
    function _delegateCompLikeTo(address compLikeDelegatee) external {
        require(
            msg.sender == admin,
            "only the admin may set the comp-like delegate"
        );
        CompLike(underlying).delegate(compLikeDelegatee);
    }

    // Handles calls created by. Updates this contract's value
    function _execute(
        string calldata sourceChain_,
        string calldata sourceAddress_,
        bytes calldata payload_
    ) internal override {
        require(Strings.equal(sourceChain_,chain), "Wrong source chain.");
        require(Strings.equal(sourceAddress_,underlyingSatellite), "Only underlying satellite contract can call this function.");
        (bytes memory functionName, bytes memory params) = abi.decode(payload_, (bytes, bytes));

        bytes4 commandSelector;

        if (keccak256(functionName) == SELECTOR_MINT) {
            commandSelector = this.mint.selector;
        } else if (keccak256(functionName) == SELECTOR_REPAY_BORROW){
            commandSelector = this.repayBorrow.selector;
        }else if (keccak256(functionName) == SELECTOR_REPAY_BORROW_BEHALF){
            commandSelector = this.repayBorrowBehalf.selector;
        } else if (keccak256(functionName) == SELECTOR_ADD_RESERVES) {
            commandSelector = this._addReserves.selector;
        } else if (keccak256(functionName) == SELECTOR_UPDATE_TRANSFER_OUT) {
            commandSelector = this.updateTransferOut.selector;
        } else {
            revert('Invalid function name');
        }

        (bool success, bytes memory result) = address(this).call(
            abi.encodeWithSelector(commandSelector, params)
        );

         if (!success) {
            if (result.length == 0) {
                require(success, 'Failed with no reason');
            } else {
                // rethrow same error
                assembly {
                    let start := add(result, 0x20)
                    let end := add(result, mload(result))
                    revert(start, end)
                }
            }
        }

    }
}

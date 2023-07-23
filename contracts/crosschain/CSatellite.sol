//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import '@axelar-network/axelar-gmp-sdk-solidity/contracts/executable/AxelarExecutable.sol';
import '@axelar-network/axelar-gmp-sdk-solidity/contracts/interfaces/IERC20.sol';
import '@openzeppelin/contracts/utils/Strings.sol';

contract CSatellite is AxelarExecutable {
    string public baseChain;
    string public baseContract;
    IERC20 underlyingToken;
    bytes32 internal constant SELECTOR_DO_TRANSFER_OUT = keccak256('doTransferOut');

    modifier onlySelf() {
        require(msg.sender == address(this), 'Function must be called by the same contract only');
        _;
    }

    constructor(
        address gateway_,
        string memory baseChain_,
        string memory baseContract_,
        address underlyingToken_
    ) AxelarExecutable(gateway_) {
        baseChain = baseChain_;
        baseContract = baseContract_;
        underlyingToken = IERC20(underlyingToken_);
    }

    function mint(uint amount) external {
        underlyingToken.transferFrom(msg.sender, address(this), amount);
        bytes memory params = abi.encode(msg.sender,amount);
        bytes memory payload = abi.encode('mint', params);

        gateway.callContract(baseChain, baseContract, payload);
    }

    function repayBorrow(uint repayAmount) external {
        underlyingToken.transferFrom(msg.sender, address(this), repayAmount);
        bytes memory params = abi.encode(msg.sender,repayAmount);
        bytes memory payload = abi.encode('repayBorrow', params);

        gateway.callContract(baseChain, baseContract, payload);
    }

    function _addReserves(uint addAmount) external {
        underlyingToken.transferFrom(msg.sender, address(this), addAmount);
        bytes memory params = abi.encode(addAmount);
        bytes memory payload = abi.encode('_addReserves', params);

        gateway.callContract(baseChain, baseContract, payload);
    }

    function repayBorrowBehalf(address borrower, uint repayAmount) external {
        underlyingToken.transferFrom(msg.sender, address(this), repayAmount);
        bytes memory params = abi.encode(msg.sender,borrower,repayAmount);
        bytes memory payload = abi.encode('repayBorrowBehalf', params);

        gateway.callContract(baseChain, baseContract, payload);
    }

    function doTransferOut(address to, uint amount) external onlySelf {
       underlyingToken.transferFrom(address(this),to,amount);

       bytes memory params = abi.encode(amount);
       bytes memory payload = abi.encode('updateTransferOut', params);
       
       gateway.callContract(baseChain, baseContract, payload);
    }

    function _execute(
        string calldata sourceChain_,
        string calldata sourceAddress_,
        bytes calldata payload_
    ) internal override {
        require(Strings.equal(sourceChain_,baseChain), "Wrong source chain.");
        require(Strings.equal(sourceAddress_,baseContract), "Only base CToken contract can call this function.");
        (bytes memory functionName, bytes memory params) = abi.decode(payload_, (bytes, bytes));

        bytes4 commandSelector;

        if (keccak256(functionName) == SELECTOR_DO_TRANSFER_OUT) {
            commandSelector = this.doTransferOut.selector;
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
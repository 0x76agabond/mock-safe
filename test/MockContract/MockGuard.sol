pragma solidity =0.8.26;
// SPDX-License-Identifier: MIT

/**
 * \
 * Author: Hoang <ginz1504@gmail.com>
 * Contact: https://github.com/0x76agabond
 * =============================================================================
 * Gnosis Safe Mock (NotSafe)
 * /*****************************************************************************
 */
import "forge-std/Test.sol";
import "forge-std/console2.sol";
import "forge-std/console.sol";
import {Enum} from "./libraries/Enum.sol";
import {ISafe} from "./interfaces/ISafe.sol";
import {BaseGuard} from "./base/BaseGuard.sol";

contract MockGuard is BaseGuard {
    // Safe recommend to leave this function as blank fallback
    fallback() external {}

    // Safe call this function before execute transaction
    function checkTransaction(
        address to,
        uint256 value,
        bytes memory data,
        Enum.Operation operation,
        uint256 safeTxGas,
        uint256 baseGas,
        uint256 gasPrice,
        address gasToken,
        address payable refundReceiver,
        bytes memory signatures,
        address executor
    ) external override {
        bytes32 txHash;
        uint256 nonce;
        {
            ISafe safe = ISafe(payable(msg.sender));
            nonce = safe.nonce();
            //// nonce++ when pass to this function so you should - 1 to get real nonce
            txHash = safe.getTransactionHash(
                to, value, data, operation, safeTxGas, baseGas, gasPrice, gasToken, refundReceiver, nonce - 1
            );

            console.log("checkTransaction");
        }
    }

    // Safe call this function after execute transaction
    function checkAfterExecution(bytes32 txHash, bool success) external override {
        // normaly, you should do change the state of Guard here.
        console.log("checkAfterExecution");
    }

    // Safe call this function before execute transaction using module
    function checkModuleTransaction(
        address to,
        uint256 value,
        bytes memory data,
        Enum.Operation operation,
        address module
    ) external pure override returns (bytes32 moduleTxHash) {
        // moduleTxHash = keccak256(abi.encodePacked(to, value, data, operation, module));
        // Implement Guard Multisig Here
        console.log("checkModuleTransaction");
    }

    // Safe call this function after execute transaction using module
    function checkAfterModuleExecution(bytes32 txHash, bool success) external override {
        // Implement Guard Multisig Confirm Here
        console.log("checkAfterModuleExecution");
    }
}

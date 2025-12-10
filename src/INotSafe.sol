// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {Enum} from "./libraries/Enum.sol";

interface INotSafe {
    // ---------------------------------------------------------
    // Events (MATCH EXACTLY NotSafe contract)
    // ---------------------------------------------------------

    // Module events
    event ModuleAdded(address module);
    event ModuleRemoved(address module);
    event ModuleError();

    // Guard events
    event GuardChanged(address guard);
    event GuardError();

    // Owner management events
    event OwnersCleared();
    event OwnerAdded(address owner);
    event OwnersError();
    event ThresholdChanged(uint256 newThreshold);

    // Execution events
    event ExecutionSuccess(bytes32 indexed txHash, uint256 payment);
    event ExecutionFailure(bytes32 indexed txHash, uint256 payment);
    event ExecutionFromModuleSuccess(address sender);
    event ExecutionFromModuleFailure(address sender);

    event ExecTransactionCalled(
        bytes32 indexed txHash,
        address indexed to,
        uint256 value,
        address indexed sender,
        bool success,
        bytes returnData
    );

    // ---------------------------------------------------------
    // Read functions
    // ---------------------------------------------------------

    function getOwners() external view returns (address[] memory result);

    function nonce() external view returns (uint256);
    function threshold() external view returns (uint256);
    function guardAddress() external view returns (address);
    function fallbackAddress() external view returns (address);
    function activateSignature() external view returns (bool);

    // ---------------------------------------------------------
    // Owner + Threshold functions
    // ---------------------------------------------------------

    function setOwnersAndThreshold(address[] calldata newOwners, uint256 newThreshold) external returns (bool);

    function swapOwner(address previousOwner, address oldOwner, address newOwner) external returns (bool);

    // ---------------------------------------------------------
    // Module functions
    // ---------------------------------------------------------

    function setModule(address module) external returns (bool);
    function removeModule(address module) external returns (bool);

    // ---------------------------------------------------------
    // Guard functions
    // ---------------------------------------------------------

    function setGuard(address guard) external returns (bool);

    // ---------------------------------------------------------
    // Fallback Handler
    // ---------------------------------------------------------

    function setFallbackHandler(address fallbackHandler) external;

    // ---------------------------------------------------------
    // Signature toggle
    // ---------------------------------------------------------

    function changeActivateSignature(bool activate) external;

    // ---------------------------------------------------------
    // Execution API — main Safe-style functions
    // ---------------------------------------------------------

    function execTransaction(
        address to,
        uint256 value,
        bytes calldata data,
        Enum.Operation operation,
        uint256 safeTxGas,
        uint256 baseGas,
        uint256 gasPrice,
        address gasToken,
        address payable refundReceiver,
        bytes calldata signatures
    ) external payable returns (bool success);

    function execTransactionFromModule(address to, uint256 value, bytes calldata data, Enum.Operation operation)
        external
        returns (bool success);

    function execTransactionFromModuleReturnData(
        address to,
        uint256 value,
        bytes calldata data,
        Enum.Operation operation
    ) external returns (bool success, bytes memory returnData);

    // ---------------------------------------------------------
    // Hash helper
    // ---------------------------------------------------------

    function getTransactionHash(
        address to,
        uint256 value,
        bytes calldata data,
        Enum.Operation operation,
        uint256 safeTxGas,
        uint256 baseGas,
        uint256 gasPrice,
        address gasToken,
        address refundReceiver,
        uint256 _nonce
    ) external view returns (bytes32);
}

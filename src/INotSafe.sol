// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {Enum} from "./libraries/Enum.sol";

interface INotSafe {
    // =========================================================
    //                       ERRORS
    // =========================================================
    error GuardError();
    error OwnersError();
    error ModuleError();
    error ExecutionFailure(bytes32 txHash, uint256 payment);
    error ExecutionFromModuleFailure(address sender);

    // =========================================================
    //                       EVENTS
    // =========================================================
    event ActivateSignatureChanged(address sender);
    event GuardChanged(address guard);

    event ExecutionSuccess(bytes32 indexed txHash, uint256 payment);
    event ExecutionFromModuleSuccess(address sender);

    event OwnersCleared();
    event OwnerAdded(address owner);
    event ThresholdChanged(uint256 newThreshold);

    event ModuleAdded(address module);
    event ModuleRemoved(address module);

    // =========================================================
    //                       VIEW FUNCTIONS
    // =========================================================
    function nonce() external view returns (uint256);
    function threshold() external view returns (uint256);
    function _txHash() external view returns (bytes32);

    function getOwners() external view returns (address[] memory);

    // =========================================================
    //                       GUARD
    // =========================================================
    function guardAddress() external view returns (address);
    function setGuard(address guard) external returns (bool);

    // =========================================================
    //                       MODULES
    // =========================================================
    function setModule(address module) external returns (bool);
    function removeModule(address module) external returns (bool);
    function isModuleActivated(address module) external view returns (bool);

    // =========================================================
    //                       OWNERS
    // =========================================================
    function setOwnersAndThreshold(address[] calldata newOwners, uint256 newThreshold) external returns (bool);

    function swapOwner(address previousOwner, address oldOwner, address newOwner) external returns (bool);

    // =========================================================
    //                       SIGNATURES
    // =========================================================
    function activateSignature() external view returns (bool);
    function changeActivateSignature(bool activate) external;
    function checkSignatures(bytes32 txHash, bytes memory signatures) external view returns (bool);

    // =========================================================
    //                       CORE EXECUTION
    // =========================================================

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
        bytes memory signatures
    ) external payable returns (bool success);

    function execTransactionFromModule(address to, uint256 value, bytes memory data, Enum.Operation operation)
        external
        returns (bool success);

    function execTransactionFromModuleReturnData(address to, uint256 value, bytes memory data, Enum.Operation operation)
        external
        returns (bool success, bytes memory returnData);

    // =========================================================
    //                       UTIL
    // =========================================================

    function getTransactionHash(
        address to,
        uint256 value,
        bytes memory data,
        Enum.Operation operation,
        uint256 safeTxGas,
        uint256 baseGas,
        uint256 gasPrice,
        address gasToken,
        address refundReceiver,
        uint256 nonce
    ) external view returns (bytes32);
}

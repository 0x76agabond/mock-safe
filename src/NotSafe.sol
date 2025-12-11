// SPDX-License-Identifier: MIT

/*************************************************************************
 * \
 * Author: Hoang <ginz1504@gmail.com>
 * Contact: https://github.com/0x76agabond
 * =============================================================================
 * Gnosis Safe Mock (NotSafe)
 * /*****************************************************************************
 */
pragma solidity ^0.8.26;

import "forge-std/console2.sol";

import {ITransactionGuard} from "./interfaces/ITransactionGuard.sol";
import {IModuleGuard} from "./interfaces/IModuleGuard.sol";

import {Enum} from "./libraries/Enum.sol";
import {Transaction} from "./libraries/Transaction.sol";
import {Executor} from "./libraries/Executor.sol";
import {SignatureHandler} from "./libraries/SignatureHandler.sol";
import {EnumerableSet} from "openzeppelin-contracts/contracts/utils/structs/EnumerableSet.sol";

contract NotSafe {
    using EnumerableSet for EnumerableSet.AddressSet;

    receive() external payable {}

    uint256 public nonce = 0;
    uint256 public threshold = 0;
    bytes32 public _txHash;

    EnumerableSet.AddressSet owners;
    mapping(address => bool) isOwner;

    function getOwners() external view returns (address[] memory result) {
        uint256 len = owners.length();
        result = new address[](len);

        for (uint256 i = 0; i < len; i++) {
            result[i] = owners.at(i);
        }
    }

    EnumerableSet.AddressSet modules;
    mapping(address => bool) isModuleActivated;

    bool public activateSignature = true;

    function changeActivateSignature(bool activate) public {
        activateSignature = activate;
        emit ActivateSignatureChanged(msg.sender);
    }

    // Module execution related
    event ActivateSignatureChanged(address sender);

    event GuardChanged(address guard);
    error GuardError();

    event ExecutionSuccess(bytes32 indexed txHash, uint256 payment);
    event ExecutionFailure(bytes32 txHash, uint256 payment);
    event ExecutionFromModuleSuccess(address sender);
    event ExecutionFromModuleFailure(address sender);

    event OwnersCleared();
    event OwnerAdded(address owner);
    error OwnersError();
    event ThresholdChanged(uint256 newThreshold);

    event ModuleAdded(address module);
    event ModuleRemoved(address module);
    error ModuleError();

    // ===========================================
    // This is where you can setup a Guard
    // No auth since this is a mock
    // Highly unrecommend on production
    // ===========================================
    address public guardAddress;

    function setGuard(address guard) public returns (bool) {
        if (guard == address(0) || guard == guardAddress) {
            revert GuardError();
        }

        guardAddress = guard;

        emit GuardChanged(guard);
        return true;
    }

    // ===========================================
    function setModule(address module) public returns (bool) {
        if (isModuleActivated[module]) {
            revert ModuleError();
        }

        isModuleActivated[module] = true;
        modules.add(module);

        emit ModuleAdded(module);
        return true;
    }

    function removeModule(address module) public returns (bool) {
        if (!isModuleActivated[module]) {
            revert ModuleError();
        }

        isModuleActivated[module] = false;
        modules.remove(module);

        emit ModuleRemoved(module);
        return true;
    }

    // ===========================================
    address public fallbackAddress;

    function setFallbackHandler(address fallbackHandler) public {
        fallbackAddress = fallbackHandler;
    }

    // ===========================================

    function setOwnersAndThreshold(address[] calldata newOwners, uint256 newThreshold) external returns (bool) {
        // Validate input first
        if (newOwners.length == 0) {
            revert OwnersError();
        }

        if (newThreshold == 0) {
            revert OwnersError();
        }

        if (newThreshold > newOwners.length) {
            revert OwnersError();
        }

        // Clear current owners
        uint256 lenOld = owners.length();
        for (uint256 i = lenOld; i > 0;) {
            address a = owners.at(i - 1);
            owners.remove(a);
            isOwner[a] = false;

            unchecked {
                --i;
            }
        }

        emit OwnersCleared();

        // Add new owners
        for (uint256 i = 0; i < newOwners.length; i++) {
            address o = newOwners[i];

            if (o == address(0)) {
                revert OwnersError();
            }

            if (owners.add(o)) {
                isOwner[o] = true;
                emit OwnerAdded(o);
            }
        }

        // Apply threshold
        threshold = newThreshold;
        emit ThresholdChanged(newThreshold);

        return true;
    }

    // Safe Internal check here
    function onBeforeExecTransaction(
        address to,
        uint256 value,
        bytes calldata data,
        Enum.Operation operation,
        uint256 safeTxGas,
        uint256 baseGas,
        uint256 gasPrice,
        address gasToken,
        address refundReceiver,
        bytes memory signatures
    ) internal view {
        // for this NotSafe, just do nothing
        // you can add some magic here but it better to do with Safe Guard
    }

    // Guard Handler here
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
    ) external payable returns (bool success) {
        _txHash = Transaction.getTransactionHash(
            address(this), to, value, data, operation, safeTxGas, baseGas, gasPrice, gasToken, refundReceiver, nonce
        );

        nonce += 1;

        // this block remove some calculaion on original Safe
        // since this is a mock Safe, I remove some gas calculation and payment

        bool sigActive = activateSignature;
        if (sigActive) {
            require(checkSignatures(_txHash, signatures), "Invalid Signature");
        }

        if (guardAddress != address(0)) {
            ITransactionGuard(guardAddress)
                .checkTransaction(
                    to,
                    value,
                    data,
                    operation,
                    safeTxGas,
                    baseGas,
                    gasPrice,
                    gasToken,
                    refundReceiver,
                    signatures,
                    msg.sender
                );
        }

        // exec transaction here
        success = Executor.execute(to, value, data, operation, gasPrice == 0 ? (gasleft() - 2500) : safeTxGas);

        if (success) emit ExecutionSuccess(_txHash, 0);
        else emit ExecutionFailure(_txHash, 0);

        if (guardAddress != address(0)) {
            ITransactionGuard(guardAddress).checkAfterExecution(_txHash, true);
        }
    }

    // Module Handler here
    function execTransactionFromModule(address to, uint256 value, bytes memory data, Enum.Operation operation)
        external
        returns (bool success)
    {
        require(isModuleActivated[address(msg.sender)], "module not activated!");

        //bytes32 moduleTxHash = keccak256(abi.encodePacked(to, value, data, operation, module));
        bytes32 moduleTxHash;

        if (guardAddress != address(0)) {
            moduleTxHash = IModuleGuard(guardAddress).checkModuleTransaction(to, value, data, operation, msg.sender);
        }

        success = Executor.execute(to, value, data, operation, type(uint256).max);

        if (guardAddress != address(0)) {
            IModuleGuard(guardAddress).checkAfterModuleExecution(moduleTxHash, success);
        }

        if (success) emit ExecutionFromModuleSuccess(msg.sender);
        else emit ExecutionFromModuleFailure(msg.sender);
    }

    function execTransactionFromModuleReturnData(address to, uint256 value, bytes memory data, Enum.Operation operation)
        external
        returns (bool success, bytes memory returnData)
    {
        bytes32 moduleTxHash;
        address guard = guardAddress;

        if (guard != address(0)) {
            moduleTxHash = IModuleGuard(guard).checkModuleTransaction(to, value, data, operation, msg.sender);
        }

        success = Executor.execute(to, value, data, operation, type(uint256).max);

        assembly {
            returnData := mload(0x40)
            mstore(0x40, add(returnData, add(returndatasize(), 0x20)))
            mstore(returnData, returndatasize())
            returndatacopy(add(returnData, 0x20), 0, returndatasize())
        }

        if (guard != address(0)) {
            IModuleGuard(guard).checkAfterModuleExecution(moduleTxHash, success);
        }

        if (success) emit ExecutionFromModuleSuccess(msg.sender);
        else emit ExecutionFromModuleFailure(msg.sender);
    }

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
        uint256 _nonce
    ) public view returns (bytes32) {
        return Transaction.getTransactionHash(
            address(this), to, value, data, operation, safeTxGas, baseGas, gasPrice, gasToken, refundReceiver, _nonce
        );
    }

    // Fallback Handler here
    fallback() external {
        address handle = fallbackAddress;
        if (handle != address(0)) {
            assembly {
                calldatacopy(0, 0, calldatasize())
                let success := delegatecall(gas(), handle, 0, calldatasize(), 0, 0)
                returndatacopy(0, 0, returndatasize())
                if eq(success, 0) { revert(0, returndatasize()) }
                return(0, returndatasize())
            }
        }
    }

    /*
    // ================================================
    // Swap Owner
    // Safe Original Implementation
    // At this point we need a implement mimic  this behave
    // ================================================

    // variables
    address public constant SENTINEL_OWNERS = address(0x1);

    function swapOwner(address prevOwner, address oldOwner, address newOwner) public authorized {
        // Owner address cannot be null, the sentinel or the Safe itself.
        require(newOwner != address(0) && newOwner != SENTINEL_OWNERS && newOwner != address(this), "GS203");
        // No duplicate owners allowed.
        require(owners[newOwner] == address(0), "GS204");
        // Validate oldOwner address and check that it corresponds to owner index.
        require(oldOwner != address(0) && oldOwner != SENTINEL_OWNERS, "GS203");
        require(owners[prevOwner] == oldOwner, "GS205");
        owners[newOwner] = owners[oldOwner];
        owners[prevOwner] = newOwner;
        owners[oldOwner] = address(0);
        emit RemovedOwner(oldOwner);
        emit AddedOwner(newOwner);
    }


    */

    // variables
    address public constant SENTINEL_OWNERS = address(0x1);

    // this is just try to mimic the behave "swapOwner"
    // highly unrecommend
    function swapOwner(address previousOwner, address oldOwner, address newOwner) external returns (bool) {
        require(isOwner[oldOwner], "Old owner not found");
        require(newOwner != address(0) && newOwner != SENTINEL_OWNERS, "New Owner Invalid");
        if (previousOwner != SENTINEL_OWNERS) {
            require(isOwner[previousOwner], "previousOwner not found");
        }

        require(!isOwner[newOwner], "newOwner Invalid");

        uint256 len = owners.length();
        address[] memory arr = new address[](len);
        for (uint256 i = 0; i < len; i++) {
            arr[i] = owners.at(i);
        }

        // find index
        int256 idx = -1;
        for (uint256 i = 0; i < len; i++) {
            if (arr[i] == oldOwner) {
                idx = int256(i);
                break;
            }
        }
        require(idx >= 0, "Old owner not found");

        // clear existing set
        for (uint256 i = 0; i < len; i++) {
            owners.remove(arr[i]);
            isOwner[arr[i]] = false;
        }

        // re-add with replacement at idx
        for (uint256 i = 0; i < len; i++) {
            address o = (i == uint256(idx)) ? newOwner : arr[i];
            if (owners.add(o)) {
                isOwner[o] = true;
            }
        }

        return true;
    }

    function checkSignatures(bytes32 txHash, bytes memory signatures) public view returns (bool) {
        SignatureHandler._validateSignatures(signatures, threshold);

        uint256 counter = 0;
        for (uint256 i = 0; i < signatures.length; i += SignatureHandler.SIGNATURE_SIZE) {
            (uint8 v, bytes32 r, bytes32 s_) = SignatureHandler.signatureSplit(signatures, i);
            address recovered = SignatureHandler._recoverSigner(txHash, v, r, s_);

            require(recovered != address(0), "Blank Owner");
            require(isOwner[recovered], "Invalid Owner");

            if (++counter >= threshold) {
                return true;
            }
        }

        return false;
    }
}

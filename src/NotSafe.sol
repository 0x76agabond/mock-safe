// SPDX-License-Identifier: MIT

/**
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
    }

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

    // This is where you can setup a Guard
    // No auth since this is a mock
    // Highly unrecommend on production
    // ===========================================
    address public guardAddress;

    function setGuard(address guard) public {
        guardAddress = guard;
    }

    // ===========================================
    function setModule(address module) public {
        require(!isModuleActivated[module], "module existed");
        isModuleActivated[module] = true;
        modules.add(module);
    }

    function removeModule(address module) public {
        require(isModuleActivated[module], "module not existed");
        isModuleActivated[module] = false;
        modules.remove(module);
    }

    // ===========================================
    address public fallbackAddress;

    function setFallbackHandler(address fallbackHandler) public {
        fallbackAddress = fallbackHandler;
    }

    function setOwnersAndThreshold(address[] calldata newOwners, uint256 newThreshold) external {
        uint256 len = owners.length();
        for (uint256 i = len; i > 0;) {
            address a = owners.at(i - 1);
            owners.remove(a);
            isOwner[a] = false;
            unchecked {
                --i;
            }
        }

        for (uint256 i = 0; i < newOwners.length; i++) {
            address o = newOwners[i];
            require(o != address(0), "Owner=0");
            if (owners.add(o)) {
                isOwner[o] = true;
            }
        }
        require(newThreshold > 0, "threshold=0");
        require(newThreshold <= owners.length(), "threshold>owners");
        threshold = newThreshold;
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

        if (activateSignature) {
            require(checkSignatures(_txHash, signatures), "Invalid Signature");
        }

        if (guardAddress != address(0)) {
            ITransactionGuard(guardAddress).checkTransaction(
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

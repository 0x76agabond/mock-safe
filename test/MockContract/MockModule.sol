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
import {ISafe} from "./interfaces/ISafe.sol";
import {Enum} from "./libraries/Enum.sol";

// This is example of a module that can change owner of Safe
// If used in production you probably need to add owner check
contract SwapOwnerModule {
    // variables
    address public constant SENTINEL_OWNERS = address(0x1);

    // event
    event WalletOwnerChanged(address indexed wallet);

    function changeWalletOwner(address wallet, uint256 ownersNumber, address oldOwner, address newOwner) external {
        require(newOwner != address(0) && newOwner != SENTINEL_OWNERS, "New Owner Invalid");
        ISafe safe = ISafe(payable(wallet));
        address[] memory owners = safe.getOwners();

        require(ownersNumber > 0, "No owners found");

        for (uint256 i = 0; i < ownersNumber; i++) {
            if (owners[i] == oldOwner) {
                address previousOwner = i > 0 ? owners[i - 1] : SENTINEL_OWNERS;

                bytes memory swapData =
                    abi.encodeWithSignature("swapOwner(address,address,address)", previousOwner, oldOwner, newOwner);

                require(safe.execTransactionFromModule(wallet, 0, swapData, Enum.Operation.Call), "Replace Owner Fail!");

                emit WalletOwnerChanged(wallet);
                return;
            }
        }
        revert("Old owner not found");
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

/**
 * \
 * Author: Hoang <ginz1504@gmail.com>
 * Contact: https://github.com/0x76agabond
 * =============================================================================
 * Gnosis Safe Mock (NotSafe)
 * /*****************************************************************************
 */
import "forge-std/console2.sol";
import "forge-std/Test.sol";
import {NotSafe} from "../src/NotSafe.sol";
import {Transaction} from "../src/libraries/Transaction.sol";
import {Enum} from "../src/libraries/Enum.sol";

import {IBEP20, BEP20Token} from "./MockContract/ERC20.sol";
import {TestManager} from "./MockContract/TestManager.sol";

contract TestNotSafeSimpleCase is TestManager {
    KeySet ks;

    function setUp() public {
        // Setup
        vm.createSelectFork(vm.rpcUrl("opbnb"));
        ks = ownerSummoner(6, "not-seed");
    }

    // This is case where we test a blank Safe
    function test_No_Modules() public {
        vm.startPrank(ks.addrs[0]);
        // ERC-20 compatible
        BEP20Token token = new BEP20Token();

        vm.startPrank(ks.addrs[1]);
        NotSafe notSafe1 = new NotSafe();
        {
            address[] memory owners1 = new address[](3);
            for (uint256 i = 0; i < 3; i++) {
                owners1[i] = ks.addrs[i];
            }
            notSafe1.setOwnersAndThreshold(owners1, 2);
        }

        vm.startPrank(ks.addrs[4]);
        NotSafe notSafe2 = new NotSafe();
        {
            address[] memory owners2 = new address[](2);
            owners2[0] = ks.addrs[4];
            owners2[1] = ks.addrs[5];
            notSafe2.setOwnersAndThreshold(owners2, 2);
        }

        {
            console.log(" ================================= ");
            console.log("threshold:", notSafe1.threshold());
            address[] memory list1 = notSafe1.getOwners();
            for (uint256 i = 0; i < list1.length; i++) {
                console.log("Owner:", list1[i]);
            }
        }

        {
            console.log(" ================================= ");
            console.log("threshold:", notSafe2.threshold());
            address[] memory list2 = notSafe2.getOwners();
            for (uint256 i = 0; i < list2.length; i++) {
                console.log("Owner:", list2[i]);
            }
        }

        {
            console.log(" ================================= ");
            vm.startPrank(ks.addrs[0]);

            // 10 token
            token.transfer(address(notSafe1), 1e19);
            console.log("Balance of notSafe1: ", token.balanceOf(address(notSafe1)));
            console.log(" ================================= ");

            // 12 token
            token.transfer(address(notSafe2), 1.2e19);
            console.log("Balance of notSafe2: ", token.balanceOf(address(notSafe2)));
        }

        {
            console.log(" ================================= ");
            // Send 1 token from notsafe1 to notsafe2
            bytes32 txHash = Transaction.getTransactionHash(
                address(notSafe1),
                address(token),
                0,
                abi.encodeWithSelector(token.transfer.selector, address(notSafe2), 1e18),
                Enum.Operation.Call,
                0,
                0,
                0,
                address(0),
                address(0),
                notSafe1.nonce()
            );

            // notsafe1 owner key 1, 2, 3 - threshold - 2
            bytes memory sig1 = generateSignature(txHash, ks.keys[1]);
            bytes memory sig2 = generateSignature(txHash, ks.keys[2]);
            bytes memory sigs = bytes.concat(sig1, sig2);

            bool success = notSafe1.execTransaction(
                address(token),
                0,
                abi.encodeWithSelector(token.transfer.selector, address(notSafe2), 1e18),
                Enum.Operation.Call,
                0,
                0,
                0,
                address(0),
                payable(address(0)),
                sigs
            );

            console.log("execTransaction", success);

            console.log("Balance of notSafe1:", token.balanceOf(address(notSafe1)));
            console.log("Balance of notSafe2:", token.balanceOf(address(notSafe2)));
        }
    }
}

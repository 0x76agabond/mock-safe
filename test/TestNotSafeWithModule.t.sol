// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

/*************************************************************************
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
import {MockGuard} from "./MockContract/MockGuard.sol";
import {SwapOwnerModule} from "./MockContract/MockModule.sol";

contract TestNotSafeWithModule is TestManager {
    KeySet ks;
    BEP20Token token;
    NotSafe notSafe1;

    function setUp() public {
        // Setup
        vm.createSelectFork(vm.rpcUrl("opbnb"));
        ks = ownerSummoner(6, "not-seed");
        // ERC-20 compatible
        vm.startPrank(ks.addrs[0]);
        token = new BEP20Token();

        vm.startPrank(ks.addrs[1]);
        notSafe1 = new NotSafe();
        {
            address[] memory owners1 = new address[](3);
            for (uint256 i = 0; i < 3; i++) {
                owners1[i] = ks.addrs[i];
            }
            notSafe1.setOwnersAndThreshold(owners1, 2);
        }

        showOwnerList();

        {
            console.log(" ================================= ");
            vm.startPrank(ks.addrs[0]);

            // 10 token
            token.transfer(address(notSafe1), 1e19);
            console.log("Balance of notSafe1: ", token.balanceOf(address(notSafe1)));
        }
    }

    function showOwnerList() public view {
        console.log(" ================================= ");
        console.log("threshold:", notSafe1.threshold());
        address[] memory list1 = notSafe1.getOwners();
        for (uint256 i = 0; i < list1.length; i++) {
            console.log("Owner:", list1[i]);
        }
    }

    function setupGuard() public {
        MockGuard guard = new MockGuard();
        notSafe1.setGuard(address(guard));

        console.log(" ================================= ");
        console.log("Guard Address: ", notSafe1.guardAddress());
    }

    function test_Module() public {
        console.log(" ================================= ");
        console.log("Test Module");

        // Setup guard to check checkModuleTransaction and checkAfterModuleExecution
        setupGuard();

        // Swap Owner module
        // This test demomtrade how to use module to replace an existed owner
        // notSafe1 use key 1, 2, 3 threshold = 2
        // swap key 3 with key 4
        SwapOwnerModule module = new SwapOwnerModule();
        notSafe1.setModule(address(module));

        console.log(" ================================= ");
        console.log("Address Target:", ks.addrs[3]);

        address[] memory owners = notSafe1.getOwners();

        module.changeWalletOwner(address(notSafe1), owners.length, owners[2], ks.addrs[3]);

        showOwnerList();
    }
}

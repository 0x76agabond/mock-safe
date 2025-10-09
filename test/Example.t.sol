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

contract TestNotSafe is Test {
    struct KeySet {
        uint256[] keys;
        address[] addrs;
    }

    // private key helper
    function ownerSummoner(uint256 count, string memory seed) internal returns (KeySet memory k) {
        k.keys = new uint256[](count);
        k.addrs = new address[](count);

        for (uint256 i = 0; i < count; i++) {
            // derive each key from seed + index + block info
            uint256 key = uint256(keccak256(abi.encodePacked(seed, block.timestamp, i)));
            address addr = vm.addr(key);

            k.keys[i] = key;
            k.addrs[i] = addr;

            vm.deal(addr, 10 ether);
            vm.label(addr, string.concat("owner_", vm.toString(i)));
        }
    }

    // signature helper
    function generateSignature(bytes32 txHash, uint256 key) internal pure returns (bytes memory sig) {
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(key, txHash);
        sig = abi.encodePacked(r, s, v);
    }

    function setUp() public {
        vm.createSelectFork(vm.rpcUrl("opbnb"));
    }

    // Since Safe call Module, Guard as Safe Modules so I call it modules
    function test_No_Modules() public {
        // Setup
        KeySet memory ks = ownerSummoner(6, "not-seed");

        vm.startPrank(ks.addrs[0]);
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
            // Next transaction mean current nonce + 1
            // Safe UI will handle this nonce increasing but sadly we don't have UI here
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
                notSafe1.nonce() + 1
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

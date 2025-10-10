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
import "forge-std/Test.sol";

contract TestManager is Test {
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
}

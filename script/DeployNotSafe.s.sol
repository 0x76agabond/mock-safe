// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import "forge-std/Script.sol";
import "../src/NotSafe.sol";

contract DeployNotSafeScript is Script {
    function run() external {
        // Load deployer from .env → PRIVATE_KEY
        uint256 deployer = vm.envUint("PRIVATE_KEY");

        vm.startBroadcast(deployer);

        // Deploy NotSafe
        NotSafe notsafe = new NotSafe();

        console2.log("========================================");
        console2.log(" NotSafe deployed to opBNB Testnet ");
        console2.log(" Address:", address(notsafe));
        console2.log("========================================");

        vm.stopBroadcast();
    }
}

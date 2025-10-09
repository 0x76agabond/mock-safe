# 🧪 Mock Safe

**Gnosis Safe** mock — I personally call it **NotSafe**.

---

## Abstract
A lightweight, standalone **Gnosis Safe simulator** for testing Guards, Modules, and transaction flows.

This mock keeps the **Safe interface** (`execTransaction`, `owners`, `nonce`)  
but skips all proxy layers — it performs **real calls** directly for deterministic testing.

---
## Motivation

**I once researched Gnosis Safe.**  
*I noticed that Modules, Guards, and Fallback Handlers are very powerful concepts, but strangely there are few runnable examples outside the Safe team's own implementations.*  

**I suspect the reason is that simulating true Safe behaviour is hard** — I couldn't find a suitable mock to rehearse these interactions.  

*So I built one for myself, a small, call-capable playground to test, poke, and learn before touching real funds.*

---
## Disclaim
⚠️ This is a mock for testing only. Do not deploy to mainnet or use with real assets.

---
## Note
Since this is a test framework, you should check test directory for example

---
## Quick Start
```bash
clone this project
forge build
forge test -vvv
happy coding 😎
```
---
## Example
```solidity
// ============================================
// Mock ERC-20
// ============================================
BEP20Token token = new BEP20Token();

vm.startPrank(ks.addrs[1]);

// ============================================
// Protagonist
// ============================================
NotSafe notSafe = new NotSafe();
{
    address[] memory owners = new address[](3);
    for (uint256 i = 0; i < 3; i++) {
        owners[i] = ks.addrs[i];
    }
    notSafe.setOwnersAndThreshold(owners, 2);
}

// ============================================
// Check Owner
// ============================================
address[] memory list1 = notSafe.getOwners();
for (uint256 i = 0; i < list1.length; i++) {
    console.log("Owner:", list1[i]);
}

// ============================================
// 10 token
// ============================================
token.transfer(address(notSafe), 1e19);
console.log("Balance of notSafe: ", token.balanceOf(address(notSafe)));

// ============================================
// Build Transaction
// Next transaction mean current nonce + 1
// ============================================
bytes32 txHash = Transaction.getTransactionHash(
    address(notSafe),
    address(token),
    0,
    abi.encodeWithSelector(token.transfer.selector, address(notSafe2), 1e18),
    Enum.Operation.Call,
    0,
    0,
    0,
    address(0),
    address(0),
    notSafe.nonce() + 1
);

// ============================================
// notSafe owner key 1, 2, 3 - threshold - 2
// ============================================
bytes memory sig1 = generateSignature(txHash, ks.keys[1]);
bytes memory sig2 = generateSignature(txHash, ks.keys[2]);
bytes memory sigs = bytes.concat(sig1, sig2);

// ============================================
// exec multisig transaction
// ============================================
bool success = notSafe.execTransaction(
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
console.log("Balance of notSafe:", token.balanceOf(address(notSafe)));

```
---
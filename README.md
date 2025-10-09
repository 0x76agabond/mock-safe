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
### Quick Start
```bash
forge build
forge test -vvv
```
---
### Example
```solidity
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

address[] memory list1 = notSafe1.getOwners();
for (uint256 i = 0; i < list1.length; i++) {
    console.log("Owner:", list1[i]);
}

// 10 token
token.transfer(address(notSafe1), 1e19);
console.log("Balance of notSafe1: ", token.balanceOf(address(notSafe1)));

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

```
---
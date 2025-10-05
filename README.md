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

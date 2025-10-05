# 🧪 Mock Safe

> Gnosis Safe mock — I personally call it **NotSafe**.

---

### Overview
A lightweight, standalone **Gnosis Safe simulator** for testing Guards, Modules, and transaction flows.

This mock keeps the **Safe interface** (`execTransaction`, `owners`, `nonce`)  
but skips all proxy layers — it performs **real calls** directly for deterministic testing.

Perfect for **Diamond Guard**, **Phantom**, or **module validation** use-cases.

---

### Quick Start
```bash
forge build
forge test -vvv

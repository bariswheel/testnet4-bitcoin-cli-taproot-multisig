# Diagrams & Visual Walkthroughs

This document complements the shell walkthroughs by providing **visual diagrams** of the journey.  
The goal: make Bitcoin internals easier to remember by seeing how the moving parts connect.

---

## 1. User Journey: Alice → Bob (2-of-3 Taproot Multisig)

```mermaid
flowchart TD
  %% Group nodes by role
  subgraph Alice[ Alice ]
    A1[Private Key 1]
    A2[Private Key 2]
    A3[Private Key 3]
    D[2-of-3 Taproot Descriptor]
    ADDR[Alice 2-of-3 Address]
  end

  subgraph Faucet[Testnet4 Faucet]
    F[Funds sent to Alice's address]
  end

  subgraph Bob[ Bob ]
    B[Taproot Single‑Sig Wallet]
  end

  %% Process nodes (declared separately to avoid inline-creation issues)
  PSBT[PSBT - Partially Signed Bitcoin Transaction]
  TX[Final Transaction]
  MINERS[Bitcoin Miners]

  %% Flow
  F --> ADDR
  ADDR -->|UTXO| PSBT
  PSBT -->|Alice signs w/ 2 keys| TX
  TX -->|Broadcast to network| MINERS
  MINERS -->|Confirmed in Block| B
```
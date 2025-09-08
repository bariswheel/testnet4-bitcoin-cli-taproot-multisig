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

## 2. Wallet Roles: Signer vs. Watch-Only
```mermaid
flowchart LR
  %% Two wallets, two responsibilities
  subgraph SIGNER["Alice Signer Wallet (has private keys)"]
    SK1["PrivKey A1"]
    SK2["PrivKey A2"]
    SK3["PrivKey A3"]
  end

  subgraph WATCH["Alice Policy / Watch-Only Wallet (no private keys)"]
    DESC["Descriptor(s)\ntr(internal, multi_a(2, X1,X2,X3))"]
    UTXO["Tracks UTXOs + addresses"]
  end

  PSBT0["PSBT (inputs, outputs,\nno sigs yet)"]
  PSBT1["PSBT + Alice's 2 signatures"]
  TXF["Finalized TX"]

  %% Responsibilities
  WATCH -->|"derive receive addr\nmonitor balance"| UTXO
  WATCH -->|"create funded PSBT"| PSBT0
  PSBT0 -->|"export PSBT to signer"| SIGNER
  SIGNER -->|"sign with 2 of 3 keys"| PSBT1
  PSBT1 -->|"import back"| WATCH
  WATCH -->|"finalize + broadcast"| TXF

```

## 3. Taproot Descriptor Anatomy
```mermaid
flowchart TB
  TR["tr( internal_key , multi_a(2, X1, X2, X3) )"]

  INT["internal_key (x-only pubkey)\n• 32-byte x coordinate\n• key-path spend possible if owned"]
  MS["multi_a(2, X1, X2, X3)\n• script-path (threshold 2-of-3)\n• 'a' = taproot key type\n• keys are x-only and ordered"]

  KP["Key-path spend\n(single key control)"]
  SP["Script-path spend\n(2 of 3 signatures)"]

  TR --> INT
  TR --> MS
  INT --> KP
  MS --> SP
```
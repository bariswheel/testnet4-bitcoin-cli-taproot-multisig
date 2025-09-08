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

## 4. PSBT Lifecycle (end-to-end)
```mermaid
sequenceDiagram
  autonumber
  participant W as Watch-Only Wallet
  participant S as Signer Wallet
  participant N as Network

  W->>W: Select UTXO(s) + build outputs
  W->>W: walletcreatefundedpsbt (fund + fee + change)
  W-->>S: Export PSBT  (base64)

  S->>S: walletprocesspsbt (add sigs with 2 keys)
  S-->>W: Return signed PSBT

  W->>W: finalizepsbt (produce hex tx)
  W->>N: sendrawtransaction
  N-->>W: txid (0 conf)
  N-->>W: Confirmations increase over time
```

## 5. UTXO Flow (Before -> Spend -> After)
```mermaid
flowchart LR
  FAUCET["Testnet4 Faucet"]
  AADDR["Alice 2-of-3 Address"]
  AUTXO["Alice UTXO\n(txid:vout, amount)"]

  SPEND["Spend\nPSBT -> Signed -> TX"]
  BADDR["Bob Taproot Address"]
  BUTXO["Bob UTXO (new)"]
  CHANGE["Alice Change (optional)"]

  %% Funding
  FAUCET -->|"funds"| AADDR --> AUTXO
  %% Spend to Bob
  AUTXO --> SPEND --> BADDR --> BUTXO
  SPEND -->|change if any| CHANGE
```

## 6. Troubleshooting Flow (Greatest Hits from Challenges.md)
```mermaid
flowchart TB
  START([Something fails])

  START --> A{bitcoin-cli\ncan't connect}
  A -->|cookie missing| A1["Run as same user as bitcoind:\n· sudo -u bitcoin ...\n· or sudo -iu bitcoin"]
  A -->|wrong port/chain| A2["Check chain + ports:\n· grep '^chain=' bitcoin.conf\n· testnet4 uses 48332 RPC"]

  START --> B{Descriptor import fails}
  B -->|Missing checksum| B1["Use getdescriptorinfo\nto append #checksum"]
  B -->|"invalid tr"| B2["Use tr(internal, multi_a(2, X1,X2,X3))\nnot threshold() for miniscript"]
  B -->|x-only confusion| B3["X keys are 64 hex chars\n(strip 02/03 if present)"]

  START --> C{Disk / DB issues}
  C --> C1["Check space: df -h /srv"]
  C --> C2["Use prune=<MiB> or move datadir"]

  START --> D{RPC 'legacy only'}
  D --> D1["dumpwallet/dumpprivkey are legacy-only\nUse descriptors + PSBT instead"]

  START --> E{Wrong user vars}
  E --> E1["Env set in one shell won't exist in new login\nPersist in ~/.bashrc if needed"]

  A1 --> DONE((Resolved))
  A2 --> DONE
  B1 --> DONE
  B2 --> DONE
  B3 --> DONE
  C1 --> DONE
  C2 --> DONE
  D1 --> DONE
  E1 --> DONE
```

## 7. Glossary Map (Quick Recall)
```mermaid
flowchart TB
  CORE["Bitcoin-CLI Multisig\n(Study Map)"]

  UTXO["UTXO\nUnspent output"]
  PSBT["PSBT\nPartially Signed TX"]
  DESC["Descriptor\nAddress/Key recipe"]
  XONLY["x-only pubkey\n(32-byte x)"]
  INTK["internal key\n(for tr key-path)"]
  MSIG["multi_a(2, X1,X2,X3)\nTaproot threshold"]
  WATCH["Watch-Only Wallet\n(policy, no keys)"]
  SIGN["Signer Wallet\n(private keys)"]

  CORE --- UTXO
  CORE --- PSBT
  CORE --- DESC
  DESC --- XONLY
  DESC --- INTK
  DESC --- MSIG
  CORE --- WATCH
  CORE --- SIGN
```


## Contrasting Karpathy’s (ECDSA, single-sig) with This Project (Taproot/Schnorr, 2-of-3 miniscript, key-path possible).

Quick recap

- Curve: both use secp256k1: y^2 \equiv x^3 + 7 \pmod p over a finite field.
- Karpathy 2021: ECDSA signatures, single-sig P2PKH/P2WPKH-style model (no Taproot).
- This project here: Schnorr signatures (BIP340) inside Taproot (BIP341/342) with miniscript 2-of-3 (script-path) and optional key-path (single x-only internal key).
- Multisig:
  - Legacy ECDSA multisig = multiple pubkeys & sigs visible in script; bulky, reveals M-of-N.
  - Taproot/Schnorr supports key aggregation (MuSig2) → 1 pubkey + 1 sig on chain (privacy/size), or miniscript script-path when needed.


## 8. ECDSA Single-Sig (Karpathy-blog-style) – flow
```mermaid
flowchart LR
  subgraph Wallet["Wallet (ECDSA)"]
    P["Privkey (secp256k1)"]
    Q["Pubkey Q = k·G"]
    ADDR["Address (e.g. P2WPKH) = HASH160(Q)"]
  end

  TXIN["TX Input (references UTXO)"]
  MSG["msg = sighash(TX)"]
  SIG["ECDSA sig (r,s)"]
  VERIFY["Node verifies: ECDSA_verify(Q, msg, r,s)"]

  P --> Q --> ADDR
  ADDR --> TXIN
  TXIN --> MSG --> SIG --> VERIFY
```
## 9. Taproot Single-Sig (Schnorr, key-path) – flow
```mermaid
flowchart LR
  %% Put the two worlds side-by-side
  subgraph Taproot["Taproot Schnorr MuSig2<br/>(key aggregation)<br/><br/>"]
    T1["Off-chain combine N pubkeys → 1 aggregated pubkey"]
    T2["Co-sign → 1 Schnorr signature"]
    T3["On-chain looks like single-sig<br/>(1 pubkey, 1 signature)"]
  end

  subgraph Legacy["Legacy ECDSA Multisig<br/>(on-chain M-of-N)<br/><br/>"]
    L1["Script lists N pubkeys"]
    L2["Spend reveals M signatures"]
    L3["Large transaction size<br/>Reveals policy on-chain"]
  end

  %% Keep flows internal to each subgraph to prevent layout collisions
  T1 --> T2 --> T3
  L1 --> L2 --> L3
```
## 10. Multisig: ECDSA legacy vs Schnorr MuSig2 (concept)
```mermaid
flowchart LR
  DESC["Descriptor:\ntr(internal, multi_a(2, X1,X2,X3))"]
  BRANCH1["Key-path (optional)\nSchnorr with internal (or agg) key"]
  BRANCH2["Script-path (your demo)\n2 of X1,X2,X3 signatures"]

  DESC --> BRANCH1
  DESC --> BRANCH2
```
## 11. Taproot Miniscript 2-of-3 (this build) – script-path spend
```mermaid
sequenceDiagram
  autonumber
  participant W as Wallet (builder)
  participant S as Signer
  participant N as Network

  Note over W: Build inputs/outputs → PSBT
  W->>S: PSBT (base64)

  par ECDSA flow
    S->>S: create ECDSA (r,s) for each input
  and Schnorr flow
    S->>S: create Schnorr (R,s) for each input
  end

  S-->>W: partially signed PSBT
  W->>W: finalize (hex tx)
  W->>N: broadcast
```
## 12. PSBT signing differences (ECDSA vs Schnorr)
```mermaid
flowchart TB
  A["ECDSA legacy multisig"] -->|"reveals M-of-N,\nN pubkeys,\nM signatures"| AC[On-chain data]
  B["Taproot key-path (MuSig2)"] -->|"looks single-sig:\n1 pubkey, 1 sig"| BC[On-chain data]
  C["Taproot script-path 2-of-3"] -->|"reveals only spent branch\n(2 keys + script)"| CC[On-chain data]
```
## 13. Visual cheat: where data is revealed on-chain
```mermaid
flowchart TB
  A["ECDSA legacy multisig"] -->|"reveals M-of-N,\nN pubkeys,\nM signatures"| AC[On-chain data]
  B["Taproot key-path (MuSig2)"] -->|"looks single-sig:\n1 pubkey, 1 sig"| BC[On-chain data]
  C["Taproot script-path 2-of-3"] -->|"reveals only spent branch\n(2 keys + script)"| CC[On-chain data]
```
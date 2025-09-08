# Design Day Appendix: Bridging Bitcoin UX & Technical Flows

This document was created as a companion to [testnet4-bitcoin-cli-taproot-multisig](../).  
It reframes the **technical deep dive** into Taproot multisig + PSBTs as **design challenges** relevant to Presidio Bitcoin Design Week.

---

## 1. Context

**Event:** Presidio Bitcoin Design Week – Deep Dive  
**Theme:** "Can we design products and experiences that bring bitcoin to billions of users:  
while staying true to decentralization, self-sovereignty, resilience, adversarial thinking, and trust minimization?"

---

## 2. Relevance of This Repo

- This repo documents building a **2-of-3 Taproot multisig wallet** and spending flow *from scratch* via `bitcoin-cli`.
- It shows the *raw ingredients* behind wallets like Bitkey, Sparrow, or Electrum.
- By surfacing complexity (descriptors, x-only pubkeys, PSBT flow), it highlights where **designers must step in** to simplify.

---

## 3. Key Design Lenses

### a. Self-Custody & Safety
- **Problem:** Most users hold Bitcoin on single devices (Trezor, Ledger, phone apps). Single point of failure.
- **Insight from repo:** 2-of-3 multisig is safer, but extremely hard to build manually.
- **Design opportunity:** Create flows where users are guided into multisig *by default* when storing >$5k.

### b. Migration Pathways
- **Problem:** Many users already have BTC in single-sig wallets.
- **Question:** How to move coins into multisig **without revealing too much on-chain** or risking loss?
- **Design opportunity:** Silent migration wizards; inheritance modes; decoy time-lock alerts.

### c. UX for Adversarial Environments
- **Repo lesson:** Environment variables, cookie auth, descriptor checksums → all are brittle for normal people.
- **Design challenge:** How to ensure **no technical footguns** for people who just want to "store safely"?

---

## 4. User Journeys to Explore

- **New User, First $5k**  
  Guided into 2-of-3 with clear metaphors: "3 safes, any 2 to open."
- **Existing HODLer (Trezor owner)**  
  Assisted migration into multisig without full key exposure.
- **Inheritance**  
  Keys distributed to family/lawyers with **time-delay protections** (e.g., 30-day trigger, FBI alert if forced too soon).

---

## 5. How to Contribute in Design Day

- Incorporate background in **Google-scale UX research & user journeys**.  
- Ask: *Where would mom get stuck?* (e.g., faucet login failures → imagine Coinbase off-ramp friction).  
- Sketch: "From faucet to PSBT" is analogous to "From paycheck to secure savings."  
- Pair technical concepts (UTXOs, PSBT, descriptors) with **user metaphors** (piggy banks, safes, shared signatures).

---

## 6. Glossary (Designer-Friendly)

- **UTXO**: "Unspent transaction output" → like a dollar bill in Bitcoin form.  
- **Descriptor**: Recipe for how coins can be spent (who needs to sign).  
- **x-only pubkey**: Shortened key format in Taproot (only the x coordinate).  
- **Taproot**: Upgrade that hides complexity; can look like single-sig even if it's multisig.  
- **PSBT**: Partially Signed Bitcoin Transaction → a draft check passed around until enough people sign.  
- **Watch-only wallet**: Can see balance & build transactions, but cannot spend.  
- **Signer wallet**: Holds private keys, actually authorizes spend.

---

## 7. Next Steps

- Add **Mermaid diagrams** (optional) mapping:
  - Multisig migration flow (single-sig → multisig).
  - UX "friction points" vs. "automation opportunities."
- Align repo with **Grand Challenges of Bitcoin Design**:
  - Branding  
  - On-/off-ramps  
  - Self-custody  
  - Addressing & identity  
  - Units & privacy

---

### A) Journey Overview: New User vs Existing HODLer vs Inheritance
```mermaid
flowchart TD
  classDef good fill:#e8fff2,stroke:#2f855a,color:#1f4d37
  classDef warn fill:#fff8e1,stroke:#b7791f,color:#744210
  classDef risk fill:#ffecec,stroke:#c53030,color:#742a2a

  START[User with BTC goal] --> CHOOSE{"Who is this user?"}

  CHOOSE -->|New User| NU[Opinionated default: 2-of-3 Multisig\n• Simple language\n• Guided setup\n• Test recovery drill]
  CHOOSE -->|Existing HODLer| EH["Migrate Single-Sig → Multisig\n• Import existing HW key\n• Build co-signer set\n• Move UTXOs safely"]
  CHOOSE -->|Inheritance| INH["Establish Heir & 3rd key\n• Time delay policy\n• Emergency contacts\n• Dead-man's switch"]

  NU --> NU_READY[Ready to receive & save safely]
  EH --> EH_PLAN["Privacy-preserving move plan"]
  INH --> INH_PLAN["Heir + policy proven with drills"]

  class NU,NU_READY good
  class EH_PLAN warn
  class INH_PLAN warn
```
### B) Migration Flow: Single-Sig → 2-of-3 Multisig (Privacy-aware)
```mermaid
flowchart LR
  classDef step fill:#eef2ff,stroke:#4c51bf,color:#1a237e
  classDef note fill:#f7fafc,stroke:#a0aec0,color:#2d3748

  SS["Single-Sig Wallet (e.g., Trezor)"]:::step --> AUDIT["Audit UTXOs\n(avoid linking, group wisely)"]:::note
  AUDIT --> BUILD["Build 2-of-3 Policy\n(you + HW + backup/inheritance)"]:::step
  BUILD --> ADDR["Derive new multisig address(es)"]:::step
  ADDR --> PLAN["Create Move Plan\n• coin control\n• staggered sends\n• fee/confirm policy"]:::note
  PLAN --> MOVE["Spend UTXOs → multisig\n(minimize address reuse)"]:::step
  MOVE --> VERIFY["Verify funds + recovery\n(run drill!)"]:::step
```
### C) PSBT Flow Annotated (Where UX friction hides)
```mermaid
sequenceDiagram
  autonumber
  participant W as Watch-Only (policy)
  participant S as Signer (private keys)
  participant N as Network

  Note over W: Select UTXOs + outputs
  W->>W: walletcreatefundedpsbt()
  Note right of W: Friction: fees, change, coin control

  W-->>S: Export PSBT (base64/QR/file)
  Note over S: UX: confirm policy & outputs clearly

  S->>S: walletprocesspsbt() (2 of 3 signatures)
  S-->>W: Return signed PSBT

  W->>W: finalizepsbt() → hex
  W->>N: sendrawtransaction()
  N-->>W: txid + confirmations
```
### D) Security Tripwires (Time-Delay + Early-Spend Alerts)
```mermaid
sequenceDiagram
  autonumber
  participant U as User
  participant C1 as Co-signer A
  participant C2 as Co-signer B (backup)
  participant Policy as Policy Engine
  participant Net as Bitcoin Network

  U->>Policy: Initiate spend > $5k
  Policy->>Policy: Check rules (2-of-3 + 30-day delay)
  Policy-->>U: "Timer started, co-signer required"
  Policy-->>C1: Approval request (out-of-band)
  Policy-->>C2: Silent notification

  Note over Policy: If second signature < 24h → alert
  C1->>Policy: Approve signature
  Policy->>Net: Broadcast after T+30 days window
  Net-->>U: Confirmations accrue

  Note over Policy: If early attempt by compromised key → notify contacts / log incident
```
### E) Roles & Key Custody (Separation of Powers)
```mermaid
flowchart TB
  classDef role fill:#ecfeff,stroke:#0891b2,color:#0e7490
  classDef data fill:#fff7ed,stroke:#ea580c,color:#9a3412
  classDef risk fill:#ffebee,stroke:#c62828,color:#8e0000

  subgraph Wallets_And_Services["Wallets / Services"]
    WO["Watch-Only Wallet\n(no private keys)"]:::role
    SW1["Signer Wallet A\n(user device)"]:::role
    SW2["Signer Wallet B\n(hardware)"]:::role
    BK["Backup/Inheritance Service\n(3rd key)"]:::role
  end

  DESC["Descriptor(s)\ntr(internal, multi_a(2,X1,X2,X3))"]:::data
  UTXO["UTXO set & addresses"]:::data
  NET[Network]

  WO --> DESC
  WO --> UTXO
  WO -->|Creates PSBT| SW1
  SW1 -->|Signs| WO
  WO -->|Requests 2nd sig| SW2
  SW2 -->|Signs| WO
  WO -->|Finalizes + Broadcasts| NET

  BK -. "emergency cosigner" .-> WO
  class BK risk
```
### F) Friction Map (Where beginners get stuck)
```mermaid
flowchart TB
  classDef pain fill:#fff1f2,stroke:#be123c,color:#7f1d1d
  classDef fix fill:#f0fdf4,stroke:#16a34a,color:#14532d

  P1["Address formats (bc1...)\nQR handling"]:::pain
  P2["Descriptors & checksums\n(getdescriptorinfo)"]:::pain
  P3["X-only keys, miniscript\ntr(..., multi_a(...))"]:::pain
  P4["PSBT exports/imports\nbetween devices"]:::pain
  P5["Fees, change, coin control"]:::pain

  F1["Human-friendly addresses\n(paynames, profiles)"]:::fix
  F2["Auto-validate descriptors\nwith clear errors"]:::fix
  F3["Guided policy builders\n(no raw miniscript)"]:::fix
  F4["Secure share channels\n(airgap QR, NFC, files)"]:::fix
  F5["Fee presets + explainers\nsafe defaults"]:::fix

  P1 --> F1
  P2 --> F2
  P3 --> F3
  P4 --> F4
  P5 --> F5
```
### G) Risk Matrix (Likelihood × Impact)
```mermaid
flowchart LR
  classDef low fill:#edf2ff,stroke:#3b82f6,color:#1e40af
  classDef med fill:#fff7ed,stroke:#fb923c,color:#9a3412
  classDef high fill:#fee2e2,stroke:#ef4444,color:#991b1b

  L1["User loses 1 key"]:::low --> M1["2-of-3 still spendable"]
  L2["Phishing tries to rush spend"]:::med --> M2["Time delay + alerts"]
  L3["Device seized under duress"]:::high --> M3["Co-signer verification + out-of-band checks"]
  L4["Backup service outage"]:::med --> M4["Diverse vendors + recovery drills"]
```
### H) On/Off-Ramp & “Upgrade to Safety” Nudges
```mermaid
flowchart TD
  BUY["Buy BTC (on-ramp)"] --> HOLD["Holding balance grows"]
  HOLD --> THRESH{"Balance > $5k?"}
  THRESH -->|Yes| NUDGE["Nudge: Upgrade to 2-of-3\n(5 min guided setup)"]
  THRESH -->|No| KEEP["Keep single-sig\n(with periodic reminders)"]
  NUDGE --> SAFE["2-of-3 Multisig\nwith tripwires & recovery drill"]
```
### I) Inheritance Journey (30-day policy example)
```mermaid
sequenceDiagram
  autonumber
  participant O as Owner
  participant Heir as Heir
  participant BK as Backup/Inheritance
  participant Policy as Policy Engine

  O->>Policy: Enable inheritance policy
  Policy-->>O: Test drill & confirm contacts
  Note over O,Heir: Periodic reminders to rehearse

  O--xPolicy: Owner inactivity detected (e.g., 12 months)
  Policy->>Heir: Notify + start 30-day window
  Policy->>BK: Request co-sign readiness
  Heir->>Policy: Provide proofs / documentation
  Policy->>Heir: After 30 days + checks → allow spend path
```

## 8. Closing Thought

This repo shows how hard it is to build safe Bitcoin storage with raw tools.  
**The design challenge:** Make 2-of-3 multisig as simple as Venmo *without violating self-sovereignty*.  
That’s the contribution we can make at Presidio.

---
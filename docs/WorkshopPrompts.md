# Workshop Prompts (Design Provocations)

These are not answers — they’re **friction points** phrased as questions to provoke design ideas.
Each section includes a small Mermaid diagram we can screen-share or print as a breakout prompt.

---

## A) Self-Custody Defaults

- Should wallets **force multisig** above certain balances (>\$5k)?
- How do we design defaults that protect users **without removing choice**?

```mermaid
flowchart TD
  BAL["User crosses $5k balance"] --> NUDGE["Prompt: Upgrade to Multisig?"]
  NUDGE -- Yes --> YES["Auto-guide into 2-of-3"]
  NUDGE -- No  --> NO["Stay single-sig (risky)"]
```
## B) Migration Pathways
	•	How can users safely move coins from existing single-sig wallets into multisig?
	•	How do we hide complexity like descriptors, PSBTs, and x-only pubkeys?

```mermaid
flowchart LR
  OLD["Trezor (single-sig)"] --> WIZARD["Migration Wizard"]
  WIZARD --> MULTI["2-of-3 Multisig"]
```

## C) Inheritance & Time-Delay
	•	Can we design time-delays + alerts that don’t overwhelm normal users?
	•	How should heirs rehearse recovery without touching real funds?

```mermaid
sequenceDiagram
  autonumber
  participant Owner
  participant Policy
  participant Heir

  Owner->>Policy: Enable inheritance
  Policy-->>Owner: Reminder drill
  Owner-->>Policy: Inactivity detected
  Policy->>Heir: Notify + 30-day timer
  Heir->>Policy: Prove identity
```

## D) Adversarial UX
	•	What happens when a keyholder is compromised or coerced?
	•	How do we make “call the FBI” triggers or alerts without false positives?

```mermaid
flowchart TD
  ATTACK["Keyholder under duress"] --> ALERT["System detects rushed spend"]
  ALERT --> ACTION1["Trigger alert to heirs/contacts"]
  ALERT --> ACTION2["Pause / delay broadcast"]
```

## E) Education & Metaphors
	•	What metaphors make Bitcoin multisig “mom proof”?
	•	“3 safes, need 2 keys”
	•	“Shared signatures = shared trust”
	•	How do we explain descriptors/PSBT in plain mental models?

```mermaid
flowchart TD
  USER["Mom"] --> SAFE["Metaphor: 3 Safes, Any 2 Keys"]
  SAFE --> TX["Transaction"]
```

---

# Proposed approach:

	•	Print one section per page for breakout groups.

	•	Ask teams to sketch the happy path, then annotate failure paths and countermeasures.

	•	Map each idea back to wallet primitives (UTXO, descriptor, PSBT, key custody).

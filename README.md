---

# 📄 Master README.md (Study Doc)

```markdown
# Bitcoin Testnet4 Taproot 2-of-3 Multisig (Shell Scripts Walkthrough)

## Introduction

This project is a hands-on walkthrough of setting up and using a **Taproot 2-of-3 multisig wallet** on Bitcoin Testnet4 using only the `bitcoin-cli` command line.

- At first, all steps were done manually, command by command.  
- To consolidate and study the process, the steps were turned into **modular shell scripts** (`00_env.sh`, `10_build_alice_2of3.sh`, etc.).  
- The goal: **understand deeply** how Taproot, x-only keys, descriptors, watch-only wallets, and PSBTs work — as opposed to clicking “send” in a GUI wallet.  

---

## Approach

1. **Signer vs Watch-only**  
   - Alice’s *signer wallet* holds her 3 private keys.  
   - Alice’s *policy/watch-only wallet* knows the descriptor but no private keys.  
   - Bob has a simple Taproot wallet.  

2. **Workflow**  
   - Alice builds a 2-of-3 Taproot descriptor with x-only keys.  
   - Faucet funds Alice’s 2-of-3 address.  
   - Alice creates and signs a PSBT to send to Bob.  
   - Transaction is broadcast and verified.  

---

## Scripts Overview

- `00_env.sh` — bootstrap environment variables and sanity checks.  
- `10_build_alice_2of3.sh` — generate A1–A3, extract x-only keys, build multisig descriptor.  
- `20_send_from_alice_to_bob.sh` — create and sign PSBT for Alice→Bob.  
- `30_check_balances.sh` — confirm balances and TX confirmations.  

Each script has its own README for detailed instructions.

---

## Challenges Encountered

- Confusion between **shell vars** vs **exported env vars**.  
- Installing missing tools (`xxd` via `vim-common`).  
- Descriptor syntax errors (`threshold` vs `multi_a`).  
- Faucet restrictions (needed GitHub login, some blocked).  
- Errors with change address type — solved by forcing change to Alice’s 2-of-3 address.  

---

## Glossary

- **bech32m**: Address encoding used by Taproot.  
- **Taproot x-only key**: 32-byte pubkey using only the x coordinate.  
- **Internal key (INT)**: Random pubkey so key-path spends are disabled.  
- **Descriptor**: Declarative string describing how a wallet derives addresses.  
- **Watch-only wallet**: Knows policies, no private keys.  
- **Signer wallet**: Holds private keys, can sign PSBTs.  
- **PSBT**: Partially Signed Bitcoin Transaction — baton between watch-only and signer.  

---

## Commands Used

- `getnewaddress`, `getaddressinfo`, `getdescriptorinfo`  
- `importdescriptors`, `deriveaddresses`  
- `listunspent`, `walletcreatefundedpsbt`  
- `walletprocesspsbt`, `finalizepsbt`, `sendrawtransaction`  
- `gettransaction`, `getbalances`, `getwalletinfo`  

---

## Variables Defined

- **A1, A2, A3**: Alice’s Taproot addresses.  
- **D1, D2, D3**: Descriptor strings for A1–A3.  
- **H1, H2, H3**: Hex pubkeys extracted.  
- **X1, X2, X3**: Normalized x-only pubkeys.  
- **INT**: Internal random x-only key.  
- **ALICE_DESC_NOCHK**: Descriptor before checksum.  
- **DESC_CHK**: Descriptor with checksum.  
- **ADDR**: Alice’s multisig address.  
- **TXID, VOUT, AMT**: Funding UTXO info.  
- **SEND**: Amount to Bob.  
- **RAW**: Unsigned PSBT.  
- **SIGNED**: PSBT after signing.  
- **FINAL_JSON**: Finalized PSBT data.  
- **TXHEX**: Raw transaction hex.  
- **TXID_CHILD**: Broadcast transaction ID.  
- **BOB_ADDR**: Bob’s address.  

---

## Suggested Study Material

- **BIP340/341**: Schnorr signatures and Taproot.  
- **Bitcoin Descriptors**: [Bitcoin Core Docs](https://github.com/bitcoin/bitcoin/blob/master/doc/descriptors.md)  
- **Miniscript**: [miniscript.org](https://bitcoin.sipa.be/miniscript/)  
- **PSBT**: [BIP174](https://github.com/bitcoin/bips/blob/master/bip-0174.mediawiki)  
- **3Blue1Brown**: videos on elliptic curves and cryptography (to understand x-only).  

---

## Next Steps

- Try the same workflow with **Bob’s 2-of-3 multisig**.  
- Use a GUI wallet (e.g., **Sparrow**, **Electrum**) for easier handling — but compare with the CLI flow.  
- Automate the faucet funding (if API access is available).  
- Explore **hardware wallets** and **HWI** (Hardware Wallet Interface) for PSBT signing.  

---

## Appendix

### Full Shell Commands

(Include everything we ran: `getnewaddress`, `getaddressinfo`, `walletcreatefundedpsbt`, `finalizepsbt`, etc. — see above.)

### Env vs Shell Variables

- `export BCLI=...` → **env var**, visible in `env`, inherited by child processes.  
- `A1=...` → **shell var**, visible in current shell, not exported unless `export A1=...`.  

### Faucet Notes

- Some faucets required GitHub login.  
- Not all worked reliably — patience needed for confirmations.  

---
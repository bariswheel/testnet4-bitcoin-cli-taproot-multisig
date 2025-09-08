# Challenges.md

A practical catalog of everything that tripped me up while building a **Taproot 2-of-3 multisig** on **Bitcoin Testnet4** using only `bitcoin-cli`. Each item explains **what happened**, **why**, **how to detect it**, and **how to fix it** — with quick commands. The goal is to think clearly under pressure, as opposed to guessing.

---

## 0) TL;DR Troubleshooting Flow

When something feels off:

1. **Confirm the network + chain data dir**
   ```bash
   grep -n '^chain=' /srv/bitcoin-testnet/bitcoin.conf
   ls -la /srv/bitcoin-testnet/testnet4/.cookie
   ```

2. **Check daemon health + logs**
   ```bash
   systemctl status -l bitcoind-testnet
   journalctl -u bitcoind-testnet -f
   ```

3. **Quick node sanity**
   ```bash
   bitcoin-cli -datadir=/srv/bitcoin-testnet -conf=/srv/bitcoin-testnet/bitcoin.conf -getinfo
   bitcoin-cli -datadir=/srv/bitcoin-testnet -conf=/srv/bitcoin-testnet/bitcoin.conf getblockchaininfo | jq '.blocks,.headers'
   ```

## 1) Multiple Users & Cookie Auth

Symptom:  
```
bitcoin-cli ... getblockhash 0 →
Could not locate RPC credentials. No authentication cookie could be found...
```

Why:  
bitcoind writes a cookie file under the active datadir (.../testnet4/.cookie). The cookie is only readable by the user that runs the daemon (here: bitcoin). If you run bitcoin-cli as a different user, the CLI can’t read the cookie — as opposed to transparent auth when users match.

Detect:
```bash
whoami
ls -la /srv/bitcoin-testnet/testnet4/.cookie
```

Fix:  

Run CLI as the same user:
```bash
sudo -u bitcoin bitcoin-cli -datadir=/srv/bitcoin-testnet -conf=/srv/bitcoin-testnet/bitcoin.conf getblockhash 0
```

or open an interactive shell:
```bash
sudo -iu bitcoin
```

## 2) sudo -u vs sudo -iu

- `sudo -u bitcoin <cmd>`: run one command as bitcoin (stay in current shell), as opposed to switching shells.
- `sudo -iu bitcoin`: open an interactive login shell for bitcoin (new $HOME, new environment).

Gotcha: Shell variables you set before won’t exist in the new login shell unless you export or re-define them (e.g., BCLI, MSCLI). Put exports into `~/.bashrc` for persistence.

## 3) Testnet3 vs Testnet4 Confusion

Symptoms:
- Logs say: “Support for testnet3 is deprecated…”
- Data directory shows /testnet3/
- RPC port mismatch (18332 vs 48332 patterns for different chains)

Why:  
Old config (chain=test) pointed to testnet3 earlier; after switching to testnet4 (chain=testnet4) you might still have stale directories.

Detect:
```bash
grep -n '^chain=' /srv/bitcoin-testnet/bitcoin.conf
ls -la /srv/bitcoin-testnet
```

Fix:
- Set `chain=testnet4` in bitcoin.conf
- Stop daemon cleanly, then start it:
  ```bash
  bitcoin-cli -datadir=/srv/bitcoin-testnet -conf=/srv/bitcoin-testnet/bitcoin.conf stop
  systemctl restart bitcoind-testnet
  ```
- (Optional) If you no longer need testnet3 and you’re certain: remove `/srv/bitcoin-testnet/testnet3` to free space.

## 4) Disk Pressure, Pruning, and txindex

Symptom:  
Service stops, logs complain about block DB or disk space.

Why:  
Unpruned nodes and/or `txindex=1` balloon storage. On a Pi, that’s pain — as opposed to pruned mode.

Detect:
```bash
df -h /srv
sudo du -h --max-depth=1 /srv | sort -h
```

Fix:  
Use pruning + turn off txindex (in `/srv/bitcoin-testnet/bitcoin.conf`):
```
prune=10000
txindex=0
```
Restart:
```bash
systemctl restart bitcoind-testnet
```

## 5) Don’t Ctrl-C During IBD

Symptom:  
Interrupted IBD, possible DB errors or reindex prompts.

Fix:  
Always stop cleanly:
```bash
bitcoin-cli -datadir=/srv/bitcoin-testnet -conf=/srv/bitcoin-testnet/bitcoin.conf stop
```
As opposed to Ctrl + C

## 6) Missing Tools: jq and xxd

Symptoms:
- `jq: command not found`
- `xxd: command not found`

Why:  
We parse JSON with jq; we generated random 32 bytes for an internal x-only key with xxd.

Fix:
```bash
sudo apt-get update
sudo apt-get install -y jq vim-common   # xxd ships with vim-common
```

## 7) Descriptor “Missing checksum”

Symptom:  
`importdescriptors → {"success": false, "error": {"code": -5, "message": "Missing checksum"}}`

Why:  
Core requires a descriptor checksum — as opposed to accepting raw strings.

Fix:
```bash
DESC_CHK=$($BCLI getdescriptorinfo "$RAW_DESC" | jq -r .descriptor)
$BCLI importdescriptors '[{"desc":"'"$DESC_CHK"'","active":true,"label":"alice-2of3","timestamp":"now"}]'
```

## 8) Wrong Miniscript Form for Taproot

Symptom:  
`getdescriptorinfo "tr(threshold(...))" → tr(): key ... is not valid`

Why:  
Taproot doesn’t accept bare `threshold()` at top level. Use Miniscript key aggregators like `multi_a` (or `sortedmulti_a`) inside `tr()`, as opposed to pre-Taproot `wsh(multi(...))`.

Correct pattern:
```
tr(<internal_xonly>,multi_a(2,<X1>,<X2>,<X3>))
# or:
tr(<internal_xonly>,sortedmulti_a(2,<X1>,<X2>,<X3>))
```

## 9) X-only Keys vs Compressed Pubkeys

Symptom:  
Confusion extracting the right 32-byte keys from descriptors.

Why:  
Taproot uses x-only 32-byte pubkeys (even-Y convention), as opposed to 33-byte compressed (02/03 + 32).

Practical tip:
- If you extract a 66-hex string starting with 02 or 03, drop the first 2 hex chars to get x-only (64 hex).
- Many Core RPCs give you a 33-byte key in descriptors for clarity, but Taproot builders expect x-only inside `multi_a/sortedmulti_a`.

⸻

## 10) Watch-Only vs Signer Wallets

Symptoms:
- PSBT can’t be fully signed.
- Wallet says watch-only: true.

Why:  
We intentionally split policy (watch-only) and keys (signer). The watch-only wallet constructs PSBTs; the signer wallet with private keys signs. That’s by design — as opposed to a single all-in-one hot wallet.

Detect:
```bash
$MSCLI getwalletinfo | jq '{watchonly:.watchonly,descriptors:.descriptors}'
$BCLI getwalletinfo  | jq '{privkeys_enabled:.private_keys_enabled}'
```

## 11) PSBT Pipeline Gotchas

### A) Wrong inputs / amounts / change
Use walletcreatefundedpsbt and let Core handle UTXO selection & change:
```bash
$MSCLI walletcreatefundedpsbt \
'[]' \
'[{"'"$BOB_ADDR"'":0.0045}]' \
0 \
'{"includeWatching":true,"subtractFeeFromOutputs":[0]}' \
true
```
- `includeWatching`: needed because our policy wallet is watch-only.
- `subtractFeeFromOutputs`: keeps the input amount clean, as opposed to manual fee calc.

### B) Not finalized
If walletprocesspsbt doesn’t fully sign, run:
```bash
$BCLI walletprocesspsbt "$RAW" | jq -r .psbt | $BCLI finalizepsbt -
```

### C) Broadcast errors
- Already spent? Low fee? Nonstandard script?  
Check mempool acceptance:
```bash
bitcoin-cli testmempoolaccept '["<hex>"]'
```

## 12) Faucets & Confirmations

Symptoms:
- Faucet refuses account / rate-limits.
- UTXO shows untrusted_pending for a while.

Reality:  
Faucets are flaky. Broadcast != confirmed. Wait for confirmations > 0, as opposed to assuming instant settlement.

Check:
```bash
$MSCLI listunspent | jq '.[] | {txid,vout,amount,confirmations}'
$BCLI getbalances | jq .
```

## 13) RPC Port & Binding Confusion

Symptom:  
bitcoin-cli tries 127.0.0.1:8332 and times out.

Why:  
Default mainnet RPC is 8332. For Testnet4, Core chose a different default port range. Since we set -datadir and -conf, let Core pick the right port for the selected chain; or explicitly add per-chain RPC settings in [test]/[testnet4] sections.

Detect:  
Look for “Binding RPC on address … port …” in logs:
```bash
journalctl -u bitcoind-testnet -f | grep -i 'Binding RPC'
```

## 14) Variable Persistence Across Sessions

Symptom:  
After reconnecting SSH, names like TXID_CHILD, FINAL_JSON are gone.

Why:  
They were shell variables, not persisted.

Fix:
- Re-export:
```bash
export BCLI='bitcoin-cli -datadir=/srv/bitcoin-testnet -conf=/srv/bitcoin-testnet/bitcoin.conf -rpcwallet=alice'
export MSCLI='bitcoin-cli -datadir=/srv/bitcoin-testnet -conf=/srv/bitcoin-testnet/bitcoin.conf -rpcwallet=alice-2of3'
```
- For permanent convenience, append those exports to /home/bitcoin/.bashrc.

## 15) Safety & Repo Hygiene

Rules of thumb (portfolio-safe, as opposed to reckless):
- Never commit wallet.dat or any private keys.
- Keep descriptors, addresses, TXIDs — these are safe and educational.

```
wallet.dat
wallet.dat-journal
*.log
*.tmp
.DS_Store
*.swp
```

## 16) Performance Tune on Pi

- dbcache=2048 (or more if RAM allows) reduces disk thrash, as opposed to tiny cache defaults.
- maxconnections=32 is sane; hundreds of peers on a Pi is counterproductive.
- Prune (prune=10000) so you don’t fill NVMe.

## 17) Quick Sanity Commands:
```bash
# Daemon health
systemctl status -l bitcoind-testnet
journalctl -u bitcoind-testnet -f

# Node info
bitcoin-cli -datadir=/srv/bitcoin-testnet -conf=/srv/bitcoin-testnet/bitcoin.conf -getinfo
bitcoin-cli -datadir=/srv/bitcoin-testnet -conf=/srv/bitcoin-testnet/bitcoin.conf getblockchaininfo | jq '.blocks,.headers'

# Wallet info
$BCLI getwalletinfo
$MSCLI getwalletinfo

# UTXOs
$MSCLI listunspent | jq '.[] | {txid,vout,amount,confirmations}'

# Descriptor checksum
DESC_CHK=$($BCLI getdescriptorinfo "$RAW" | jq -r .descriptor); echo "$DESC_CHK"

# PSBT validate/broadcast
bitcoin-cli testmempoolaccept '["'"$TXHEX"'"]'
bitcoin-cli sendrawtransaction "$TXHEX"
```

## 18) Mindset

- Prefer understanding the pipeline (policy → PSBT → signing → finalize → broadcast), as opposed to button-mashing.
- Treat errors as probes that reveal how Bitcoin Core thinks.
- Write notes while you work (this file!) so future-you learns 10× faster.
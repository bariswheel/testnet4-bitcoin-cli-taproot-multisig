# Challenges.md

A practical catalog of everything that tripped me up while building a **Taproot 2-of-3 multisig** on **Bitcoin Testnet4** using only `bitcoin-cli`. Each item explains **what happened**, **why**, **how to detect it**, and **how to fix it** — with quick commands. The goal is to think clearly under pressure, as opposed to guessing.

---

## 0) TL;DR Troubleshooting Flow

When something feels off:

1. **Confirm the network + chain data dir**
   ```bash
   grep -n '^chain=' /srv/bitcoin-testnet/bitcoin.conf
   ls -la /srv/bitcoin-testnet/testnet4/.cookie

2. **Check daemon health + logs**
    ```bash
    systemctl status -l bitcoind-testnet
    journalctl -u bitcoind-testnet -f

3. **Quick node sanity**
    ```bash
    bitcoin-cli -datadir=/srv/bitcoin-testnet -conf=/srv/bitcoin-testnet/bitcoin.conf -getinfo
    bitcoin-cli -datadir=/srv/bitcoin-testnet -conf=/srv/bitcoin-testnet/bitcoin.conf getblockchaininfo | jq '.blocks,.headers'


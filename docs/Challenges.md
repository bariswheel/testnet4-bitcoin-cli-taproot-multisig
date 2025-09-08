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

1) Multiple Users & Cookie Auth

Symptom:
bitcoin-cli ... getblockhash 0 →
Could not locate RPC credentials. No authentication cookie could be found...

Why:
bitcoind writes a cookie file under the active datadir (.../testnet4/.cookie). The cookie is only readable by the user that runs the daemon (here: bitcoin). If you run bitcoin-cli as a different user, the CLI can’t read the cookie — as opposed to transparent auth when users match.

Detect:

whoami
ls -la /srv/bitcoin-testnet/testnet4/.cookie

Fix: 

Run CLI as the same user:

sudo -u bitcoin bitcoin-cli -datadir=/srv/bitcoin-testnet -conf=/srv/bitcoin-testnet/bitcoin.conf getblockhash 0

or open an interactive shell:

sudo -iu bitcoin

2) sudo -u vs sudo -iu
	•	sudo -u bitcoin <cmd>: run one command as bitcoin (stay in current shell), as opposed to switching shells.
	•	sudo -iu bitcoin: open an interactive login shell for bitcoin (new $HOME, new environment).

Gotcha: Shell variables you set before won’t exist in the new login shell unless you export or re-define them (e.g., BCLI, MSCLI). Put exports into ~/.bashrc for persistence.

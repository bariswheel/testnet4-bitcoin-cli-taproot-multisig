⸻

LessonsLearned.md

A running log of what I learned building a Taproot 2-of-3 multisig on Bitcoin Testnet4 using only bitcoin-cli. Written to be brutally practical, as opposed to fluffy.

⸻

1) Environment, users, and permissions
	•	sudo -u bitcoin <cmd> runs one command as the bitcoin user, keeping my current shell.
	•	Use this when I only need a single privileged call, as opposed to switching shells.
	•	sudo -iu bitcoin starts an interactive login shell for the bitcoin user.
	•	New environment, new $HOME, new $PATH, new $BCLI. Ephemeral shell vars from my previous session won’t exist here unless exported, as opposed to staying in the same session.
	•	Shell var vs env var
	•	A1=... lives only in the current shell, not inherited by child processes.
	•	export BCLI=... becomes an environment variable; tools like jq, curl, or child shells see it, as opposed to shell-only variables.
	•	Cookie auth vs RPC password
	•	Running bitcoind creates testnet4/.cookie. bitcoin-cli reads it only if the calling user can read that file. If I run CLI as a different user, I’ll see: “Could not locate RPC credentials”, as opposed to smooth auth.
	•	Fix: run CLI as the same user (bitcoin) or configure rpcuser/rpcpassword (less preferred).

⸻

2) Networks and disk
	•	Testnet4 vs Testnet3
	•	Testnet4 uses prefix tb1p… for Taproot and a different genesis. The data directory is .../testnet4/, as opposed to testnet3/. Mixing them creates weirdness (wrong ports, wrong cookie, wrong blocks).
	•	Pruning vs txindex
	•	Pruned nodes (prune=10000) keep a cap on block files (~10 GB). Great for Pi, as opposed to full archival.
	•	txindex=0 is required with pruning; txindex=1 on a tiny disk is pain. Decide upfront.
	•	dbcache
	•	More dbcache (e.g., 2048) speeds validation by caching UTXO set, as opposed to hammering the NVMe.

⸻

3) Daemon hygiene and logs
	•	Don’t Ctrl-C during IBD (initial block download). Use bitcoin-cli stop, as opposed to a hard kill.
	•	Systemd is your friend
	•	systemctl status -l bitcoind-testnet → quick health
	•	journalctl -u bitcoind-testnet -f → live logs (progress, peers, pruning)
	•	Space panics
	•	df -h /srv and du -h --max-depth=1 /srv find the hogs, as opposed to guessing.

⸻

4) Descriptors and x-only keys — the mental model
	•	Descriptors are “how to spend” strings, not keys. Example:

tr([5b4bd300/86h/1h/0h/0/0]03abcd...ef)#checksum

	•	tr(...) = Taproot policy
	•	[...] = origin + HD path
	•	03abcd... = 33-byte compressed pubkey (for info) which maps to a 32-byte x-only key under Taproot, as opposed to legacy P2PKH/P2WPKH semantics.

	•	X-only
	•	Taproot uses only the X coordinate (32 bytes). Y is implied: pick the even-Y solution, as opposed to storing a full 33-byte compressed key with a parity byte.
	•	getdescriptorinfo must add the checksum
	•	Importing raw descriptors will fail with “Missing checksum”, as opposed to succeeding. Always run:

DESC_CHK=$($BCLI getdescriptorinfo "$RAW" | jq -r .descriptor)



⸻

5) Watch-only vs signer — division of responsibility
	•	Watch-only wallet holds policy (descriptor) and tracks UTXOs, as opposed to holding keys.
	•	Signer wallet holds private keys and signs PSBTs, as opposed to merely watching.
	•	This split is intentional: safer mental model and a mirror of hardware-wallet workflows.

⸻

6) PSBT pipeline — what actually happens
	1.	Collect UTXO: listunspent → get TXID, VOUT, AMT.
	2.	Build PSBT: walletcreatefundedpsbt (watch-only policy).
	3.	Sign PSBT: walletprocesspsbt (signer wallet) — can be partial or complete, as opposed to raw hex signing.
	4.	Finalize: finalizepsbt → outputs {hex, complete:true}.
	5.	Broadcast: sendrawtransaction HEX.
	6.	Verify: gettransaction TXID_CHILD + getbalances.

Why PSBT? It’s a portable transaction envelope — ideal for multi-party or offline signing, as opposed to bespoke ad-hoc flows.

⸻

7) Faucets and confirmations
	•	Faucets are rate-limited/unreliable. Some require GitHub login. That’s normal.
	•	Mempool vs Confirmed: untrusted_pending shows mempool; wait for confirmations > 0, as opposed to assuming instant settlement.

⸻

8) Common errors I hit (and fixes)
	•	“Missing checksum” → run getdescriptorinfo and use .descriptor.
	•	“Could not locate RPC credentials” → run CLI as bitcoin (cookie readable) or set RPC creds.
	•	“Only legacy wallets supported by dumpwallet” → descriptor wallets don’t dump legacy WIF; use getrawchangeaddress + getaddressinfo for descriptors, as opposed to dumping everything.
	•	“key … is not valid” with tr(threshold(...)) → Taproot doesn’t accept bare threshold(). Use multi_a or Miniscript sortedmulti_a, as opposed to pre-Taproot wsh(multi(...)).
	•	xxd: command not found → install vim-common. xxd creates random internal x-only (/dev/urandom), as opposed to trying to hand-craft 32 bytes.

⸻

9) Safety and repo hygiene
	•	Never commit wallet.dat or raw private keys, as opposed to showing off.
	•	.gitignore should ignore wallet.dat*, logs, temp files.
	•	Keep addresses, descriptors, TXIDs — these are safe and educational.

⸻

10) Why do this by hand?
	•	Doing it via CLI is muscle memory for how Bitcoin really works, as opposed to GUI magic.
	•	Once the internals are clear, moving to Sparrow/Electrum teaches how GUIs map to PSBT/descriptors.
	•	Hiring signal: shows you understand policy, construction, and validation, not just button-clicks.

⸻

11) What I’d do differently next time
	•	Start on Testnet4 immediately; delete testnet3 early to save disk.
	•	Set prune=10000, dbcache=2048, maxconnections=32 up front.
	•	Put BCLI/MSCLI exports into ~/.bashrc for the bitcoin user to persist across SSH reconnects, as opposed to redefining them.
	•	Treat faucets as flaky; have 2–3 backups ready.
	•	Capture every command + output into /docs/walkthrough.md while I go.

⸻

12) Quick glossary (opinionated)
	•	Descriptor: A “how to spend / how to derive” recipe (not a key).
	•	X-only: 32-byte pubkey (Taproot), even-Y convention, as opposed to 33-byte compressed.
	•	PSBT: Transaction envelope passed between policy and signer(s).
	•	Watch-only: Tracks UTXOs, no private keys, as opposed to signer.
	•	Signer: Holds keys and produces signatures, as opposed to only watching.
	•	Pruning: Keep recent blocks capped; saves disk, as opposed to full archival.
	•	dbcache: RAM for UTXO/DB caches; more RAM → fewer disk hits.
	•	Cookie auth: Per-process token in .cookie, as opposed to static RPC passwords.

⸻

13) Troubleshooting checklist (copy/paste friendly)
	•	systemctl status -l bitcoind-testnet
	•	journalctl -u bitcoind-testnet -f
	•	bitcoin-cli -datadir=... -conf=... -getinfo
	•	bitcoin-cli -datadir=... -conf=... getblockchaininfo | jq '.blocks,.headers'
	•	ls -la /srv/bitcoin-testnet/testnet4/.cookie (permissions)
	•	df -h /srv and du -h --max-depth=1 /srv (disk)
	•	grep -n '^chain=' /srv/bitcoin-testnet/bitcoin.conf (network)
	•	Re-derive descriptor checksum: getdescriptorinfo
	•	Verify wallet context: getwalletinfo (watch-only? private keys available?)

⸻

14) Perspective: why Taproot 2-of-3?
	•	Privacy: Key-path spend looks like single-sig, as opposed to shouting “I’m a multisig”.
	•	Flexibility: Script-path via Miniscript lets me encode more complex policies later (timelocks, recovery keys), as opposed to one rigid rule.
	•	Standards: PSBT + descriptors are the lingua franca across wallets.

⸻

If you’re reading this in the repo: you’re invited to open issues with your own gotchas. The goal is to actually understand, as opposed to just copy-pasting commands. 🚀
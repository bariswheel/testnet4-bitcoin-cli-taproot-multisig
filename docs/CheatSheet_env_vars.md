A tight cheat-sheet for every variable I grepped, plus the two exported env helpers. what it is, why we needed it, and how we used it.

## Always-exported helpers (show up in env)
- BCLI
- What: convenience alias for the signer wallet (Alice’s single-sig wallet).
- Value: bitcoin-cli -datadir=/srv/bitcoin-testnet -conf=/srv/bitcoin-testnet/bitcoin.conf -rpcwallet=alice
- Why: lets you type $BCLI getnewaddress as opposed to retyping flags.
- Used for: generating Alice’s single-sig addresses, signing PSBTs, broadcasting.
- MSCLI
- What: convenience alias for the policy/watch-only multisig wallet.
- Value: bitcoin-cli ... -rpcwallet=alice-2of3
- Why: keeps the watch-only actions separate, as opposed to mixing with signer.
- Used for: importing the Taproot 2-of-3 descriptor, listing UTXOs, funding PSBTs.

## Shell variables (not exported unless you export them)

### Address & key extraction (Alice’s 3 keys)
- A1, A2, A3
- What: Alice’s three Taproot (bech32m) addresses created in the signer wallet.
- Why: each corresponds to a different child key; we extracted pubkeys from them to build multisig.
- Used for: running $BCLI getaddressinfo "$A1" etc. to pull the descriptor and pubkey.
- D1, D2, D3
- What: the descriptor strings returned by getaddressinfo .desc for A1–A3 (e.g., tr([path]02….)#chk).
- Why: descriptors carry the key material and derivation info; we parse them to get pubkeys.
- Used for: piping through jq/sed to extract hex pubkeys.
- H1, H2, H3
- What: the raw hex compressed pubkeys (66 hex = 33 bytes) extracted from D1–D3.
- Why: intermediate step before making x-only keys.
- Used for: deciding whether to strip the first byte.
- X1, X2, X3
- What: x-only pubkeys (64 hex = 32 bytes) for Taproot (BIP340 uses x-only).
- Why: miniscript Taproot descriptors like multi_a expect x-only keys.
- Used for: constructing the Taproot 2-of-3 descriptor.

### Multisig descriptor construction
- INT
- What: the internal x-only key (random 32 bytes) used as the Taproot internal key.
- Why: prevents accidental single-sig key-path spends; forces script-path (2-of-3) policy.
- Used for: tr($INT, multi_a(2,$X1,$X2,$X3)).
- ALICE_DESC_NOCHK
- What: your 2-of-3 Taproot miniscript descriptor without checksum.
- Why: human-assembled; Core needs a checksum to accept it.
- Used for: passed into getdescriptorinfo to get a checksummed version.
- DESC_CHK
- What: the checksummed descriptor returned by getdescriptorinfo.
- Why: required by importdescriptors; guarantees descriptor integrity.
- Used for: "$MSCLI importdescriptors '[{"desc":"...#abcd1234", ...}]'".
- ADDR
- What: the derived Taproot address for the exact 2-of-3 descriptor (watch-only wallet).
- Why: receive/fund address for your policy wallet; also used as a forced changeAddress.
- Used for: faucet deposit, listunspent, and walletcreatefundedpsbt (change).

### Funding & sending
- TXID
- What: the transaction id of the faucet UTXO that funded ADDR.
- Why: identifies the coin you’re spending.
- Used for: PSBT input: [{ "txid":"$TXID","vout":$VOUT }].
- VOUT
- What: the output index of that UTXO in TXID.
- Why: pair with TXID to reference the exact coin.
- Used for: same PSBT input array.
- AMT
- What: the amount we observed in that UTXO (e.g., 0.00500000).
- Why: sizing the send and ensuring funds cover fee + change.
- Used for: simple arithmetic to set SEND.
- SEND
- What: the send amount to Bob (e.g., 0.0045).
- Why: we chose a safe value < AMT to leave room for fee/change.
- Used for: PSBT outputs: { "$BOB_ADDR": $SEND }.
- BOB_ADDR
- What: Bob’s receive Taproot address (from Bob’s signer wallet).
- Why: destination of Alice’s payment.
- Used for: the output map when funding the PSBT.

### PSBT flow
- RAW
- What: the unsigned PSBT created in the watch-only wallet via walletcreatefundedpsbt.
- Why: lets the policy wallet pick inputs/fees and (since no keypool) we forced changeAddress:"$ADDR".
- Used for: fed to the signer to add signatures.
- SIGNED
- What: the PSBT after signing in the signer wallet (walletprocesspsbt).
- Why: contains the Taproot signatures/witness data, but still in PSBT form.
- Used for: finalizepsbt.
- FINAL_JSON
- What: JSON result of finalizepsbt, including "hex" and "complete": true.
- Why: we extract the final raw transaction hex from here.
- Used for: setting TXHEX.
- TXHEX
- What: the raw transaction hex ready to broadcast.
- Why: input to sendrawtransaction.
- Used for: actually broadcasting the spend.
- TXID_CHILD
- What: the txid returned after broadcast (Alice → Bob payment).
- Why: to track confirmations and verify balances.
- Used for: gettransaction "$TXID_CHILD"; block explorers if you want.

⸻

## Why shell vs env matters
- Shell vars (all the ones above except BCLI/MSCLI) do not appear in env and don’t survive new shells, as opposed to exported env vars which do show up in env and pass to child processes.
- If you want persistence across sessions, put exports for the helpers (and any long-lived things) into /home/bitcoin/.bashrc.
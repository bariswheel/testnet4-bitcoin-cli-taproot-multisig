#!/usr/bin/env bash
# spend Alice→Bob using PSBT (watch-only funds, signer keys)
# Why? Separation of policy and keys
# Quick notes:
# - Assumes ./0_env.sh and ./1_build_alice_2of3.sh have been run
# - Assumes Alice’s 2-of-3 address (ADDR) has been funded (faucet/miner)
# - Assumes Bob’s wallet (bob) exists; we create a receive address for him
# - Saves TXID_CHILD (broadcast txid) to .send_vars for later reference

# - Tip: use `bitcoin-cli -rpcwallet=alice-2of3 listunspent` to see UTXOs
# - Tip: use `bitcoin-cli -rpcwallet=bob listtransactions` to see incoming tx
# - Tip: use `bitcoin-cli -rpcwallet=alice-2of-3 gettransaction <txid>` to see details
# -- Tip: use `bitcoin-cli -rpcwallet=alice-2of-3 getrawtransaction <txid> 1` for full details
# - Tip: use `bitcoin-cli -rpcwallet=alice-2of-3 getdescriptorinfo "<desc>"` to decode descriptors

# What is a descriptor? A descriptor is a string that describes how to spend a Bitcoin output.
# It includes information about the type of script, the public keys involved, and any conditions
# that must be met to spend the output. Descriptors are used to define wallets and addresses
# in a more human-readable and structured way.

# What does it look like? Example 2-of-3 Taproot descriptor:
#   tr([d34db33f/86h/1h/0h]03a1b2c3d4e5f67890123456789abcdef0123456789abcdef0123456789ab,
#      02b1c2d3e4f567890123456789abcdef0123456789abcdef0123456789abcd,
#      02b1c2d3e4f567890123456789abcdef0123456789abcdef0123456789ab)    # # checksum

# Those long hex strings are x-only pubkeys (BIP340/341). The `tr(...)` means Taproot
# (P2TR). The `[d34db33f/86h/1h/0h]` is an HD key origin (fingerprint + derivation path).
# The `,`-separated keys inside `tr(...)` are the 3 cosigners. The `#` and what follows is a
# checksum (not part of the descriptor itself).
# The `multi_a(2,...)` miniscript fragment means 2-of-3 multisig with BIP340/341 rules.
# What if I want to learn more? See BIP380 and BIP387.
# What if I want to decode a descriptor? Use `bitcoin-cli getdescriptorinfo "<desc>"`.
# What if I want to create a descriptor? Use `bitcoin-cli createmultisig` or
# `bitcoin-cli deriveaddresses` or manually (advanced).
# What if I want to import a descriptor into a wallet? Use `bitcoin-cli importdescriptors '[{...}]'`.
# What if I want to see a wallet’s descriptor? Use `bitcoin-cli getwalletinfo` or
# `bitcoin-cli listdescriptors` (if supported).
# What if the descriptor has private keys? Use `bitcoin-cli dumpwallet` or
# `bitcoin-cli importwallet` (if supported).
# What if the descriptor is missing? Use `bitcoin-cli importdescriptors` with `active=false` (if supported).


# --------------------------------------------------------------------------------------------------
# 20_send_from_alice_to_bob.sh
# Purpose
#   Spend coins received to the watch-only 2-of-3 (ADDR) *from* Alice’s A1/A2/A3 keys using PSBT.
#   The policy wallet chooses inputs/fees and creates an unsigned PSBT; the signer wallet adds
#   signatures; we finalize and broadcast the raw tx.
#
# Why PSBT
#   Clean separation of policy and keys. Watch-only can’t sign (by design), as opposed to mixing
#   private keys into your policy wallet. PSBT is the standard baton between them.
# --------------------------------------------------------------------------------------------------
set -euo pipefail
: "${BCLI:?Run ./00_env.sh first}"
: "${MSCLI:?Run ./00_env.sh first}"

# Load saved vars
source .alice_vars

# 0) Get or make Bob a Taproot receive address from his wallet (assumes wallet "bob" exists)
BOBCLI="bitcoin-cli -datadir=/srv/bitcoin-testnet -conf=/srv/bitcoin-testnet/bitcoin.conf -rpcwallet=bob"
BOB_ADDR=$($BOBCLI getnewaddress "bob-recv" bech32m)
echo "[info] Bob receive address: $BOB_ADDR"

# 1) Pick Alice’s funding UTXO that paid to the 2-of-3 address (ADDR)
#    We choose the most recent confirmed one. You could pin a specific TXID/VOUT if you want.
readarray -t LINES < <($MSCLI listunspent 1 | \
  jq -r --arg addr "$ADDR" '.[] | select(.address==$addr) | "\(.txid) \(.vout) \(.amount)"' | tail -n1)

if [[ ${#LINES[@]} -eq 0 ]]; then
  echo "[error] No confirmed UTXO for $ADDR yet. Fund it (faucet/miner) and try again." >&2
  exit 1
fi

TXID=$(awk '{print $1}' <<< "${LINES[0]}")
VOUT=$(awk '{print $2}' <<< "${LINES[0]}")
AMT=$(awk '{print $3}' <<< "${LINES[0]}")

echo "[info] UTXO  txid=$TXID vout=$VOUT amount=$AMT"

# 2) Decide how much to send to Bob, leaving room for fees and change.
#    We’ll send 0.0045 if we have >= 0.0006; else half (defensive fallback).
if awk "BEGIN{exit !($AMT >= 0.0006)}"; then
  SEND=0.0045
else
  SEND=$(awk -v a="$AMT" 'BEGIN{printf "%.8f", a*0.5}')
fi
echo "[info] SEND=$SEND (to $BOB_ADDR)"

# 3) Create the PSBT in the WATCH-ONLY wallet, forcing change back to the same 2-of-3 address.
#    includeWatching=true lets it spend watch-only UTXOs; changeAddress pins change to ADDR.
RAW=$($MSCLI walletcreatefundedpsbt \
  "[{\"txid\":\"$TXID\",\"vout\":$VOUT}]" \
  "{\"$BOB_ADDR\":$SEND}" \
  0 \
  "{\"subtractFeeFromOutputs\":[0],\"replaceable\":true,\"includeWatching\":true,\"changeAddress\":\"$ADDR\"}" \
  true | jq -r .psbt)

echo "[info] PSBT length: $(echo -n "$RAW" | wc -c)"

# 4) Sign the PSBT in the SIGNER wallet (has private keys for A1/A2/A3)
SIGNED=$($BCLI walletprocesspsbt "$RAW" | jq -r .psbt)

# 5) Finalize the PSBT into raw hex, then broadcast
FINAL_JSON=$($BCLI finalizepsbt "$SIGNED")
echo "$FINAL_JSON" | jq .

TXHEX=$(echo "$FINAL_JSON" | jq -r .hex)
TXID_CHILD=$($BCLI sendrawtransaction "$TXHEX")
echo "[result] broadcast txid: $TXID_CHILD"

# Save for later checks
cat > .send_vars <<EOF
TXID=$TXID
VOUT=$VOUT
AMT=$AMT
SEND=$SEND
TXID_CHILD=$TXID_CHILD
EOF
echo "[saved] wrote .send_vars"
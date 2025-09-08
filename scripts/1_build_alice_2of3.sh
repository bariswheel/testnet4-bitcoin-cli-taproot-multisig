#!/usr/bin/env bash
# Make 3 Taproot keys and a 2-of-3 multisig descriptor in Alice’s wallets
# Some notes when you run this script:
# If a faucet sends funds to ADDR, they’ll land in the watch-only wallet (alice-2of3) because that wallet
# knows the descriptor — as opposed to the signer wallet which only holds the private keys for A1..A3.
# --------------------------------------------------------------------------------------------------
# 10_build_alice_2of3.sh
#
# Purpose
#   Generate 3 Taproot addresses (A1..A3) in Alice’s signer wallet, extract x-only public keys,
#   build a Taproot miniscript 2-of-3 descriptor, checksum it, import into the watch-only policy
#   wallet, and derive a receive address (ADDR).
#
# Why
#   Taproot (BIP340/341) uses x-only pubkeys. Miniscript `multi_a(2,...)` enforces 2-of-3 script
#   spending. We add a random internal key so single-sig key-path is impossible — as opposed to
#   leaving an accidental single-key spend path.
# --------------------------------------------------------------------------------------------------
set -euo pipefail

# Require helpers
: "${BCLI:?Run ./00_env.sh first to set BCLI/MSCLI}"
: "${MSCLI:?Run ./00_env.sh first to set BCLI/MSCLI}"

# 1) Three new Taproot receive addresses in the signer wallet
A1=$($BCLI getnewaddress "alice-key1" bech32m)
A2=$($BCLI getnewaddress "alice-key2" bech32m)
A3=$($BCLI getnewaddress "alice-key3" bech32m)
echo "[info] A1=$A1"
echo "[info] A2=$A2"
echo "[info] A3=$A3"

# 2) Extract each address’s descriptor and the 33-byte compressed pubkey inside it
desc_hex () { $BCLI getaddressinfo "$1" | jq -r '.desc'; }
pick_hex () { sed -E 's@.*\]([0-9A-Fa-f]+)\).*@\1@'; }   # pulls hex after ']' until ')' or '#'

D1=$(desc_hex "$A1"); H1=$(printf "%s" "$D1" | pick_hex)
D2=$(desc_hex "$A2"); H2=$(printf "%s" "$D2" | pick_hex)
D3=$(desc_hex "$A3"); H3=$(printf "%s" "$D3" | pick_hex)
echo "[info] D1=$D1"
echo "[info] D2=$D2"
echo "[info] D3=$D3"
echo "[info] H1=$H1"
echo "[info] H2=$H2"
echo "[info] H3=$H3"

# 3) Normalize to x-only keys (BIP340): if 33-byte (66 hex) drop 1-byte prefix 02/03; else keep
xonly () { local h="$1"; if [[ ${#h} -eq 66 ]]; then echo "${h:2}"; else echo "$h"; fi; }
X1=$(xonly "$H1")
X2=$(xonly "$H2")
X3=$(xonly "$H3")
echo "[info] X1=$X1"
echo "[info] X2=$X2"
echo "[info] X3=$X3"

# 4) Generate a random internal x-only key (prevents key-path single-sig spends)
#    Needs xxd; install once via: sudo apt-get install -y xxd
INT=$(xxd -p -l 32 /dev/urandom)
echo "[info] INT=$INT"

# 5) Build the Taproot miniscript descriptor (no checksum yet)
#    tr(<internal_xonly>, multi_a(2,<X1>,<X2>,<X3>))
ALICE_DESC_NOCHK="tr($INT,multi_a(2,$X1,$X2,$X3))"
echo "[info] ALICE_DESC_NOCHK=$ALICE_DESC_NOCHK"

# 6) Ask Core to validate + append checksum
DESC_CHK=$($BCLI getdescriptorinfo "$ALICE_DESC_NOCHK" | jq -r .descriptor)
echo "[info] DESC_CHK=$DESC_CHK"

# 7) Import descriptor into the watch-only policy wallet and mark active
$MSCLI importdescriptors "[{ \"desc\": \"$DESC_CHK\", \"active\": true, \"label\": \"alice-2of3\", \"timestamp\": \"now\" }]" | jq .

# 8) Derive the address for this exact descriptor (the receive/change target)
ADDR=$($MSCLI deriveaddresses "$DESC_CHK" | jq -r '.[0]')
echo "[result] alice-2of3 receive addr (also change): $ADDR"

# Persist handy vars for later scripts
cat > .alice_vars <<EOF
A1=$A1
A2=$A2
A3=$A3
X1=$X1
X2=$X2
X3=$X3
INT=$INT
DESC_CHK=$DESC_CHK
ADDR=$ADDR
EOF
echo "[saved] wrote .alice_vars"
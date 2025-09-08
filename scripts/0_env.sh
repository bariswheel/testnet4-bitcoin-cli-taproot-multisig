#!/usr/bin/env bash
# Session bootstrap: helpers, sanity checks, etc.
# --------------------------------------------------------------------------------------------------
# 00_env.sh
#
# Purpose
#   Prime your shell with convenient helpers pointing at your Testnet4 node and wallets.
#   We export BCLI (Alice signer) and MSCLI (Alice policy/watch-only 2-of-3) so child
#   processes and scripts inherit them, as opposed to plain shell vars which die with the shell.
#
# Why
#   Re-typing -datadir/-conf/-rpcwallet is error-prone. Aliases keep muscle memory short.
# --------------------------------------------------------------------------------------------------
set -euo pipefail

# Where your node data lives
DATADIR="/srv/bitcoin-testnet"
CONF="$DATADIR/bitcoin.conf"

# Exported helpers (show up in `env`, survive into child processes)
export BCLI="bitcoin-cli -datadir=$DATADIR -conf=$CONF -rpcwallet=alice"
export MSCLI="bitcoin-cli -datadir=$DATADIR -conf=$CONF -rpcwallet=alice-2of3"

# Quick sanity: prove we’re on testnet4 (genesis hash)
echo "[info] chain check: $(bitcoin-cli -datadir=$DATADIR -conf=$CONF getblockhash 0)"
echo "[info] signer wallet: $($BCLI getwalletinfo | jq '{name,descriptor,private_keys_enabled}')"
echo "[info] policy  wallet: $($MSCLI getwalletinfo | jq '{name,descriptor,private_keys_enabled}')"


# --------------------------------------------------------------------------------------------------
# 00_env.sh — Environment Bootstrap
#
# What
# Sets up environment variables (`BCLI` and `MSCLI`) to make Bitcoin Core CLI usage easier.
#
# Why
# Typing out `bitcoin-cli -datadir=... -conf=... -rpcwallet=...` every time is repetitive and error-prone.
# This script simplifies the workflow and ensures consistency.
#
# How
# - Defines `DATADIR` and `CONF`.
# - Exports `BCLI` (Alice signer wallet).
# - Exports `MSCLI` (Alice 2-of-3 policy/watch-only wallet).
# - Performs a quick sanity check:
#   - Verifies you’re on Testnet4.
#   - Prints wallet info for Alice and Alice-2of3.
#
# Usage
# ```bash
# chmod +x 00_env.sh
# ./00_env.sh
# ```
#!/usr/bin/env bash
# Quick status and confirmations after sending a transaction
# FAQ:
# - How can I check the status of a transaction?
#   Use `bitcoin-cli gettransaction <txid>` to check the status of a transaction.
# - How can I see the balance of a wallet?
#   Use `bitcoin-cli -rpcwallet=<wallet_name> getbalances` to see the balance of a wallet.
# - What if I want to see all transactions for a wallet?
#   Use `bitcoin-cli -rpcwallet=<wallet_name> listtransactions` to see all transactions for a wallet.
# - How can I check the confirmation status of a transaction?
#   Use `bitcoin-cli gettransaction <txid>` and look for the "confirmations" field.
# - How can I check the balance of a multisig wallet?
#   Use `bitcoin-cli -rpcwallet=<multisig_wallet_name> getbalances` to see the balance of a multisig wallet.
# - How can I check the balance of another user's wallet?
#   Use `bitcoin-cli -rpcwallet=<other_user_wallet_name> getbalances` to see the balance of another user's wallet.
# - How can I check the balance of a wallet using a different datadir or config file?
#   Use `bitcoin-cli -datadir=<path_to_datadir> -conf=<path_to_conf_file> -rpcwallet=<wallet_name> getbalances` to see the balance of a wallet using a different datadir or config file.
# - How can I check the balance of a wallet using environment variables?
#   Set the environment variables `BCLI` and `MSCLI` to your desired `bitcoin-cli` commands and use them to check balances.
# - What does set -euo pipefail do in a bash script?
#   It makes the script exit on errors, unset variables, and failed pipes for better error handling.
# - How can I source variables from another file in a bash script?
#   Use the `source <file_name>` command to include variables from another file.
# - How can I format JSON output in bash?
#   Use `jq` to format and filter JSON output in bash.
# - How can I check the balance of a wallet named "alice"?
#   Use `bitcoin-cli -rpcwallet=alice getbalances` to see the balance of the "alice" wallet.
# - How can I check the balance of a multisig wallet named "alice-2of3"?
#   Use `bitcoin-cli -rpcwallet=alice-2of3 getbalances` to see the balance of the "alice-2of3" multisig wallet.
# - How can I check the balance of a wallet named "bob" in a different datadir?
#   Use `bitcoin-cli -datadir=/path/to/datadir -conf=/path/to/bitcoin.conf -rpcwallet=bob getbalances` to see the balance of the "bob" wallet in a different datadir.
# - How can I check the details of a transaction using its txid?
#   Use `bitcoin-cli gettransaction <txid>` to see the details of a transaction using its txid.
# - How can I filter specific fields from the transaction details?
#   Use `jq '{field1, field2, ...}'` to filter specific fields from the JSON output.
# - How can I ensure that my bash script runs with strict error handling?
#   Use `set -euo pipefail` at the beginning of your bash script for strict error handling.
# - How can I check the balance and transaction status after sending a transaction?
#   Use a script like this one to check balances and transaction status after sending a transaction
# --------------------------------------------------------------------------------------------------
# 30_check_balances.sh
#
# Purpose
#   Re-show balances and confirmation state after a send.
# --------------------------------------------------------------------------------------------------
set -euo pipefail
: "${BCLI:?Run ./00_env.sh first}"
: "${MSCLI:?Run ./00_env.sh first}"

source .alice_vars
source .send_vars
BOBCLI="bitcoin-cli -datadir=/srv/bitcoin-testnet -conf=/srv/bitcoin-testnet/bitcoin.conf -rpcwallet=bob"

echo "[info] Alice signer (alice) balance:"
$BCLI getbalances | jq .

echo "[info] Alice policy (alice-2of3) balance:"
$MSCLI getbalances | jq .

echo "[info] Bob (bob) balance:"
$BOBCLI getbalances | jq .

echo "[info] Child tx (Alice -> Bob): $TXID_CHILD"
$BCLI gettransaction "$TXID_CHILD" | jq '{amount, fee, confirmations}'
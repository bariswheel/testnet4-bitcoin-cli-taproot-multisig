<!-- filepath: /Users/baris/code/testnet4-bitcoin-cli-taproot-multisig/docs/QuickGlossaryforScriptsDir.md -->
Quick glossary (so the why sticks)

- bech32m: address encoding used by Taproot (as opposed to bech32 used by segwit v0).
- Taproot x-only pubkey: 32-byte public key using only the x-coordinate (BIP340). Two possible y’s collapse to one convention (even y), which simplifies validation and signatures, as opposed to 33-byte compressed keys with 02/03 prefix.
- Internal key (INT): the top-level Taproot key inside tr(<internal>, script) that commits to the whole script tree. We use a random key nobody controls so key-path single-sig spends are impossible; you must use the script path (your 2-of-3), as opposed to accidentally letting a single key spend things.
- Descriptor: a structured string describing how to derive/validate spending — not just an address. With a checksum appended, Core can safely import/watch/derive without secrets, as opposed to importing random addresses with no provenance.
- Watch-only wallet: a wallet that knows policies/addresses but holds no private keys. It can select inputs, estimate fees, and build PSBTs — not sign — as opposed to a signing wallet that has private keys enabled.
- PSBT: Partially Signed Bitcoin Transaction. A transport format that lets policy and keys live in different places safely; watch-only builds, signer signs, broadcaster broadcasts — as opposed to stuffing keys into a hot policy wallet.
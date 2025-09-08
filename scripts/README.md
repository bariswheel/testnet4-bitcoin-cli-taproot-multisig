# Scripts Overview

Each script captures one stage of the multisig workflow:

1. **01_generate_keys.sh**  
   - Creates 3 Taproot addresses for Alice (`A1`, `A2`, `A3`).  
   - Extracts descriptors and x-only pubkeys.  

2. **02_build_multisig.sh**  
   - Constructs a 2-of-3 Taproot descriptor.  
   - Imports it into the `alice-2of3` wallet.  
   - Derives the multisig receive address.  

3. **03_request_funds.sh**  
   - Requests coins from a Testnet4 faucet.  
   - Verifies UTXOs appear in Alice’s watch-only wallet.  

4. **04_send_tx.sh**  
   - Builds a PSBT spending from Alice to Bob.  
   - Signs with Alice’s signer wallet.  
   - Broadcasts the transaction to the Testnet network.  

---
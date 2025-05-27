Prover Overview


Arbitrum storage proof documentation:
https://docs.google.com/document/d/1zf_9r5-yL3yqwr6zfz-bExU8gey4hr8Q3jVi8tbev3I/edit?tab=t.0

1. Given:
    - time (aka now / current block)
    - L1 block info
   Prove:
    - the execution client state-root for Eth L1 is <L1-execution-state-root>
   How:
    - Steps 1-4
    - File: l1_state_proofs.go (generic to all L2s)

2. Given:
    - a proven <L1-execution-state-root>
    - Arbitrum L2Oracle contract address
    - Storage slot for latestConfirmedBlock in the L2Oracle contract
   Prove:
    - the latestConfirmedBlock and its metadata for Arbitrum
   How:
    - Step 5 & Step 7.2 & Step 8 in the doc
    - File: arbitrum_prover/state_proofs.go (specific to arbitrum)

3. Given:
    - latestConfirmedBlock and its metadata for Arbitrum
    - The RIP7755 Inbox contract address on Arbitrum
    - Storage slot for fulfillmentInfo[requestHash]
   Prove:
    - fulfillmentInfo is stored at latestConfirmedBlock in Arbitrum
      (aka the fulfiller has successfully fulfilled the request)
   How:
    - Step 6 & 7.1 & 8 in the doc
    - File: inbox_storage_proofs.go (generic to most L2s)
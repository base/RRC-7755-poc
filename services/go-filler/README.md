# RRC-7755 Go Filler Service

> **DISCLAIMER:** This is a preliminary draft version of a Go implementation for the RRC-7755 filler. It contains experimental and hacky code that is not production-ready. Please do not use the code for any production purposes. This implementation is meant for demonstration and testing purposes only.
> 
> **⚠️ IMPORTANT:** Users should understand that:
> - This code is still in early development
> - It may contain bugs or failures.
> - The implementation makes numerous assumptions that might not hold in other environments
> - This code is highly imperfect and is generated in a hackathon-like development environment. It does not represent Base's engineering standards or best practices
> - It is provided solely as a reference implementation for experimental purposes
> - No warranty or official support is provided for this code
>
> Please use this implementation wisely and only for exploratory purposes. Do not deploy it in production environments.

The Go Filler service is part of the RRC-7755 proof-of-concept implementation. It listens for message events from Outbox contracts on source chains and fulfills those messages on destination chains.

## Features

### What is included in the go-filler

1. Outbox package:
- Listen to requests from outbox
- Validate request content
- Send fulfillment to inbox

2. Prover package:
- Generate proof of fulfillment on arbitrum as a destination chain on devnet (disclaimer: unit tested but not E2E tested onchain)

### What is not included yet

- Usage of service frameworks
- Storage for outbox requests
- Submission of proof to the outbox to claim rewards
- Mainnet storage proof


## Prerequisites

- Go 1.20 or later
- Access to Ethereum RPC endpoints

## Environment Setup

Create a `.env` file in the project root directory with the following variables:

```
# RPC endpoints for different chains (examples)
SEPOLIA_RPC=wss://ethereum-sepolia-rpc.publicnode.com
BASE_SEPOLIA_RPC=wss://base-sepolia-rpc.publicnode.com
ARBITRUM_SEPOLIA_RPC=wss://sepolia-rollup.arbitrum.io/feed

# Wallet configuration
from-address: .env//YOUR_WALLET_ADDR
private-key: .env//YOUR_WALLET_PRIVATE_KEY
recipient-address: .env//RECIPIENT_ADDR
```

## Configuration

The service uses YAML configuration files located in `services/go-filler/cmd/config/`. The main configuration file is `local.yaml`, which includes:

- Chain configurations (chain IDs, RPC URLs, contract addresses)
- Wallet configuration
- Outbox and Inbox address mappings

## Building and Running

### Using Make

The project includes a Makefile with several useful commands:

```bash
# Run the service
make run
```

### Manual Running

If you prefer to run the service manually:

```bash
cd services/go-filler
go build -o bin/filler cmd/main.go
./bin/filler
```

## Troubleshooting

### Common Issues

- **Connection issues**: Check your RPC endpoint URLs and ensure they're accessible from your environment.
- **Insufficient funds**: Ensure your wallet has enough funds on the destination chains to cover transaction costs.



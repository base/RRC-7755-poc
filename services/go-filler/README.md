# RRC-7755 Go Filler Service

> **DISCLAIMER:** This is a preliminary draft version of a Go implementation for the RRC-7755 filler. It contains experimental and hacky code that is not production-ready. Please use with caution and careful consideration. This implementation is meant for demonstration and testing purposes only.
> 
> **⚠️ IMPORTANT:** Users should understand that:
> - This code is still in early development
> - It may contain bugs or failures.
> - The implementation makes numerous assumptions that might not hold in other environments
> - This code is highly imperfect and does not represent Base's engineering standards or best practices
> - It is provided solely as a reference implementation for experimental purposes
>
> Please use this implementation wisely and only for exploratory purposes. Do not deploy it in production environments without substantial modifications and proper testing.

The Go Filler service is part of the RRC-7755 proof-of-concept implementation. It listens for message events from Outbox contracts on source chains and fulfills those messages on destination chains.

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

## Sample Transaction Sender

The service includes a sample transaction sender (`internal/inbox/sample_sender.go`) that can be used to test cross-chain messaging. The sample sender:

1. Creates a test transaction on the Base Sepolia network
2. Uses the wallet configuration from the config file
3. Signs and sends a simple ETH transfer to demonstrate transaction processing

This sample sender is enabled in `cmd/main.go` and automatically executes when the service starts:

```go
txManager := inbox.NewTransactionSenderManager(clientMgr, cfg, log)
err = txManager.SendTestTransaction(ctx)
```

To use the sample sender with your own parameters:
- Update the recipient address in the config file
- Modify the transaction amount (currently set to 10000000000 wei or 0.00000001 ETH)
- Ensure your wallet has sufficient funds on the Base Sepolia network


## Troubleshooting

### Common Issues

- **Connection issues**: Check your RPC endpoint URLs and ensure they're accessible from your environment.
- **Insufficient funds**: Ensure your wallet has enough funds on the destination chains to cover transaction costs.



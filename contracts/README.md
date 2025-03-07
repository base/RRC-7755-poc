# RRC-7755 Contracts _(RRC-7755-poc)_

A proof-of-concept implementation of the [RRC-7755](https://github.com/ethereum/RIPs/blob/master/RIPS/rip-7755.md) protocol for standardized, permissionless, and decentralized cross-chain calls.

## Table of Contents

- [Background](#background)
- [Security](#security)
- [Install](#install)
- [Usage](#usage)
  - [Standard Requests](#standard-requests)
  - [ERC-4337 User Operations](#erc-4337-user-operations)
- [Contract Architecture](#contract-architecture)
- [Deployed Contracts](#deployed-contracts)
- [Contributing](#contributing)
- [License](#license)

## Security

This is a proof-of-concept implementation and has not been audited for production use. Use at your own risk.

## Install

### Install Foundry if not already installed

```bash
make install-foundry
```

### Install dependencies

```bash
forge install
```

### Compile contracts

```bash
forge build
```

### Run tests

```bash
make test
```

### Check coverage report

```bash
make coverage
```

## Usage

### Setup

Create a `.env` file in this directory with the following:

```txt
ARBITRUM_SEPOLIA_RPC=
OPTIMISM_SEPOLIA_RPC=
BASE_SEPOLIA_RPC=
```

Create a cast wallet with the following command (you'll need a private key ready - if you don't have one, you can create one with `cast wallet new` first):

```bash
cast wallet import testnet-admin --interactive
```

Enter the private key of the account you want to use. Note, this account needs to be funded on all chains you'd like to submit requests to.

### Standard Requests

Base Sepolia -> Arbitrum Sepolia

```bash
make submit-base-to-arbitrum
```

Base Sepolia -> Optimism Sepolia

```bash
make submit-base-to-optimism
```

Arbitrum Sepolia -> Base Sepolia

```bash
make submit-arbitrum-to-base
```

Arbitrum Sepolia -> Optimism Sepolia

```bash
make submit-optimism-to-arbitrum
```

Optimism Sepolia -> Base Sepolia

```bash
make submit-optimism-to-base
```

### ERC-4337 User Operations

Base Sepolia -> Arbitrum Sepolia

```bash
make userop-base-to-arbitrum
```

Base Sepolia -> Optimism Sepolia

```bash
make userop-base-to-optimism
```

Arbitrum Sepolia -> Base Sepolia

```bash
make userop-arbitrum-to-base
```

Arbitrum Sepolia -> Optimism Sepolia

```bash
make userop-arbitrum-to-optimism
```

Optimism Sepolia -> Arbitrum Sepolia

```bash
make userop-optimism-to-arbitrum
```

Optimism Sepolia -> Base Sepolia

```bash
make userop-optimism-to-base
```

### Fulfilling Requests

To fulfill a cross-chain request:

```bash
make fulfill-request
```

### Recovering Paymaster Funds

To recover funds from the paymaster:

```bash
make recover-paymaster-funds
```

## Contract Architecture

The RRC-7755 protocol implementation consists of the following key contracts:

- **RRC7755Base**: Contains helper functions and shared message attributes for RRC-7755 used by both Inbox and Outbox contracts.
- **RRC7755Inbox**: An inbox contract that routes requested transactions on destination chains and stores record of their fulfillment.
- **RRC7755Outbox**: An abstract Outbox contract containing common logic for sending messages and facilitating reward redemption for fulfillers.
- **Paymaster**: Used as a hook for fulfillers to provide funds for requested transactions when the cross-chain calls.
- **NonceManager**: Manages the nonce for the RRC7755 protocol.

The exact proof verification used by an Outbox depends on the destination chain that Outbox is designed for. We have three options at this point in time:

- **RRC7755OutboxToArbitrum**: An outbox meant for an ERC-4788 compliant chain to send messages to Arbitrum.
- **RRC7755OutboxToHashi**: A flexible outbox that can be deployed to any evm compatible chain. It relies on the [Hashi](https://crosschain-alliance.gitbook.io/hashi) system for sharing block headers from various destination chains.
- **RRC7755OutboxToOPStack**: An outbox meant for an ERC-4788 compliant chain to send messages to OP Stack chains.

The protocol also includes libraries for handling proofs and validating cross-chain calls:

- **GlobalTypes**: Utility functions for converting addresses to bytes32 and vice versa.
- **StateValidator**: Validates storage proofs.
- **ArbitrumProver**: Utility library for validating Arbitrum storage proofs.
- **HashiProver**: Utility library for validating storage proofs against state relayed by the Hashi system.
- **OPStackProver**: Utility library for validating OP Stack storage proofs.

## Deployed Contracts

The following contracts are deployed on testnet networks:

### Arbitrum Sepolia

- Paymaster: `0xb9fe312ea3343c6bede81e6b55e4f366ef7de349`
- RRC7755Inbox: `0x323adf2126c21437f483c2577a19d710dba1ef67`
- RRC7755OutboxToOPStack: `0x8e08557ea7ee8f0f864e8d19fa2efb0dc461d1a6`
- RRC7755OutboxToHashi: `0x3dd851ef532b2dd539687d7b3584ecb9774376e7`

### Base Sepolia

- Paymaster: `0x46f0a3ff3e76e3a8e934d89b6fa9638ff5242af3`
- RRC7755Inbox: `0xe680ae8de71ece7d7fc88ef3cbbdcc2a2431513e`
- RRC7755OutboxToArbitrum: `0x6f3dddfa9af3d8fa1ae02e8266fb30416f1c78ba`
- RRC7755OutboxToOPStack: `0x0fd2223e845a7d4a7dc5379f80c0c1a3f2b441e0`
- RRC7755OutboxToHashi: `0x6c54ebbe73fa66f77c62bb54b63ef567a0adcb9b`

### Optimism Sepolia

- Paymaster: `0xfc05c360c52ed9cf5e186d7d0331e78f0cc81c2a`
- RRC7755Inbox: `0xe830e648adb3174a1c8d0a981a34267bad6c5de7`
- RRC7755OutboxToArbitrum: `0x5d3147ffeee0dbbaff600d50299b917011da326d`
- RRC7755OutboxToOPStack: `0xa41efddafd269e923786674533d24677592266e5`
- RRC7755OutboxToHashi: `0x00191e3d735554e58fe63c6c5a314f3caeee64f5`

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## License

This project is licensed under the [MIT License](../LICENSE).

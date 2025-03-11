![Base](logo.webp)

# RRC-7755

## Overview

RRC-7755 is a Rollup Improvement Proposal that introduces a standard for facilitating cross-chain calls within the Ethereum ecosystem. It aims to minimize trust assumptions by means of a proof system that leverages state sharing between Ethereum and its rollups. This proof system verifies destination chain call execution, enabling secure compensation for offchain agents that process requested transactions.

For more information, read the full proposal [here](https://github.com/ethereum/RIPs/blob/master/RIPS/rip-7755.md).

This repository serves as a proof of concept implementation of the RRC-7755 protocol.

## Components

- [Contracts](./contracts/README.md)
- [Fulfiller](./services/ts-filler/README.md)

## License

This project is licensed under the MIT License.

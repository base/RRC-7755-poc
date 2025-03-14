import {
  decodeEventLog,
  type Address,
  type Block,
  type Hex,
  type Log,
} from "viem";
const { ssz } = await import("@lodestar/types");
const { SignedBeaconBlock } = ssz.electra;

import ArbitrumRollup from "../abis/ArbitrumRollup";
import AnchorStateRegistry from "../abis/AnchorStateRegistry";
import {
  SupportedChains,
  type ActiveChains,
  type Assertion,
  type DecodedNodeCreatedLog,
  type GetBeaconRootAndL2TimestampReturnType,
  type L2Block,
} from "../common/types/chain";
import type ConfigService from "../config/config.service";
import safeFetch from "../common/utils/safeFetch";
import exponentialBackoff from "../common/utils/exponentialBackoff";

export default class ChainService {
  private usingHashi: boolean;

  constructor(
    private readonly activeChains: ActiveChains,
    private readonly configService: ConfigService
  ) {
    this.usingHashi =
      !this.activeChains.src.exposesL1State ||
      !this.activeChains.dst.sharesStateWithL1;
  }

  async getBeaconRootAndL2Timestamp(): Promise<GetBeaconRootAndL2TimestampReturnType> {
    console.log("getBeaconRootAndL2Timestamp");
    const config = this.activeChains.src;
    const block: L2Block = await exponentialBackoff(
      async () => await config.publicClient.getBlock()
    );

    return {
      beaconRoot: block.parentBeaconBlockRoot,
      timestampForL2BeaconOracle: block.timestamp,
    };
  }

  async getBeaconBlock(tag: string): Promise<any> {
    console.log("getBeaconBlock");
    const beaconApiUrl = this.configService.getOrThrow("NODE");
    const url = `${beaconApiUrl}/eth/v2/beacon/blocks/${tag}`;
    const req = { headers: { Accept: "application/octet-stream" } };
    const resp = await exponentialBackoff(
      async () => await safeFetch(url, req),
      { successCallback: (res) => res && res.status === 200 }
    );

    if (!resp) {
      throw new Error("Error fetching Beacon Block");
    }

    if (resp.status === 404) {
      throw new Error(`Missing block ${tag}`);
    }

    if (resp.status !== 200) {
      throw new Error(`error fetching block ${tag}: ${await resp.text()}`);
    }

    const raw = new Uint8Array(await resp.arrayBuffer());
    const signedBlock = SignedBeaconBlock.deserialize(raw);
    return signedBlock.message;
  }

  async getL1Block(): Promise<Block> {
    return await this.activeChains.l1.publicClient.getBlock();
  }

  async getL2Block(blockNumber?: bigint): Promise<{
    l2Block: Block;
    parentAssertionHash?: Hex;
    afterInboxBatchAcc?: Hex;
    assertion?: Assertion;
  }> {
    console.log("getL2Block");

    switch (this.activeChains.dst.chainId) {
      case SupportedChains.ArbitrumSepolia:
        return await this.getArbitrumSepoliaBlock(blockNumber);
      case SupportedChains.BaseSepolia:
      case SupportedChains.OptimismSepolia:
      case SupportedChains.MockOptimism:
        return await this.getOptimismSepoliaBlock(blockNumber);
      default:
        throw new Error("Received unknown chain in getL2Block");
    }
  }

  private async getArbitrumSepoliaBlock(l1BlockNumber?: bigint): Promise<{
    l2Block: Block;
    parentAssertionHash: Hex;
    afterInboxBatchAcc: Hex;
    assertion: Assertion;
  }> {
    console.log("getArbitrumSepoliaBlock");

    if (!this.usingHashi) {
      if (!l1BlockNumber) {
        throw new Error("Block number is required");
      }
    }

    // Need to get blockHash instead
    // 1. Get latest node from Rollup contract
    const assertionHash: Hex = await exponentialBackoff(async () => {
      return await this.activeChains.l1.publicClient.readContract({
        address: this.activeChains.dst.l2Oracle,
        abi: ArbitrumRollup,
        functionName: "latestConfirmed",
        blockNumber: l1BlockNumber,
      });
    });

    // 2. Query event from latest node creation
    const logs = await this.getLogs(assertionHash);
    if (logs.length === 0) {
      throw new Error("Error finding Arb Rollup Log");
    }
    const topics = decodeEventLog({
      abi: ArbitrumRollup,
      data: logs[0].data,
      topics: logs[0].topics,
    }) as unknown as DecodedNodeCreatedLog;

    if (!topics.args) {
      throw new Error("Error decoding NodeCreated log");
    }
    if (!topics.args.assertion) {
      throw new Error("Error: assertion field not found in decoded log");
    }

    // 3. Grab assertion from Node event
    const { parentAssertionHash, assertion, afterInboxBatchAcc } = topics.args;

    // 4. Parse blockHash from assertion
    const blockHash = assertion.afterState.globalState.bytes32Vals[0];
    const l2Block = await exponentialBackoff(async () => {
      return await this.activeChains.dst.publicClient.getBlock({
        blockHash,
      });
    });
    return {
      l2Block,
      parentAssertionHash,
      afterInboxBatchAcc,
      assertion: assertion.afterState,
    };
  }

  private async getOptimismSepoliaBlock(
    blockNumber?: bigint
  ): Promise<{ l2Block: Block }> {
    const l2BlockNumber = await this.getL2BlockNumber(blockNumber);
    const l2Block = await exponentialBackoff(async () => {
      return await this.activeChains.dst.publicClient.getBlock({
        blockNumber: l2BlockNumber,
      });
    });
    return { l2Block };
  }

  private async getLogs(assertionHash: Address): Promise<Log[]> {
    const etherscanApiKey = this.configService.getOrThrow("ETHERSCAN_API_KEY");
    const url = `https://api-sepolia.etherscan.io/api?module=logs&action=getLogs&address=${this.activeChains.dst.l2Oracle}&topic0=0x901c3aee23cf4478825462caaab375c606ab83516060388344f0650340753630&topic0_1_opr=and&topic1=${assertionHash}&page=1&apikey=${etherscanApiKey}`;

    return await this.request(url);
  }

  private async getL2BlockNumber(l1BlockNumber?: bigint): Promise<bigint> {
    if (this.usingHashi) {
      // NOTE: This is only for a proof of concept. We have a mock shoyu bashi contract that allows us to directly set the block hash for the l2 block number.
      // In production, more sophisticated logic will be needed to determine the latest block number accounted for in the Hashi system.
      return await exponentialBackoff(
        async () => await this.activeChains.dst.publicClient.getBlockNumber()
      );
    }

    if (!l1BlockNumber) {
      throw new Error("Block number is required");
    }

    const config = this.activeChains.l1;
    const [, l2BlockNumber]: [any, bigint] = await exponentialBackoff(
      async () => {
        return await config.publicClient.readContract({
          address: this.activeChains.dst.l2Oracle,
          abi: AnchorStateRegistry,
          functionName: "anchors",
          args: [0n],
          blockNumber: l1BlockNumber,
        });
      }
    );
    return l2BlockNumber;
  }

  async getOutboxLogs(
    fromBlock: number,
    outboxAddress: Address
  ): Promise<Log[]> {
    const apiKey = this.activeChains.src.etherscanApiKey;
    const url = `${this.activeChains.src.etherscanApiUrl}/api?module=logs&action=getLogs&address=${outboxAddress}&topic0=0x8c3e2b6a5f9f3998732307b6e6be96b5c909d7801671bffa843457af80ccc21f&page=1&apikey=${apiKey}&fromBlock=${fromBlock}`;

    return await this.request(url);
  }

  private async request(url: string): Promise<any> {
    const res = await exponentialBackoff(async () => await safeFetch(url), {
      successCallback: (res) => res && res.ok,
    });

    if (res === null || !res.ok) {
      throw new Error("Error fetching logs from etherscan");
    }

    const json = await res.json();

    return json.result;
  }
}

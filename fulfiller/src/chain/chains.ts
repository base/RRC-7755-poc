import {
  arbitrumSepolia,
  baseSepolia,
  optimismSepolia,
  sepolia,
} from "viem/chains";
import { createPublicClient, http } from "viem";

import { Provers, type ChainConfig } from "../common/types/chain";
import { chainA } from "../common/chains/chainA";
import { chainB } from "../common/chains/chainB";
import { mockL1 } from "../common/chains/mockL1";

export default {
  // Arbitrum Sepolia
  421614: {
    chainId: 421614,
    outboxContracts: {
      Hashi: "0xaa7b83ca363504a753fa059af17131dff1f55d00",
    },
    rpcUrl:
      process.env.ARBITRUM_SEPOLIA_RPC ||
      arbitrumSepolia.rpcUrls.default.http[0],
    l2Oracle: "0x042B2E6C5E99d4c521bd49beeD5E99651D9B0Cf4",
    l2OracleStorageKey:
      "0x0000000000000000000000000000000000000000000000000000000000000076",
    contracts: {
      // inbox: "0xdac62f96404AB882F5a61CFCaFb0C470a19FC514", // mock verifier address
      inbox: "0xa651231f817b056ef42d05bb65914ab257cdaa1f",
      entryPoint: "0x0000000071727De22E5E9d8BAf0edAc6f37da032",
      paymaster: "0x38fe4578bf38409affb88e44786e59052265fb02",
    },
    publicClient: createPublicClient({
      chain: arbitrumSepolia,
      transport: http(process.env.ARBITRUM_SEPOLIA_RPC),
    }),
    targetProver: Provers.Arbitrum,
    exposesL1State: false,
    sharesStateWithL1: true,
    etherscanApiKey: process.env.ARBISCAN_API_KEY,
    etherscanApiUrl: "https://api-sepolia.arbiscan.io",
  },
  // Base Sepolia
  84532: {
    chainId: 84532,
    outboxContracts: {
      Arbitrum: "0x82e5967546624daae02af5165176825a9a9a912d",
      OPStack: "0xaa182e3e8c9cb80f6cde5d4986132c797fb29a06",
      Hashi: "0xd929bd8fc15322a309e59c13cc03a88bc1042b40",
    },
    rpcUrl: process.env.BASE_SEPOLIA_RPC || baseSepolia.rpcUrls.default.http[0],
    l2Oracle: "0x4C8BA32A5DAC2A720bb35CeDB51D6B067D104205",
    l2OracleStorageKey:
      "0xa6eef7e35abe7026729641147f7915573c7e97b47efa546f5f6e3230263bcb49",
    contracts: {
      l2MessagePasser: "0x4200000000000000000000000000000000000016",
      inbox: "0x7d4652fa81aec41f075ea62a134cabc121c5d484",
      entryPoint: "0x0000000071727De22E5E9d8BAf0edAc6f37da032",
      paymaster: "0xaa7b83ca363504a753fa059af17131dff1f55d00",
    },
    publicClient: createPublicClient({
      chain: baseSepolia,
      transport: http(process.env.BASE_SEPOLIA_RPC),
    }),
    targetProver: Provers.OPStack,
    exposesL1State: true,
    sharesStateWithL1: true,
    etherscanApiKey: process.env.BASESCAN_API_KEY,
    etherscanApiUrl: "https://api-sepolia.basescan.org",
  },
  // Optimism Sepolia
  11155420: {
    chainId: 11155420,
    outboxContracts: {
      Arbitrum: "0xf29e537569d29b125a74e4498724f8a9a848b770",
      OPStack: "0xbdbd57f48ddf577ef7f0d13d8728494a783aa8d8",
      Hashi: "0xc4e98ccdf034b02b049222b8ef42597d76c81db8",
    },
    rpcUrl:
      process.env.OPTIMISM_SEPOLIA_RPC ||
      optimismSepolia.rpcUrls.default.http[0],
    l2Oracle: "0x218CD9489199F321E1177b56385d333c5B598629",
    l2OracleStorageKey:
      "0xa6eef7e35abe7026729641147f7915573c7e97b47efa546f5f6e3230263bcb49",
    contracts: {
      l2MessagePasser: "0x4200000000000000000000000000000000000016",
      inbox: "0x13bb830380802faea8cc032bc9bbead4e5aae0ab",
      entryPoint: "0x0000000071727De22E5E9d8BAf0edAc6f37da032",
      paymaster: "0xce2433caafcfb72f31e6d595ddd53ac82e5ab3b8",
    },
    publicClient: createPublicClient({
      chain: optimismSepolia,
      transport: http(process.env.OPTIMISM_SEPOLIA_RPC),
    }),
    targetProver: Provers.OPStack,
    exposesL1State: true,
    sharesStateWithL1: true,
    etherscanApiKey: process.env.OPTIMISM_API_KEY,
    etherscanApiUrl: "https://api-sepolia-optimistic.etherscan.io",
  },
  // Sepolia
  11155111: {
    chainId: 11155111,
    outboxContracts: {},
    rpcUrl: process.env.SEPOLIA_RPC || sepolia.rpcUrls.default.http[0],
    l2Oracle: "0x",
    l2OracleStorageKey: "0x",
    contracts: {},
    publicClient: createPublicClient({
      chain: sepolia,
      transport: http(process.env.SEPOLIA_RPC),
    }),
    targetProver: Provers.None,
    exposesL1State: false,
    sharesStateWithL1: false,
    etherscanApiKey: process.env.ETHERSCAN_API_KEY,
    etherscanApiUrl: "",
  },
  // Mock Base
  111111: {
    chainId: 111111,
    outboxContracts: {
      Arbitrum: "0x9fE46736679d2D9a65F0992F2272dE9f3c7fa6e0",
      OPStack: "0xCf7Ed3AccA5a467e9e704C703E8D87F634fB0Fc9",
    },
    rpcUrl: "http://localhost:8546",
    l2Oracle: "0x5FbDB2315678afecb367f032d93F642f64180aa3",
    l2OracleStorageKey:
      "0xa6eef7e35abe7026729641147f7915573c7e97b47efa546f5f6e3230263bcb49",
    contracts: {
      inbox: "0xe7f1725E7734CE288F8367e1Bb143E90bb3F0512",
    },
    publicClient: createPublicClient({
      chain: chainA,
      transport: http(),
    }),
    targetProver: Provers.OPStack,
    exposesL1State: true,
    sharesStateWithL1: true,
    etherscanApiKey: "",
    etherscanApiUrl: "",
  },
  // Mock Optimism
  111112: {
    chainId: 111112,
    outboxContracts: {
      Arbitrum: "0x9fE46736679d2D9a65F0992F2272dE9f3c7fa6e0",
      OPStack: "0xCf7Ed3AccA5a467e9e704C703E8D87F634fB0Fc9",
    },
    rpcUrl: "http://localhost:8547",
    l2Oracle: "0xe7f1725E7734CE288F8367e1Bb143E90bb3F0512",
    l2OracleStorageKey:
      "0xa6eef7e35abe7026729641147f7915573c7e97b47efa546f5f6e3230263bcb49",
    contracts: {
      inbox: "0xe7f1725E7734CE288F8367e1Bb143E90bb3F0512",
      l2MessagePasser: "0x4200000000000000000000000000000000000016",
    },
    publicClient: createPublicClient({
      chain: chainB,
      transport: http(),
    }),
    targetProver: Provers.OPStack,
    exposesL1State: true,
    sharesStateWithL1: true,
    etherscanApiKey: "",
    etherscanApiUrl: "",
  },
  // Mock L1
  31337: {
    chainId: 31337,
    outboxContracts: {},
    rpcUrl: "http://localhost:8545",
    l2Oracle: "0x",
    l2OracleStorageKey: "0x",
    contracts: {},
    publicClient: createPublicClient({
      chain: mockL1,
      transport: http(),
    }),
    targetProver: Provers.None,
    exposesL1State: false,
    sharesStateWithL1: false,
    etherscanApiKey: "",
    etherscanApiUrl: "",
  },
} as Record<number, ChainConfig>;

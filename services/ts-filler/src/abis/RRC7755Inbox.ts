export default [
  {
    type: "constructor",
    inputs: [
      {
        name: "paymaster",
        type: "address",
        internalType: "address",
      },
    ],
    stateMutability: "nonpayable",
  },
  {
    type: "function",
    name: "PAYMASTER",
    inputs: [],
    outputs: [
      {
        name: "",
        type: "address",
        internalType: "contract Paymaster",
      },
    ],
    stateMutability: "view",
  },
  {
    type: "function",
    name: "fulfill",
    inputs: [
      {
        name: "sourceChain",
        type: "bytes32",
        internalType: "bytes32",
      },
      {
        name: "sender",
        type: "bytes32",
        internalType: "bytes32",
      },
      {
        name: "payload",
        type: "bytes",
        internalType: "bytes",
      },
      {
        name: "attributes",
        type: "bytes[]",
        internalType: "bytes[]",
      },
      {
        name: "fulfiller",
        type: "address",
        internalType: "address",
      },
    ],
    outputs: [],
    stateMutability: "payable",
  },
  {
    type: "function",
    name: "getFulfillmentInfo",
    inputs: [
      {
        name: "requestHash",
        type: "bytes32",
        internalType: "bytes32",
      },
    ],
    outputs: [
      {
        name: "",
        type: "tuple",
        internalType: "struct RRC7755Inbox.FulfillmentInfo",
        components: [
          {
            name: "timestamp",
            type: "uint96",
            internalType: "uint96",
          },
          {
            name: "fulfiller",
            type: "address",
            internalType: "address",
          },
        ],
      },
    ],
    stateMutability: "view",
  },
  {
    type: "function",
    name: "getRequestId",
    inputs: [
      {
        name: "sourceChain",
        type: "bytes32",
        internalType: "bytes32",
      },
      {
        name: "sender",
        type: "bytes32",
        internalType: "bytes32",
      },
      {
        name: "destinationChain",
        type: "bytes32",
        internalType: "bytes32",
      },
      {
        name: "receiver",
        type: "bytes32",
        internalType: "bytes32",
      },
      {
        name: "payload",
        type: "bytes",
        internalType: "bytes",
      },
      {
        name: "attributes",
        type: "bytes[]",
        internalType: "bytes[]",
      },
    ],
    outputs: [
      {
        name: "",
        type: "bytes32",
        internalType: "bytes32",
      },
    ],
    stateMutability: "view",
  },
  {
    type: "function",
    name: "storeReceipt",
    inputs: [
      {
        name: "messageId",
        type: "bytes32",
        internalType: "bytes32",
      },
      {
        name: "fulfiller",
        type: "address",
        internalType: "address",
      },
    ],
    outputs: [],
    stateMutability: "nonpayable",
  },
  {
    type: "event",
    name: "CallFulfilled",
    inputs: [
      {
        name: "requestHash",
        type: "bytes32",
        indexed: true,
        internalType: "bytes32",
      },
      {
        name: "fulfilledBy",
        type: "address",
        indexed: true,
        internalType: "address",
      },
    ],
    anonymous: false,
  },
  {
    type: "error",
    name: "AttributeNotFound",
    inputs: [
      {
        name: "selector",
        type: "bytes4",
        internalType: "bytes4",
      },
    ],
  },
  {
    type: "error",
    name: "CallAlreadyFulfilled",
    inputs: [],
  },
  {
    type: "error",
    name: "CannotCallPaymaster",
    inputs: [],
  },
  {
    type: "error",
    name: "InvalidCaller",
    inputs: [],
  },
  {
    type: "error",
    name: "InvalidValue",
    inputs: [
      {
        name: "expected",
        type: "uint256",
        internalType: "uint256",
      },
      {
        name: "actual",
        type: "uint256",
        internalType: "uint256",
      },
    ],
  },
  {
    type: "error",
    name: "Reentrancy",
    inputs: [],
  },
  {
    type: "error",
    name: "UserOp",
    inputs: [],
  },
  {
    type: "error",
    name: "ZeroAddress",
    inputs: [],
  },
] as const;

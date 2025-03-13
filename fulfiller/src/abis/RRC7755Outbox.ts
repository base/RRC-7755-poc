export default [
  {
    type: "function",
    name: "CANCEL_DELAY_SECONDS",
    inputs: [],
    outputs: [
      {
        name: "",
        type: "uint256",
        internalType: "uint256",
      },
    ],
    stateMutability: "view",
  },
  {
    type: "function",
    name: "cancelMessage",
    inputs: [
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
    outputs: [],
    stateMutability: "nonpayable",
  },
  {
    type: "function",
    name: "cancelUserOp",
    inputs: [
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
        name: "userOp",
        type: "tuple",
        internalType: "struct PackedUserOperation",
        components: [
          {
            name: "sender",
            type: "address",
            internalType: "address",
          },
          {
            name: "nonce",
            type: "uint256",
            internalType: "uint256",
          },
          {
            name: "initCode",
            type: "bytes",
            internalType: "bytes",
          },
          {
            name: "callData",
            type: "bytes",
            internalType: "bytes",
          },
          {
            name: "accountGasLimits",
            type: "bytes32",
            internalType: "bytes32",
          },
          {
            name: "preVerificationGas",
            type: "uint256",
            internalType: "uint256",
          },
          {
            name: "gasFees",
            type: "bytes32",
            internalType: "bytes32",
          },
          {
            name: "paymasterAndData",
            type: "bytes",
            internalType: "bytes",
          },
          {
            name: "signature",
            type: "bytes",
            internalType: "bytes",
          },
        ],
      },
    ],
    outputs: [],
    stateMutability: "nonpayable",
  },
  {
    type: "function",
    name: "claimReward",
    inputs: [
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
      {
        name: "proof",
        type: "bytes",
        internalType: "bytes",
      },
      {
        name: "payTo",
        type: "address",
        internalType: "address",
      },
    ],
    outputs: [],
    stateMutability: "nonpayable",
  },
  {
    type: "function",
    name: "claimReward",
    inputs: [
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
        name: "userOp",
        type: "tuple",
        internalType: "struct PackedUserOperation",
        components: [
          {
            name: "sender",
            type: "address",
            internalType: "address",
          },
          {
            name: "nonce",
            type: "uint256",
            internalType: "uint256",
          },
          {
            name: "initCode",
            type: "bytes",
            internalType: "bytes",
          },
          {
            name: "callData",
            type: "bytes",
            internalType: "bytes",
          },
          {
            name: "accountGasLimits",
            type: "bytes32",
            internalType: "bytes32",
          },
          {
            name: "preVerificationGas",
            type: "uint256",
            internalType: "uint256",
          },
          {
            name: "gasFees",
            type: "bytes32",
            internalType: "bytes32",
          },
          {
            name: "paymasterAndData",
            type: "bytes",
            internalType: "bytes",
          },
          {
            name: "signature",
            type: "bytes",
            internalType: "bytes",
          },
        ],
      },
      {
        name: "proof",
        type: "bytes",
        internalType: "bytes",
      },
      {
        name: "payTo",
        type: "address",
        internalType: "address",
      },
    ],
    outputs: [],
    stateMutability: "nonpayable",
  },
  {
    type: "function",
    name: "getMessageId",
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
    name: "getMessageStatus",
    inputs: [
      {
        name: "messageId",
        type: "bytes32",
        internalType: "bytes32",
      },
    ],
    outputs: [
      {
        name: "",
        type: "uint8",
        internalType: "enum RRC7755Outbox.CrossChainCallStatus",
      },
    ],
    stateMutability: "view",
  },
  {
    type: "function",
    name: "getNonce",
    inputs: [
      {
        name: "account",
        type: "address",
        internalType: "address",
      },
    ],
    outputs: [
      {
        name: "",
        type: "uint256",
        internalType: "uint256",
      },
    ],
    stateMutability: "view",
  },
  {
    type: "function",
    name: "getOptionalAttributes",
    inputs: [],
    outputs: [
      {
        name: "",
        type: "bytes4[]",
        internalType: "bytes4[]",
      },
    ],
    stateMutability: "pure",
  },
  {
    type: "function",
    name: "getRequesterAndExpiryAndReward",
    inputs: [
      {
        name: "messageId",
        type: "bytes32",
        internalType: "bytes32",
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
      {
        name: "",
        type: "uint256",
        internalType: "uint256",
      },
      {
        name: "",
        type: "bytes32",
        internalType: "bytes32",
      },
      {
        name: "",
        type: "uint256",
        internalType: "uint256",
      },
    ],
    stateMutability: "view",
  },
  {
    type: "function",
    name: "getRequiredAttributes",
    inputs: [
      {
        name: "isUserOp",
        type: "bool",
        internalType: "bool",
      },
    ],
    outputs: [
      {
        name: "",
        type: "bytes4[]",
        internalType: "bytes4[]",
      },
    ],
    stateMutability: "pure",
  },
  {
    type: "function",
    name: "getUserOpAttributes",
    inputs: [
      {
        name: "userOp",
        type: "tuple",
        internalType: "struct PackedUserOperation",
        components: [
          {
            name: "sender",
            type: "address",
            internalType: "address",
          },
          {
            name: "nonce",
            type: "uint256",
            internalType: "uint256",
          },
          {
            name: "initCode",
            type: "bytes",
            internalType: "bytes",
          },
          {
            name: "callData",
            type: "bytes",
            internalType: "bytes",
          },
          {
            name: "accountGasLimits",
            type: "bytes32",
            internalType: "bytes32",
          },
          {
            name: "preVerificationGas",
            type: "uint256",
            internalType: "uint256",
          },
          {
            name: "gasFees",
            type: "bytes32",
            internalType: "bytes32",
          },
          {
            name: "paymasterAndData",
            type: "bytes",
            internalType: "bytes",
          },
          {
            name: "signature",
            type: "bytes",
            internalType: "bytes",
          },
        ],
      },
    ],
    outputs: [
      {
        name: "",
        type: "bytes[]",
        internalType: "bytes[]",
      },
    ],
    stateMutability: "pure",
  },
  {
    type: "function",
    name: "getUserOpHash",
    inputs: [
      {
        name: "userOp",
        type: "tuple",
        internalType: "struct PackedUserOperation",
        components: [
          {
            name: "sender",
            type: "address",
            internalType: "address",
          },
          {
            name: "nonce",
            type: "uint256",
            internalType: "uint256",
          },
          {
            name: "initCode",
            type: "bytes",
            internalType: "bytes",
          },
          {
            name: "callData",
            type: "bytes",
            internalType: "bytes",
          },
          {
            name: "accountGasLimits",
            type: "bytes32",
            internalType: "bytes32",
          },
          {
            name: "preVerificationGas",
            type: "uint256",
            internalType: "uint256",
          },
          {
            name: "gasFees",
            type: "bytes32",
            internalType: "bytes32",
          },
          {
            name: "paymasterAndData",
            type: "bytes",
            internalType: "bytes",
          },
          {
            name: "signature",
            type: "bytes",
            internalType: "bytes",
          },
        ],
      },
      {
        name: "receiver",
        type: "bytes32",
        internalType: "bytes32",
      },
      {
        name: "destinationChain",
        type: "bytes32",
        internalType: "bytes32",
      },
    ],
    outputs: [
      {
        name: "",
        type: "bytes32",
        internalType: "bytes32",
      },
    ],
    stateMutability: "pure",
  },
  {
    type: "function",
    name: "innerValidateProofAndGetReward",
    inputs: [
      {
        name: "messageId",
        type: "bytes32",
        internalType: "bytes32",
      },
      {
        name: "inboxContractStorageKey",
        type: "bytes",
        internalType: "bytes",
      },
      {
        name: "attributes",
        type: "bytes[]",
        internalType: "bytes[]",
      },
      {
        name: "proofData",
        type: "bytes",
        internalType: "bytes",
      },
      {
        name: "caller",
        type: "address",
        internalType: "address",
      },
    ],
    outputs: [
      {
        name: "",
        type: "bytes32",
        internalType: "bytes32",
      },
      {
        name: "",
        type: "uint256",
        internalType: "uint256",
      },
    ],
    stateMutability: "view",
  },
  {
    type: "function",
    name: "processAttributes",
    inputs: [
      {
        name: "messageId",
        type: "bytes32",
        internalType: "bytes32",
      },
      {
        name: "attributes",
        type: "bytes[]",
        internalType: "bytes[]",
      },
      {
        name: "requester",
        type: "address",
        internalType: "address",
      },
      {
        name: "value",
        type: "uint256",
        internalType: "uint256",
      },
      {
        name: "requireInbox",
        type: "bool",
        internalType: "bool",
      },
    ],
    outputs: [],
    stateMutability: "nonpayable",
  },
  {
    type: "function",
    name: "sendMessage",
    inputs: [
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
    stateMutability: "payable",
  },
  {
    type: "function",
    name: "supportsAttribute",
    inputs: [
      {
        name: "selector",
        type: "bytes4",
        internalType: "bytes4",
      },
    ],
    outputs: [
      {
        name: "",
        type: "bool",
        internalType: "bool",
      },
    ],
    stateMutability: "pure",
  },
  {
    type: "event",
    name: "CrossChainCallCanceled",
    inputs: [
      {
        name: "messageId",
        type: "bytes32",
        indexed: true,
        internalType: "bytes32",
      },
    ],
    anonymous: false,
  },
  {
    type: "event",
    name: "CrossChainCallCompleted",
    inputs: [
      {
        name: "messageId",
        type: "bytes32",
        indexed: true,
        internalType: "bytes32",
      },
      {
        name: "submitter",
        type: "address",
        indexed: false,
        internalType: "address",
      },
    ],
    anonymous: false,
  },
  {
    type: "event",
    name: "MessagePosted",
    inputs: [
      {
        name: "messageId",
        type: "bytes32",
        indexed: true,
        internalType: "bytes32",
      },
      {
        name: "sourceChain",
        type: "bytes32",
        indexed: false,
        internalType: "bytes32",
      },
      {
        name: "sender",
        type: "bytes32",
        indexed: false,
        internalType: "bytes32",
      },
      {
        name: "destinationChain",
        type: "bytes32",
        indexed: false,
        internalType: "bytes32",
      },
      {
        name: "receiver",
        type: "bytes32",
        indexed: false,
        internalType: "bytes32",
      },
      {
        name: "payload",
        type: "bytes",
        indexed: false,
        internalType: "bytes",
      },
      {
        name: "attributes",
        type: "bytes[]",
        indexed: false,
        internalType: "bytes[]",
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
    name: "CannotCancelRequestBeforeExpiry",
    inputs: [
      {
        name: "currentTimestamp",
        type: "uint256",
        internalType: "uint256",
      },
      {
        name: "expiry",
        type: "uint256",
        internalType: "uint256",
      },
    ],
  },
  {
    type: "error",
    name: "DuplicateAttribute",
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
    name: "ExpiryTooSoon",
    inputs: [],
  },
  {
    type: "error",
    name: "InvalidCaller",
    inputs: [
      {
        name: "caller",
        type: "address",
        internalType: "address",
      },
      {
        name: "expectedCaller",
        type: "address",
        internalType: "address",
      },
    ],
  },
  {
    type: "error",
    name: "InvalidNonce",
    inputs: [],
  },
  {
    type: "error",
    name: "InvalidReceiver",
    inputs: [],
  },
  {
    type: "error",
    name: "InvalidRequester",
    inputs: [],
  },
  {
    type: "error",
    name: "InvalidStatus",
    inputs: [
      {
        name: "expected",
        type: "uint8",
        internalType: "enum RRC7755Outbox.CrossChainCallStatus",
      },
      {
        name: "actual",
        type: "uint8",
        internalType: "enum RRC7755Outbox.CrossChainCallStatus",
      },
    ],
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
        name: "received",
        type: "uint256",
        internalType: "uint256",
      },
    ],
  },
  {
    type: "error",
    name: "MissingRequiredAttribute",
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
    name: "UnsupportedAttribute",
    inputs: [
      {
        name: "selector",
        type: "bytes4",
        internalType: "bytes4",
      },
    ],
  },
] as const;

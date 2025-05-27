package listener

const (
	// Buffer sizes
	crossChainCallRequestedBufferSize = 10

	// Attribute selectors
	nonceAttributeSelector     uint32 = 0xce03fdab
	rewardAttributeSelector    uint32 = 0xa362e5db
	delayAttributeSelector     uint32 = 0x84f550e0
	requesterAttributeSelector uint32 = 0x3bd94e4c
	l2OracleAttributeSelector  uint32 = 0x7ff7245a

	// Attribute sizes
	attributeBaseSize     = 36 // 4 + 32 (selector + data)
	attributeExtendedSize = 68 // 4 + 32 + 32 (selector + two data fields)

	// Field sizes
	bytes32Size   = 32
	uint64Size    = 8
	addressSize   = 20
	addressOffset = bytes32Size - addressSize // 12
	uint64Offset  = bytes32Size - uint64Size  // 24
	selectorSize  = 4

	// Base number system
	decimalBase = 10

	// Chain IDs
	baseSepolia     = 84532
	arbitrumSepolia = 421614

	// Test values
	testValue = 200000000000000
)

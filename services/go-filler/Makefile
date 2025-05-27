ORG := base-org
PROJECT := RRC-7755-poc
VERSION := $(shell git describe --tags)
BUILD := $(shell git rev-parse --short HEAD)

#
# Tool Prerequisites Check
# This ensures that you have the necessary executables installed to run this makefile.
#
GEN_PREREQUISITES = mockgen
BUILD_PREREQUISITES = git go
VALIDATION_PREREQUISITES = golangci-lint 

#
# Build Options
# Typical inputs to the build targets found below.
#
TARGET=target
BIN=$(TARGET)/bin
LDFLAGS=-ldflags "-X=main.Version=$(VERSION) -X=main.Build=$(BUILD)"


#
# Informational Targets
# These rarely change, and only serve to print out helpful details about this makefile.
#
.PHONY: usage
usage:
	@ echo "Usage: make [`cat Makefile | grep "^[A-z\%\-]*:" | awk '{print $$1}' | sed "s/://g" | sed "s/%/[1-3]/g" | xargs`]"

.PHONY: info
info:
	@ echo ORG: $(ORG)
	@ echo PROJECT: $(PROJECT)
	@ echo VERSION: $(VERSION)
	@ echo BUILD: $(BUILD)

#
# Build Targets
# These are the primary developer workflow targets for building the software.
#
.PHONY: clean
clean: info
	@ rm -rf target
	@ go mod tidy

.PHONY: build_deps
build_deps: info clean
	@ printf $(foreach exec,$(BUILD_PREREQUISITES), \
        $(if $(shell which $(exec)),"", \
        $(error "No $(exec) in PATH. Prerequisites are: $(BUILD_PREREQUISITES)")))


.PHONY: gen
gen: info clean
	@ echo "Generating mocks..."
	@ mockgen -destination=internal/client/mocks/eth_client_mock.go -mock_names EthClient=MockEthClient -package=mocks github.com/base-org/RRC-7755-poc/internal/client EthClient
	@ mockgen -destination=internal/prover/mocks/eth_rpc_client_mock.go -mock_names EthRPCClient=MockEthRPCClient -package=mocks github.com/base-org/RRC-7755-poc/internal/prover/storage_prover EthRPCClient
	@ mockgen -destination=internal/prover/mocks/l1_client_mock.go -mock_names L1Client=MockL1Client -package=mocks github.com/base-org/RRC-7755-poc/internal/prover/l1_state_prover L1Client

.PHONY: install_tools
install_tools:
	@echo "--- Installing tools..."
	@go install github.com/golang/mock/mockgen@latest


.PHONY: build
build: info build_deps
	@ printf "\nBuild app\n"
	@ go build $(LDFLAGS) -o $(BIN)/$(PROJECT) cmd/main.go
	@ cp -R cmd/config $(BIN)/

run: build
	@ printf "\nrunning main directory with go run..."
	@ cd cmd && go run main.go

.PHONY: build-contracts
build-contracts:
	@ echo "Building contracts..."
	@ cd RRC-7755-poc/contracts \
		&& forge install \
		&& forge build

.PHONY: generate-bindings
generate-bindings:
	@ echo "Generating bindings..."
	@ go install github.com/ethereum/go-ethereum/cmd/abigen@v1.14.11
	@ abigen --abi contracts/out/RRC7755Outbox.sol/RRC7755Outbox.abi.json --pkg rrc_7755_outbox --type RRC7755Outbox --out bindings/rrc_7755_outbox/rrc_7755_outbox.go
	@ abigen --abi contracts/out/RRC7755Inbox.sol/RRC7755Inbox.abi.json --pkg rrc_7755_inbox --type RRC7755Inbox --out bindings/rrc_7755_inbox/rrc_7755_inbox.go
	@ abigen --abi contracts/out/Entrypoint.sol/Entrypoint.abi.json --pkg entrypoint --type Entrypoint --out bindings/entrypoint/entrypoint.go
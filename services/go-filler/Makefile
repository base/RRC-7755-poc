-include .env
export

.PHONY: bindings

test-log-fetcher:
	go test ./log-fetcher/internal/...

run-log-fetcher:
	go run ./log-fetcher/cmd

bindings:
	go install github.com/ethereum/go-ethereum/cmd/abigen@v1.14.11
	cd ../../contracts && forge build
	abigen --abi ../../contracts/out/RRC7755Outbox.sol/RRC7755Outbox.abi.json --pkg bindings --type RRC7755Outbox --out bindings/rip_7755_outbox.go

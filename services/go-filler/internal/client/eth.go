package client

import (
	"context"
	"crypto/tls"
	"fmt"

	"github.com/ethereum/go-ethereum/ethclient"
	"github.com/ethereum/go-ethereum/rpc"
	"github.com/gorilla/websocket"

	"github.com/base-org/RRC-7755-poc/internal/config"
)

func NewEthClient(ctx context.Context, chainConfig config.ChainConfig) (*ethclient.Client, error) {
	dialer := *websocket.DefaultDialer
	dialer.TLSClientConfig = &tls.Config{InsecureSkipVerify: chainConfig.NodeInsecureSkipVerify}

	rpcClient, err := rpc.DialOptions(ctx, chainConfig.NodeURL, rpc.WithWebsocketDialer(dialer))
	if err != nil {
		return nil, fmt.Errorf("eth client dial: %w", err)
	}

	return ethclient.NewClient(rpcClient), nil
}

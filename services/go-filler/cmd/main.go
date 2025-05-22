package main

import (
	"context"
	"fmt"
	"log"
	"os"
	"os/signal"
	"syscall"

	"github.com/base-org/RRC-7755-poc/internal/client"
	"github.com/base-org/RRC-7755-poc/internal/config"
	"github.com/base-org/RRC-7755-poc/internal/inbox"
	"github.com/base-org/RRC-7755-poc/internal/listener"
	"github.com/joho/godotenv"
	"go.uber.org/zap"
)

func main() {
	// Load .env file from project root
	if err := godotenv.Load("../../.env"); err != nil {
		log.Printf("Warning: .env file not found: %v", err)
	}

	log, err := zap.NewProduction()
	if err != nil {
		log.Fatal("failed to create logger", zap.Error(err))
	}

	log.Info("Starting up")
	ctx, cancel := context.WithCancel(context.Background())

	cfg, err := config.Unmarshal(log)
	if err != nil {
		log.Fatal("creating config", zap.Error(err))
	}

	clientMgr, err := client.NewManager(ctx, cfg)
	if err != nil {
		log.Fatal("initializing client manager", zap.Error(err))
	}

	sigChan := make(chan os.Signal, 1)
	signal.Notify(sigChan, syscall.SIGINT, syscall.SIGTERM)
	go func() {
		<-sigChan
		fmt.Println("Received shutdown signal. Shutting down gracefully...")
		cancel()
	}()

	outboxListener, err := listener.NewOutboxListener(ctx, clientMgr, cfg, log)
	if err != nil {
		log.Fatal("initializing outbox listener", zap.Error(err))
	}
	go func(){
		err = outboxListener.Run(ctx)
		if err != nil {
			log.Fatal("starting listener", zap.Error(err))
		}
		log.Info("outbox listener created successfully")
	
	}()
	// Uncomment to send a test transaction
	// "github.com/base-org/RRC-7755-poc/internal/inbox"
	txManager := inbox.NewTransactionSenderManager(clientMgr, cfg, log)

	err = txManager.SendTestTransaction(ctx)
	if err != nil {
		log.Fatal("failed to send test transaction", zap.Error(err))
	}
	log.Info("transaction sender manager initialized successfully")
	wait := make(chan struct{})
	<- wait
}

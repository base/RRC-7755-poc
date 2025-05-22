package config

import (
	"reflect"

	"github.com/ethereum/go-ethereum/common"
	"github.com/mitchellh/mapstructure"
	"github.com/spf13/viper"
	"go.uber.org/zap"
)

func stringToAddressHookFunc() mapstructure.DecodeHookFuncType {
	return func(
		f reflect.Type,
		t reflect.Type,
		data interface{},
	) (interface{}, error) {
		if f.Kind() != reflect.String {
			return data, nil
		}
		if t != reflect.TypeOf(common.Address{}) {
			return data, nil
		}

		// Convert it by parsing
		return common.HexToAddress(data.(string)), nil
	}
}

type (
	Config struct {
		Endpoint       string            `mapstructure:"endpoint"`
		Timeout        string            `mapstructure:"timeout"`
		Database       database          `mapstructure:"database"`
		TestBool       bool              `mapstructure:"test-bool"`
		TestStringList []string          `mapstructure:"test-string-list"`
		TestStringMap  map[string]string `mapstructure:"test-string-map"`
		TestEnv        string            `mapstructure:"test-env"`
		TestFile       string            `mapstructure:"test-file"`

		Chain   map[string]ChainConfig `mapstructure:"chain"`
		Wallets WalletConfig           `mapstructure:"wallets"`
	}

	database struct {
		URL      string `mapstructure:"url"`
		Password string `mapstructure:"password"`
	}

	WalletConfig struct {
		FromAddress      string `mapstructure:"from-address"`
		PrivateKey       string `mapstructure:"private-key"`
		RecipientAddress string `mapstructure:"recipient-address"`
	}
)

func (c *WalletConfig) GetFromAddress() common.Address {
	return common.HexToAddress(c.FromAddress)
}

func (c *WalletConfig) GetRecipientAddress() common.Address {
	return common.HexToAddress(c.RecipientAddress)
}

func Unmarshal(log *zap.Logger) (*Config, error) {
	v := viper.New()
	v.AutomaticEnv()
	v.AddConfigPath("./config")
	v.SetConfigName("local")
	v.SetConfigType("yaml")

	err := v.ReadInConfig()
	if err != nil {
		return nil, err
	}

	var config Config
	err = v.Unmarshal(&config, viper.DecodeHook(stringToAddressHookFunc()))
	if err != nil {
		return nil, err
	}

	log.Info("Using config file", zap.Any("config", config))
	return &config, nil
}

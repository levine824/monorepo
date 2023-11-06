package main

import (
	"flag"
	"fmt"
	"net"
	"strings"

	"github.com/levine824/monorepo/app/backend/internal/service"
	v1 "github.com/levine824/monorepo/gen/go/backend/v1"
	"github.com/spf13/viper"
	"google.golang.org/grpc"
	"google.golang.org/grpc/grpclog"
)

var (
	// Version is the version of the compiled software.
	// go build -ldflags "-X main.Version=x.y.z"
	Version string
	// flagCfg is the config file.
	flagCfg string
)

func init() {
	flag.StringVar(&flagCfg, "c", "", "config path, eg: -c config.yaml")
}

func ReadInConfig(cfg string) {
	if cfg != "" {
		viper.SetConfigFile(cfg)
	} else {
		viper.AddConfigPath(".")
		viper.AddConfigPath("$HOME/.config")
		viper.SetConfigName("config")
		viper.SetConfigType("yaml")
	}

	//viper.SetEnvPrefix("MYAPP")
	viper.SetEnvKeyReplacer(strings.NewReplacer(".", "_"))
	viper.AutomaticEnv()

	if err := viper.ReadInConfig(); err != nil {
		panic(fmt.Sprintf("Read config failed.\n[Error] %s\n", err))
	}
}

func main() {
	// Read config.
	flag.Parse()
	ReadInConfig(flagCfg)

	name := viper.GetString("server.name")
	host := viper.GetString("server.host")
	port := viper.GetString("server.port")
	grpcAddr := host + ":" + port

	listen, err := net.Listen("tcp", grpcAddr)
	if err != nil {
		grpclog.Fatalf("Failed to listen: %v", err)
	}

	s := grpc.NewServer()

	v1.RegisterMessageServiceServer(s, &service.MessageService{})

	grpclog.Infof("GRPC listen on %s", port)
	grpclog.Infof("The version of %s is %s", name, Version)

	grpclog.Fatal(s.Serve(listen))
}

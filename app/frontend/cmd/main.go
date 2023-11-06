package main

import (
	"flag"
	"fmt"
	"strings"

	"github.com/labstack/echo"
	"github.com/levine824/monorepo/app/frontend/internal/client"
	"github.com/levine824/monorepo/app/frontend/internal/handler"
	"github.com/spf13/viper"
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
	flag.Parse()

	// Read config.
	ReadInConfig(flagCfg)

	// Init grpc client connection pool.
	client.InitBackendConnPool()

	e := echo.New()
	// Add the route.
	name := viper.GetString("server.name")
	e.GET("/sayHello/:name", handler.SayHelloHandler)

	host := viper.GetString("server.host")
	port := viper.GetString("server.port")

	//e.Use(middleware.Logger())
	e.Logger.Printf("The version of %s is %s.", name, Version)
	e.Logger.Fatal(e.Start(host + ":" + port))
}

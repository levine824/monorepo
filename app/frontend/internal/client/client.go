package client

import (
	"context"
	"fmt"
	"time"

	v1 "github.com/levine824/monorepo/gen/go/backend/v1"
	"github.com/levine824/monorepo/pkg/grpcpool"
	"github.com/spf13/viper"
	"google.golang.org/grpc"
	"google.golang.org/grpc/credentials/insecure"
)

var backendConnPool *grpcpool.Pool

func InitBackendConnPool() {
	pool, err := grpcpool.New(func() (*grpc.ClientConn, error) {
		target := viper.GetString("client.backend.host") + ":" + viper.GetString("client.backend.port")
		opt := grpc.WithTransportCredentials(insecure.NewCredentials())
		conn, err := grpc.Dial(target, opt)
		if err != nil {
			return nil, err
		}
		return conn, nil
	}, 1, 5, time.Second*180)
	if err != nil {
		panic(fmt.Sprintf("Init pool failed: %v", err))
	}
	backendConnPool = pool
}

func GetMessageServiceClient(ctx context.Context) (v1.MessageServiceClient, *grpcpool.ClientConn, error) {
	conn, err := backendConnPool.Get(ctx)
	if err != nil {
		return nil, nil, err
	}
	return v1.NewMessageServiceClient(conn), conn, nil
}

func PutBackendConn(conn *grpcpool.ClientConn) error {
	return conn.Close()
}

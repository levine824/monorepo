package handler

import (
	"context"
	"fmt"
	"log"
	"net/http"

	"github.com/labstack/echo"
	"github.com/levine824/monorepo/app/frontend/internal/client"
	v1 "github.com/levine824/monorepo/gen/go/backend/v1"
	"github.com/levine824/monorepo/pkg/grpcpool"
)

func SayHelloHandler(c echo.Context) error {
	ctx := context.Background()
	rc, conn, err := client.GetMessageServiceClient(ctx)
	if err != nil {
		return err
	}
	defer func(conn *grpcpool.ClientConn) {
		err := client.PutBackendConn(conn)
		if err != nil {
			log.Printf("Close the connection failed: %v", err)
		}
	}(conn)
	req := &v1.GetMessageRequest{Name: c.Param("name")}
	res, err := rc.GetMessage(ctx, req)
	if err != nil {
		return err
	}
	return c.HTML(http.StatusOK, generateHtml(res.GetMsg()))
}

func generateHtml(msg string) string {
	return fmt.Sprintf("<strong>%s</strong>", msg)
}

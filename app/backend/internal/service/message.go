package service

import (
	"context"
	"fmt"

	v1 "github.com/levine824/monorepo/gen/go/backend/v1"
)

type MessageService struct {
	v1.UnimplementedMessageServiceServer
}

func (m *MessageService) GetMessage(ctx context.Context, req *v1.GetMessageRequest) (*v1.GetMessageResponse, error) {
	return &v1.GetMessageResponse{Msg: generateMessage(req.Name)}, nil
}

func generateMessage(name string) string {
	if name == "jack" {
		return fmt.Sprintf("Hello %s, welcome!", name)
	} else if name == "tom" {
		return fmt.Sprintf("Hi %s, welcome!", name)
	} else {
		return "Who are you?"
	}
}

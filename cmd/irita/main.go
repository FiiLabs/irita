package main

import (
	"fmt"
	"os"

	"github.com/cosmos/cosmos-sdk/server"
	svrcmd "github.com/cosmos/cosmos-sdk/server/cmd"

	"github.com/bianjieai/irita/app"
	"github.com/bianjieai/irita/cmd/irita/cmd"

	"net/http"
	_ "net/http/pprof"
)

func main() {

	go func() {
		fmt.Println(http.ListenAndServe("localhost:6060", nil))
	}()

	rootCmd, _ := cmd.NewRootCmd()
	if err := svrcmd.Execute(rootCmd, app.DefaultNodeHome); err != nil {
		switch e := err.(type) {
		case server.ErrorCode:
			os.Exit(e.Code)

		default:
			os.Exit(1)
		}
	}
}

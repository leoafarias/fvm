package main

import (
	"log"

	"github.com/leoafarias/fvm/cmd"
)

func init() {
	log.SetPrefix("LOG: ")
	// log.SetFlags(log.Ldate | log.Lmicroseconds | log.Llongfile)
	log.Println("Init started")
}

func main() {
	cmd.Execute()

}

package main

import (
	"path"

	"github.com/leoafarias/fvm/cmd"
	homedir "github.com/mitchellh/go-homedir"
)

var (
	homePath    string
	flutterPath string
	// WorkspacePath - Sets the workspace of the tool
	WorkspacePath string
)

func main() {
	homePath, _ = homedir.Dir()
	flutterPath = path.Join(homePath, "flutter")

	cmd.Execute()
}

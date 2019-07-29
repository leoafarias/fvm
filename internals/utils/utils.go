package utils

import (
	"fmt"
	"os"
	"path"
	"strings"

	homedir "github.com/mitchellh/go-homedir"
)

// GetWorkspaceHome - Path for the current fvm workspace
func GetWorkspaceHome() string {
	homeDir, _ := homedir.Dir()
	workspaceHome := path.Join(homeDir, "fvm")
	os.MkdirAll(workspaceHome, os.ModePerm)
	return workspaceHome
}

// GetFlutterHome - Returns the home path to the flutter directory
func GetFlutterHome() string {

	var flutterHome string

	// Get all env variables
	envVar := os.Getenv("PATH")

	v := strings.Split(envVar, ":")

	// Range to find flutter and trim bin path
	for _, v := range v {
		if strings.Contains(v, "flutter") {
			flutterHome = strings.TrimSuffix(v, "/bin")
		}
	}

	// If flutter path has not been set
	if len(flutterHome) == 0 {

		// Set default flutter home
		flutterHome = path.Join(GetWorkspaceHome(), "flutter")

		// Set path to flutter bin
		flutterActiveBin := path.Join(flutterHome, "bin", "flutter")

		// usr/local/bin path to flutter
		flutterUsrLocalBin := path.Join("/", "usr", "local", "bin", "flutter")

		// Always clean up symlink before
		os.RemoveAll(flutterUsrLocalBin)

		// Creates a symlink from the usr/local/bin to the flutter exec in the flutterHome
		if err := os.Symlink(flutterActiveBin, flutterUsrLocalBin); err != nil {
			// TODO: Make errors a bit better
			// fmt.Println(err)
			fmt.Println("Please set your flutter path before using the tool")
			os.Exit(0)
		}

	}
	// Make sure directories exist and are created
	os.MkdirAll(flutterHome, os.ModePerm)

	return flutterHome

}

// Move - Moves a file from src to dest
func Move(src, dest string) error {
	// Copy the current versionPath into flutterHome
	err := Copy(src, dest)
	if err != nil {
		fmt.Println(err)
	} else {
		// If file is copied go ahead and remove it.
		err = os.RemoveAll(path.Join(src))
	}

	return err
}

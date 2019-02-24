package lib

import (
	"fmt"
	"io/ioutil"
	"log"
	"os"
	"os/exec"
)

// GetFlutterChannel - Clones git from Flutter repo
func GetFlutterChannel(branch string) {
	versionDir := versionsPath + "/" + branch

	// clean directory just in case before cloning
	if err := os.RemoveAll(versionDir); err != nil {
		log.Fatal(err)
	}

	cmd := exec.Command("git", "clone", "-b", branch, "https://github.com/flutter/flutter.git", versionDir)
	cmd.Stdout = os.Stdout
	cmd.Stderr = os.Stderr
	if err := cmd.Run(); err != nil {
		log.Fatalf("cmd.Run() failed with %s\n", err)
	}
}

// GetFlutterVersion - Gets the version of flutter from the branch directory
func GetFlutterVersion(branch string) (string, error) {
	b, err := ioutil.ReadFile(versionsPath + "/" + branch + "/version")
	if err != nil {
		return "", err
	}

	return string(b), nil
}

// RunFlutterDoctor - runs 'flutter doctor' command
func RunFlutterDoctor() error {
	cmd := exec.Command("flutter", "doctor")
	cmd.Stdout = os.Stdout
	cmd.Stderr = os.Stderr
	err := cmd.Run()

	return err
}

// Exists = checks if directory exists
func Exists(branch string) (bool, error) {
	// check if version directory exists
	if _, err := os.Stat(versionsPath + "/" + branch); err != nil {
		if os.IsNotExist(err) {
			// -> version directory does not exist
			fmt.Println("Branch does not exist")
			return false, err
		}
		// -> error when getting file
		log.Fatalf("cmd.Run() failed with %s\n", err)
	}
	return true, nil
}

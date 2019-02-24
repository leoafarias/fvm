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
func GetFlutterVersion(branch string) string {
	b, err := ioutil.ReadFile(versionsPath + "/" + branch + "/version")
	if err != nil {
		fmt.Print(err)
	}

	return string(b)
}

// RunFlutterDoctor - runs 'flutter doctor' command
func RunFlutterDoctor() {
	cmd := exec.Command("flutter", "doctor")
	cmd.Stdout = os.Stdout
	cmd.Stderr = os.Stderr
	err := cmd.Run()
	if err != nil {
		log.Fatalf("cmd.Run() failed with %s\n", err)
	}
}

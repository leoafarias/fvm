package lib

import (
	"log"
	"os"
	"os/exec"
)

// GetChannel - Clones git from Flutter repo
func GetChannel(branch string) {
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

// RunDoctor - runs 'flutter doctor' command
func RunDoctor() {
	cmd := exec.Command("flutter", "doctor")
	cmd.Stdout = os.Stdout
	cmd.Stderr = os.Stderr
	err := cmd.Run()
	if err != nil {
		log.Fatalf("cmd.Run() failed with %s\n", err)
	}
}

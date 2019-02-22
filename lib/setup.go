package lib

import (
	"log"
	"os"
	"os/exec"
)

// GetChannel - Clones git from Flutter repo
func GetChannel(branch string, tag string) {
	cmd := exec.Command("git", "clone", "-b", branch, "https://github.com/flutter/flutter.git", "./versions/"+branch)
	cmd.Stdout = os.Stdout
	cmd.Stderr = os.Stderr
	err := cmd.Run()
	if err != nil {
		log.Fatalf("cmd.Run() failed with %s\n", err)
	}
}

// RenameDir - renames directory as a way to keep flutter env persistent
func RenameDir(branch string) {
	err := os.RemoveAll("versions/active")
	if err != nil {
		log.Fatal(err)
	}

	error := os.Rename("versions/"+branch, "versions/active")
	if error != nil {
		log.Fatal(error)
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

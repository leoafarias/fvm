package fluttertools

import (
	"bufio"
	"fmt"
	"io/ioutil"
	"log"
	"os"
	"os/exec"
	"path"
	"strings"
	"sync"
	"time"

	"github.com/briandowns/spinner"
)

var wg sync.WaitGroup

const versionsPath = "versions"

// GetChannel - Clones git from Flutter repo
func GetChannel(branch string) error {
	s := spinner.New(spinner.CharSets[11], 100*time.Millisecond)
	s.Suffix = " Cloning " + branch
	s.Start()

	versionDir := path.Join(versionsPath, branch)

	// clean directory just in case before cloning
	if err := os.RemoveAll(versionDir); err != nil {
		log.Fatal(err)
	}

	cmd := exec.Command("git", "clone", "-b", branch, "https://github.com/flutter/flutter.git", versionDir)

	err := cmd.Start()
	if err != nil {
		log.Fatalf("cmd.Start() failed with '%s'\n", err)
	}

	err = cmd.Wait()
	if err != nil {
		log.Fatalf("cmd.Start() failed with '%s'\n", err)
	}

	s.Stop()
	fmt.Println("[✓] " + branch + " successfully cloned.")

	return nil

}

// GetChannelInfo = gets channel that is selected
func GetChannelInfo(channel string) (string, error) {
	// cmd := exec.Command("git", "rev-parse", "--abbrev-ref", "--symbolic", "@{u}")
	// 	_branch = branch == 'HEAD' ? _channel : branch;

	cmd := exec.Command("git", "rev-parse", "--abbrev-ref", "HEAD")
	workspacePath, _ := os.Getwd()
	cmd.Dir = path.Join(workspacePath, versionsPath, channel)
	o, err := cmd.Output()
	if err != nil {
		return "", err
	}

	// Have to trim the line break on conversion
	return strings.TrimSuffix(string(o), "\n"), nil
}

// GetVersionNumber - Gets the version of flutter from the branch directory
func GetVersionNumber(branch string) (string, error) {
	b, err := ioutil.ReadFile(path.Join(versionsPath, branch, "version"))
	if err != nil {
		return "", err
	}

	return string(b), nil
}

// RunDoctor - runs 'flutter doctor' command
func RunDoctor() {
	s := spinner.New(spinner.CharSets[11], 100*time.Millisecond)
	s.Suffix = " Building Flutter Tool"
	s.Start()

	cmd := exec.Command("flutter", "doctor")

	c := make(chan struct{})
	wg.Add(1)
	go func(cmd *exec.Cmd, c chan struct{}) {
		defer wg.Done()
		stdout, err := cmd.StdoutPipe()
		if err != nil {
			panic(err)
		}
		<-c
		scanner := bufio.NewScanner(stdout)
		for scanner.Scan() {
			m := scanner.Text()
			// fmt.Println(m)
			s.Suffix = " " + m
		}
	}(cmd, c)

	c <- struct{}{}
	cmd.Start()

	wg.Wait()
	s.Stop()
	fmt.Println("[✓] Flutter is setup")

}

package fluttertools

import (
	"fmt"
	"io/ioutil"
	"log"
	"os"
	"os/exec"
	"path"
	"strings"
	"time"

	"github.com/briandowns/spinner"
	"github.com/ttacon/chalk"
)

// GetChannel - Clones git from Flutter repo
func GetChannel(versionsPath string, branch string) error {
	s := spinner.New(spinner.CharSets[11], 100*time.Millisecond)
	s.Color("cyan", "bold")
	s.Suffix = " Cloning [" + branch + "]"

	s.Start()

	versionDir := path.Join(versionsPath, branch)

	// clean directory just in case before cloning
	if err := os.RemoveAll(versionDir); err != nil {
		log.Fatal(err)
	}

	_, err := runGit(versionsPath, "clone", "-b", branch, "https://github.com/flutter/flutter.git", branch)
	if err != nil {
		return err
	}

	s.Stop()
	fmt.Println(chalk.Cyan.Color("[✓]"), "Channel ["+branch+"] cloned.")

	return nil

}

// GetChannelInfo = gets channel that is selected
func GetChannelInfo(versionPath string) (string, error) {

	branch, err := runGit(versionPath, "rev-parse", "--abbrev-ref", "HEAD")

	if branch == "HEAD" {
		branch, _ = runGit(versionPath, "tag", "--points-at", "HEAD")
	}

	// Have to trim the line break on conversion
	return branch, err
}

// GetVersionNumber - Gets the version of flutter from the branch directory
func GetVersionNumber(versionPath string) (string, error) {
	b, err := ioutil.ReadFile(path.Join(versionPath, "version"))
	if err != nil {
		return "", err
	}

	return string(b), nil
}

func runGit(execPath string, args ...string) (string, error) {
	cmd := exec.Command("git", args...)
	cmd.Dir = execPath

	// err := cmd.Start()
	// if err != nil {
	// 	log.Fatalf("cmd.Start() failed with '%s'\n", err)
	// }

	// err = cmd.Wait()
	// if err != nil {
	// 	log.Fatalf("cmd.Start() failed with '%s'\n", err)
	// }

	o, err := cmd.CombinedOutput()
	if err != nil {
		return "", err
	}

	return strings.TrimSuffix(string(o), "\n"), nil

}

// RunDoctor - runs 'flutter doctor' command
func RunDoctor() {
	s := spinner.New(spinner.CharSets[11], 100*time.Millisecond)
	s.Color("cyan", "bold")
	s.Suffix = " Setting up Flutter"
	s.Start()

	cmd := exec.Command("flutter", "doctor")

	cmd.Start()

	cmd.Wait()
	s.Stop()
	fmt.Println(chalk.Cyan.Color("[✓]"), "Flutter is setup")
}

// RunDoctor - runs 'flutter doctor' command
// func RunDoctor() {
// 	s := spinner.New(spinner.CharSets[11], 100*time.Millisecond)
// 	s.Color("cyan", "bold")

// 	s.Start()

// 	cmd := exec.Command("flutter", "doctor")

// 	c := make(chan struct{})
// 	wg.Add(1)

// 	go func(cmd *exec.Cmd, c chan struct{}) {
// 		s := spinner.New(spinner.CharSets[11], 100*time.Millisecond)
// 		s.Prefix = "Setting up Flutter"
// 		s.Color("cyan", "bold")
// 		s.Start()

// 		defer wg.Done()
// 		stdout, err := cmd.StdoutPipe()
// 		if err != nil {
// 			panic(err)
// 		}
// 		<-c
// 		scanner := bufio.NewScanner(stdout)
// 		for scanner.Scan() {
// 			m := scanner.Text()
// 			// fmt.Println(m)
// 			if !strings.HasPrefix(m, " ") {
// 				s.Suffix = m
// 			}
// 		}

// 		fmt.Println("[✓] " + "Setup Complete")

// 	}(cmd, c)

// 	c <- struct{}{}
// 	cmd.Start()

// 	cmd.Wait()
// 	s.Stop()
// 	fmt.Println(chalk.Cyan.Color("[✓]"), "Flutter is setup")
// }

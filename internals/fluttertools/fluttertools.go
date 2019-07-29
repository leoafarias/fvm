package fluttertools

import (
	"fmt"
	"log"
	"os"
	"os/exec"
	"path"
	"strings"
	"time"

	"github.com/briandowns/spinner"
	"github.com/ttacon/chalk"
)

const flutterRepo = "https://github.com/flutter/flutter.git"

// GetChannel - Clones git from Flutter repository
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

	_, err := runGit(versionsPath, "clone", "-b", branch, flutterRepo, branch)
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
		branch, err = runGit(versionPath, "tag", "--points-at", "HEAD")
	}

	if err != nil {
		return "", err
	}

	// Have to trim the line break on conversion
	return branch, nil
}

func runGit(execPath string, args ...string) (string, error) {
	cmd := exec.Command("git", args...)
	cmd.Dir = execPath

	o, err := cmd.CombinedOutput()
	if err != nil {
		return "", err
	}

	return strings.TrimSuffix(string(o), "\n"), nil

}

// GetAllVersions - Gets all available versions
func GetAllVersions() ([]string, error) {
	var versions []string
	o, err := runGit(".", "ls-remote", "--tags", flutterRepo)
	if err != nil {
		return []string{}, err
	}

	tags := strings.Fields(o)

	for _, v := range tags {
		if strings.Contains(v, "refs/tags") {
			versions = append(versions, strings.TrimPrefix(v, "refs/tags/"))
		}
	}

	return versions, nil
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

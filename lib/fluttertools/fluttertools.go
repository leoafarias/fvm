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
	homedir "github.com/mitchellh/go-homedir"
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

	o, err := cmd.CombinedOutput()
	if err != nil {
		return "", err
	}

	return strings.TrimSuffix(string(o), "\n"), nil

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
		homeDir, _ := homedir.Dir()

		// Set default flutter home
		flutterHome = path.Join(homeDir, "flutter")

		// Set path to flutter bin
		flutterExec := path.Join(flutterHome, "bin", "flutter")

		// usr/local/bin path to flutter
		usrBinFlutter := path.Join("/", "usr", "local", "bin", "flutter")

		// Always clean up symlink before
		os.RemoveAll(usrBinFlutter)

		// Creates a symlink from the usr/local/bin to the flutter exec in the flutterHome
		if err := os.Symlink(flutterExec, usrBinFlutter); err != nil {
			// fmt.Println(err)
			fmt.Println("Please set your flutter path before using the tool")
			os.Exit(0)
		}

	}

	// Make sure directories exist and are created
	os.MkdirAll(flutterHome, os.ModePerm)

	return flutterHome

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

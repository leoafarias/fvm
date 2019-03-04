package lib

import (
	"errors"
	"fmt"
	"io/ioutil"
	"log"
	"os"
	"path"
	"strings"
	"time"

	"github.com/briandowns/spinner"
	"github.com/leoafarias/fvm/lib/fluttertools"
	homedir "github.com/mitchellh/go-homedir"
	"github.com/ttacon/chalk"
)

var (
	flutterHome   = fluttertools.GetFlutterHome()
	workspaceHome = getWorkspaceHome()
)

// Versions - slice of versions
type Versions []Version

// Version = version struct type
type Version struct {
	Name   string
	number string
	Active bool
	dir    bool
}

// LoadVersion - loads requested version
func LoadVersion(version string) error {

	var lv Version
	var vs Versions

	vs, err := ListVersions()
	if err != nil {
		return err
	}

	for _, v := range vs {

		if v.Name == version {
			lv = v
		}
	}

	// If no version was found, set to be the version
	if (lv == Version{}) {
		lv = Version{
			Name:   version,
			dir:    false,
			Active: false,
		}
	}

	finalVersion, err := setup(lv)
	if err != nil {
		return err
	}

	fmt.Println(chalk.Cyan.Color("[✓] Current Version: "), finalVersion.Name, finalVersion.number)
	return nil

}

func setup(v Version) (Version, error) {

	// If directory doesnt exists get the channel
	if v.dir == false {
		if err := fluttertools.GetChannel(workspaceHome, v.Name); err != nil {
			return Version{}, err
		}
		v.dir = true
	}

	// If there is a directory and not active
	if v.dir && v.Active == false {

		// moves new branch into active
		if err := toggleActive(false, v.Name); err != nil {
			log.Fatal("toggleActive() - Moving new branch into active // ", err)
		}

		v.Active = true
	}

	// If there is no version run Doctor
	if v.number == "" {
		fluttertools.RunDoctor()
		versionNumber, err := fluttertools.GetVersionNumber(flutterHome)
		if err != nil {
			return Version{}, err
		}

		v.number = versionNumber
	}

	return v, nil
}

// ListVersions - lists all the current versions
func ListVersions() (Versions, error) {
	var vs Versions
	files, err := ioutil.ReadDir(workspaceHome)
	if err != nil {
		return Versions{}, err
	}

	for _, f := range files {
		// If file is not a directory skip
		if !f.IsDir() {
			continue
		}
		dir := f.Name()

		versionNumber, _ := fluttertools.GetVersionNumber(path.Join(workspaceHome, dir))

		vs = append(vs, Version{
			Name:   dir,
			number: versionNumber,
			Active: false,
			dir:    true,
		})
	}

	// Get current active channel
	currentVersion, err := fluttertools.GetChannelInfo(flutterHome)
	if err != nil {
		return vs, nil
	}

	// Find active version in Versions and update the status
	for i := range vs {
		if vs[i].Name == currentVersion {
			vs[i].Active = true
		}
	}

	return vs, nil
}

// ShakeVersions - Remove all versions except the active one
func ShakeVersions() error {

	// Gets all the installed versions
	vs, err := ListVersions()
	if err != nil {
		return err
	}

	// Loops all installed versions
	for _, v := range vs {
		// If version matches and its active
		if v.Active == false {
			// Remove the version that is not active
			if err := os.RemoveAll(path.Join(workspaceHome, v.Name)); err != nil {
				return err
			}
		}
	}

	return nil
}

// RemoveVersion - Removes a specifc version
func RemoveVersion(version string) error {
	dirPath := path.Join(workspaceHome, version)

	// Gets all the installed versions
	vs, err := ListVersions()
	if err != nil {
		return err
	}

	// Loops all installed versions
	for _, v := range vs {
		// If version matches and its active
		if v.Name == version && v.Active {
			os.RemoveAll(flutterHome)
		}
	}
	// Remove everything from version directory
	if err := os.RemoveAll(dirPath); err != nil {
		return err
	}

	return nil
}

// CheckVersion = checks if version passed is valid
func CheckVersion(version string) (string, error) {
	// Check if version is one of the channels
	if version == "master" || version == "dev" || version == "beta" || version == "stable" {
		return version, nil
	}

	// If version does not start with a "v" add it
	if !strings.HasPrefix(version, "v") {
		version = "v" + version
	}

	vs, err := fluttertools.GetAllVersions()
	if err != nil {
		return "", err
	}

	for _, v := range vs {
		if v == version {
			return version, nil
		}
	}

	return "", errors.New("Not a valid version number")
}

// toggleActive - Sets from active to inactive and inactive to active versions
func toggleActive(fromActive bool, branch string) error {

	var toPath string

	s := spinner.New(spinner.CharSets[11], 100*time.Millisecond)
	s.Color("cyan", "bold")
	s.Start()

	if fromActive {

		s.Suffix = "Deactivating version [" + branch + "]"
		if err := os.Remove(flutterHome); err != nil {
			log.Fatal(err)
		}
	} else {

		s.Suffix = "Deactivating version [" + branch + "]"
		os.Remove(flutterHome)
		toPath = path.Join(workspaceHome, branch)
		s.Suffix = "Activating version [" + branch + "]"
		err := os.Symlink(toPath, flutterHome)
		if err != nil {
			log.Fatal(err)
		}
	}

	s.Stop()
	fmt.Println(chalk.Cyan.Color("[✓]"), s.Suffix)
	return nil
}

func getWorkspaceHome() string {
	homeDir, _ := homedir.Dir()
	workspaceHome := path.Join(homeDir, "fvm")
	os.MkdirAll(workspaceHome, os.ModePerm)
	return workspaceHome
}

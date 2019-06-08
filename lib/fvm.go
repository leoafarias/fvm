package lib

import (
	"errors"
	"fmt"
	"io/ioutil"
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
	Number string
	Active bool
	Exists bool
}

func (v *Version) setup() error {
	// If directory does not exists get the channel
	if v.Exists == false {
		if err := fluttertools.GetChannel(workspaceHome, v.Name); err != nil {
			return err
		}
		v.Exists = true
	}

	// If there is a directory and not active
	if v.Exists && v.Active == false {

		// activaes version
		if err := v.activate(); err != nil {
			return err
		}

		v.Active = true
	}

	// If there is no version run Doctor
	if v.Number == "" {
		fluttertools.RunDoctor()
		versionNumber, err := fluttertools.GetVersionNumber(flutterHome)
		if err != nil {
			return err
		}

		v.Number = versionNumber
	}

	return nil
}

func (v *Version) remove() error {
	dirPath := path.Join(workspaceHome, v.Name)

	if v.Active {
		os.RemoveAll(flutterHome)
	}

	// Remove everything from version directory
	if err := os.RemoveAll(dirPath); err != nil {
		return err
	}

	v = &Version{}

	return nil
}

func (v *Version) activate() error {
	s := spinner.New(spinner.CharSets[11], 100*time.Millisecond)
	s.Color("cyan", "bold")
	s.Start()
	s.Suffix = "Activating version [" + v.Name + "]"

	if v.Active {
		return nil
	}

	if err := os.Remove(flutterHome); err != nil {
		return err
	}

	toPath := path.Join(workspaceHome, v.Name)

	if err := os.Symlink(toPath, flutterHome); err != nil {
		return err
	}

	s.Stop()
	fmt.Println(chalk.Cyan.Color("[✓]"), s.Suffix)

	return nil
}

// Shake - Removes all versions except the inactive one
func (vs *Versions) Shake() error {
	// Loops all installed versions
	for _, v := range *vs {
		// If version matches and its not active
		if v.Active == false {
			// Remove the version that is not active
			if err := os.RemoveAll(path.Join(workspaceHome, v.Name)); err != nil {
				return err
			}
		}
	}

	return nil
}

// LoadVersion - loads requested version
func LoadVersion(version string) (Version, error) {

	// Checks if its a valid version. Returns corrected
	version, err := CheckVersion(version)
	if err != nil {
		return Version{}, err
	}

	// Gets all currently installed versions
	vs, err := ListVersions()
	if err != nil {
		return Version{}, err
	}

	var lv Version

	// Checks if version to load is currently installed
	for _, v := range vs {
		if v.Name == version {
			lv = v
		}
	}

	// If no version was found, set to be the version
	if (lv == Version{}) {
		lv = Version{
			Name:   version,
			Exists: false,
			Active: false,
		}
	}

	return lv, nil

}

// AddVersion - Adds a new version
func AddVersion(version string) error {
	v, err := LoadVersion(version)
	if err != nil {
		return err
	}

	if err := v.setup(); err != nil {
		return err
	}

	// If the name is the same as the number, name release for friendly message
	if v.Name == ("v" + v.Number) {
		v.Name = "Release"
	}
	fmt.Println(chalk.Cyan.Color("[✓] Current Version: "), v.Name, v.Number)
	return nil
}

// RemoveVersion - Removes a version
func RemoveVersion(version string) error {
	v, err := LoadVersion(version)
	if err != nil {
		return err
	}

	if err := v.remove(); err != nil {
		return err
	}
	return nil
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

		versionNumber, _ := fluttertools.GetVersionNumber(path.Join(workspaceHome, f.Name()))

		vs = append(vs, Version{
			Name:   f.Name(),
			Number: versionNumber,
			Active: false,
			Exists: true,
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

func getWorkspaceHome() string {
	homeDir, _ := homedir.Dir()
	workspaceHome := path.Join(homeDir, "fvm")
	os.MkdirAll(workspaceHome, os.ModePerm)
	return workspaceHome
}

func removeFromSlice(s []int, i int) []int {
	s[i] = s[len(s)-1]
	// We do not need to put s[i] at the end, as it will be discarded anyway
	return s[:len(s)-1]
}

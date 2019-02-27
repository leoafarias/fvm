package lib

import (
	"fmt"
	"io/ioutil"
	"log"
	"os"
	"path"
	"path/filepath"
	"time"

	"github.com/briandowns/spinner"
	"github.com/leoafarias/fvm/lib/fluttertools"
	homedir "github.com/mitchellh/go-homedir"
	"github.com/ttacon/chalk"
)

var (
	homeDir, _    = homedir.Dir()
	flutterHome   = path.Join(homeDir, "flutter")
	workspaceHome = path.Join(homeDir, "fvm")
	versionsDir   = path.Join(workspaceHome, "versions")
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
func LoadVersion(branch string) {

	var lv Version
	var vs Versions

	vs, err := ListVersions()
	if err != nil {
		log.Fatal("ListVersions() - Cannot list channels // ", err)
	}

	for _, v := range vs {

		if v.Name == branch {
			lv = v
		}

		// If active version is not needed version
		if v.Active && v.Name != branch {
			// Move version back to it's diretory
			if err := toggleActive(true, string(v.Name)); err != nil {
				log.Fatal("toggleActive() - Moving active version back to version dir // ", err)
			}
		}
	}

	// If no version was found, set to be the branch
	if (lv == Version{}) {
		lv = Version{
			Name:   branch,
			dir:    false,
			Active: false,
		}
	}

	finalVersion, err := setup(lv)
	if err != nil {
		log.Fatal("setup() - Channel setup did not work // ", err)
	}

	fmt.Println(chalk.Cyan.Color("[✓] Current Version: "), finalVersion.Name, finalVersion.number)

}

func setup(v Version) (Version, error) {

	// If directory doesnt exists get the channel
	if v.dir == false {
		fluttertools.GetChannel(versionsDir, v.Name)
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
	files, err := ioutil.ReadDir(versionsDir)
	if err != nil {
		return Versions{}, err
	}

	for _, f := range files {
		// If file is not a directory skip
		if !f.IsDir() {
			continue
		}
		dir := f.Name()

		versionNumber, _ := fluttertools.GetVersionNumber(path.Join(versionsDir, dir))

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

	// Get current active version
	currentVersionNMumber, _ := fluttertools.GetVersionNumber(flutterHome)

	vs = append(vs, Version{
		Name:   currentVersion,
		number: currentVersionNMumber,
		Active: true,
		dir:    true,
	})

	return vs, nil
}

// RemoveVersions - Remove all the files in the versionPath provided
func RemoveVersions() error {
	folders, err := filepath.Glob(filepath.Join(versionsDir, "*"))
	if err != nil {
		return err
	}
	for _, folder := range folders {
		err = os.RemoveAll(folder)
		if err != nil {
			return err
		}
	}
	return nil
}

// RemoveVersion - Removes a specifc version
func RemoveVersion(version string) error {
	var dirPath string
	vs, err := ListVersions()
	if err != nil {
		log.Fatal("ListVersions() - Cannot list channels // ", err)
	}

	for _, v := range vs {
		if v.Name == version && v.Active {
			dirPath = flutterHome
		} else {
			dirPath = path.Join(versionsDir, version)

		}
	}
	err = os.RemoveAll(dirPath)
	if err != nil {
		return err
	}

	return nil
}

// toggleActive - Sets from active to inactive and inactive to active versions
func toggleActive(fromActive bool, branch string) error {
	var fromPath string
	var toPath string

	s := spinner.New(spinner.CharSets[11], 100*time.Millisecond)
	s.Color("cyan", "bold")

	if fromActive {
		fromPath = flutterHome
		toPath = path.Join(versionsDir, branch)
		s.Suffix = "Deactivating version [" + branch + "]"
	} else {
		fromPath = path.Join(versionsDir, branch)
		toPath = flutterHome
		s.Suffix = "Activating version [" + branch + "]"
	}

	s.Start()

	err := os.Rename(fromPath, toPath)
	if err != nil {
		return err
	}

	s.Stop()
	fmt.Println(chalk.Cyan.Color("[✓]"), s.Suffix)
	return err
}

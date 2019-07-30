package fluttertools

import (
	"fmt"
	"io/ioutil"
	"log"
	"os"
	"path"
	"time"

	"github.com/briandowns/spinner"
	"github.com/leoafarias/fvm/internals/utils"
	"github.com/ttacon/chalk"
)

var (
	flutterHome  = utils.GetFlutterHome()
	versionsHome = utils.GetVersionsHome()
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

// Setup - Does the setup for the flutter version
func (v *Version) Setup() error {
	// If directory does not exists get the channel
	if v.Exists == false {
		log.Printf("Version: %+v not currently downloaded.\n", v)
		if err := GetChannel(versionsHome, v.Name); err != nil {
			return err
		}
		v.Exists = true
	}

	// If there is a directory and not active
	if v.Exists && v.Active == false {
		log.Printf("Version: %+v downloaded but its not active.\n", v)
		// activates version
		if err := v.activate(); err != nil {
			return err
		}

		v.Active = true
	}

	// If there is no version run Doctor
	if v.Number == "" {
		log.Printf("Version: %+v downloaded but not installed.\n", v.Name)
		// RunDoctor()
		versionNumber, err := GetVersionNumber(flutterHome)
		if err != nil {
			return err
		}

		v.Number = versionNumber
	}

	// Check if version exists and is active to avoid installing again
	if v.Exists && v.Active {
		fmt.Printf("%+v\n", v)
		return nil
	}

	return nil
}

// Remove - Removes version from file system
func (v *Version) Remove() error {
	log.Printf("Removing %#v\n", v.Name)
	dirPath := path.Join(versionsHome, v.Name)

	if v.Active {
		log.Printf("%#v is currently active\n", v.Name)
		// If version is active, it should be removed from flutterHome
		dirPath = flutterHome
	}

	// Remove everything from version directory
	log.Printf("Removing %#v from file system\n", v.Name)
	if err := os.RemoveAll(dirPath); err != nil {
		log.Print(err)
		return err
	}

	v = &Version{}

	return nil
}

func (v *Version) activate() error {
	s := spinner.New(spinner.CharSets[11], 100*time.Millisecond)
	s.Color("cyan", "bold")
	s.Start()
	s.Suffix = " Activating version [" + v.Name + "]"

	// We will defer functions for better code readability
	// Important: Last in first out order
	defer fmt.Println(chalk.Cyan.Color("[✓]"), s.Suffix)
	defer s.Stop()

	if v.Active {
		return nil
	}

	// Sets version path to be activated in workspace
	newVersionPath := path.Join(versionsHome, v.Name)

	currentVersion, err := GetChannelInfo(flutterHome)
	if err != nil || currentVersion == "" {
		// If there is an error when getting current active version, or cannot get it.. clean up
		if err := os.RemoveAll(path.Join(flutterHome)); err != nil {
			return err
		}
	}

	oldVersionPath := path.Join(versionsHome, currentVersion)

	// Copy the current versionPath into flutterHome
	err = utils.Move(flutterHome, oldVersionPath)
	if err != nil {
		fmt.Println(err)
	}

	// Copy the current versionPath into flutterHome
	err = utils.Move(newVersionPath, flutterHome)
	if err != nil {
		fmt.Println(err)
	}

	return err
}

// Shake - Removes all versions except the inactive one
func (vs *Versions) Shake() error {
	// Loops all installed versions
	for _, v := range *vs {
		// If version matches and its not active
		if v.Active == false {
			// Remove the version that is not active
			if err := os.RemoveAll(path.Join(versionsHome, v.Name)); err != nil {
				return err
			}
		}
	}

	return nil
}

// GetVersionNumber - Gets the version of flutter from the branch directory
func GetVersionNumber(versionPath string) (string, error) {
	log.Printf("Getting version number from %#v", versionPath)
	b, err := ioutil.ReadFile(path.Join(versionPath, "version"))
	if err != nil {
		log.Printf("No version number found.")
		return "", err
	}

	log.Printf("Version number is %#v", string(b))

	return string(b), nil
}

package lib

import (
	"fmt"
	"io/ioutil"
	"log"
	"os"
	"path"

	"github.com/leoafarias/fvm/fluttertools"
)

const (
	versionsPath  = "versions"
	activeDirPath = versionsPath + "active"
)

// Versions - slice of versions
type Versions []Version

// Version = version struct type
type Version struct {
	Name   string
	number string
	active bool
	dir    bool
}

// LoadVersion - loads requested version
func LoadVersion(branch string) {

	var lv Version
	var vs Versions

	vs, err := ListChannels()
	if err != nil {
		log.Fatal("ListChannels() - Cannot list channels // ", err)
	}

	for _, v := range vs {

		if v.Name == branch {
			lv = v
		}

		// If active version is not needed version
		if v.active && v.Name != branch {
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
			active: false,
		}
	}

	finalVersion, err := channelSetup(lv)
	if err != nil {
		log.Fatal("channelSetup() - Channel setup did not work // ", err)
	}

	fmt.Println("Done! ", finalVersion.Name, finalVersion.number)

}

func channelSetup(v Version) (Version, error) {

	// If directory doesnt exists get the channel
	if v.dir == false {
		fluttertools.GetChannel(v.Name)
		v.dir = true
	}

	// If there is a directory and not active
	if v.dir && v.active == false {

		// moves new branch into active
		if err := toggleActive(false, v.Name); err != nil {
			log.Fatal("toggleActive() - Moving new branch into active // ", err)
		}

		v.active = true
	}

	// If there is no version run Doctor
	if v.number == "" {
		fluttertools.RunDoctor()
		versionNumber, err := fluttertools.GetVersionNumber("active")
		if err != nil {
			return Version{}, err
		}

		v.number = versionNumber
	}

	return v, nil
}

// ListChannels - lists all the current versions
func ListChannels() (Versions, error) {
	var vs Versions
	files, err := ioutil.ReadDir(versionsPath)
	if err != nil {
		return Versions{}, err
	}

	for _, f := range files {
		// If file is not a directory skip
		if !f.IsDir() {
			continue
		}
		dir := f.Name()
		isActive := false
		versionNumber, _ := fluttertools.GetVersionNumber(dir)

		if dir == "active" {
			dir, _ = fluttertools.GetChannelInfo("active")
			isActive = true
		}

		vs = append(vs, Version{
			Name:   dir,
			number: versionNumber,
			active: isActive,
			dir:    true,
		})
	}

	return vs, nil
}

func channelCleanUp(channel string) {
	// clean directory just in case before cloning
	if err := os.RemoveAll(path.Join(versionsPath, channel)); err != nil {
		log.Fatal(err)
	}
}

// toggleActive - Sets from active to inactive and inactive to active versions
func toggleActive(fromActive bool, branch string) error {
	var fromPath string
	var toPath string

	if fromActive {
		fromPath = path.Join(versionsPath, "active")
		toPath = path.Join(versionsPath, branch)
	} else {
		fromPath = path.Join(versionsPath, branch)
		toPath = path.Join(versionsPath, "active")
	}

	err := os.Rename(fromPath, toPath)

	if err != nil {
		return err
	}
	return err
}

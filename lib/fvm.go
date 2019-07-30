package lib

import (
	"errors"
	"fmt"
	"io/ioutil"
	"log"
	"path"
	"strings"

	"github.com/leoafarias/fvm/internals/fluttertools"
	"github.com/leoafarias/fvm/internals/utils"
	"github.com/ttacon/chalk"
)

var (
	flutterHome  = utils.GetFlutterHome()
	versionsHome = utils.GetVersionsHome()
)

// LoadVersion - loads requested version
func LoadVersion(version string) (fluttertools.Version, error) {
	log.Printf("Loading version %#v", version)
	// Checks if its a valid version. Returns corrected
	version, err := IsValidVersion(version)
	if err != nil {
		return fluttertools.Version{}, err
	}

	// Gets all currently installed versions
	vs, err := ListLocalVersions()
	if err != nil {
		return fluttertools.Version{}, err
	}

	var lv fluttertools.Version

	// Checks if version to load is currently installed
	for _, v := range vs {
		if v.Name == version {
			lv = v
		}
	}

	// If no version was found, set to be the version
	if (lv == fluttertools.Version{}) {
		lv = fluttertools.Version{
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

	// Setup version
	if err := v.Setup(); err != nil {
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

	if err := v.Remove(); err != nil {
		return err
	}
	return nil
}

// ListLocalVersions - lists all the current versions
func ListLocalVersions() (fluttertools.Versions, error) {
	var vs fluttertools.Versions
	files, err := ioutil.ReadDir(versionsHome)
	if err != nil {
		return fluttertools.Versions{}, err
	}

	for _, f := range files {
		// If file is not a directory skip
		if !f.IsDir() {
			continue
		}

		versionNumber, _ := fluttertools.GetVersionNumber(path.Join(versionsHome, f.Name()))

		vs = append(vs, fluttertools.Version{
			Name:   f.Name(),
			Number: versionNumber,
			Active: false,
			Exists: true,
		})
	}

	// Get current active channel
	currentVersion, err := fluttertools.GetChannelInfo(flutterHome)
	if err != nil {
		log.Printf("Cannot get current version in FlutterHome\n")
		return vs, nil
	}

	// Add current active version
	log.Printf("#### Current Version: %+v.\n", currentVersion)

	versionNumber, _ := fluttertools.GetVersionNumber(flutterHome)
	vs = append(vs, fluttertools.Version{
		Name:   currentVersion,
		Number: versionNumber,
		Active: true,
		Exists: true,
	})

	return vs, nil
}

// IsValidVersion = checks if version passed is valid
func IsValidVersion(version string) (string, error) {
	// Check if version is one of the channels
	if version == "master" || version == "dev" || version == "beta" || version == "stable" {
		log.Printf("Is a valid channel of %#v", version)
		return version, nil
	}

	// If version does not start with a "v" add it
	if !strings.HasPrefix(version, "v") {
		version = "v" + version
	}

	log.Printf("Getting valid Flutter versions to compare.")
	vs, err := fluttertools.GetAllVersions()
	if err != nil {
		return "", err
	}

	// See if version matches a valid flutter version
	for _, v := range vs {
		if v == version {
			log.Printf("Is a valid version of %#v", version)
			return version, nil
		}
	}

	err = errors.New("Not a valid Flutter version")
	log.Print(err)
	return "", err
}

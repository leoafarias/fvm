package lib

import (
	"fmt"
	"log"
	"os"

	"github.com/schollz/jsonstore"
)

// Version - type of version
// type Version struct {
// 	name    string
// 	version string
// }

const (
	versionsPath  = "./versions"
	activeDirPath = versionsPath + "/active"
)

// LoadVersion - loads requested version
func LoadVersion(branch string) {
	ks, err := jsonstore.Open("data.json")

	if err != nil {
		ks = new(jsonstore.JSONStore)
	}

	setActiveVersion(branch, ks)
}

func setActiveVersion(branch string, ks *jsonstore.JSONStore) {
	activeBranch, err := getActiveBranch(ks)

	// removes active version back to the version directory
	if err != nil {
		if err := os.RemoveAll(activeDirPath); err != nil {
			log.Fatal(err)
		}
		DeleteSave(ks, "active")
	} else {

		if activeBranch == branch {
			return
		}

		if err := toggleActive(true, activeBranch); err != nil {
			log.Fatal("toggleActive() - Moving active version back to version dir // ", err)
		}

		DeleteSave(ks, "active")
	}

	if _, err := Exists(branch); err != nil {
		GetFlutterChannel(branch)
	}

	// moves new branch into active
	if err := toggleActive(false, branch); err != nil {
		log.Fatal("toggleActive() - Moving new branch into active // ", err)
	}

	if err := SetSave(ks, "active", branch); err != nil {
		log.Fatal("SetSave() - cannot save new state // ", err)
	}

	version, err := GetFlutterVersion("active")
	if err != nil {
		RunFlutterDoctor()
		version, err = GetFlutterVersion("active")
		if err != nil {
			log.Fatal("GetFlutterVersion() - Could not get flutter version after running doctor // ", err)
		}
	}

	fmt.Println("Current Version: " + version)

}

// toggleActive - Sets from active to inactive and inactive to active versions
func toggleActive(fromActive bool, branch string) error {
	var fromPath string
	var toPath string

	if fromActive {
		fromPath = activeDirPath
		toPath = versionsPath + "/" + branch
	} else {
		fromPath = versionsPath + "/" + branch
		toPath = activeDirPath
	}

	err := os.Rename(fromPath, toPath)
	if err != nil {
		return err
	}
	return err
}

func getActiveBranch(ks *jsonstore.JSONStore) (string, error) {
	var activeBranch string
	fmt.Println("Active Branch", activeBranch)
	if err := ks.Get("active", &activeBranch); err != nil {
		fmt.Println("Error on get", activeBranch)
		return "", err
	}
	fmt.Println("After get Branch", activeBranch)
	if _, err := Exists("active"); err != nil {

		return "", err
	}
	return activeBranch, nil
}

package lib

import (
	"fmt"
	"log"
	"os"

	"github.com/schollz/jsonstore"
)

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
		ks.Delete("active")
	} else {

		if activeBranch == branch {
			return
		}

		if err := toggleActive(true, activeBranch); err != nil {
			log.Fatal("toggleActive() - Moving active version back to version dir // ", err)
		}

		DeleteSave(ks, "active")
	}

	if _, err := exists(branch); err != nil {
		GetFlutterChannel(branch)
	}

	// moves new branch into active
	if err := toggleActive(false, branch); err != nil {
		log.Fatal("toggleActive() - Moving new branch into active // ", err)
	}

	SetSave(ks, "acrive", branch)
	if err := ks.Set("active", branch); err != nil {
		log.Fatal("ks.Set() - Storing state of active version // ", err)
	}

	if err := jsonstore.Save(ks, "data.json"); err != nil {
		log.Fatal("jsonstore.save() - Could not save state // ", err)
	}

	RunFlutterDoctor()
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
	if _, err := exists("active"); err != nil {

		return "", err
	}
	return activeBranch, nil
}

func exists(branch string) (bool, error) {
	// check if version directory exists
	if _, err := os.Stat(versionsPath + "/" + branch); err != nil {
		if os.IsNotExist(err) {
			// -> version directory does not exist
			fmt.Println("Branch does not exist")
			return false, err
		}
		// -> error when getting file
		log.Fatalf("cmd.Run() failed with %s\n", err)
	}
	return true, nil
}

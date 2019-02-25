package lib

import (
	"fmt"
	"io/ioutil"
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
	// ks, err := jsonstore.Open("data.json")

	// if err != nil {
	// 	ks = new(jsonstore.JSONStore)
	// }

	// os.Getwd()

	// setActiveVersion(branch, ks)

	// cmd := exec.Command("git", "rev-parse", "--abbrev-ref", "--symbolic", "@{u}")
	// b, _ := cmd.Output()
	// fmt.Println(string(b))

	// cmd = exec.Command("git", "rev-parse", "--abbrev-ref", "HEAD")
	// b, _ = cmd.Output()

	setActiveVersion(branch)

}

func setActiveVersion(branch string) {
	activeBranch, err := GetChannel("active")
	if err != nil {
		activeBranch = "NO_ACTIVE"
	}

	if branch != activeBranch && branch != "NO_ACTIVE" {
		if err := toggleActive(true, activeBranch); err != nil {
			log.Fatal("toggleActive() - Moving active version back to version dir // ", err)
		}
	}

}

func channelExists(channel string) bool {
	files, err := ioutil.ReadDir(versionsPath)
	if err != nil {
		log.Fatal(err)
	}
	for _, f := range files {
		if f.Name() == channel {
			return true
		}
	}
	return false
}

func flutterSetup(branch string) {

	if !channelExists(branch) {
		GetFlutterChannel(branch)
	}

	// moves new branch into active
	if err := toggleActive(false, branch); err != nil {
		log.Fatal("toggleActive() - Moving new branch into active // ", err)
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

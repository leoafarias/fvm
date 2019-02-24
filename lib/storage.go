package lib

import (
	"log"
	"os"

	"github.com/schollz/jsonstore"
)

const storageFile = "data.json"

// SetSave - Sets a value and saves in one function
func SetSave(ks *jsonstore.JSONStore, branch string, value interface{}) error {
	err := ks.Set(branch, value)

	err = jsonstore.Save(ks, storageFile)

	return err
}

// DeleteSave = Deletes a key and saves the file in one function
func DeleteSave(ks *jsonstore.JSONStore, branch string) error {
	ks.Delete(branch)

	err := jsonstore.Save(ks, storageFile)

	if err := os.RemoveAll(versionsPath + "/" + branch); err != nil {
		log.Fatal(err)
	}

	return err
}

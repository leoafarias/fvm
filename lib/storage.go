package lib

import (
	"log"

	"github.com/schollz/jsonstore"
)

const storageFile = "data.json"

// SetSave - Sets a value and saves in one function
func SetSave(ks *jsonstore.JSONStore, key string, value interface{}) error {
	if err := ks.Set(key, value); err != nil {
		log.Fatal("ks.Set() - Storing state of active version // ", err)
	}

	if err := jsonstore.Save(ks, storageFile); err != nil {
		log.Fatal("jsonstore.save() - Could not save state // ", err)
	}

	// return error
}

// DeleteSave = Deletes a key and saves the file in one function
func DeleteSave(ks *jsonstore.JSONStore, key string) error {
	ks.Delete(key)

	if err := jsonstore.Save(ks, storageFile); err != nil {
		log.Fatal("jsonstore.save() - Could not save state // ", err)
	}

	// return err
}

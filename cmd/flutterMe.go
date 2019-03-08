// Copyright © 2019 NAME HERE <EMAIL ADDRESS>
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

package cmd

import (
	"fmt"
	"os/exec"
	"path"
	"strings"

	"github.com/leoafarias/fvm/lib/fluttertools"

	"github.com/leoafarias/fvm/lib"

	"github.com/spf13/cobra"
)

// flutterMeCmd represents the flutterMe command
var flutterMeCmd = &cobra.Command{
	Use:   "flutter-me",
	Short: "Just sets flutter up for you",
	Run: func(cmd *cobra.Command, args []string) {
		if err := lib.AddVersion("stable"); err != nil {
			fmt.Print("There was an issue setting up Flutter")
		}

		flutterHome := fluttertools.GetFlutterHome()
		flutterGalleryPath := path.Join(flutterHome, "examples", "flutter_gallery")

		fmt.Println(flutterGalleryPath)

		if _, err := runCmd(".", "open", "-a", "Simulator"); err != nil {
			fmt.Print(err)
			fmt.Print("Could not start simulator")
		}

		if _, err := runCmd(flutterGalleryPath, "flutter", "packages", "get"); err != nil {
			fmt.Print(err)
			fmt.Print("Could not get packages")
		}

		if _, err := runCmd(flutterGalleryPath, "flutter", "run"); err != nil {
			fmt.Print(err)
			fmt.Print("Could not run Flutter app")
		}

		if _, err := runCmd(flutterGalleryPath, "code", "."); err != nil {
			fmt.Print(err)
			fmt.Print("Could not open visual studio code")
		}

		if _, err := runCmd(".", "code", "--install-extension", "dart-code.dart-code"); err != nil {
			fmt.Print(err)
		}

		if _, err := runCmd(".", "code", "--install-extension", "dart-code.flutter"); err != nil {
			fmt.Print(err)
		}

	},
}

func runCmd(execPath string, key string, args ...string) (string, error) {
	cmd := exec.Command(key, args...)
	cmd.Dir = execPath

	o, err := cmd.CombinedOutput()
	if err != nil {
		return "", err
	}

	return strings.TrimSuffix(string(o), "\n"), nil

}

func init() {
	rootCmd.AddCommand(flutterMeCmd)

	// Here you will define your flags and configuration settings.

	// Cobra supports Persistent Flags which will work for this command
	// and all subcommands, e.g.:
	// flutterMeCmd.PersistentFlags().String("foo", "", "A help for foo")

	// Cobra supports local flags which will only run when this command
	// is called directly, e.g.:
	// flutterMeCmd.Flags().BoolP("toggle", "t", false, "Help message for toggle")
}

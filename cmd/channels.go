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
	"os"
	"path/filepath"

	"github.com/leoafarias/fvm/lib"
	"github.com/spf13/cobra"
)

// Upgrade - flag to trigger a full channel upgrade
var Upgrade bool

// masterCmd represents the master command
var masterCmd = &cobra.Command{
	Use:   "master",
	Short: "Switch to the master channel",
	Run: func(cmd *cobra.Command, args []string) {
		lib.AddVersion("master")
	},
}

// devCmd represents the dev command
var devCmd = &cobra.Command{
	Use:   "dev",
	Short: "Switch to the dev channel",
	Run: func(cmd *cobra.Command, args []string) {
		lib.AddVersion("dev")
	},
}

// betaCmd represents the beta command
var betaCmd = &cobra.Command{
	Use:   "beta",
	Short: "Switch to the beta channel",
	Run: func(cmd *cobra.Command, args []string) {
		lib.AddVersion("beta")
	},
}

// stableCmd represents the stable command
var stableCmd = &cobra.Command{
	Use:   "stable",
	Short: "Switch to the stable channel",
	Run: func(cmd *cobra.Command, args []string) {
		lib.AddVersion("stable")
	},
}

// stableCmd represents the stable command
var dirCmd = &cobra.Command{
	Use:   "dir",
	Short: "Current Directory",
	Run: func(cmd *cobra.Command, args []string) {
		ex, err := os.Executable()
		if err != nil {
			panic(err)
		}
		exPath := filepath.Dir(ex)
		fmt.Println(exPath)
	},
}

func init() {
	rootCmd.AddCommand(masterCmd)
	rootCmd.AddCommand(devCmd)
	rootCmd.AddCommand(betaCmd)
	rootCmd.AddCommand(stableCmd)
	rootCmd.AddCommand(dirCmd)

	rootCmd.PersistentFlags().BoolVarP(&Upgrade, "upgrade", "u", false, "Gets the latest version of the channel")

}

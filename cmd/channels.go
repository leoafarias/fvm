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
	"github.com/leoafarias/fvm/lib"
	"github.com/spf13/cobra"
)

// masterCmd represents the master command
var masterCmd = &cobra.Command{
	Use:   "master",
	Short: "Switch to the master channel",
	Run: func(cmd *cobra.Command, args []string) {
		lib.LoadVersion("master")
	},
}

// devCmd represents the dev command
var devCmd = &cobra.Command{
	Use:   "dev",
	Short: "Switch to the dev channel",
	Run: func(cmd *cobra.Command, args []string) {
		lib.LoadVersion("dev")
	},
}

// betaCmd represents the beta command
var betaCmd = &cobra.Command{
	Use:   "beta",
	Short: "Switch to the beta channel",
	Run: func(cmd *cobra.Command, args []string) {
		lib.LoadVersion("beta")
	},
}

// stableCmd represents the stable command
var stableCmd = &cobra.Command{
	Use:   "stable",
	Short: "Switch to the stable channel",
	Run: func(cmd *cobra.Command, args []string) {
		lib.LoadVersion("stable")
	},
}

func init() {
	rootCmd.AddCommand(masterCmd)
	rootCmd.AddCommand(devCmd)
	rootCmd.AddCommand(betaCmd)
	rootCmd.AddCommand(stableCmd)

	// Here you will define your flags and configuration settings.

	// Cobra supports Persistent Flags which will work for this command
	// and all subcommands, e.g.:
	// channelCmd.PersistentFlags().String("foo", "", "A help for foo")

	// Cobra supports local flags which will only run when this command
	// is called directly, e.g.:
	// channelCmd.Flags().BoolP("toggle", "t", false, "Help message for toggle")
}

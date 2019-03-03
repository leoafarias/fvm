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
	"errors"
	"fmt"
	"log"
	"os"
	"strings"

	"github.com/leoafarias/fvm/lib"
	"github.com/manifoldco/promptui"
	homedir "github.com/mitchellh/go-homedir"
	"github.com/spf13/cobra"
	"github.com/spf13/viper"
)

var cfgFile string

// rootCmd represents the base command when called without any subcommands
var rootCmd = &cobra.Command{
	Use:   "fvm",
	Short: "Lists all the installed versions of Flutter",
	Args: func(cmd *cobra.Command, args []string) error {
		if len(args) > 1 {
			return errors.New("Can only accept one argument")
		}

		return nil
	},
	// Uncomment the following line if your bare application
	// has an action associated with it:
	Run: func(cmd *cobra.Command, args []string) {
		if len(args) == 1 {
			getVersion(args)
		} else {
			versionPicker()
		}
	},
}

func getVersion(args []string) {
	var version string
	if strings.HasPrefix(args[0], "v") {
		version = args[0]
	} else {
		version = "v" + args[0]
	}
	lib.LoadVersion(version)
}

func versionPicker() {
	// var options []string
	vs, err := lib.ListVersions()
	if err != nil {
		log.Fatal(err)
	}

	if len(vs) == 0 {
		fmt.Println("No Flutter versions installed")
		os.Exit(0)
	}

	templates := promptui.SelectTemplates{
		Active:   `👉  {{ .Name | cyan | bold }}`,
		Inactive: `   {{ .Name | cyan }}`,
		Selected: `{{ "✔" | green | bold }} {{ "Channel" | bold }}: {{ .Name | cyan }}`,
	}

	list := promptui.Select{
		Label:     "Choose Installed Versions",
		Items:     vs,
		Templates: &templates,
	}

	i, _, err := list.Run()
	if err != nil {
		fmt.Printf("Prompt failed %v\n", err)
		return
	}

	lib.LoadVersion(vs[i].Name)
}

// Execute adds all child commands to the root command and sets flags appropriately.
// This is called by main.main(). It only needs to happen once to the rootCmd.
func Execute() {
	if err := rootCmd.Execute(); err != nil {
		fmt.Println(err)
		os.Exit(1)
	}
}

func init() {
	cobra.OnInitialize(initConfig)

	// Here you will define your flags and configuration settings.
	// Cobra supports persistent flags, which, if defined here,
	// will be global for your application.
	// rootCmd.PersistentFlags().StringVar(&cfgFile, "config", "", "config file (default is $HOME/.fvm.yaml)")

	// Cobra also supports local flags, which will only run
	// when this action is called directly.
	// rootCmd.Flags().BoolP("toggle", "t", false, "Help message for toggle")
}

// initConfig reads in config file and ENV variables if set.
func initConfig() {
	if cfgFile != "" {
		// Use config file from the flag.
		viper.SetConfigFile(cfgFile)
	} else {
		// Find home directory.
		home, err := homedir.Dir()
		if err != nil {
			fmt.Println(err)
			os.Exit(1)
		}

		// Search config in home directory with name ".fvm" (without extension).
		viper.AddConfigPath(home)
		viper.SetConfigName(".fvm")
	}

	viper.AutomaticEnv() // read in environment variables that match

	// If a config file is found, read it in.
	if err := viper.ReadInConfig(); err == nil {
		fmt.Println("Using config file:", viper.ConfigFileUsed())
	}
}

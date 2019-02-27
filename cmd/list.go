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
	"log"
	"os"

	"github.com/leoafarias/fvm/lib"
	"github.com/manifoldco/promptui"
	"github.com/spf13/cobra"
)

// listCmd represents the list command
var listCmd = &cobra.Command{
	Use:   "list",
	Short: "Lists currently installed channels",
	Run: func(cmd *cobra.Command, args []string) {
		// var options []string
		vs, err := lib.ListVersions()
		if err != nil {
			log.Fatal(err)
		}
		fmt.Println(len(vs))
		if len(vs) == 0 {
			fmt.Println("No Flutter versions installed")
			os.Exit(1)
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
	},
}

func init() {
	rootCmd.AddCommand(listCmd)

	// Here you will define your flags and configuration settings.

	// Cobra supports Persistent Flags which will work for this command
	// and all subcommands, e.g.:
	// listCmd.PersistentFlags().String("foo", "", "A help for foo")

	// Cobra supports local flags which will only run when this command
	// is called directly, e.g.:
	// listCmd.Flags().BoolP("toggle", "t", false, "Help message for toggle")
}

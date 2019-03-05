package cmd

import (
	"fmt"
	"os"

	"github.com/leoafarias/fvm/lib/fluttertools"

	"github.com/leoafarias/fvm/lib"
	"github.com/manifoldco/promptui"
	"github.com/spf13/cobra"
)

// releasesCmd represents the releases command
var releasesCmd = &cobra.Command{
	Use:   "releases",
	Short: "A brief description of your command",
	Long: `A longer description that spans multiple lines and likely contains examples
and usage of using your command. For example:

Cobra is a CLI library for Go that empowers applications.
This application is a tool to generate the needed files
to quickly create a Cobra application.`,
	Run: func(cmd *cobra.Command, args []string) {
		releasePicker()
	},
}

func releasePicker() {
	// var options []string
	vs, err := fluttertools.GetAllVersions()
	if err != nil {
		fmt.Println("Could not get Flutter releases")
		os.Exit(0)
	}

	templates := promptui.SelectTemplates{
		Active:   `👉  {{ . | cyan | bold }}`,
		Inactive: `   {{ . | cyan }}`,
		Selected: `{{ "✔" | green | bold }} {{ "Channel" | bold }}: {{ . | cyan }}`,
	}

	list := promptui.Select{
		Label:     "Choose a release",
		Items:     vs,
		Size:      20,
		Templates: &templates,
	}

	i, _, err := list.Run()
	if err != nil {
		fmt.Printf("Prompt failed %v\n", err)
		return
	}

	lib.AddVersion(vs[i])
}

func init() {
	rootCmd.AddCommand(releasesCmd)
}

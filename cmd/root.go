package cmd

import (
	"errors"
	"fmt"
	"log"
	"os"

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
			v, err := lib.CheckVersion(args[0])
			if err != nil {
				fmt.Println("Not a valid version")
				os.Exit(0)
			}
			lib.AddVersion(v)
		} else {
			versionPicker()
		}
	},
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
		Active:   `👉  {{ .Name | cyan | bold }}{{ "/" | cyan | bold }}{{ .Number | cyan | bold}}`,
		Inactive: `   {{ .Name | white }}`,
		Selected: `{{ "✔" | green | bold }} {{ "Version" | bold }}: {{ .Name | cyan }}`,
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

	lib.AddVersion(vs[i].Name)
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

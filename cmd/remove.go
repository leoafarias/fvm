package cmd

import (
	"errors"
	"fmt"
	"os"

	"github.com/leoafarias/fvm/lib"
	"github.com/spf13/cobra"
)

// removeCmd represents the remove command
var removeCmd = &cobra.Command{
	Use:   "remove [version]",
	Short: "Removes a version that is already installed ",
	Args: func(cmd *cobra.Command, args []string) error {
		if len(args) != 1 {
			return errors.New("What is the version")
		}

		return nil
	},
	Run: func(cmd *cobra.Command, args []string) {
		v, err := lib.CheckVersion(args[0])
		if err != nil {
			fmt.Println("Not a valid version")
			os.Exit(0)
		}
		lib.RemoveVersion(v)
	},
}

func init() {
	rootCmd.AddCommand(removeCmd)
}

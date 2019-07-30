package cmd

import (
	"errors"

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
		lib.RemoveVersion(args[0])
	},
}

func init() {
	rootCmd.AddCommand(removeCmd)
}

package cmd

import (
	"github.com/leoafarias/fvm/lib"
	"github.com/spf13/cobra"
)

// pruneCmd represents the prune command
var shakeCmd = &cobra.Command{
	Use:   "shake",
	Short: "Remove all flutter versions",

	Run: func(cmd *cobra.Command, args []string) {
		lib.ShakeVersions()
	},
}

func init() {
	rootCmd.AddCommand(shakeCmd)
}

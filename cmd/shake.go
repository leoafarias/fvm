package cmd

import (
	"log"
	"os"

	"github.com/leoafarias/fvm/lib"
	"github.com/spf13/cobra"
)

// pruneCmd represents the prune command
var shakeCmd = &cobra.Command{
	Use:   "shake",
	Short: "Remove all flutter versions",

	Run: func(cmd *cobra.Command, args []string) {
		vs, err := lib.ListVersions()
		if err != nil {
			log.Fatal(err)
			os.Exit(0)
		}

		vs.Shake()
	},
}

func init() {
	rootCmd.AddCommand(shakeCmd)
}
